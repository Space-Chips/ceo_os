import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit_models.dart';
import '../models/settings_models.dart';
import '../models/task_models.dart';
import '../models/user_models.dart';
import '../services/family_controls_local_store.dart';
import '../services/supabase_service.dart';
import '../config/apple_review_compliance.dart';

class FeatureRepository {
  static const String adultContentShieldMarker = '__ADULT_CONTENT__';
  final SupabaseService _supabaseService;
  final FamilyControlsLocalStore _familyControlsLocalStore =
      FamilyControlsLocalStore();

  FeatureRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

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
    final response = await _client
        .from('app_settings')
        .select()
        .eq('created_by', _currentUserId)
        .maybeSingle();
    if (response == null) return null;
    return AppSettings.fromJson(response);
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

  Future<void> setAdultContentShieldEnabled(bool enabled) async {
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
    final response = await _client
        .from('notes')
        .select()
        .eq('created_by', _currentUserId)
        .order('updated_date', ascending: false);
    return (response as List).map((e) => Note.fromJson(e)).toList();
  }

  Future<int> countNotes() async {
    final response = await _client
        .from('notes')
        .select('id')
        .eq('created_by', _currentUserId);
    return (response as List).length;
  }

  Future<String> createNote(String title, String content) async {
    final inserted = await _client
        .from('notes')
        .insert({
          'created_by': _currentUserId,
          'title': title,
          'content': content,
          'updated_date': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<void> updateNote(String id, String title, String content) async {
    await _client
        .from('notes')
        .update({
          'title': title,
          'content': content,
          'updated_date': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('created_by', _currentUserId);
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
    await _client
        .from('rest_periods')
        .delete()
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> deleteNote(String id) async {
    await _client
        .from('notes')
        .delete()
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<List<Objective>> getObjectives() async {
    final response = await _client
        .from('objectives')
        .select()
        .eq('created_by', _currentUserId)
        .eq('archived', false)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Objective.fromJson(e)).toList();
  }

  Future<Objective?> createObjective(String title) async {
    if (title.trim().isEmpty) return null;
    final response = await _client
        .from('objectives')
        .insert({
          'created_by': _currentUserId,
          'title': title.trim(),
          'archived': false,
        })
        .select()
        .single();
    return Objective.fromJson(response);
  }

  Future<void> archiveObjective(String objectiveId) async {
    await _client
        .from('objectives')
        .update({'archived': true})
        .eq('id', objectiveId)
        .eq('created_by', _currentUserId);
  }

  Future<List<EventType>> getEventTypes() async {
    final response = await _client
        .from('event_types')
        .select()
        .eq('created_by', _currentUserId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => EventType.fromJson(e)).toList();
  }

  Future<void> createEventType(String name, String color, String icon) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    await _client.from('event_types').insert({
      'created_by': _currentUserId,
      'name': trimmedName,
      'color': color,
      'icon': icon,
    });
  }

  Future<void> deleteEventType(String id) async {
    await _client
        .from('event_types')
        .delete()
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<WinStreak?> getWinStreak() async {
    final response = await _client
        .from('win_streaks')
        .select()
        .eq('created_by', _currentUserId)
        .maybeSingle();
    if (response == null) return null;
    return WinStreak.fromJson(response);
  }

  Future<List<BlockedApp>> getBlockedApps() async {
    final response = await _client
        .from('blocked_apps')
        .select()
        .eq('created_by', _currentUserId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => BlockedApp.fromJson(e)).toList();
  }

  Future<BlockedApp?> createBlockedAppRecord(String appName) async {
    final trimmedName = appName.trim();
    if (trimmedName.isEmpty) return null;
    final response = await _client
        .from('blocked_apps')
        .insert({
          'created_by': _currentUserId,
          'app_name': trimmedName,
          'time_limit_minutes': 0,
        })
        .select()
        .single();
    return BlockedApp.fromJson(response);
  }

  Future<void> createBlockedApp(String appName) async {
    await createBlockedAppRecord(appName);
  }

  Future<void> deleteBlockedApp(String id) async {
    await _client
        .from('blocked_apps')
        .delete()
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> addBlockedAppTime(String id, int minutes) async {
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
    await _client
        .from('blocked_websites')
        .update({'time_limit_minutes': safe})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> setBlockedAppTime(String id, int minutes) async {
    final safe = minutes < 0 ? 0 : minutes;
    await _client
        .from('blocked_apps')
        .update({'time_limit_minutes': safe})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<List<BlockedWebsite>> getBlockedWebsites() async {
    final response = await _client
        .from('blocked_websites')
        .select()
        .eq('created_by', _currentUserId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => BlockedWebsite.fromJson(e)).toList();
  }

  Future<BlockedWebsite?> createBlockedWebsiteRecord(String urlDomain) async {
    final trimmedDomain = urlDomain.trim();
    if (trimmedDomain.isEmpty) return null;
    final response = await _client
        .from('blocked_websites')
        .insert({
          'created_by': _currentUserId,
          'url_domain': trimmedDomain,
          'time_limit_minutes': 0,
        })
        .select()
        .single();
    return BlockedWebsite.fromJson(response);
  }

  Future<void> createBlockedWebsite(String urlDomain) async {
    await createBlockedWebsiteRecord(urlDomain);
  }

  Future<void> deleteBlockedWebsite(String id) async {
    await _client
        .from('blocked_websites')
        .delete()
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> addBlockedWebsiteTime(String id, int minutes) async {
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
    final response = await _client
        .from('rest_periods')
        .select()
        .eq('created_by', _currentUserId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => RestPeriod.fromJson(e)).toList();
  }

  Future<void> createRestPeriod({
    required DateTime startTime,
    required DateTime endTime,
    bool active = true,
  }) async {
    await _client.from('rest_periods').insert({
      'created_by': _currentUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'active': active,
    });
  }

  Future<void> updateRestPeriodActive(String id, bool active) async {
    await _client
        .from('rest_periods')
        .update({'active': active})
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  Future<void> updateRestPeriod({
    required String id,
    DateTime? startTime,
    DateTime? endTime,
    bool? active,
  }) async {
    final payload = <String, dynamic>{};
    if (startTime != null) payload['start_time'] = startTime.toIso8601String();
    if (endTime != null) payload['end_time'] = endTime.toIso8601String();
    if (active != null) payload['active'] = active;
    if (payload.isEmpty) return;

    await _client
        .from('rest_periods')
        .update(payload)
        .eq('id', id)
        .eq('created_by', _currentUserId);
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
      return (response as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
