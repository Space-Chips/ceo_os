import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_models.dart';
import '../services/supabase_service.dart';
import '../utils/app_logger.dart';

class TaskRepository {
  final SupabaseService _supabaseService;

  TaskRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  Future<List<ParetoTask>> getTasks({bool includeCompleted = false}) async {
    try {
      dynamic query = _client
          .from('pareto_tasks')
          .select()
          .eq('created_by', _currentUserId);

      if (!includeCompleted) {
        query = query.eq('completed', false);
      }

      final response = await query.order('sort_order', ascending: true);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _cacheKey(includeCompleted ? 'tasks_all_v1' : 'tasks_active_v1'),
          jsonEncode(response),
        );
      } catch (_) {
        // Best effort only.
      }

      return (response as List)
          .map((data) => ParetoTask.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting tasks.', e);
      // Offline-first fallback: return last cached snapshot if present.
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(
          _cacheKey(includeCompleted ? 'tasks_all_v1' : 'tasks_active_v1'),
        );
        if (raw == null || raw.isEmpty) return [];
        final decoded = jsonDecode(raw);
        if (decoded is! List) return [];
        return decoded
            .whereType<Map>()
            .map((row) => ParetoTask.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> uncompleteTask(String taskId) async {
    await _client
        .from('pareto_tasks')
        .update({'completed': false, 'completed_date': null})
        .eq('id', taskId)
        .eq('created_by', _currentUserId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client
        .from('pareto_tasks')
        .delete()
        .eq('id', taskId)
        .eq('created_by', _currentUserId);
  }

  Future<void> addTask(
    String title, {
    String? importance,
    String? duration,
    String? groupId,
    DateTime? deadline,
    String? description,
    bool syncToCalendar = false,
  }) async {
    final payload = <String, dynamic>{
      'created_by': _currentUserId,
      'title': title,
      'importance_level': importance,
      'time_duration': duration,
      'group_id': groupId,
      'deadline': deadline?.toIso8601String(),
      'description': description,
      'completed': false,
    };
    Map<String, dynamic> response = {};
    try {
      response = await _client
          .from('pareto_tasks')
          .insert(payload)
          .select('id, title, deadline')
          .single();
    } on PostgrestException catch (e) {
      var current = e;
      final fallbackPayload = Map<String, dynamic>.from(payload);
      while (true) {
        final isSchemaColumnIssue =
            current.code == 'PGRST204' || current.code == '42703';
        if (!isSchemaColumnIssue) rethrow;

        final msg = current.message;
        final quoted = RegExp(r"'([^']+)' column").firstMatch(msg)?.group(1);
        final dotted = RegExp(
          r'pareto_tasks\.([a-zA-Z0-9_]+)',
        ).firstMatch(msg)?.group(1);
        final missingColumn = quoted ?? dotted;
        if (missingColumn == null ||
            !fallbackPayload.containsKey(missingColumn)) {
          rethrow;
        }
        fallbackPayload.remove(missingColumn);

        try {
          response = await _client
              .from('pareto_tasks')
              .insert(fallbackPayload)
              .select('id, title')
              .single();
          break;
        } on PostgrestException catch (next) {
          current = next;
          continue;
        }
      }
    }

    if (syncToCalendar && deadline != null) {
      await addEvent(
        title,
        "${deadline.year.toString().padLeft(4, '0")}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
        description: description,
        sourceType: 'task',
        sourceId: response['id'] as String?,
      );
    }
  }

  Future<void> completeTask(String taskId) async {
    await _client
        .from('pareto_tasks')
        .update({
          'completed': true,
          'completed_date': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId)
        .eq('created_by', _currentUserId);
  }

  // --- Task Groups ---

  Future<List<TaskGroup>> getTaskGroups() async {
    try {
      final response = await _client
          .from('task_groups')
          .select()
          .eq('created_by', _currentUserId)
          .order('name', ascending: true);

      return (response as List)
          .map((data) => TaskGroup.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting task groups.', e);
      return [];
    }
  }

  Future<TaskGroup> addTaskGroup(String name, {String? color}) async {
    final response = await _client
        .from('task_groups')
        .insert({'created_by': _currentUserId, 'name': name, 'color': color})
        .select()
        .single();

    return TaskGroup.fromJson(response);
  }

  // --- Events ---

  Future<List<CalendarEvent>> getAllEvents() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final horizonDate = DateTime.now().add(const Duration(days: 740));
      final dateStr = _formatDate(cutoffDate);

      final upcomingResponse = await _client
          .from('calendar_events')
          .select()
          .eq('created_by', _currentUserId)
          .gte('event_date', dateStr)
          .order('event_date', ascending: true);

      final recurringResponse = await _client
          .from('calendar_events')
          .select()
          .eq('created_by', _currentUserId)
          .not('recurrence_rule', 'is', null);

      final merged = <String, Map<String, dynamic>>{};
      for (final item in (upcomingResponse as List)) {
        final row = Map<String, dynamic>.from(item as Map);
        final id = row['id'] as String?;
        if (id != null && id.isNotEmpty) {
          merged[id] = row;
        }
      }
      for (final item in (recurringResponse as List)) {
        final row = Map<String, dynamic>.from(item as Map);
        final id = row['id'] as String?;
        if (id != null && id.isNotEmpty) {
          merged[id] = row;
        }
      }

      final baseEvents = merged.values
          .map((data) => CalendarEvent.fromJson(data))
          .toList();

      final expanded = _expandRecurringEvents(
        baseEvents,
        cutoffDate: cutoffDate,
        horizonDate: horizonDate,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey('events_v1'), jsonEncode(merged.values));
      } catch (_) {
        // Best effort only.
      }

      return expanded;
    } catch (e) {
      AppLogger.error('Error getting events.', e);
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_cacheKey('events_v1'));
        if (raw == null || raw.isEmpty) return [];
        final decoded = jsonDecode(raw);
        if (decoded is! List) return [];
        final baseEvents = decoded
            .whereType<Map>()
            .map((row) => CalendarEvent.fromJson(Map<String, dynamic>.from(row)))
            .toList();

        final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
        final horizonDate = DateTime.now().add(const Duration(days: 740));
        return _expandRecurringEvents(
          baseEvents,
          cutoffDate: cutoffDate,
          horizonDate: horizonDate,
        );
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> addEvent(
    String title,
    String date, {
    String? time,
    int? durationMinutes,
    String? description,
    String? sourceType,
    String? sourceId,
    String? recurrenceRule,
    String? eventTypeId,
  }) async {
    final payload = <String, dynamic>{
      'created_by': _currentUserId,
      'title': title,
      'description': description,
      'event_date': date,
      'event_time': time,
      'duration_minutes': durationMinutes,
      'source_type': sourceType ?? 'manual',
      'source_id': sourceId,
      'event_type_id': eventTypeId,
      'recurrence_rule': recurrenceRule,
    };

    try {
      await _client.from('calendar_events').insert(payload);
    } on PostgrestException catch (e) {
      final missingDuration =
          e.code == 'PGRST204' ||
          e.code == '42703' ||
          e.message.contains('duration_minutes');
      if (!missingDuration) rethrow;

      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('duration_minutes');
      await _client.from('calendar_events').insert(fallbackPayload);
    }
  }
}
