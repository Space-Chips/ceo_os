import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/habit_models.dart';
import '../services/supabase_service.dart';
import '../utils/app_logger.dart';

class HabitRepository {
  final SupabaseService _supabaseService;

  HabitRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  Future<List<Habit>> getHabits() async {
    try {
      final response = await _client
          .from('habits')
          .select()
          .eq('created_by', _currentUserId)
          .eq('archived', false)
          .order('created_at');

      return (response as List).map((data) => Habit.fromJson(data)).toList();
    } catch (e) {
      AppLogger.error('Error getting habits.', e);
      return [];
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
    try {
      final response = await _client
          .from('habits')
          .insert({
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
          })
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
      AppLogger.error('Error creating habit.', e);
      return null;
    }
  }

  Future<void> archiveHabit(String habitId) async {
    await _client
        .from('habits')
        .update({'archived': true})
        .eq('id', habitId)
        .eq('created_by', _currentUserId);
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
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await _client
          .from('habit_completions')
          .select()
          .eq('created_by', _currentUserId)
          .eq('date', dateStr);

      return (response as List)
          .map((data) => HabitCompletion.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting completions for date.', e);
      return [];
    }
  }

  Future<List<HabitCompletion>> getCompletionsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);

    try {
      final response = await _client
          .from('habit_completions')
          .select()
          .eq('created_by', _currentUserId)
          .gte('date', startStr)
          .lte('date', endStr);

      return (response as List)
          .map((data) => HabitCompletion.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting completions range.', e);
      return [];
    }
  }

  Future<void> toggleCompletion(
    String habitId,
    DateTime date, {
    double? amount,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
  }

  Future<void> setCompletionForDate({
    required String habitId,
    required DateTime date,
    required bool completed,
    String? state,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
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
        'checked_in_date': completed ? DateTime.now().toIso8601String() : null,
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

    await _client.from('habit_logs').insert({
      'habit_id': habitId,
      'created_by': _currentUserId,
      'content': content,
      'date': dateStr,
    });
  }
}
