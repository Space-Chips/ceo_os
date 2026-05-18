import 'dart:async';

import '../models/advanced_stats_models.dart';
import '../models/stats_event_models.dart';
import '../repositories/advanced_stats_repository.dart';

class StatsEngine {
  StatsEngine._internal();

  static final StatsEngine instance = StatsEngine._internal();

  factory StatsEngine() => instance;

  final AdvancedStatsRepository _repository = AdvancedStatsRepository();

  Future<void> hydrateHistoricalStats({int days = 120}) async {}

  Future<void> trackEvent(
    StatsEventType eventType, {
    DateTime? eventTime,
    String sourceKey = 'app',
    Map<String, dynamic> payload = const {},
    bool recompute = true,
  }) async {
    final now = eventTime ?? DateTime.now();
    await _repository.logEvent(
      StatsEventInput(
        eventType: eventType,
        eventTime: now,
        sourceKey: sourceKey,
        payload: payload,
      ),
    );
  }

  Future<void> recordFocusSessionStarted({
    required int plannedDurationMinutes,
    String? linkedTaskId,
  }) {
    return trackEvent(
      StatsEventType.focusSessionStarted,
      payload: {
        'planned_duration_minutes': plannedDurationMinutes,
        if (linkedTaskId != null && linkedTaskId.trim().isNotEmpty)
          'linked_task_id': linkedTaskId.trim(),
      },
    );
  }

  Future<void> recordFocusSessionCompleted({
    required int durationMinutes,
    String? linkedTaskId,
  }) {
    return trackEvent(
      StatsEventType.focusSessionCompleted,
      payload: {
        'duration_minutes': durationMinutes,
        if (linkedTaskId != null && linkedTaskId.trim().isNotEmpty)
          'linked_task_id': linkedTaskId.trim(),
      },
    );
  }

  Future<void> recordFocusSessionBroken({required int elapsedMinutes}) {
    return trackEvent(
      StatsEventType.focusSessionBroken,
      payload: {'elapsed_minutes': elapsedMinutes},
    );
  }

  Future<void> recordCeoSessionStarted({required int plannedDurationMinutes}) {
    return trackEvent(
      StatsEventType.ceoSessionStarted,
      payload: {'planned_duration_minutes': plannedDurationMinutes},
    );
  }

  Future<void> recordCeoSessionCompleted({required int durationMinutes}) {
    return trackEvent(
      StatsEventType.ceoSessionCompleted,
      payload: {'duration_minutes': durationMinutes},
    );
  }

  Future<void> recordCeoSessionBroken({required int elapsedMinutes}) {
    return trackEvent(
      StatsEventType.ceoSessionBroken,
      payload: {'elapsed_minutes': elapsedMinutes},
    );
  }

  Future<void> recordBlockedAppAttempt({
    required String appName,
    String category = 'default',
    bool blocked = true,
  }) {
    return trackEvent(
      StatsEventType.blockedAppAttempt,
      payload: {'app_name': appName, 'category': category, 'blocked': blocked},
    );
  }

  Future<void> recordBlockedSiteAttempt({
    required String domain,
    String category = 'default',
    bool blocked = true,
  }) {
    return trackEvent(
      StatsEventType.blockedSiteAttempt,
      payload: {
        'site_domain': domain,
        'category': category,
        'blocked': blocked,
      },
    );
  }

  Future<void> recordScreenTime({required int totalMinutes}) {
    return trackEvent(
      StatsEventType.screenTimeRecorded,
      payload: {'total_minutes': totalMinutes, 'is_total': true},
    );
  }

  Future<void> recordProductiveTime({required int minutes}) {
    return trackEvent(
      StatsEventType.productiveTimeRecorded,
      payload: {'minutes': minutes},
    );
  }

  Future<void> recordDistractingTime({
    required int minutes,
    bool isTotal = true,
  }) {
    return trackEvent(
      StatsEventType.distractingTimeRecorded,
      payload: {'minutes': minutes, 'is_total': isTotal},
    );
  }

  Future<void> recordHabitPlanned({
    required String habitId,
    DateTime? eventTime,
  }) {
    return trackEvent(
      StatsEventType.habitPlanned,
      eventTime: eventTime,
      payload: {'habit_id': habitId},
    );
  }

  Future<void> recordHabitStatus({
    required String habitId,
    required bool completed,
    DateTime? eventTime,
  }) {
    return trackEvent(
      completed ? StatsEventType.habitCompleted : StatsEventType.habitMissed,
      eventTime: eventTime,
      payload: {'habit_id': habitId},
    );
  }

  Future<void> recordRankChanged({
    required String rankName,
    int? rankLevel,
    double? rankProgressPercent,
  }) {
    return trackEvent(
      StatsEventType.rankChanged,
      payload: {
        'rank_name': rankName,
        if (rankLevel != null) 'rank_level': rankLevel,
        if (rankProgressPercent != null)
          'rank_progress_percent': rankProgressPercent,
      },
    );
  }

  Future<void> recordManualTimeExtensionRequested({
    required int minutes,
    String source = 'unknown',
  }) {
    return trackEvent(
      StatsEventType.manualTimeExtensionRequested,
      payload: {'minutes': minutes, 'source': source},
    );
  }

  Future<void> recordManualTimeExtensionConfirmed({
    required int minutes,
    String source = 'unknown',
  }) {
    return trackEvent(
      StatsEventType.manualTimeExtensionConfirmed,
      payload: {'minutes': minutes, 'source': source},
    );
  }

  Future<void> recordDashboardOpened() {
    return trackEvent(StatsEventType.dashboardOpened, recompute: false);
  }

  Future<AdvancedStatsSnapshot> buildSnapshot({DateTime? now}) async {
    final target = now ?? DateTime.now();
    final today = DateTime(target.year, target.month, target.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}';

    final stored = await _repository.getSnapshot();
    final daily = stored.daily ?? DailyStats.empty(createdBy: '', date: today);
    final weekly =
        stored.weekly ??
        WeeklyStats(
          createdBy: '',
          weekStartDate: weekStart,
          weekEndDate: weekStart.add(const Duration(days: 6)),
        );
    final monthly =
        stored.monthly ?? MonthlyStats(createdBy: '', month: monthKey);
    final lifetime = stored.lifetime ?? LifetimeStats.empty(createdBy: '');
    final heatmap = stored.heatmap.isNotEmpty
        ? stored.heatmap
        : List.generate(
            30,
            (index) => HeatmapCell.fromScore(
              today.subtract(Duration(days: 29 - index)),
              index == 29 ? daily.attentionScore : 0,
            ),
          );

    return AdvancedStatsSnapshot(
      daily: daily,
      weekly: weekly,
      monthly: monthly,
      lifetime: lifetime,
      heatmap: heatmap,
      highlights: stored.highlights.isNotEmpty
          ? stored.highlights
          : [
              StatsHighlight(
                label: 'Score',
                value: daily.attentionScore.toString(),
              ),
              StatsHighlight(
                label: 'Focus',
                value: _formatMinutes(weekly.totalFocusTimeMinutes),
              ),
              StatsHighlight(
                label: 'Blocked',
                value: weekly.totalDistractionsBlocked.toString(),
              ),
            ],
      todayCard:
          stored.todayCard ??
          TodayShareCard(
            attentionScore: daily.attentionScore,
            deepWorkTimeMinutes: daily.deepWorkTimeMinutes,
            distractionsBlocked: daily.distractionsBlocked,
            currentStreak: [
              daily.focusStreakValue,
              daily.ceoStreakValue,
              daily.habitStreakValue,
            ].reduce((a, b) => a > b ? a : b),
          ),
      weeklyCard:
          stored.weeklyCard ??
          WeeklyTransformationCard(
            attentionDelta: weekly.weeklyTransformationDelta.toDouble(),
            screenTimeNowMinutes: weekly.totalScreenTimeMinutes,
            timeRecoveredMinutes: weekly.totalTimeRecoveredMinutes,
            consistencyPercent: weekly.consistencyPercent.toDouble(),
          ),
      ceoCard: stored.ceoCard ?? const CeoCompletionCard(),
      heatmapCard:
          stored.heatmapCard ??
          HeatmapShareCard(
            bestScore: heatmap.fold<int>(
              0,
              (best, cell) => cell.score > best ? cell.score : best,
            ),
            consistencyPercent: weekly.consistencyPercent,
            cells: heatmap,
          ),
      milestoneCards: stored.milestoneCards,
      insights: stored.insights.isNotEmpty
          ? stored.insights
          : const [
              WeeklyInsight(
                title: 'Not enough data yet',
                message: 'Complete more sessions to generate useful insights.',
              ),
            ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }
}
