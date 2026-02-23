import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_models.dart';
import '../services/supabase_service.dart';

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

      return (response as List)
          .map((data) => ParetoTask.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<void> uncompleteTask(String taskId) async {
    await _client
        .from('pareto_tasks')
        .update({'completed': false, 'completed_date': null})
        .eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('pareto_tasks').delete().eq('id', taskId);
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
        '${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
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
        .eq('id', taskId);
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
      print('Error getting task groups: $e');
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
      final dateStr =
          '${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('calendar_events')
          .select()
          .eq('created_by', _currentUserId)
          .gte('event_date', dateStr)
          .order('event_date', ascending: true);

      return (response as List)
          .map((data) => CalendarEvent.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  Future<void> addEvent(
    String title,
    String date, {
    String? time,
    String? description,
    String? sourceType,
    String? sourceId,
    String? recurrenceRule,
  }) async {
    await _client.from('calendar_events').insert({
      'created_by': _currentUserId,
      'title': title,
      'description': description,
      'event_date': date,
      'event_time': time,
      'source_type': sourceType ?? 'manual',
      'source_id': sourceId,
      'recurrence_rule': recurrenceRule,
    });
  }
}
