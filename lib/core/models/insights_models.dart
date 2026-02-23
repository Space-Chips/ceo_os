class DashboardSnapshot {
  final int totalTasks;
  final int completedTasks;
  final int tasksDueToday;
  final int overdueTasks;
  final int totalHabits;
  final int habitsCompletedToday;
  final int currentHabitStreak;
  final int totalFocusMinutes7d;
  final int focusSessions7d;
  final int eventsNext7d;
  final int rankLevel;
  final String rankName;
  final int rankPoints;
  final int percentile;
  final List<String> insights;

  const DashboardSnapshot({
    required this.totalTasks,
    required this.completedTasks,
    required this.tasksDueToday,
    required this.overdueTasks,
    required this.totalHabits,
    required this.habitsCompletedToday,
    required this.currentHabitStreak,
    required this.totalFocusMinutes7d,
    required this.focusSessions7d,
    required this.eventsNext7d,
    required this.rankLevel,
    required this.rankName,
    required this.rankPoints,
    required this.percentile,
    required this.insights,
  });

  double get taskCompletionRate =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  double get habitCompletionRate =>
      totalHabits == 0 ? 0 : habitsCompletedToday / totalHabits;

  int get productivityScore {
    final taskScore = (taskCompletionRate * 40).round();
    final habitScore = (habitCompletionRate * 30).round();
    final focusScore = (totalFocusMinutes7d / 35).clamp(0, 20).round();
    final planningScore = eventsNext7d > 0 ? 10 : 0;
    return (taskScore + habitScore + focusScore + planningScore).clamp(0, 100);
  }
}
