import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_models.dart';
import '../services/supabase_service.dart';
import '../services/write_queue.dart';
import '../utils/app_logger.dart';

class HabitRepository {
  final SupabaseService _supabaseService;

  HabitRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  String _cacheKey(String suffix) =>
      'habit_repository::$_currentUserId::$suffix';

  Future<List<Habit>> getHabits() async {
    try {
      final response = await _client
          .from('habits')
          .select()
          .eq('created_by', _currentUserId)
          .eq('archived', false)
          .order('created_at');

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey('habits_v1'), jsonEncode(response));
      } catch (_) {
        // Best effort only.
      }

      return (response as List).map((data) => Habit.fromJson(data)).toList();
    } catch (e) {
      AppLogger.error('Error getting habits.', e);
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_cacheKey('habits_v1'));
        if (raw == null || raw.isEmpty) return [];
        final decoded = jsonDecode(raw);
        if (decoded is! List) return [];
        return decoded
            .whereType<Map>()
            .map((row) => Habit.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<Habit?> createHabit(
    String title, {
    bool isDaily = true,
    String? icon,
    String? category,
    String? quote,
    String? frequencyType,
    int? intervalDays,
    String? targetType,
    int? targetValue,
    String? targetUnit,
    String? reminderTime,
    bool autoPopup = false,
    String? colorTheme,
    List<int>? specificDays,
    bool syncToCalendar = false,
  }) async {
    final clientId = const Uuid().v4();
    final payload = <String, dynamic>{
      'id': clientId,
      'created_by': _currentUserId,
      'title': title,
      'is_daily': isDaily,
      'icon': icon,
      'category': category,
      'quote': quote,
      'frequency_type': frequencyType ?? 'daily',
      'interval_days': intervalDays,
      'target_type': targetType ?? 'all',
      'target_value': targetValue,
      'target_unit': targetUnit,
      'reminder_time': reminderTime,
      'auto_popup': autoPopup,
      'color_theme': colorTheme,
      'specific_days': specificDays,
      'archived': false,
    };
    try {
      final response = await _client
          .from('habits')
          .insert(payload)
          .select()
          .single();
      final habit = Habit.fromJson(response);

      if (syncToCalendar && reminderTime != null) {
        final now = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        await _client.from('calendar_events').insert({
          'created_by': _currentUserId,
          'title': 'Habit: $title',
          'description': quote,
          'event_date': dateStr,
          'event_time': '$reminderTime:00',
          'source_type': 'habit',
          'source_id': habit.id,
          'recurrence_rule': frequencyType ?? 'daily',
        });
      }

      return habit;
    } catch (e) {
      AppLogger.error('Error creating habit (queued for sync).', e);
      // Queue the insert and rebuild a Habit from the payload so the UI can
      // proceed. Optimistically append to the local habits cache.
      await WriteQueue.enqueue(
        table: 'habits',
        type: WriteOpType.insert,
        payload: payload,
      );
      await _optimisticallyAppendHabit(payload);

      if (syncToCalendar && reminderTime != null) {
        final now = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        await WriteQueue.enqueue(
          table: 'calendar_events',
          type: WriteOpType.insert,
          payload: {
            'id': const Uuid().v4(),
            'created_by': _currentUserId,
            'title': 'Habit: $title',
            'description': quote,
            'event_date': dateStr,
            'event_time': '$reminderTime:00',
            'source_type': 'habit',
            'source_id': clientId,
            'recurrence_rule': frequencyType ?? 'daily',
          },
        );
      }

      try {
        return Habit.fromJson(payload);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _optimisticallyAppendHabit(
    Map<String, dynamic> habitRow,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey('habits_v1'));
      final list = <Map<String, dynamic>>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list.addAll(
            decoded
                .whereType<Map>()
                .map((m) => m.cast<String, dynamic>()),
          );
        }
      }
      list.add(Map<String, dynamic>.from(habitRow));
      await prefs.setString(_cacheKey('habits_v1'), jsonEncode(list));
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> archiveHabit(String habitId) async {
    const payload = {'archived': true};
    final match = {'id': habitId, 'created_by': _currentUserId};
    try {
      await _client
          .from('habits')
          .update(payload)
          .eq('id', habitId)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'habits',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  Future<void> deleteHabit(String habitId) async {
    await archiveHabit(habitId);
  }

  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) async {
    try {
      final response = await _client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId)
          .eq('created_by', _currentUserId)
          .order('date', ascending: false);

      return (response as List)
          .map((data) => HabitCompletion.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting completions.', e);
      return [];
    }
  }

  Future<List<HabitCompletion>> getCompletionHistory(String habitId) async {
    return getCompletionsForHabit(habitId);
  }

  Future<List<HabitCompletion>> getTodaysCompletions() async {
    final now = DateTime.now();
    return getCompletionsForDate(now);
  }

  Future<List<HabitCompletion>> getCompletionsForDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      final response = await _client
          .from('habit_completions')
          .select()
          .eq('created_by', _currentUserId)
          .eq('date', dateStr);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _cacheKey('completions_${dateStr}_v1'),
          jsonEncode(response),
        );
      } catch (_) {
        // Best effort only.
      }

      return (response as List)
          .map((data) => HabitCompletion.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting completions for date.', e);
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_cacheKey('completions_${dateStr}_v1'));
        if (raw == null || raw.isEmpty) return [];
        final decoded = jsonDecode(raw);
        if (decoded is! List) return [];
        return decoded
            .whereType<Map>()
            .map(
              (row) => HabitCompletion.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<HabitCompletion>> getCompletionsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);
    final cacheId = 'range_${startStr}_$endStr';

    try {
      final response = await _client
          .from('habit_completions')
          .select()
          .eq('created_by', _currentUserId)
          .gte('date', startStr)
          .lte('date', endStr);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _cacheKey('completions_${cacheId}_v1'),
          jsonEncode(response),
        );
      } catch (_) {
        // Best effort only.
      }

      return (response as List)
          .map((data) => HabitCompletion.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting completions range.', e);
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_cacheKey('completions_${cacheId}_v1'));
        if (raw == null || raw.isEmpty) return [];
        final decoded = jsonDecode(raw);
        if (decoded is! List) return [];
        return decoded
            .whereType<Map>()
            .map(
              (row) => HabitCompletion.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> toggleCompletion(
    String habitId,
    DateTime date, {
    double? amount,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      // Check if exists
      final existing = await _client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId)
          .eq('created_by', _currentUserId)
          .eq('date', dateStr)
          .maybeSingle();

      if (existing != null) {
        // Toggle
        final current = existing['completed'] as bool;
        await _client
            .from('habit_completions')
            .update({
              'completed': !current,
              'state': amount
                  ?.toString(), // Use state to store the amount if needed
            })
            .eq('id', existing['id'])
            .eq('created_by', _currentUserId);
      } else {
        // Insert
        await _client.from('habit_completions').insert({
          'habit_id': habitId,
          'created_by': _currentUserId,
          'date': dateStr,
          'completed': true,
          'state': amount?.toString(),
          'checked_in_date': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // Offline fallback — derive next state from local cache and enqueue an
      // upsert. Optimistically rewrite the cache so the UI reflects the toggle.
      await _offlineToggleCompletion(
        habitId: habitId,
        dateStr: dateStr,
        amount: amount,
      );
    }
  }

  Future<void> _offlineToggleCompletion({
    required String habitId,
    required String dateStr,
    double? amount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKey('completions_${dateStr}_v1');
    final raw = prefs.getString(cacheKey);
    List<Map<String, dynamic>> cached = const [];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        cached = decoded
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList(growable: true);
      } else {
        cached = <Map<String, dynamic>>[];
      }
    } else {
      cached = <Map<String, dynamic>>[];
    }

    final idx = cached.indexWhere((row) => row['habit_id'] == habitId);
    final nextCompleted = idx == -1
        ? true
        : !(cached[idx]['completed'] as bool? ?? false);

    final nowIso = DateTime.now().toIso8601String();
    final id = idx == -1
        ? const Uuid().v4()
        : (cached[idx]['id'] as String? ?? const Uuid().v4());

    final upsertRow = <String, dynamic>{
      'id': id,
      'habit_id': habitId,
      'created_by': _currentUserId,
      'date': dateStr,
      'completed': nextCompleted,
      'state': amount?.toString(),
      'checked_in_date': nextCompleted ? nowIso : null,
    };

    if (idx == -1) {
      cached.add(upsertRow);
    } else {
      cached[idx] = {...cached[idx], ...upsertRow};
    }
    try {
      await prefs.setString(cacheKey, jsonEncode(cached));
    } catch (_) {
      // Best effort.
    }

    await WriteQueue.enqueue(
      table: 'habit_completions',
      type: WriteOpType.upsert,
      payload: upsertRow,
      onConflict: 'habit_id,created_by,date',
    );
  }

  Future<void> setCompletionForDate({
    required String habitId,
    required DateTime date,
    required bool completed,
    String? state,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final existing = await _client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId)
          .eq('created_by', _currentUserId)
          .eq('date', dateStr)
          .maybeSingle();

      if (existing == null) {
        await _client.from('habit_completions').insert({
          'habit_id': habitId,
          'created_by': _currentUserId,
          'date': dateStr,
          'completed': completed,
          'state': state,
          'checked_in_date':
              completed ? DateTime.now().toIso8601String() : null,
        });
        return;
      }

      await _client
          .from('habit_completions')
          .update({
            'completed': completed,
            'state': state,
            'checked_in_date': completed
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', existing['id'])
          .eq('created_by', _currentUserId);
    } catch (_) {
      await _offlineSetCompletion(
        habitId: habitId,
        dateStr: dateStr,
        completed: completed,
        state: state,
      );
    }
  }

  Future<void> _offlineSetCompletion({
    required String habitId,
    required String dateStr,
    required bool completed,
    String? state,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKey('completions_${dateStr}_v1');
    final raw = prefs.getString(cacheKey);
    List<Map<String, dynamic>> cached = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        cached = decoded
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList(growable: true);
      }
    }

    final idx = cached.indexWhere((row) => row['habit_id'] == habitId);
    final id = idx == -1
        ? const Uuid().v4()
        : (cached[idx]['id'] as String? ?? const Uuid().v4());

    final nowIso = DateTime.now().toIso8601String();
    final upsertRow = <String, dynamic>{
      'id': id,
      'habit_id': habitId,
      'created_by': _currentUserId,
      'date': dateStr,
      'completed': completed,
      'state': state,
      'checked_in_date': completed ? nowIso : null,
    };

    if (idx == -1) {
      cached.add(upsertRow);
    } else {
      cached[idx] = {...cached[idx], ...upsertRow};
    }
    try {
      await prefs.setString(cacheKey, jsonEncode(cached));
    } catch (_) {}

    await WriteQueue.enqueue(
      table: 'habit_completions',
      type: WriteOpType.upsert,
      payload: upsertRow,
      onConflict: 'habit_id,created_by,date',
    );
  }

  // --- Habit Logs (Diary) ---

  Future<List<HabitLog>> getHabitLogs(String habitId) async {
    try {
      final response = await _client
          .from('habit_logs')
          .select()
          .eq('habit_id', habitId)
          .eq('created_by', _currentUserId)
          .order('date', ascending: false);

      return (response as List).map((data) => HabitLog.fromJson(data)).toList();
    } catch (e) {
      AppLogger.error('Error getting habit logs.', e);
      return [];
    }
  }

  Future<void> createHabitLog(String habitId, String content) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final payload = {
      'habit_id': habitId,
      'created_by': _currentUserId,
      'content': content,
      'date': dateStr,
    };
    try {
      await _client.from('habit_logs').insert(payload);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'habit_logs',
        type: WriteOpType.insert,
        payload: payload,
      );
    }
  }
}
