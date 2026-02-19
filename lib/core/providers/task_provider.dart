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
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _repository.getTasks();
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
  }) async {
    try {
      await _repository.addTask(
        title,
        importance: importance,
        duration: duration,
        groupId: groupId,
      );
      await loadTasks();
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
      await loadTasks();
    } catch (e) {
      print('Error completing task: $e');
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
  }) async {
    try {
      await _repository.addEvent(
        title,
        date,
        time: time,
        description: description,
      );
      await loadEvents();
    } catch (e) {
      print('Error adding event: $e');
    }
  }
}