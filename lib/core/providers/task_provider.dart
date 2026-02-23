import 'package:flutter/material.dart';
import '../models/task_models.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;

  List<ParetoTask> _tasks = [];
  List<CalendarEvent> _events = [];
  List<TaskGroup> _groups = [];
  bool _isLoading = false;

  TaskProvider({TaskRepository? repository})
    : _repository = repository ?? TaskRepository();

  List<ParetoTask> get tasks => List.unmodifiable(_tasks);
  List<CalendarEvent> get events => List.unmodifiable(_events);
  List<TaskGroup> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;

  Future<void> loadTasks() async {
    await loadTasksWithCompleted(includeCompleted: false);
  }

  Future<void> loadTasksWithCompleted({bool includeCompleted = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _repository.getTasks(includeCompleted: includeCompleted);
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

  Future<void> addTask(
    String title, {
    String? importance,
    String? duration,
    String? groupId,
    DateTime? deadline,
    String? description,
    bool syncToCalendar = false,
  }) async {
    try {
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
    } catch (e) {
      print('Error adding task: $e');
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
    String? description,
    String? sourceType,
    String? sourceId,
    String? recurrenceRule,
  }) async {
    try {
      await _repository.addEvent(
        title,
        date,
        time: time,
        description: description,
        sourceType: sourceType,
        sourceId: sourceId,
        recurrenceRule: recurrenceRule,
      );
      await loadEvents();
    } catch (e) {
      print('Error adding event: $e');
    }
  }
}
