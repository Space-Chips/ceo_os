import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// A habit with streak tracking.
class Habit {
  final String id;
  String name;
  IconData icon;
  Color color;
  int targetPerDay; // how many times per day
  Map<String, int> completions; // date string -> count
  DateTime createdAt;

  Habit({
    String? id,
    required this.name,
    this.icon = Icons.check_circle_outline,
    this.color = const Color(0xFF3B82F6),
    this.targetPerDay = 1,
    Map<String, int>? completions,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        completions = completions ?? {},
        createdAt = createdAt ?? DateTime.now();

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool isCompletedOn(DateTime date) {
    final key = _dateKey(date);
    return (completions[key] ?? 0) >= targetPerDay;
  }

  int completionsOn(DateTime date) => completions[_dateKey(date)] ?? 0;

  void checkIn(DateTime date) {
    final key = _dateKey(date);
    completions[key] = (completions[key] ?? 0) + 1;
  }

  void uncheckIn(DateTime date) {
    final key = _dateKey(date);
    final current = completions[key] ?? 0;
    if (current > 0) {
      completions[key] = current - 1;
    }
  }

  /// Current streak in days (consecutive completions ending today or yesterday).
  int get currentStreak {
    int streak = 0;
    var date = DateTime.now();
    // Allow starting from today or yesterday
    if (!isCompletedOn(date)) {
      date = date.subtract(const Duration(days: 1));
    }
    while (isCompletedOn(date)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Best streak ever.
  int get bestStreak {
    if (completions.isEmpty) return 0;
    int best = 0;
    int current = 0;
    // Sort dates and iterate
    final dates = completions.keys.toList()..sort();
    DateTime? prevDate;
    for (final key in dates) {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if ((completions[key] ?? 0) >= targetPerDay) {
        if (prevDate != null &&
            date.difference(prevDate).inDays == 1) {
          current++;
        } else {
          current = 1;
        }
        if (current > best) best = current;
        prevDate = date;
      } else {
        current = 0;
        prevDate = null;
      }
    }
    return best;
  }

  /// Completion rate over last 7 days.
  double get weeklyRate {
    int completed = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      if (isCompletedOn(now.subtract(Duration(days: i)))) {
        completed++;
      }
    }
    return completed / 7;
  }
}

/// In-memory habit list with check-in tracking.
class HabitProvider extends ChangeNotifier {
  final List<Habit> _habits = [];

  List<Habit> get habits => List.unmodifiable(_habits);

  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
  }

  void removeHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  void checkIn(String id, {DateTime? date}) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.checkIn(date ?? DateTime.now());
    notifyListeners();
  }

  void uncheckIn(String id, {DateTime? date}) {
    final habit = _habits.firstWhere((h) => h.id == id);
    habit.uncheckIn(date ?? DateTime.now());
    notifyListeners();
  }

  void loadSampleData() {
    if (_habits.isNotEmpty) return;
    final now = DateTime.now();
    final habit1 = Habit(
      name: 'Meditate',
      icon: Icons.self_improvement,
      color: const Color(0xFF8B5CF6),
    );
    final habit2 = Habit(
      name: 'Read 30 min',
      icon: Icons.menu_book,
      color: const Color(0xFF3B82F6),
    );
    final habit3 = Habit(
      name: 'Exercise',
      icon: Icons.fitness_center,
      color: const Color(0xFF22C55E),
    );
    final habit4 = Habit(
      name: 'Journal',
      icon: Icons.edit_note,
      color: const Color(0xFFF59E0B),
    );

    // Add some historical data
    for (int i = 1; i <= 14; i++) {
      final date = now.subtract(Duration(days: i));
      if (i % 1 == 0) habit1.checkIn(date);
      if (i % 2 == 0) habit2.checkIn(date);
      if (i % 1 == 0 && i < 10) habit3.checkIn(date);
      if (i % 3 == 0) habit4.checkIn(date);
    }

    _habits.addAll([habit1, habit2, habit3, habit4]);
    notifyListeners();
  }
}
