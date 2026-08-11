class DashboardSnapshot {
  final int totalTasks;
  final int completedTasks;
  final int crucialTasksTotal;
  final int crucialTasksCompleted;
  final int estimatedTaskMinutesPlanned;
  final int estimatedTaskMinutesCompleted;
  final int tasksDueToday;
  final int overdueTasks;
  final int totalHabits;
  final int habitsCompletedToday;
  final double weeklyHabitCompletionRate;
  final int activeHabitDays;
  final int currentHabitStreak;
  final int bestHabitStreak;
  final int totalFocusMinutes7d;
  final int focusSessions7d;
  final int attentionScoreToday;
  final int deepWorkMinutesToday;
  final int focusSessionsCompletedToday;
  final int earlyExitsToday;
  final int distractionsBlockedToday;
  final int recoveredTimeMinutesToday;
  final int eventsNext7d;
  final int rankLevel;
  final String rankName;
  final int rankPoints;
  final int percentile;
  final List<String> insights;

  const DashboardSnapshot({
    required this.totalTasks,
    required this.completedTasks,
    required this.crucialTasksTotal,
    required this.crucialTasksCompleted,
    required this.estimatedTaskMinutesPlanned,
    required this.estimatedTaskMinutesCompleted,
    required this.tasksDueToday,
    required this.overdueTasks,
    required this.totalHabits,
    required this.habitsCompletedToday,
    required this.weeklyHabitCompletionRate,
    required this.activeHabitDays,
    required this.currentHabitStreak,
    required this.bestHabitStreak,
    required this.totalFocusMinutes7d,
    required this.focusSessions7d,
    required this.attentionScoreToday,
    required this.deepWorkMinutesToday,
    required this.focusSessionsCompletedToday,
    required this.earlyExitsToday,
    required this.distractionsBlockedToday,
    required this.recoveredTimeMinutesToday,
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
    final taskScore = (taskCompletionRate * 35).round();
    final habitScore = (habitCompletionRate * 25).round();
    final focusScore = (attentionScoreToday * 0.4).round();
    return (taskScore + habitScore + focusScore).clamp(0, 100);
  }
}
