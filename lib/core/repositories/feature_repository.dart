import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit_models.dart';
import '../models/settings_models.dart';
import '../models/task_models.dart';
import '../models/user_models.dart';
import '../services/supabase_service.dart';

class FeatureRepository {
  final SupabaseService _supabaseService;

  FeatureRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

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
        .eq('id', existing.id);
  }

  Future<String> saveActiveAppsFast(
    List<String> apps, {
    String? settingsId,
  }) async {
    if (settingsId != null && settingsId.isNotEmpty) {
      await _client
          .from('app_settings')
          .update({'active_apps': apps})
          .eq('id', settingsId);
      return settingsId;
    }

    final created = await _client
        .from('app_settings')
        .insert({'created_by': _currentUserId, 'active_apps': apps})
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

  Future<void> createNote(String title, String content) async {
    await _client.from('notes').insert({
      'created_by': _currentUserId,
      'title': title,
      'content': content,
      'updated_date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateNote(String id, String title, String content) async {
    await _client
        .from('notes')
        .update({
          'title': title,
          'content': content,
          'updated_date': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
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

  Future<List<EventType>> getEventTypes() async {
    final response = await _client
        .from('event_types')
        .select()
        .eq('created_by', _currentUserId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => EventType.fromJson(e)).toList();
  }

  Future<void> createEventType(String name, String color, String icon) async {
    await _client.from('event_types').insert({
      'created_by': _currentUserId,
      'name': name,
      'color': color,
      'icon': icon,
    });
  }

  Future<void> deleteEventType(String id) async {
    await _client.from('event_types').delete().eq('id', id);
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

  Future<List<Map<String, dynamic>>> getScreenTimeLogs({int days = 7}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final date = DateFormat('yyyy-MM-dd').format(from);
    final response = await _client
        .from('screen_time_logs')
        .select()
        .eq('created_by', _currentUserId)
        .gte('date', date)
        .order('date', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
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
        .eq('id', existing.id);
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
}
