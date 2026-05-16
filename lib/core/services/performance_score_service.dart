import 'dart:math' as math;

import '../models/advanced_stats_models.dart';
import '../models/insights_models.dart';
import '../models/performance_score_models.dart';

class PerformanceScoreService {
  const PerformanceScoreService._();

  static PerformanceScoreBundle build({
    required DashboardSnapshot dashboard,
    DailyStats? daily,
    WeeklyStats? weekly,
    LifetimeStats? lifetime,
  }) {
    final execution = _buildExecution(dashboard);
    final consistency = _buildConsistency(dashboard, daily: daily, lifetime: lifetime);
    final attention = _buildAttention(dashboard, daily: daily, weekly: weekly);
    final wakeScore = ((execution.score * 0.3) +
            (consistency.score * 0.3) +
            (attention.score * 0.4))
        .round()
        .clamp(0, 100);

    return PerformanceScoreBundle(
      execution: execution,
      consistency: consistency,
      attention: attention,
      wake: WakeScoreBreakdown(
        score: wakeScore,
        executionScore: execution.score,
        consistencyScore: consistency.score,
        attentionScore: attention.score,
      ),
    );
  }

  static ExecutionScoreBreakdown _buildExecution(DashboardSnapshot dashboard) {
    final completionRate = dashboard.totalTasks == 0
        ? 0.0
        : dashboard.completedTasks / dashboard.totalTasks;
    final crucialRate = dashboard.crucialTasksTotal == 0
        ? completionRate
        : dashboard.crucialTasksCompleted / dashboard.crucialTasksTotal;
    final estimatedRate = dashboard.estimatedTaskMinutesPlanned == 0
        ? completionRate
        : (dashboard.estimatedTaskMinutesCompleted /
                dashboard.estimatedTaskMinutesPlanned)
            .clamp(0, 1)
            .toDouble();

    final score = ((completionRate * 45) +
            (crucialRate * 35) +
            (estimatedRate * 20))
        .round()
        .clamp(0, 100);

    return ExecutionScoreBreakdown(
      score: score,
      tasksCompleted: dashboard.completedTasks,
      totalTasks: dashboard.totalTasks,
      completionRate: completionRate,
      crucialTasksCompleted: dashboard.crucialTasksCompleted,
      crucialTasksTotal: dashboard.crucialTasksTotal,
      estimatedMinutesPlanned: dashboard.estimatedTaskMinutesPlanned,
      estimatedMinutesCompleted: dashboard.estimatedTaskMinutesCompleted,
    );
  }

  static ConsistencyScoreBreakdown _buildConsistency(
    DashboardSnapshot dashboard, {
    DailyStats? daily,
    LifetimeStats? lifetime,
  }) {
    final todayCompletionRate = dashboard.totalHabits == 0
        ? 0.0
        : dashboard.habitsCompletedToday / dashboard.totalHabits;
    final weeklyCompletionRate = dashboard.weeklyHabitCompletionRate
        .clamp(0, 1)
        .toDouble();
    final currentStreak = daily?.habitStreakValue ?? dashboard.currentHabitStreak;
    final bestStreak = math.max(
      currentStreak,
      dashboard.bestHabitStreak > 0
          ? dashboard.bestHabitStreak
          : (lifetime?.highestStreakEver ?? 0),
    );
    final streakRate = (currentStreak / 14).clamp(0, 1).toDouble();
    final activeDaysRate = (dashboard.activeHabitDays / 7).clamp(0, 1).toDouble();
    final score = ((weeklyCompletionRate * 45) +
            (todayCompletionRate * 15) +
            (streakRate * 25) +
            (activeDaysRate * 15))
        .round()
        .clamp(0, 100);

    return ConsistencyScoreBreakdown(
      score: score,
      habitsCompleted: dashboard.habitsCompletedToday,
      totalHabits: dashboard.totalHabits,
      weeklyCompletionRate: weeklyCompletionRate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      activeDays: dashboard.activeHabitDays,
    );
  }

  static AttentionScoreBreakdown _buildAttention(
    DashboardSnapshot dashboard, {
    DailyStats? daily,
    WeeklyStats? weekly,
  }) {
    final focusSessionsCompleted =
        daily?.focusSessionsCompleted ??
        dashboard.focusSessionsCompletedToday.takeIfPositive() ??
        dashboard.focusSessions7d;
    final deepWorkMinutes =
        daily?.deepWorkTimeMinutes.takeIfPositive() ??
        dashboard.deepWorkMinutesToday.takeIfPositive() ??
        weekly?.totalDeepWorkTimeMinutes ??
        dashboard.totalFocusMinutes7d;
    final earlyExits =
        (daily?.focusSessionsBroken ?? 0) + (daily?.ceoSessionsBroken ?? 0) > 0
        ? (daily?.focusSessionsBroken ?? 0) + (daily?.ceoSessionsBroken ?? 0)
        : dashboard.earlyExitsToday;
    final distractionsBlocked =
        daily?.distractionsBlocked.takeIfPositive() ??
        dashboard.distractionsBlockedToday;
    final recoveredTimeMinutes =
        daily?.timeRecoveredMinutes.takeIfPositive() ??
        dashboard.recoveredTimeMinutesToday;

    final fallbackScore = (((math.min(1.0, deepWorkMinutes / 210.0)) * 50) +
            ((math.min(1.0, focusSessionsCompleted / 7.0)) * 20) +
            ((math.min(1.0, distractionsBlocked / 12.0)) * 15) +
            ((math.min(1.0, recoveredTimeMinutes / 60.0)) * 15) -
            (earlyExits * 10))
        .round()
        .clamp(0, 100);

    final score = (daily?.attentionScore ??
            (dashboard.attentionScoreToday > 0
                ? dashboard.attentionScoreToday
                : null) ??
            fallbackScore)
        .clamp(0, 100);

    return AttentionScoreBreakdown(
      score: score,
      focusSessionsCompleted: focusSessionsCompleted,
      deepWorkMinutes: deepWorkMinutes,
      earlyExits: earlyExits,
      distractionsBlocked: distractionsBlocked,
      recoveredTimeMinutes: recoveredTimeMinutes,
    );
  }
}

extension on int {
  int? takeIfPositive() => this > 0 ? this : null;
}
