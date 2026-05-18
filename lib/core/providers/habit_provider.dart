import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit_models.dart';
import '../models/premium_models.dart';
import '../repositories/habit_repository.dart';
import '../repositories/premium_repository.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;
  final PremiumRepository _premiumRepository;

  List<Habit> _habits = [];
  Map<String, List<HabitCompletion>> _completions =
      {}; // habitId -> completions
  bool _isLoading = false;
  Map<String, Set<String>> _widgetLast7DaysDoneByHabit = const {};
  Map<String, Set<String>> _widgetLast7DaysFailedByHabit = const {};
  List<DateTime> _widgetLast7Days = const [];

  HabitProvider({HabitRepository? repository})
    : _repository = repository ?? HabitRepository(),
      _premiumRepository = PremiumRepository();

  List<Habit> get habits => List.unmodifiable(_habits);
  List<Habit> get habitsWithCompletedBottom {
    final sorted = [..._habits];
    sorted.sort((a, b) {
      final aDone = isHabitCompletedToday(a.id);
      final bDone = isHabitCompletedToday(b.id);
      if (aDone == bDone) return a.createdAt.compareTo(b.createdAt);
      return aDone ? 1 : -1;
    });
    return sorted;
  }

  bool get isLoading => _isLoading;

  String _pendingKey() {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'pending::habits::$uid::v1';
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_pendingKey()) ?? const <String>[];
      return raw
          .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
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
        items.map((m) => jsonEncode(m)).toList(growable: false),
      );
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> _flushPendingIfAny() async {
    final pending = await _loadPending();
    if (pending.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final item in pending) {
      try {
        await _repository.createHabit(
          (item['title'] as String?) ?? '',
          isDaily: (item['isDaily'] as bool?) ?? true,
          icon: item['icon'] as String?,
          category: item['category'] as String?,
          quote: item['quote'] as String?,
          frequencyType: item['frequencyType'] as String?,
          intervalDays: item['intervalDays'] as int?,
          targetType: item['targetType'] as String?,
          targetValue: item['targetValue'] as int?,
          targetUnit: item['targetUnit'] as String?,
          reminderTime: item['reminderTime'] as String?,
          autoPopup: (item['autoPopup'] as bool?) ?? false,
          colorTheme: item['colorTheme'] as String?,
          specificDays: (item['specificDays'] as List?)
              ?.map((e) => e as int)
              .toList(),
          syncToCalendar: (item['syncToCalendar'] as bool?) ?? false,
        );
      } catch (_) {
        remaining.add(item);
      }
    }
    await _savePending(remaining);
  }

  /// Precomputed last-7-days window used by the Habits Table widget.
  /// Days are ordered oldest -> newest (today last).
  List<DateTime> get widgetLast7Days => List.unmodifiable(_widgetLast7Days);

  /// Precomputed completion map used by the Habits Table widget.
  /// Map: habitId -> set of yyyy-MM-dd that are completed.
  Map<String, Set<String>> get widgetCompletionMapLast7Days =>
      _widgetLast7DaysDoneByHabit;

  /// Precomputed explicit-fail map used by the Habits Table widget.
  /// Map: habitId -> set of yyyy-MM-dd that are explicitly marked as not done.
  Map<String, Set<String>> get widgetFailedMapLast7Days =>
      _widgetLast7DaysFailedByHabit;

  /// Count of habits completed today.
  int get completedToday {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
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
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final comps = _completions[habitId] ?? [];
    return comps.any((c) => c.date == todayStr && c.completed);
  }

  Future<List<HabitCompletion>> getCompletionHistory(String habitId) async {
    return await _repository.getCompletionHistory(habitId);
  }

  Future<List<HabitCompletion>> getCompletionsForRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _repository.getCompletionsForDateRange(start, end);
  }

  Future<void> loadWidgetCompletionsForLast7Days() async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 6));
    _widgetLast7Days = List.generate(
      7,
      (i) =>
          DateTime(start.year, start.month, start.day).add(Duration(days: i)),
    );

    try {
      final completions = await _repository.getCompletionsForDateRange(
        start,
        end.add(const Duration(days: 1)),
      );
      final doneMap = <String, Set<String>>{};
      final failedMap = <String, Set<String>>{};
      for (final c in completions) {
        if (c.completed) {
          final set = doneMap.putIfAbsent(c.habitId, () => <String>{});
          set.add(c.date);
        } else {
          final set = failedMap.putIfAbsent(c.habitId, () => <String>{});
          set.add(c.date);
        }
      }
      _widgetLast7DaysDoneByHabit = doneMap;
      _widgetLast7DaysFailedByHabit = failedMap;
    } catch (e) {
      _widgetLast7DaysDoneByHabit = const {};
      _widgetLast7DaysFailedByHabit = const {};
    }
  }

  Future<List<HabitLog>> getHabitLogs(String habitId) async {
    return await _repository.getHabitLogs(habitId);
  }

  Future<void> addHabitLog(String habitId, String content) async {
    await _repository.createHabitLog(habitId, content);
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      _habits.removeWhere((habit) => habit.id == habitId);
      _completions.remove(habitId);
      notifyListeners();
    } catch (e) {
      print('Error deleting habit: $e');
      await loadData();
    }
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
      await _flushPendingIfAny();
    } catch (e) {
      print('Error loading habit data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PremiumCheckResult> createHabit(
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
    List<int>? specificDays,
    bool syncToCalendar = false,
  }) async {
    try {
      // Enforce limits using local state (fast + avoids schema/count drift).
      final runtime = await _premiumRepository.getRuntime();
      if (!runtime.resolved.canCreateUnlimitedHabits) {
        final activeCount = _habits.where((h) => !h.archived).length;
        if (activeCount >= runtime.config.habitsFreeLimit) {
          return PremiumCheckResult.blocked(
            reason: 'habits',
            limit: runtime.config.habitsFreeLimit,
            current: activeCount,
          );
        }
      }

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
        specificDays: specificDays,
        syncToCalendar: syncToCalendar,
      );
      if (newHabit != null) {
        _habits.add(newHabit);
        notifyListeners();
      }
      return const PremiumCheckResult.allowed();
    } catch (e) {
      print('Error creating habit: $e');
      // Never fail-open on premium gating.
      return const PremiumCheckResult.blocked(reason: 'habits');
    }
  }

  Future<void> toggleHabit(String habitId, {double? amount}) async {
    try {
      // Optimistic update
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final comps = _completions.putIfAbsent(habitId, () => []);
      final index = comps.indexWhere((c) => c.date == todayStr);
      if (index != -1) {
        final old = comps[index];
        comps[index] = HabitCompletion(
          id: old.id,
          habitId: old.habitId,
          date: old.date,
          state: old.state,
          completed: !old.completed,
          createdBy: old.createdBy,
          checkedInDate: old.checkedInDate,
          createdAt: old.createdAt,
        );
      } else {
        comps.add(
          HabitCompletion(
            id: 'optimistic-$habitId-$todayStr',
            habitId: habitId,
            date: todayStr,
            completed: true,
            createdBy: 'local',
            createdAt: DateTime.now(),
          ),
        );
      }
      notifyListeners();

      await _repository.toggleCompletion(habitId, now, amount: amount);

      // Refresh to get exact state from DB
      final updatedCompletions = await _repository.getTodaysCompletions();
      _completions.clear();
      for (var comp in updatedCompletions) {
        if (_completions.containsKey(comp.habitId)) {
          _completions[comp.habitId]!.add(comp);
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

  Future<void> setHabitCompletionForDate({
    required String habitId,
    required DateTime date,
    required bool completed,
    String? state,
  }) async {
    await _repository.setCompletionForDate(
      habitId: habitId,
      date: date,
      completed: completed,
      state: state,
    );
  }
}
