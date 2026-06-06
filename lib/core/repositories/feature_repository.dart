import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/habit_models.dart';
import '../models/settings_models.dart';
import '../models/task_models.dart';
import '../models/user_models.dart';
import '../services/family_controls_local_store.dart';
import '../services/offline_cache.dart';
import '../services/supabase_service.dart';
import '../services/write_queue.dart';
import '../config/apple_review_compliance.dart';
import 'focus_repository.dart';

class FeatureRepository {
  static const String adultContentShieldMarker = '__ADULT_CONTENT__';
  final SupabaseService _supabaseService;
  final FamilyControlsLocalStore _familyControlsLocalStore;
  late final FocusRepository _focusRepository = FocusRepository(
    supabaseService: _supabaseService,
  );

  FeatureRepository({
    SupabaseService? supabaseService,
    FamilyControlsLocalStore? familyControlsLocalStore,
  }) : _supabaseService = supabaseService ?? SupabaseService(),
       _familyControlsLocalStore =
           familyControlsLocalStore ?? FamilyControlsLocalStore();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;
  bool get _useLocalFamilyControlsStorage =>
      AppleReviewCompliance.exposesLocalOnlyFamilyControls;

  String? normalizeDomainInput(
    String? domain, {
    Set<String> allowedSpecialValues = const {},
  }) {
    final value = domain?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    if (allowedSpecialValues.contains(value)) return value;
    return value
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\\.'), '')
        .split('/')
        .first;
  }

  Future<AppSettings?> getAppSettings() async {
    try {
      final response = await _client
          .from('app_settings')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();
      if (response == null) {
        await OfflineCache.writeList('app_settings_v1', const []);
        return null;
      }
      await OfflineCache.writeList('app_settings_v1', [
        response.cast<String, dynamic>(),
      ]);
      return AppSettings.fromJson(response);
    } catch (_) {
      final cached = await OfflineCache.readList('app_settings_v1');
      if (cached == null || cached.isEmpty) return null;
      return AppSettings.fromJson(cached.first);
    }
  }

  Future<void> saveActiveApps(List<String> apps) async {
    final existing = await getAppSettings();
    if (existing == null) {
      await _client.from('app_settings').insert({
        'created_by': _currentUserId,
        'active_apps': apps,
      });
      return;
    }

    await _client
        .from('app_settings')
        .update({'active_apps': apps})
        .eq('id', existing.id)
        .eq('created_by', _currentUserId);
  }

  Future<String> saveActiveAppsFast(
    List<String> apps, {
    String? settingsId,
  }) async {
    if (settingsId != null && settingsId.isNotEmpty) {
      await _client
          .from('app_settings')
          .update({'active_apps': apps})
          .eq('id', settingsId)
          .eq('created_by', _currentUserId);
      return settingsId;
    }

    final created = await _client
        .from('app_settings')
        .upsert({
          'created_by': _currentUserId,
          'active_apps': apps,
        }, onConflict: 'created_by')
        .select('id')
        .single();
    return created['id'] as String;
  }

  Future<List<Note>> getNotes() async {
    try {
      final response = await _client
          .from('notes')
          .select()
          .eq('created_by', _currentUserId)
          .order('updated_date', ascending: false);
      final raw = (response as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
      await OfflineCache.writeList('notes_v1', raw);
      return raw.map(Note.fromJson).toList(growable: false);
    } catch (_) {
      final cached = await OfflineCache.readList('notes_v1');
      if (cached == null) return const [];
      return cached.map(Note.fromJson).toList(growable: false);
    }
  }

  Future<int> countNotes() async {
    final response = await _client
        .from('notes')
        .select('id')
        .eq('created_by', _currentUserId);
    return (response as List).length;
  }

  Future<String> createNote(String title, String content) async {
    final clientId = const Uuid().v4();
    final payload = {
      'id': clientId,
      'created_by': _currentUserId,
      'title': title,
      'content': content,
      'updated_date': DateTime.now().toIso8601String(),
    };
    try {
      final inserted = await _client
          .from('notes')
          .insert(payload)
          .select('id')
          .single();
      return inserted['id'] as String;
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'notes',
        type: WriteOpType.insert,
        payload: payload,
      );
      // Optimistically append to cache so the notes list shows the new note.
      final cached = await OfflineCache.readList('notes_v1') ?? const [];
      await OfflineCache.writeList('notes_v1', [
        Map<String, dynamic>.from(payload),
        ...cached,
      ]);
      return clientId;
    }
  }

  Future<void> updateNote(String id, String title, String content) async {
    final payload = {
      'title': title,
      'content': content,
      'updated_date': DateTime.now().toIso8601String(),
    };
    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('notes')
          .update(payload)
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'notes',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  Future<void> updateBlockedWebsiteDomain(String id, String? domain) async {
    final normalized = normalizeDomainInput(
      domain,
      allowedSpecialValues: {adultContentShieldMarker},
    );
    final nextValue = (normalized != null && normalized.isNotEmpty)
        ? normalized
        : null;
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.updateBlockedWebsiteDomain(id, nextValue);
      return;
    }
    if (nextValue == null) return;
    await _client
        .from('blocked_websites')
        .update({'url_domain': nextValue})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> updateBlockedAppName(String id, String appName) async {
    final trimmed = appName.trim();
    if (trimmed.isEmpty) return;
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.updateBlockedAppName(id, trimmed);
      return;
    }
    await _client
        .from('blocked_apps')
        .update({'app_name': trimmed})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> deleteRestPeriod(String id) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.deleteRestPeriod(id);
      return;
    }
    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('rest_periods')
          .delete()
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'rest_periods',
        type: WriteOpType.delete,
        match: match,
      );
    }
  }

  Future<void> deleteNote(String id) async {
    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('notes')
          .delete()
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'notes',
        type: WriteOpType.delete,
        match: match,
      );
    }
  }

  Future<List<Objective>> getObjectives() async {
    try {
      final response = await _client
          .from('objectives')
          .select()
          .eq('created_by', _currentUserId)
          .eq('archived', false)
          .order('created_at', ascending: false);
      final raw = (response as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
      await OfflineCache.writeList('objectives_v1', raw);
      return raw.map(Objective.fromJson).toList(growable: false);
    } catch (_) {
      final cached = await OfflineCache.readList('objectives_v1');
      if (cached == null) return const [];
      return cached.map(Objective.fromJson).toList(growable: false);
    }
  }

  Future<Objective?> createObjective(String title) async {
    if (title.trim().isEmpty) return null;
    final clientId = const Uuid().v4();
    final payload = {
      'id': clientId,
      'created_by': _currentUserId,
      'title': title.trim(),
      'archived': false,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      final response = await _client
          .from('objectives')
          .insert(payload)
          .select()
          .single();
      return Objective.fromJson(response);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'objectives',
        type: WriteOpType.insert,
        payload: payload,
      );
      final cached = await OfflineCache.readList('objectives_v1') ?? const [];
      await OfflineCache.writeList('objectives_v1', [
        Map<String, dynamic>.from(payload),
        ...cached,
      ]);
      try {
        return Objective.fromJson(payload);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> archiveObjective(String objectiveId) async {
    const payload = {'archived': true};
    final match = {'id': objectiveId, 'created_by': _currentUserId};
    try {
      await _client
          .from('objectives')
          .update(payload)
          .eq('id', objectiveId)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'objectives',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  Future<List<EventType>> getEventTypes() async {
    try {
      final response = await _client
          .from('event_types')
          .select()
          .eq('created_by', _currentUserId)
          .order('created_at', ascending: false);
      final raw = (response as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
      await OfflineCache.writeList('event_types_v1', raw);
      return raw.map(EventType.fromJson).toList(growable: false);
    } catch (_) {
      final cached = await OfflineCache.readList('event_types_v1');
      if (cached == null) return const [];
      return cached.map(EventType.fromJson).toList(growable: false);
    }
  }

  Future<void> createEventType(String name, String color, String icon) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final payload = {
      'id': const Uuid().v4(),
      'created_by': _currentUserId,
      'name': trimmedName,
      'color': color,
      'icon': icon,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await _client.from('event_types').insert(payload);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'event_types',
        type: WriteOpType.insert,
        payload: payload,
      );
      final cached = await OfflineCache.readList('event_types_v1') ?? const [];
      await OfflineCache.writeList('event_types_v1', [
        Map<String, dynamic>.from(payload),
        ...cached,
      ]);
    }
  }

  Future<void> deleteEventType(String id) async {
    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('event_types')
          .delete()
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'event_types',
        type: WriteOpType.delete,
        match: match,
      );
    }
  }

  Future<WinStreak?> getWinStreak() async {
    return _focusRepository.getOrRepairWinStreak();
  }

  Future<List<BlockedApp>> getBlockedApps() async {
    if (_useLocalFamilyControlsStorage) {
      return _familyControlsLocalStore.getBlockedApps();
    }
    try {
      final response = await _client
          .from('blocked_apps')
          .select()
          .eq('created_by', _currentUserId)
          .order('created_at', ascending: false);
      final raw = (response as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
      await OfflineCache.writeList('blocked_apps_v1', raw);
      return raw.map(BlockedApp.fromJson).toList(growable: false);
    } catch (_) {
      final cached = await OfflineCache.readList('blocked_apps_v1');
      if (cached == null) return const [];
      return cached.map(BlockedApp.fromJson).toList(growable: false);
    }
  }

  Future<BlockedApp?> createBlockedAppRecord(String appName) async {
    final trimmedName = appName.trim();
    if (trimmedName.isEmpty) return null;
    if (_useLocalFamilyControlsStorage) {
      return _familyControlsLocalStore.createBlockedAppRecord(
        createdBy: _currentUserId,
        appName: trimmedName,
      );
    }
    final payload = {
      'id': const Uuid().v4(),
      'created_by': _currentUserId,
      'app_name': trimmedName,
      'time_limit_minutes': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      final response = await _client
          .from('blocked_apps')
          .insert(payload)
          .select()
          .single();
      return BlockedApp.fromJson(response);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'blocked_apps',
        type: WriteOpType.insert,
        payload: payload,
      );
      final cached = await OfflineCache.readList('blocked_apps_v1') ?? const [];
      await OfflineCache.writeList('blocked_apps_v1', [
        Map<String, dynamic>.from(payload),
        ...cached,
      ]);
      try {
        return BlockedApp.fromJson(payload);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> createBlockedApp(String appName) async {
    await createBlockedAppRecord(appName);
  }

  Future<void> deleteBlockedApp(String id) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.deleteBlockedApp(id);
      return;
    }
    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('blocked_apps')
          .delete()
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'blocked_apps',
        type: WriteOpType.delete,
        match: match,
      );
    }
  }

  Future<void> setAdultContentShieldEnabled(bool enabled) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.setAdultContentShieldEnabled(
        enabled: enabled,
        createdBy: _currentUserId,
        marker: adultContentShieldMarker,
      );
      return;
    }
    if (enabled) {
      final existing = await _client
          .from('blocked_websites')
          .select('id')
          .eq('created_by', _currentUserId)
          .eq('url_domain', adultContentShieldMarker)
          .maybeSingle();
      if (existing == null) {
        await _client.from('blocked_websites').insert({
          'created_by': _currentUserId,
          'url_domain': adultContentShieldMarker,
          'time_limit_minutes': 0,
        });
      }
    } else {
      await _client
          .from('blocked_websites')
          .delete()
          .eq('created_by', _currentUserId)
          .eq('url_domain', adultContentShieldMarker);
    }

    // Keep the native focus blocker in sync so this toggle has direct effect.
    try {
      await _client
          .from('block_lists')
          .update({'adult_blocking': enabled})
          .eq('created_by', _currentUserId);
    } catch (_) {
      // Ignore if block_lists is not available in this environment.
    }
  }

  Future<void> addBlockedAppTime(String id, int minutes) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.addBlockedAppTime(id, minutes);
      return;
    }
    final row = await _client
        .from('blocked_apps')
        .select('time_limit_minutes')
        .eq('id', id)
        .eq('created_by', _currentUserId)
        .maybeSingle();
    if (row == null) return;
    final current = (row['time_limit_minutes'] as num?)?.toInt() ?? 0;
    await _client
        .from('blocked_apps')
        .update({'time_limit_minutes': current + minutes})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> setBlockedWebsiteTime(String id, int minutes) async {
    final safe = minutes < 0 ? 0 : minutes;
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.setBlockedWebsiteTime(id, safe);
      return;
    }
    await _client
        .from('blocked_websites')
        .update({'time_limit_minutes': safe})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> setBlockedAppTime(String id, int minutes) async {
    final safe = minutes < 0 ? 0 : minutes;
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.setBlockedAppTime(id, safe);
      return;
    }
    await _client
        .from('blocked_apps')
        .update({'time_limit_minutes': safe})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<List<BlockedWebsite>> getBlockedWebsites() async {
    if (_useLocalFamilyControlsStorage) {
      return _familyControlsLocalStore.getBlockedWebsites();
    }
    try {
      final response = await _client
          .from('blocked_websites')
          .select()
          .eq('created_by', _currentUserId)
          .order('created_at', ascending: false);
      final raw = (response as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
      await OfflineCache.writeList('blocked_websites_v1', raw);
      return raw.map(BlockedWebsite.fromJson).toList(growable: false);
    } catch (_) {
      final cached = await OfflineCache.readList('blocked_websites_v1');
      if (cached == null) return const [];
      return cached.map(BlockedWebsite.fromJson).toList(growable: false);
    }
  }

  Future<BlockedWebsite?> createBlockedWebsiteRecord(String urlDomain) async {
    final trimmedDomain = urlDomain.trim();
    if (trimmedDomain.isEmpty) return null;
    final payload = {
      'id': const Uuid().v4(),
      'created_by': _currentUserId,
      'url_domain': trimmedDomain,
      'time_limit_minutes': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      final response = await _client
          .from('blocked_websites')
          .insert(payload)
          .select()
          .single();
      return BlockedWebsite.fromJson(response);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'blocked_websites',
        type: WriteOpType.insert,
        payload: payload,
      );
      final cached =
          await OfflineCache.readList('blocked_websites_v1') ?? const [];
      await OfflineCache.writeList('blocked_websites_v1', [
        Map<String, dynamic>.from(payload),
        ...cached,
      ]);
      try {
        return BlockedWebsite.fromJson(payload);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> createBlockedWebsite(String urlDomain) async {
    await createBlockedWebsiteRecord(urlDomain);
  }

  Future<void> deleteBlockedWebsite(String id) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.deleteBlockedWebsite(id);
      return;
    }
    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('blocked_websites')
          .delete()
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'blocked_websites',
        type: WriteOpType.delete,
        match: match,
      );
    }
  }

  Future<void> addBlockedWebsiteTime(String id, int minutes) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.addBlockedWebsiteTime(id, minutes);
      return;
    }
    final row = await _client
        .from('blocked_websites')
        .select('time_limit_minutes')
        .eq('id', id)
        .eq('created_by', _currentUserId)
        .maybeSingle();
    if (row == null) return;
    final current = (row['time_limit_minutes'] as num?)?.toInt() ?? 0;
    await _client
        .from('blocked_websites')
        .update({'time_limit_minutes': current + minutes})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<List<RestPeriod>> getRestPeriods() async {
    if (_useLocalFamilyControlsStorage) {
      return _familyControlsLocalStore.getRestPeriods();
    }
    try {
      final response = await _client
          .from('rest_periods')
          .select()
          .eq('created_by', _currentUserId)
          .order('created_at', ascending: false);
      final raw = (response as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
      await OfflineCache.writeList('rest_periods_v1', raw);
      return raw.map(RestPeriod.fromJson).toList(growable: false);
    } catch (_) {
      final cached = await OfflineCache.readList('rest_periods_v1');
      if (cached == null) return const [];
      return cached.map(RestPeriod.fromJson).toList(growable: false);
    }
  }

  Future<void> createRestPeriod({
    required DateTime startTime,
    required DateTime endTime,
    bool active = true,
    String reason = 'flemme',
  }) async {
    final cleanedReason = reason.trim();
    final effectiveReason = cleanedReason.isEmpty ? 'flemme' : cleanedReason;
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.createRestPeriod(
        createdBy: _currentUserId,
        startTime: startTime,
        endTime: endTime,
        active: active,
        reason: effectiveReason,
      );
      return;
    }
    final payload = {
      'id': const Uuid().v4(),
      'created_by': _currentUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'active': active,
      'reason': effectiveReason,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await _client.from('rest_periods').insert(payload);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'rest_periods',
        type: WriteOpType.insert,
        payload: payload,
      );
      final cached = await OfflineCache.readList('rest_periods_v1') ?? const [];
      await OfflineCache.writeList('rest_periods_v1', [
        Map<String, dynamic>.from(payload),
        ...cached,
      ]);
    }
  }

  Future<void> updateRestPeriodActive(String id, bool active) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.updateRestPeriodActive(id, active);
      return;
    }
    final payload = {'active': active};
    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('rest_periods')
          .update(payload)
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'rest_periods',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  Future<void> updateRestPeriod({
    required String id,
    DateTime? startTime,
    DateTime? endTime,
    bool? active,
  }) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.updateRestPeriod(
        id: id,
        startTime: startTime,
        endTime: endTime,
        active: active,
      );
      return;
    }
    final payload = <String, dynamic>{};
    if (startTime != null) payload['start_time'] = startTime.toIso8601String();
    if (endTime != null) payload['end_time'] = endTime.toIso8601String();
    if (active != null) payload['active'] = active;
    if (payload.isEmpty) return;

    final match = {'id': id, 'created_by': _currentUserId};
    try {
      await _client
          .from('rest_periods')
          .update(payload)
          .eq('id', id)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'rest_periods',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  Future<WeeklyContract?> getCurrentWeeklyContract() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final start = DateFormat('yyyy-MM-dd').format(monday);
    final end = DateFormat('yyyy-MM-dd').format(sunday);

    final response = await _client
        .from('weekly_contracts')
        .select()
        .eq('created_by', _currentUserId)
        .eq('week_start_date', start)
        .eq('week_end_date', end)
        .maybeSingle();

    if (response == null) return null;
    return WeeklyContract.fromJson(response);
  }

  Future<void> upsertCurrentWeeklyContract({
    required String reward,
    required String sanction,
    required int threshold,
    required bool committed,
  }) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final start = DateFormat('yyyy-MM-dd').format(monday);
    final end = DateFormat('yyyy-MM-dd').format(sunday);

    final existing = await getCurrentWeeklyContract();
    if (existing == null) {
      await _client.from('weekly_contracts').insert({
        'created_by': _currentUserId,
        'week_start_date': start,
        'week_end_date': end,
        'reward_text': reward,
        'sanction_text': sanction,
        'success_threshold_percentage': threshold,
        'committed': committed,
      });
      return;
    }

    await _client
        .from('weekly_contracts')
        .update({
          'reward_text': reward,
          'sanction_text': sanction,
          'success_threshold_percentage': threshold,
          'committed': committed,
        })
        .eq('id', existing.id)
        .eq('created_by', _currentUserId);
  }

  Future<List<WeeklyHabitScore>> getWeeklyHabitScores({int limit = 12}) async {
    final response = await _client
        .from('weekly_habit_scores')
        .select()
        .eq('created_by', _currentUserId)
        .order('week_start_date', ascending: false)
        .limit(limit);
    return (response as List).map((e) => WeeklyHabitScore.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getScreenTimeLogs({int days = 14}) async {
    if (_useLocalFamilyControlsStorage) return const [];
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('screen_time_logs')
          .select()
          .eq('created_by', _currentUserId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false);
      final raw = (response as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      await OfflineCache.writeList('screen_time_logs_v1', raw);
      return raw;
    } catch (_) {
      final cached = await OfflineCache.readList('screen_time_logs_v1');
      return cached ?? const [];
    }
  }
}
