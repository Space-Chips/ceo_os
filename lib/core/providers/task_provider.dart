import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Priority levels for tasks.
enum TaskPriority { urgent, high, medium, low, none }

/// A single subtask item.
class SubTask {
  final String id;
  String title;
  bool isComplete;

  SubTask({String? id, required this.title, this.isComplete = false})
      : id = id ?? const Uuid().v4();
}

/// A task item.
class Task {
  final String id;
  String title;
  String? description;
  TaskPriority priority;
  DateTime? dueDate;
  bool isComplete;
  List<SubTask> subtasks;
  DateTime createdAt;

  Task({
    String? id,
    required this.title,
    this.description,
    this.priority = TaskPriority.none,
    this.dueDate,
    this.isComplete = false,
    List<SubTask>? subtasks,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get subtaskProgress {
    if (subtasks.isEmpty) return isComplete ? 1.0 : 0.0;
    return subtasks.where((s) => s.isComplete).length / subtasks.length;
  }

  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isComplete;
}

/// In-memory task list with CRUD operations.
class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _tasks
        .where((t) =>
            !t.isComplete &&
            t.dueDate != null &&
            t.dueDate!.isAfter(today) &&
            t.dueDate!.isBefore(tomorrow))
        .toList();
  }

  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return _tasks
        .where((t) =>
            !t.isComplete && t.dueDate != null && t.dueDate!.isAfter(tomorrow))
        .toList();
  }

  List<Task> get completedTasks =>
      _tasks.where((t) => t.isComplete).toList();

  List<Task> get incompleteTasks =>
      _tasks.where((t) => !t.isComplete).toList();

  void addTask(Task task) {
    _tasks.insert(0, task);
    _addSampleDataIfEmpty();
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  void toggleTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isComplete = !task.isComplete;
    notifyListeners();
  }

  void toggleSubtask(String taskId, String subtaskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subtask = task.subtasks.firstWhere((s) => s.id == subtaskId);
    subtask.isComplete = !subtask.isComplete;
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Load sample data for demo.
  void loadSampleData() {
    if (_tasks.isNotEmpty) return;
    final now = DateTime.now();
    _tasks.addAll([
      Task(
        title: 'Review Q1 strategy deck',
        description: 'Final review before board meeting',
        priority: TaskPriority.urgent,
        dueDate: now.add(const Duration(hours: 3)),
        subtasks: [
          SubTask(title: 'Check financial projections'),
          SubTask(title: 'Update competitor analysis'),
          SubTask(title: 'Add market expansion slide'),
        ],
      ),
      Task(
        title: 'Ship v2.0 feature set',
        priority: TaskPriority.high,
        dueDate: now.add(const Duration(days: 2)),
        subtasks: [
          SubTask(title: 'User authentication', isComplete: true),
          SubTask(title: 'Dashboard redesign', isComplete: true),
          SubTask(title: 'API integration'),
          SubTask(title: 'Performance optimization'),
        ],
      ),
      Task(
        title: 'Weekly team sync',
        priority: TaskPriority.medium,
        dueDate: now.add(const Duration(days: 1)),
      ),
      Task(
        title: 'Read "The Hard Thing About Hard Things"',
        priority: TaskPriority.low,
        dueDate: now.add(const Duration(days: 7)),
      ),
      Task(
        title: 'Update portfolio website',
        priority: TaskPriority.medium,
        dueDate: now.add(const Duration(days: 3)),
      ),
    ]);
    notifyListeners();
  }

  void _addSampleDataIfEmpty() {
    // no-op placeholder
  }
}
