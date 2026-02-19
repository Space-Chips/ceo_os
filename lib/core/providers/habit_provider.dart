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

  Future<void> createHabit(String title, {bool isDaily = true, String? icon}) async {
    try {
      final newHabit = await _repository.createHabit(title, isDaily: isDaily, icon: icon);
      if (newHabit != null) {
        _habits.add(newHabit);
        notifyListeners();
      }
    } catch (e) {
      print('Error creating habit: $e');
    }
  }

  Future<void> toggleHabit(String habitId) async {
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
        } else {
          // Add new (a bit tricky without real ID, but UI just needs to know it's done)
          // We'll rely on reload after toggle for real consistency or sophisticated local state
          // actually repository toggle handles DB, we should just reload or assume success
        }
      }

      await _repository.toggleCompletion(habitId, now);

      // Refresh to get exact state from DB
      final updatedCompletions = await _repository.getTodaysCompletions();
      _completions
          .clear(); // careful clearing everything if we only fetched today
      // Actually simpler to just reload this habit's completion or all
      // Let's just update based on what we got back
      for (var comp in updatedCompletions) {
        if (_completions.containsKey(comp.habitId)) {
          // Replace or add
          _completions[comp.habitId] = [
            comp,
          ]; // simplistic, assumes only today matters for this view
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
