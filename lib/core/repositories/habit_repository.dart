import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/habit_models.dart';
import '../services/supabase_service.dart';

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
      print('Error getting habits: $e');
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
          })
          .select()
          .single();

      return Habit.fromJson(response);
    } catch (e) {
      print('Error creating habit: $e');
      return null;
    }
  }

  Future<void> archiveHabit(String habitId) async {
    await _client.from('habits').update({'archived': true}).eq('id', habitId);
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
      print('Error getting completions: $e');
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
      print('Error getting completions for date: $e');
      return [];
    }
  }

  Future<List<HabitCompletion>> getCompletionsForDateRange(DateTime start, DateTime end) async {
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
      print('Error getting completions range: $e');
      return [];
    }
  }

  Future<void> toggleCompletion(String habitId, DateTime date, {double? amount}) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Check if exists
    final existing = await _client
        .from('habit_completions')
        .select()
        .eq('habit_id', habitId)
        .eq('date', dateStr)
        .maybeSingle();

    if (existing != null) {
      // Toggle
      final current = existing['completed'] as bool;
      await _client
          .from('habit_completions')
          .update({
            'completed': !current,
            'state': amount?.toString(), // Use state to store the amount if needed
          })
          .eq('id', existing['id']);
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

  // --- Habit Logs (Diary) ---

  Future<List<HabitLog>> getHabitLogs(String habitId) async {
    try {
      final response = await _client
          .from('habit_logs')
          .select()
          .eq('habit_id', habitId)
          .eq('created_by', _currentUserId)
          .order('date', ascending: false);

      return (response as List)
          .map((data) => HabitLog.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting habit logs: $e');
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
