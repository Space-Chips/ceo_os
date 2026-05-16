import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/premium_models.dart';
import '../models/task_models.dart';
import '../repositories/premium_repository.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;
  final PremiumRepository _premiumRepository;

  List<ParetoTask> _tasks = [];
  List<CalendarEvent> _events = [];
  List<TaskGroup> _groups = [];
  bool _isLoading = false;
  static const _uuid = Uuid();

  TaskProvider({TaskRepository? repository})
    : _repository = repository ?? TaskRepository(),
      _premiumRepository = PremiumRepository();

  List<ParetoTask> get tasks => List.unmodifiable(_tasks);
  List<CalendarEvent> get events => List.unmodifiable(_events);
  List<TaskGroup> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;

  String _pendingKey() {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'pending::tasks::$uid::v1';
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_pendingKey()) ?? const <String>[];
      return raw
          .map((s) => Map<String, dynamic>.from(_decodeJsonMap(s)))
          .toList(growable: true);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _savePending(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _pendingKey(),
        items.map(_encodeJson).toList(growable: false),
      );
    } catch (_) {
      // Best effort only.
    }
  }

  Map<String, dynamic> _decodeJsonMap(String raw) {
    if (raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(decoded);
  }

  String _encodeJson(Map<String, dynamic> value) => jsonEncode(value);

  Future<void> _flushPendingIfAny() async {
    final pending = await _loadPending();
    if (pending.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final item in pending) {
      try {
        await _repository.addTask(
          (item['title'] as String?) ?? '',
          importance: item['importance'] as String?,
          duration: item['duration'] as String?,
          groupId: item['groupId'] as String?,
          deadline: item['deadline'] != null
              ? DateTime.tryParse(item['deadline'] as String)
              : null,
          description: item['description'] as String?,
          syncToCalendar: (item['syncToCalendar'] as bool?) ?? false,
        );
      } catch (_) {
        remaining.add(item);
      }
    }
    await _savePending(remaining);
  }

  Future<void> loadTasks() async {
    await loadTasksWithCompleted(includeCompleted: false);
  }

  Future<void> loadTasksWithCompleted({bool includeCompleted = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _repository.getTasks(includeCompleted: includeCompleted);
      await _flushPendingIfAny();
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroups() async {
    try {
      _groups = await _repository.getTaskGroups();
      notifyListeners();
    } catch (e) {
      print('Error loading task groups: $e');
    }
  }

  Future<PremiumCheckResult> addTask(
    String title, {
    String? importance,
    String? duration,
    String? groupId,
    DateTime? deadline,
    String? description,
    bool syncToCalendar = false,
  }) async {
    try {
      // Enforce limits using local state (fast + avoids schema/count drift).
      final runtime = await _premiumRepository.getRuntime();
      if (!runtime.resolved.canCreateUnlimitedTasks) {
        final activeCount = _tasks.where((t) => !t.completed).length;
        if (activeCount >= runtime.config.tasksFreeLimit) {
          return PremiumCheckResult.blocked(
            reason: 'tasks',
            limit: runtime.config.tasksFreeLimit,
            current: activeCount,
          );
        }
      }

      await _repository.addTask(
        title,
        importance: importance,
        duration: duration,
        groupId: groupId,
        deadline: deadline,
        description: description,
        syncToCalendar: syncToCalendar,
      );
      await loadTasksWithCompleted(includeCompleted: true);
      await loadEvents();
      return const PremiumCheckResult.allowed();
    } catch (e) {
      print('Error adding task: $e');
      // Offline-first fallback: store a pending create and surface it locally.
      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'local';
      final local = ParetoTask(
        id: 'local-task-${_uuid.v4()}',
        createdBy: uid,
        title: title,
        importanceLevel: importance,
        timeDuration: duration,
        completed: false,
        groupId: groupId,
        deadline: deadline,
        description: description,
        createdAt: DateTime.now(),
      );
      _tasks = [local, ..._tasks];
      notifyListeners();

      final pending = await _loadPending();
      pending.add({
        'title': title,
        'importance': importance,
        'duration': duration,
        'groupId': groupId,
        'deadline': deadline?.toIso8601String(),
        'description': description,
        'syncToCalendar': syncToCalendar,
      });
      await _savePending(pending);
      return const PremiumCheckResult.allowed();
    }
  }

  Future<void> addTaskGroup(String name, {String? color}) async {
    try {
      await _repository.addTaskGroup(name, color: color);
      await loadGroups();
    } catch (e) {
      print('Error adding group: $e');
    }
  }

  Future<void> completeTask(String id) async {
    try {
      await _repository.completeTask(id);
      await loadTasksWithCompleted(includeCompleted: true);
    } catch (e) {
      print('Error completing task: $e');
    }
  }

  Future<void> uncompleteTask(String id) async {
    try {
      await _repository.uncompleteTask(id);
      await loadTasksWithCompleted(includeCompleted: true);
    } catch (e) {
      print('Error uncompleting task: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await _repository.getAllEvents();
    } catch (e) {
      print('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCalendarEvent({
    required String title,
    required String date,
    String? time,
    int? durationMinutes,
    String? description,
    String? sourceType,
    String? sourceId,
    String? recurrenceRule,
    String? eventTypeId,
  }) async {
    try {
      await _repository.addEvent(
        title,
        date,
        time: time,
        durationMinutes: durationMinutes,
        description: description,
        sourceType: sourceType,
        sourceId: sourceId,
        recurrenceRule: recurrenceRule,
        eventTypeId: eventTypeId,
      );
      await loadEvents();
    } catch (e) {
      print('Error adding event: $e');
    }
  }
}
