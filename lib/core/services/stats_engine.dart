import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/advanced_stats_models.dart';
import '../models/stats_event_models.dart';
import '../repositories/advanced_stats_repository.dart';
import 'stats_heatmap_generator.dart';
import 'stats_insight_generator.dart';

class StatsEngine {
  StatsEngine._internal();

  static final StatsEngine instance = StatsEngine._internal();

  factory StatsEngine() => instance;

  final AdvancedStatsRepository _repository = AdvancedStatsRepository();
  final StatsHeatmapGenerator _heatmapGenerator = const StatsHeatmapGenerator();
  final StatsInsightGenerator _insightGenerator = const StatsInsightGenerator();

  static const String _historyCacheKey = 'advanced_stats_history_events_v1';
  static const String _historyHydratedAtKey = 'advanced_stats_hydrated_at_v1';

  Future<void> hydrateHistoricalStats({int days = 120}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final events = await _loadHistoricalEvents(start: start, end: now);
    if (events.isEmpty) {
      await _persistHydrationTimestamp();
      return;
    }

    final eventsByDay = <DateTime, List<StatsEvent>>{};
    for (final event in events) {
      final day = DateTime(
        event.eventTime.year,
        event.eventTime.month,
        event.eventTime.day,
      );
      eventsByDay.putIfAbsent(day, () => <StatsEvent>[]).add(event);
    }

    final dailyStats = <DailyStats>[];
    for (
      var day = start;
      !day.isAfter(today);
      day = day.add(const Duration(days: 1))
    ) {
      final stats = _buildDailyStats(day, eventsByDay[day] ?? const []);
      dailyStats.add(stats);
      await _repository.upsertDailyStats(stats);
    }

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekStats = _buildWeeklyStats(
      weekStart,
      dailyStats.where((stats) => !stats.date.isBefore(weekStart)).toList(),
    );
    await _repository.upsertWeeklyStats(weekStats);

    final monthKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}';
    final monthStats = _buildMonthlyStats(
      monthKey,
      dailyStats
          .where(
            (stats) =>
                stats.date.year == today.year &&
                stats.date.month == today.month,
          )
          .toList(),
      weekStats,
    );
    await _repository.upsertMonthlyStats(monthStats);

    final lifetime = _buildLifetimeStats(dailyStats);
    await _repository.upsertLifetimeStats(lifetime);
    await _persistHydrationTimestamp();
  }

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
    final fallbackDays = List.generate(
      30,
      (index) => index == 29
          ? daily
          : DailyStats.empty(
              createdBy: daily.createdBy,
              date: today.subtract(Duration(days: 29 - index)),
            ),
    );
    final heatmap = stored.heatmap.isNotEmpty
        ? stored.heatmap
        : _heatmapGenerator.build(fallbackDays);
    final generatedHeatmapCard = _heatmapGenerator.buildCard(fallbackDays);
    final generatedInsights = _insightGenerator.build(
      weekly: weekly,
      recentDaily: fallbackDays,
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
          generatedHeatmapCard ??
          HeatmapShareCard(bestScore: 0, consistencyPercent: 0, cells: heatmap),
      milestoneCards: stored.milestoneCards,
      insights: stored.insights.isNotEmpty
          ? stored.insights
          : generatedInsights.isNotEmpty
          ? generatedInsights
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

  Future<List<StatsEvent>> _loadHistoricalEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return _readCachedEvents(start: start, end: end);
      final response = await Supabase.instance.client
          .from('advanced_stats_events')
          .select('event_type,event_time,source_key,payload')
          .eq('created_by', uid)
          .gte('event_time', start.toIso8601String())
          .lte('event_time', end.toIso8601String())
          .order('event_time', ascending: true);
      final rows = (response as List).whereType<Map>().toList();
      await _cacheEventRows(rows);
      return rows.map(_eventFromRow).whereType<StatsEvent>().toList();
    } catch (_) {
      return _readCachedEvents(start: start, end: end);
    }
  }

  StatsEvent? _eventFromRow(Map<dynamic, dynamic> row) {
    final eventType = _eventTypeFromStorage(row['event_type']?.toString());
    final eventTime = DateTime.tryParse(row['event_time']?.toString() ?? '');
    if (eventType == null || eventTime == null) return null;
    final payload = row['payload'] is Map
        ? Map<String, dynamic>.from(row['payload'] as Map)
        : const <String, dynamic>{};
    return StatsEvent(
      eventType: eventType,
      eventTime: eventTime,
      sourceKey: row['source_key']?.toString() ?? 'app',
      payload: payload,
    );
  }

  Future<void> _cacheEventRows(List<Map<dynamic, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyCacheKey, jsonEncode(rows));
    } catch (_) {
      // Best effort cache.
    }
  }

  Future<List<StatsEvent>> _readCachedEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyCacheKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(_eventFromRow)
          .whereType<StatsEvent>()
          .where(
            (event) =>
                !event.eventTime.isBefore(start) &&
                !event.eventTime.isAfter(end),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persistHydrationTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _historyHydratedAtKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // Best effort cache.
    }
  }

  DailyStats _buildDailyStats(DateTime day, List<StatsEvent> events) {
    var focusCompleted = 0;
    var focusBroken = 0;
    var ceoCompleted = 0;
    var ceoBroken = 0;
    var focusMinutes = 0;
    var ceoMinutes = 0;
    var blocked = 0;
    var screenTimeMinutes = 0;
    var productiveMinutes = 0;
    var distractingMinutes = 0;
    var habitsPlanned = 0;
    var habitsCompleted = 0;
    var habitsMissed = 0;

    for (final event in events) {
      switch (event.eventType) {
        case StatsEventType.focusSessionCompleted:
          focusCompleted++;
          focusMinutes += _payloadInt(event, 'duration_minutes');
        case StatsEventType.focusSessionBroken:
          focusBroken++;
        case StatsEventType.ceoSessionCompleted:
          ceoCompleted++;
          ceoMinutes += _payloadInt(event, 'duration_minutes');
        case StatsEventType.ceoSessionBroken:
          ceoBroken++;
        case StatsEventType.blockedAppAttempt:
        case StatsEventType.blockedSiteAttempt:
          if (event.payload['blocked'] != false) blocked++;
        case StatsEventType.screenTimeRecorded:
          screenTimeMinutes = _payloadInt(event, 'total_minutes');
        case StatsEventType.productiveTimeRecorded:
          productiveMinutes += _payloadInt(event, 'minutes');
        case StatsEventType.distractingTimeRecorded:
          distractingMinutes += _payloadInt(event, 'minutes');
        case StatsEventType.habitPlanned:
          habitsPlanned++;
        case StatsEventType.habitCompleted:
          habitsCompleted++;
        case StatsEventType.habitMissed:
          habitsMissed++;
        case StatsEventType.focusSessionStarted:
        case StatsEventType.ceoSessionStarted:
        case StatsEventType.rankChanged:
        case StatsEventType.manualTimeExtensionRequested:
        case StatsEventType.manualTimeExtensionConfirmed:
        case StatsEventType.dashboardOpened:
          break;
      }
    }

    final planned = habitsPlanned == 0
        ? habitsCompleted + habitsMissed
        : habitsPlanned;
    final habitRate = planned == 0 ? 0.0 : habitsCompleted / planned;
    final deepWorkMinutes = focusMinutes + ceoMinutes;
    final timeRecovered = blocked * 5;
    final score = _clampScore(
      25 +
          (habitRate * 25).round() +
          (deepWorkMinutes / 4).round() +
          (blocked * 2) -
          (focusBroken * 8) -
          (ceoBroken * 10) -
          (distractingMinutes / 20).round(),
    );

    return DailyStats(
      createdBy: '',
      date: day,
      attentionScore: score,
      fullDisciplineQualifiedDay:
          score >= 75 && focusCompleted > 0 && habitRate >= 0.8,
      habitStreakValue: habitRate >= 0.8 && planned > 0 ? 1 : 0,
      focusSessionsCompleted: focusCompleted,
      focusSessionsBroken: focusBroken,
      ceoSessionsBroken: ceoBroken,
      deepWorkTimeMinutes: deepWorkMinutes,
      distractionsBlocked: blocked,
      timeRecoveredMinutes: timeRecovered,
      habitCompletionRate: habitRate,
      focusStreakValue: focusCompleted > 0 ? 1 : 0,
      ceoStreakValue: ceoCompleted > 0 ? 1 : 0,
    );
  }

  WeeklyStats _buildWeeklyStats(DateTime weekStart, List<DailyStats> days) {
    final focusSessions = days.fold<int>(
      0,
      (sum, day) => sum + day.focusSessionsCompleted,
    );
    final focusMinutes = days.fold<int>(
      0,
      (sum, day) => sum + day.deepWorkTimeMinutes,
    );
    final best = days.fold<int>(
      0,
      (value, day) => day.attentionScore > value ? day.attentionScore : value,
    );
    final worst = days.isEmpty
        ? 0
        : days.fold<int>(
            100,
            (value, day) =>
                day.attentionScore < value ? day.attentionScore : value,
          );
    final score = days.isEmpty
        ? 0
        : (days.fold<int>(0, (sum, day) => sum + day.attentionScore) /
                  days.length)
              .round();

    return WeeklyStats(
      createdBy: '',
      weekStartDate: weekStart,
      weekEndDate: weekStart.add(const Duration(days: 6)),
      weeklyAttentionScore: score,
      totalFocusTimeMinutes: focusMinutes,
      totalCeoTimeMinutes: 0,
      totalDeepWorkTimeMinutes: focusMinutes,
      totalTimeRecoveredMinutes: days.fold<int>(
        0,
        (sum, day) => sum + day.timeRecoveredMinutes,
      ),
      totalDistractionsBlocked: days.fold<int>(
        0,
        (sum, day) => sum + day.distractionsBlocked,
      ),
      averageFocusSessionLengthMinutes: focusSessions == 0
          ? 0
          : (focusMinutes / focusSessions).round(),
      consistencyPercent: days.isEmpty
          ? 0
          : ((days.where((day) => day.fullDisciplineQualifiedDay).length /
                        days.length) *
                    100)
                .round(),
      completionRate: days.isEmpty
          ? 0
          : ((days.fold<double>(
                          0,
                          (sum, day) => sum + day.habitCompletionRate,
                        ) /
                        days.length) *
                    100)
                .round(),
      bestDayAttentionScore: best,
      worstDayAttentionScore: worst,
      weeklyTransformationDelta: score,
    );
  }

  MonthlyStats _buildMonthlyStats(
    String month,
    List<DailyStats> days,
    WeeklyStats week,
  ) {
    final score = days.isEmpty
        ? 0
        : (days.fold<int>(0, (sum, day) => sum + day.attentionScore) /
                  days.length)
              .round();
    return MonthlyStats(
      createdBy: '',
      month: month,
      monthlyAttentionScore: score,
      totalFocusTimeMinutes: days.fold<int>(
        0,
        (sum, day) => sum + day.deepWorkTimeMinutes,
      ),
      totalDeepWorkTimeMinutes: days.fold<int>(
        0,
        (sum, day) => sum + day.deepWorkTimeMinutes,
      ),
      totalTimeRecoveredMinutes: days.fold<int>(
        0,
        (sum, day) => sum + day.timeRecoveredMinutes,
      ),
      consistencyPercent: days.isEmpty
          ? 0
          : ((days.where((day) => day.fullDisciplineQualifiedDay).length /
                        days.length) *
                    100)
                .round(),
      totalSessionsCompleted: days.fold<int>(
        0,
        (sum, day) => sum + day.focusSessionsCompleted,
      ),
      totalSessionsBroken: days.fold<int>(
        0,
        (sum, day) => sum + day.focusSessionsBroken + day.ceoSessionsBroken,
      ),
      totalHabitsCompleted: days.fold<int>(
        0,
        (sum, day) => sum + (day.habitCompletionRate > 0 ? 1 : 0),
      ),
      bestWeekAttentionScore: week.weeklyAttentionScore,
      longestSessionOfMonth: days.fold<int>(
        0,
        (value, day) =>
            day.deepWorkTimeMinutes > value ? day.deepWorkTimeMinutes : value,
      ),
    );
  }

  LifetimeStats _buildLifetimeStats(List<DailyStats> days) {
    final best = days.fold<int>(
      0,
      (value, day) => day.attentionScore > value ? day.attentionScore : value,
    );
    final lowestScreen = 0;
    final deepWork = days.fold<int>(
      0,
      (sum, day) => sum + day.deepWorkTimeMinutes,
    );
    final recovered = days.fold<int>(
      0,
      (sum, day) => sum + day.timeRecoveredMinutes,
    );
    return LifetimeStats(
      createdBy: '',
      highestStreakEver: _longestQualifiedStreak(days),
      lifeRecoveredDays: recovered / 1440,
      totalFocusTimeMinutes: deepWork,
      totalDeepWorkTimeMinutes: deepWork,
      totalDistractionsBlocked: days.fold<int>(
        0,
        (sum, day) => sum + day.distractionsBlocked,
      ),
      totalFocusSessionsCompleted: days.fold<int>(
        0,
        (sum, day) => sum + day.focusSessionsCompleted,
      ),
      totalHabitsCompleted: days.fold<int>(
        0,
        (sum, day) => sum + (day.habitCompletionRate > 0 ? 1 : 0),
      ),
      bestAttentionScoreEver: best,
      lowestScreenTimeEver: lowestScreen,
    );
  }

  int _longestQualifiedStreak(List<DailyStats> days) {
    var best = 0;
    var current = 0;
    for (final day in days) {
      if (day.fullDisciplineQualifiedDay) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  int _payloadInt(StatsEvent event, String key) {
    final raw = event.payload[key];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  int _clampScore(int score) => score.clamp(0, 100);

  StatsEventType? _eventTypeFromStorage(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'focus_session_started':
        return StatsEventType.focusSessionStarted;
      case 'focus_session_completed':
        return StatsEventType.focusSessionCompleted;
      case 'focus_session_broken':
        return StatsEventType.focusSessionBroken;
      case 'ceo_session_started':
        return StatsEventType.ceoSessionStarted;
      case 'ceo_session_completed':
        return StatsEventType.ceoSessionCompleted;
      case 'ceo_session_broken':
        return StatsEventType.ceoSessionBroken;
      case 'blocked_app_attempt':
        return StatsEventType.blockedAppAttempt;
      case 'blocked_site_attempt':
        return StatsEventType.blockedSiteAttempt;
      case 'screen_time_recorded':
        return StatsEventType.screenTimeRecorded;
      case 'productive_time_recorded':
        return StatsEventType.productiveTimeRecorded;
      case 'distracting_time_recorded':
        return StatsEventType.distractingTimeRecorded;
      case 'habit_planned':
        return StatsEventType.habitPlanned;
      case 'habit_completed':
        return StatsEventType.habitCompleted;
      case 'habit_missed':
        return StatsEventType.habitMissed;
      case 'rank_changed':
        return StatsEventType.rankChanged;
      case 'manual_time_extension_requested':
        return StatsEventType.manualTimeExtensionRequested;
      case 'manual_time_extension_confirmed':
        return StatsEventType.manualTimeExtensionConfirmed;
      case 'dashboard_opened':
        return StatsEventType.dashboardOpened;
    }
    return null;
  }
}
