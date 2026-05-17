import '../models/advanced_stats_models.dart';

class StatsInsightGenerator {
  const StatsInsightGenerator();

  List<WeeklyInsight> build({
    required WeeklyStats? weekly,
    required List<DailyStats> recentDaily,
  }) {
    if (weekly == null) return const [];

    final insights = <WeeklyInsight>[];

    final bestFocusWindow = weekly.bestFocusWindow;
    if (bestFocusWindow != null && bestFocusWindow.isNotEmpty) {
      insights.add(
        WeeklyInsight(
          title: 'Peak Focus Window',
          message: 'You focus best between $bestFocusWindow.',
        ),
      );
    }

    final distractingWindow = weekly.mostDistractingTimeWindow;
    if (distractingWindow != null && distractingWindow.isNotEmpty) {
      insights.add(
        WeeklyInsight(
          title: 'Distraction Window',
          message: 'You are most distracted between $distractingWindow.',
        ),
      );
    }

    final distractingApp = weekly.mostDistractingApp;
    if (distractingApp != null && distractingApp.isNotEmpty) {
      insights.add(
        WeeklyInsight(
          title: 'Most Distracting App',
          message: '$distractingApp is generating the most friction this week.',
        ),
      );
    }

    if (weekly.screenTimeTrend < 0) {
      insights.add(
        WeeklyInsight(
          title: 'Screen Time Drop',
          message:
              'You reduced your screen time by ${weekly.screenTimeTrend.abs().toStringAsFixed(1)}% this week.',
        ),
      );
    } else if (weekly.screenTimeTrend > 0) {
      insights.add(
        WeeklyInsight(
          title: 'Screen Time Alert',
          message:
              'Your screen time increased by ${weekly.screenTimeTrend.toStringAsFixed(1)}% versus last week.',
        ),
      );
    }

    if (recentDaily.isNotEmpty) {
      final best = recentDaily.reduce(
        (a, b) => a.attentionScore >= b.attentionScore ? a : b,
      );
      insights.add(
        WeeklyInsight(
          title: 'Best Day',
          message:
              'Your strongest discipline day hit ${best.attentionScore}/100 on ${_fmtDay(best.date)}.',
        ),
      );

      final weakest = recentDaily.reduce(
        (a, b) => a.attentionScore <= b.attentionScore ? a : b,
      );
      insights.add(
        WeeklyInsight(
          title: 'Lowest Day',
          message:
              'Your weakest discipline day was ${weakest.attentionScore}/100 on ${_fmtDay(weakest.date)}. Protect that window next week.',
        ),
      );
    }

    return insights.take(5).toList(growable: false);
  }

  String _fmtDay(DateTime date) {
    return "${date.year.toString().padLeft(4, '0")}-'
        "${date.month.toString().padLeft(2, '0")}-'
        "${date.day.toString().padLeft(2, '0")}';
  }
}
