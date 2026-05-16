import '../models/advanced_stats_models.dart';

class StatsHeatmapGenerator {
  const StatsHeatmapGenerator();

  List<HeatmapCell> build(List<DailyStats> days) {
    return days.map((day) => HeatmapCell.fromScore(day.date, day.attentionScore)).toList();
  }

  HeatmapShareCard? buildCard(List<DailyStats> days) {
    if (days.isEmpty) return null;
    final cells = build(days);
    final bestScore = days.map((day) => day.attentionScore).reduce((a, b) => a > b ? a : b);
    final consistencyPercent =
        ((days.where((day) => day.fullDisciplineQualifiedDay).length / days.length) * 100)
            .round();
    return HeatmapShareCard(
      bestScore: bestScore,
      consistencyPercent: consistencyPercent,
      cells: cells,
    );
  }
}
