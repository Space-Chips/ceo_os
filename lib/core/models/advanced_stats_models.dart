class DailyStats {
  final String createdBy;
  final DateTime date;
  final int attentionScore;
  final bool fullDisciplineQualifiedDay;
  final int habitStreakValue;
  final int focusSessionsCompleted;
  final int focusSessionsBroken;
  final int ceoSessionsBroken;
  final int deepWorkTimeMinutes;
  final int distractionsBlocked;
  final int timeRecoveredMinutes;
  final double habitCompletionRate;
  final int focusStreakValue;
  final int ceoStreakValue;

  const DailyStats({
    required this.createdBy,
    required this.date,
    this.attentionScore = 0,
    this.fullDisciplineQualifiedDay = false,
    this.habitStreakValue = 0,
    this.focusSessionsCompleted = 0,
    this.focusSessionsBroken = 0,
    this.ceoSessionsBroken = 0,
    this.deepWorkTimeMinutes = 0,
    this.distractionsBlocked = 0,
    this.timeRecoveredMinutes = 0,
    this.habitCompletionRate = 0,
    this.focusStreakValue = 0,
    this.ceoStreakValue = 0,
  });

  factory DailyStats.empty({
    required String createdBy,
    required DateTime date,
  }) {
    return DailyStats(createdBy: createdBy, date: date);
  }
}

class WeeklyStats {
  final String createdBy;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int weeklyAttentionScore;
  final int totalFocusTimeMinutes;
  final int totalCeoTimeMinutes;
  final int totalDeepWorkTimeMinutes;
  final int totalTimeRecoveredMinutes;
  final int totalDistractionsBlocked;
  final int totalScreenTimeMinutes;
  final int averageFocusSessionLengthMinutes;
  final int consistencyPercent;
  final int completionRate;
  final int bestDayAttentionScore;
  final int worstDayAttentionScore;
  final int percentile;
  final double screenTimeTrend;
  final int weeklyTransformationDelta;
  final String? bestFocusWindow;
  final String? mostDistractingTimeWindow;
  final String? mostDistractingApp;

  const WeeklyStats({
    required this.createdBy,
    required this.weekStartDate,
    required this.weekEndDate,
    this.weeklyAttentionScore = 0,
    this.totalFocusTimeMinutes = 0,
    this.totalCeoTimeMinutes = 0,
    this.totalDeepWorkTimeMinutes = 0,
    this.totalTimeRecoveredMinutes = 0,
    this.totalDistractionsBlocked = 0,
    this.totalScreenTimeMinutes = 0,
    this.averageFocusSessionLengthMinutes = 0,
    this.consistencyPercent = 0,
    this.completionRate = 0,
    this.bestDayAttentionScore = 0,
    this.worstDayAttentionScore = 0,
    this.percentile = 0,
    this.screenTimeTrend = 0,
    this.weeklyTransformationDelta = 0,
    this.bestFocusWindow,
    this.mostDistractingTimeWindow,
    this.mostDistractingApp,
  });
}

class MonthlyStats {
  final String createdBy;
  final String month;
  final int monthlyAttentionScore;
  final int totalFocusTimeMinutes;
  final int totalCeoTimeMinutes;
  final int totalDeepWorkTimeMinutes;
  final int totalTimeRecoveredMinutes;
  final int totalScreenTimeMinutes;
  final int consistencyPercent;
  final int totalSessionsCompleted;
  final int totalSessionsBroken;
  final int totalHabitsCompleted;
  final int bestWeekAttentionScore;
  final String? lowestScreenTimeDay;
  final int longestSessionOfMonth;
  final int rankChange;

  const MonthlyStats({
    required this.createdBy,
    required this.month,
    this.monthlyAttentionScore = 0,
    this.totalFocusTimeMinutes = 0,
    this.totalCeoTimeMinutes = 0,
    this.totalDeepWorkTimeMinutes = 0,
    this.totalTimeRecoveredMinutes = 0,
    this.totalScreenTimeMinutes = 0,
    this.consistencyPercent = 0,
    this.totalSessionsCompleted = 0,
    this.totalSessionsBroken = 0,
    this.totalHabitsCompleted = 0,
    this.bestWeekAttentionScore = 0,
    this.lowestScreenTimeDay,
    this.longestSessionOfMonth = 0,
    this.rankChange = 0,
  });
}

class LifetimeStats {
  final String createdBy;
  final int highestStreakEver;
  final String currentRank;
  final double lifeRecoveredDays;
  final int totalFocusTimeMinutes;
  final int totalCeoTimeMinutes;
  final int totalDeepWorkTimeMinutes;
  final int totalDistractionsBlocked;
  final int totalFocusSessionsCompleted;
  final int totalCeoSessionsCompleted;
  final int totalHabitsCompleted;
  final int bestAttentionScoreEver;
  final int lowestScreenTimeEver;

  const LifetimeStats({
    required this.createdBy,
    this.highestStreakEver = 0,
    this.currentRank = 'Bronze',
    this.lifeRecoveredDays = 0,
    this.totalFocusTimeMinutes = 0,
    this.totalCeoTimeMinutes = 0,
    this.totalDeepWorkTimeMinutes = 0,
    this.totalDistractionsBlocked = 0,
    this.totalFocusSessionsCompleted = 0,
    this.totalCeoSessionsCompleted = 0,
    this.totalHabitsCompleted = 0,
    this.bestAttentionScoreEver = 0,
    this.lowestScreenTimeEver = 0,
  });

  factory LifetimeStats.empty({required String createdBy}) {
    return LifetimeStats(createdBy: createdBy);
  }
}

class HeatmapCell {
  final DateTime date;
  final int score;
  int get attentionScore => score;
  int get intensityLevel => (score / 25).clamp(0, 4).floor();

  const HeatmapCell({required this.date, required this.score});

  factory HeatmapCell.fromScore(DateTime date, int score) {
    return HeatmapCell(date: date, score: score);
  }
}

class HeatmapShareCard {
  final int bestScore;
  final int consistencyPercent;
  final List<HeatmapCell> cells;

  const HeatmapShareCard({
    required this.bestScore,
    required this.consistencyPercent,
    required this.cells,
  });
}

class WeeklyInsight {
  final String title;
  final String message;

  const WeeklyInsight({required this.title, required this.message});
}

class StatsHighlight {
  final String label;
  final String value;
  final String? deltaLabel;

  const StatsHighlight({
    required this.label,
    required this.value,
    this.deltaLabel,
  });
}

class TodayShareCard {
  final int attentionScore;
  final int deepWorkTimeMinutes;
  final int distractionsBlocked;
  final int currentStreak;

  const TodayShareCard({
    this.attentionScore = 0,
    this.deepWorkTimeMinutes = 0,
    this.distractionsBlocked = 0,
    this.currentStreak = 0,
  });
}

class WeeklyTransformationCard {
  final double attentionDelta;
  final int screenTimeNowMinutes;
  final int timeRecoveredMinutes;
  final double consistencyPercent;

  const WeeklyTransformationCard({
    this.attentionDelta = 0,
    this.screenTimeNowMinutes = 0,
    this.timeRecoveredMinutes = 0,
    this.consistencyPercent = 0,
  });
}

class CeoCompletionCard {
  final int sessionDurationMinutes;
  final bool completedWithoutExit;
  final int streakImpact;

  const CeoCompletionCard({
    this.sessionDurationMinutes = 0,
    this.completedWithoutExit = true,
    this.streakImpact = 0,
  });
}

class MilestoneShareCard {
  final String milestoneType;
  final String title;
  final String subtitle;

  const MilestoneShareCard({
    this.milestoneType = 'milestone',
    required this.title,
    required this.subtitle,
  });
}

class AdvancedStatsSnapshot {
  final DailyStats? daily;
  final WeeklyStats? weekly;
  final MonthlyStats? monthly;
  final LifetimeStats? lifetime;
  final List<StatsHighlight> highlights;
  final List<HeatmapCell> heatmap;
  final TodayShareCard? todayCard;
  final WeeklyTransformationCard? weeklyCard;
  final CeoCompletionCard? ceoCard;
  final HeatmapShareCard? heatmapCard;
  final List<MilestoneShareCard> milestoneCards;
  final List<WeeklyInsight> insights;

  const AdvancedStatsSnapshot({
    this.daily,
    this.weekly,
    this.monthly,
    this.lifetime,
    this.highlights = const [],
    this.heatmap = const [],
    this.todayCard,
    this.weeklyCard,
    this.ceoCard,
    this.heatmapCard,
    this.milestoneCards = const [],
    this.insights = const [],
  });
}
