import '../models/advanced_stats_models.dart';

class StatsEngine {
  const StatsEngine();

  Future<void> hydrateHistoricalStats({int days = 120}) async {}

  Future<AdvancedStatsSnapshot> buildSnapshot() async {
    final now = DateTime.now();
    final daily = DailyStats.empty(createdBy: '', date: now);
    final weekly = WeeklyStats(
      createdBy: '',
      weekStartDate: now.subtract(Duration(days: now.weekday - 1)),
      weekEndDate: now.add(Duration(days: 7 - now.weekday)),
    );
    final monthly = MonthlyStats(
      createdBy: '',
      month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
    );
    final lifetime = LifetimeStats.empty(createdBy: '');
    final heatmap = List.generate(
      30,
      (index) =>
          HeatmapCell.fromScore(now.subtract(Duration(days: 29 - index)), 0),
    );

    return AdvancedStatsSnapshot(
      daily: daily,
      weekly: weekly,
      monthly: monthly,
      lifetime: lifetime,
      heatmap: heatmap,
      highlights: const [
        StatsHighlight(label: 'Score', value: '0'),
        StatsHighlight(label: 'Focus', value: '0m'),
        StatsHighlight(label: 'Blocked', value: '0'),
      ],
      todayCard: const TodayShareCard(),
      weeklyCard: const WeeklyTransformationCard(),
      ceoCard: const CeoCompletionCard(),
      heatmapCard: HeatmapShareCard(
        bestScore: 0,
        consistencyPercent: 0,
        cells: heatmap,
      ),
      insights: const [
        WeeklyInsight(
          title: 'Not enough data yet',
          message: 'Complete more sessions to generate useful insights.',
        ),
      ],
    );
  }
}
