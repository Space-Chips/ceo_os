import 'package:flutter/material.dart';
import '../models/habit_models.dart';
import '../repositories/habit_repository.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;

  List<Habit> _habits = [];
  Map<String, List<HabitCompletion>> _completions =
      {}; // habitId -> completions
  bool _isLoading = false;

  HabitProvider({HabitRepository? repository})
    : _repository = repository ?? HabitRepository();

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get isLoading => _isLoading;

  /// Count of habits completed today.
  int get completedToday {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    int count = 0;

    for (var habit in _habits) {
      final comps = _completions[habit.id] ?? [];
      final isDone = comps.any((c) => c.date == todayStr && c.completed);
      if (isDone) count++;
    }
    return count;
  }

  bool isHabitCompletedToday(String habitId) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final comps = _completions[habitId] ?? [];
    return comps.any((c) => c.date == todayStr && c.completed);
  }

  Future<List<HabitCompletion>> getCompletionHistory(String habitId) async {
    return await _repository.getCompletionHistory(habitId);
  }

  Future<List<HabitCompletion>> getCompletionsForRange(DateTime start, DateTime end) async {
    return await _repository.getCompletionsForDateRange(start, end);
  }

  Future<List<HabitLog>> getHabitLogs(String habitId) async {
    return await _repository.getHabitLogs(habitId);
  }

  Future<void> addHabitLog(String habitId, String content) async {
    await _repository.createHabitLog(habitId, content);
  }

  int calculateStreak(String habitId, List<HabitCompletion> history) {
    if (history.isEmpty) return 0;
    
    int streak = 0;
    final now = DateTime.now();
    final sortedComps = history.where((c) => c.completed).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedComps.isEmpty) return 0;

    // Check if latest completion is today or yesterday
    final latestDate = DateTime.parse(sortedComps.first.date);
    final diff = now.difference(latestDate).inDays;
    if (diff > 1) return 0;

    DateTime current = latestDate;
    streak = 1;

    for (int i = 1; i < sortedComps.length; i++) {
      final next = DateTime.parse(sortedComps[i].date);
      if (current.difference(next).inDays == 1) {
        streak++;
        current = next;
      } else if (current.difference(next).inDays == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _habits = await _repository.getHabits();

      // Load completions for each habit (this could be optimized with a single query or join)
      // For now, let's just load today's completions to be fast
      final todayCompletions = await _repository.getTodaysCompletions();

      // Organize into map
      _completions.clear();
      for (var comp in todayCompletions) {
        if (_completions.containsKey(comp.habitId)) {
          _completions[comp.habitId]!.add(comp);
        } else {
          _completions[comp.habitId] = [comp];
        }
      }

      // We might need historical completions for streaks, but let's handle that later or separately
    } catch (e) {
      print('Error loading habit data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createHabit(
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
      final newHabit = await _repository.createHabit(
        title,
        isDaily: isDaily,
        icon: icon,
        category: category,
        quote: quote,
        frequencyType: frequencyType,
        intervalDays: intervalDays,
        targetType: targetType,
        targetValue: targetValue,
        targetUnit: targetUnit,
        reminderTime: reminderTime,
        autoPopup: autoPopup,
        colorTheme: colorTheme,
      );
      if (newHabit != null) {
        _habits.add(newHabit);
        notifyListeners();
      }
    } catch (e) {
      print('Error creating habit: $e');
    }
  }

  Future<void> toggleHabit(String habitId, {double? amount}) async {
    try {
      // Optimistic update
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Update local state temporarily
      if (_completions.containsKey(habitId)) {
        final index = _completions[habitId]!.indexWhere(
          (c) => c.date == todayStr,
        );
        if (index != -1) {
          // Toggle existing
          final old = _completions[habitId]![index];
          _completions[habitId]![index] = HabitCompletion(
            id: old.id,
            habitId: old.habitId,
            date: old.date,
            completed: !old.completed,
            createdBy: old.createdBy,
            createdAt: old.createdAt,
          );
        }
      }

      await _repository.toggleCompletion(habitId, now, amount: amount);

      // Refresh to get exact state from DB
      final updatedCompletions = await _repository.getTodaysCompletions();
      _completions.clear();
      for (var comp in updatedCompletions) {
        if (_completions.containsKey(comp.habitId)) {
          _completions[comp.habitId] = [comp];
        } else {
          _completions[comp.habitId] = [comp];
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling habit: $e');
      // Revert if needed
      await loadData();
    }
  }
}
