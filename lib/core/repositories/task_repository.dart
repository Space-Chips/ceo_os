import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_models.dart';
import '../services/supabase_service.dart';

class TaskRepository {
  final SupabaseService _supabaseService;

  TaskRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  Future<List<ParetoTask>> getTasks() async {
    try {
      final response = await _client
          .from('pareto_tasks')
          .select()
          .eq('created_by', _currentUserId)
          .eq('completed', false)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((data) => ParetoTask.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<void> addTask(
    String title, {
    String? importance,
    String? duration,
    String? groupId,
  }) async {
    await _client.from('pareto_tasks').insert({
      'created_by': _currentUserId,
      'title': title,
      'importance_level': importance,
      'time_duration': duration,
      'group_id': groupId,
      'completed': false,
    });
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
    final response = await _client.from('task_groups').insert({
      'created_by': _currentUserId,
      'name': name,
      'color': color,
    }).select().single();

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
  }) async {
    await _client.from('calendar_events').insert({
      'created_by': _currentUserId,
      'title': title,
      'description': description,
      'event_date': date,
      'event_time': time,
    });
  }
}