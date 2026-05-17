import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../components/components.dart';
import '../../core/models/advanced_stats_models.dart';
import '../../core/models/insights_models.dart';
import '../../core/repositories/insights_repository.dart';
import '../../core/services/performance_score_service.dart';
import '../../core/services/stats_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rank_art.dart';

String _localizedRankDisplay(BuildContext context, String rawRankName) {
  final language = context.watch<LanguageProvider>();
  switch (RankArt.canonicalKey(rawRankName)) {
    case 'awakened':
      return language.t('rank_awakened');
    case 'immortal':
      return language.t('rank_immortal');
    case 'diamond':
      return language.t('rank_diamond');
    case 'platinum':
      return language.t('rank_platinum');
    case 'gold':
      return language.t('rank_gold');
    case 'silver':
      return language.t('rank_silver');
    case 'bronze':
      return language.t('rank_bronze');
    case 'sleeping':
    default:
      return language.t('rank_asleep');
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsEngine _engine = StatsEngine();
  final InsightsRepository _insightsRepository = InsightsRepository();
  final HabitRepository _habitRepository = HabitRepository();
  final PageController _pageController = PageController();
  HabitProvider? _habitProvider;
  TaskProvider? _taskProvider;
  Timer? _refreshDebounce;

  AdvancedStatsSnapshot? _snapshot;
  DashboardSnapshot? _dashboardSnapshot;
  List<Habit> _habits = const [];
  List<HabitCompletion> _habitYearCompletions = const [];
  bool _loading = true;
  String? _error;
  int _page = 0;

  static const List<String> _tabs = [
    'Overview',
    'Week',
    'Month',
    'Lifetime',
    'Insights',
  ];

  String _t(String key) => context.watch<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final habitProvider = context.read<HabitProvider>();
    final taskProvider = context.read<TaskProvider>();

    if (!identical(_habitProvider, habitProvider)) {
      _habitProvider?.removeListener(_handleSourceDataChanged);
      _habitProvider = habitProvider;
      _habitProvider?.addListener(_handleSourceDataChanged);
    }

    if (!identical(_taskProvider, taskProvider)) {
      _taskProvider?.removeListener(_handleSourceDataChanged);
      _taskProvider = taskProvider;
      _taskProvider?.addListener(_handleSourceDataChanged);
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _habitProvider?.removeListener(_handleSourceDataChanged);
    _taskProvider?.removeListener(_handleSourceDataChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _handleSourceDataChanged() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _engine.hydrateHistoricalStats(days: 120);
      final snapshot = await _engine.buildSnapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      final raw = e.toString();
      if (!mounted) return;
      setState(() {
        _error = _mapStatsError(raw);
        _loading = false;
      });
    }
  }

  String _mapStatsError(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized.contains('advanced_stats_events') ||
        normalized.contains('advanced_daily_stats') ||
        normalized.contains('advanced_weekly_stats') ||
        normalized.contains('advanced_monthly_stats') ||
        normalized.contains('advanced_lifetime_stats')) {
      return 'Advanced stats are not available right now. Please try again later.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.7)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: Icon(CupertinoIcons.back, color: AppColors.accent),
        ),
        middle: Text(_t('advanced_stats'), style: AppTypography.headline),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _load,
          child: Icon(CupertinoIcons.refresh, color: AppColors.accent, size: 20),
        ),
      ),
      child: _loading
          ? Center(child: CupertinoActivityIndicator(color: AppColors.accent))
          : _snapshot == null
          ? _ErrorState(message: _error ?? 'Stats unavailable', onRetry: _load)
          : _Content(
              snapshot: _snapshot!,
              dashboardSnapshot: _dashboardSnapshot,
              habits: _habits,
              habitYearCompletions: _habitYearCompletions,
              page: _page,
              pageController: _pageController,
              onPageSelected: (index) {
                if (!mounted) return;
                setState(() => _page = index);
              },
            ),
    );
  }
}

class _Content extends StatelessWidget {
  final AdvancedStatsSnapshot snapshot;
  final DashboardSnapshot? dashboardSnapshot;
  final List<Habit> habits;
  final List<HabitCompletion> habitYearCompletions;
  final int page;
  final PageController pageController;
  final ValueChanged<int> onPageSelected;

  const _Content({
    required this.snapshot,
    required this.dashboardSnapshot,
    required this.habits,
    required this.habitYearCompletions,
    required this.page,
    required this.pageController,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _HeroHeader(snapshot: snapshot, dashboardSnapshot: dashboardSnapshot),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _StatsScreenState._tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = page == index;
                return GestureDetector(
                  onTap: () {
                    pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: selected
                          ? AppColors.accentSoft.withValues(alpha: 0.2)
                          : AppColors.surface.withValues(alpha: 0.72),
                      border: Border.all(
                        color: selected ? AppColors.borderStrong : AppColors.border,
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      _StatsScreenState._tabs[index],
                      style: AppTypography.footnote.copyWith(
                        color: selected ? AppColors.label : AppColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: onPageSelected,
              children: [
                _OverviewPage(
                  snapshot: snapshot,
                  dashboardSnapshot: dashboardSnapshot,
                ),
                _WeekPage(snapshot: snapshot),
                _MonthPage(
                  snapshot: snapshot,
                  habits: habits,
                  habitYearCompletions: habitYearCompletions,
                ),
                _LifetimePage(snapshot: snapshot),
                _InsightsPage(
                  snapshot: snapshot,
                  dashboardSnapshot: dashboardSnapshot,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final AdvancedStatsSnapshot snapshot;
  final DashboardSnapshot? dashboardSnapshot;

  const _HeroHeader({required this.snapshot, required this.dashboardSnapshot});

  @override
  Widget build(BuildContext context) {
    final weekly = snapshot.weekly;
    final daily = snapshot.daily;
    final lifetime = snapshot.lifetime;
    final wakeScore = dashboardSnapshot == null
        ? 0
        : PerformanceScoreService.build(dashboard: dashboardSnapshot!).wake.score;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GlassCard(
        borderRadius: 22,
        level: GlassCardLevel.elevated,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discipline analytics', style: AppTypography.overline.copyWith(color: AppColors.accent)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${daily?.attentionScore ?? 0}',
                        style: AppTypography.heroNumber.copyWith(color: AppColors.label),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Attention Score',
                        style: AppTypography.subhead.copyWith(color: AppColors.secondaryLabel),
                      ),
                    ],
                  ),
                ),
                _CompactMetric(
                  label: language.t('streak'),
                  value: '${lifetime?.highestStreakEver ?? 0}d',
                ),
                const SizedBox(width: 8),
                _CompactMetric(
                  label: 'Rank',
                  value: RankArt.displayName(
                    lifetime?.currentRank ?? weekly?.mostDistractingApp ?? 'Asleep',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.highlights.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = snapshot.highlights[index];
                  return Container(
                    width: 122,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surface.withValues(alpha: 0.76),
                      border: Border.all(color: AppColors.border, width: 0.9),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: AppTypography.caption1),
                        const Spacer(),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (item.deltaLabel != null)
                          Text(
                            item.deltaLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption2.copyWith(color: AppColors.secondaryLabel),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  final AdvancedStatsSnapshot snapshot;
  final DashboardSnapshot? dashboardSnapshot;

  const _OverviewPage({
    required this.snapshot,
    required this.dashboardSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final daily = snapshot.daily;
    final weekly = snapshot.weekly;
    final dashboard = dashboardSnapshot;
    final scores = dashboard == null
        ? null
        : PerformanceScoreService.build(dashboard: dashboard);
    final wakeScore = scores?.wake.score ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        if (scores != null) ...[
          _ScoreSectionCard(
            title: language.t('dashboard_wake_score'),
            score: scores.wake.score,
            accent: AppColors.accent,
            items: [
              _DetailItem('Execution Score', '${scores.wake.executionScore}'),
              _DetailItem('Consistency Score', '${scores.wake.consistencyScore}'),
              _DetailItem('Attention Score', '${scores.wake.attentionScore}'),
            ],
          ),
          const SizedBox(height: 10),
          _ScoreSectionCard(
            title: 'Execution Score',
            score: scores.execution.score,
            accent: AppColors.primaryOrange,
            items: [
              _DetailItem(
                'Tasks completed',
                '${scores.execution.tasksCompleted}/${scores.execution.totalTasks}',
              ),
              _DetailItem(
                'Completion rate',
                _formatPercent(scores.execution.completionRate * 100),
              ),
              _DetailItem(
                'Crucial tasks completed',
                '${scores.execution.crucialTasksCompleted}/${scores.execution.crucialTasksTotal}',
              ),
              _DetailItem(
                'Estimated vs completed time',
                scores.execution.estimatedMinutesPlanned > 0
                    ? '${scores.execution.estimatedMinutesCompleted}m / ${scores.execution.estimatedMinutesPlanned}m'
                    : 'No task estimates yet',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ScoreSectionCard(
            title: 'Consistency Score',
            score: scores.consistency.score,
            accent: AppColors.success,
            items: [
              _DetailItem(
                'Habits completed',
                '${scores.consistency.habitsCompleted}/${scores.consistency.totalHabits}',
              ),
              _DetailItem(
                'Weekly completion rate',
                _formatPercent(scores.consistency.weeklyCompletionRate * 100),
              ),
              _DetailItem(
                'Current streak',
                '${scores.consistency.currentStreak} days',
              ),
              _DetailItem(
                'Best streak',
                '${scores.consistency.bestStreak} days',
              ),
              _DetailItem(
                'Active days',
                '${scores.consistency.activeDays}/7',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DetailListCard(
            title: 'Focus & Control',
            items: [
              _DetailItem(
                'Focus sessions completed',
                '${scores.attention.focusSessionsCompleted}',
              ),
              _DetailItem(
                'Deep work minutes',
                '${scores.attention.deepWorkMinutes}m',
              ),
              _DetailItem('Early exits', '${scores.attention.earlyExits}'),
              _DetailItem(
                'Distractions blocked',
                '${scores.attention.distractionsBlocked}',
              ),
              _DetailItem(
                'Recovered time',
                '${scores.attention.recoveredTimeMinutes}m',
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Deep work',
                value: _formatMinutes(daily?.deepWorkTimeMinutes ?? 0),
                subtitle: 'Completed focus + CEO time',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Recovered',
                value: _formatMinutes(daily?.timeRecoveredMinutes ?? 0),
                subtitle: 'Time saved from distractions',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Blocked',
                value: '${daily?.distractionsBlocked ?? 0}',
                subtitle: 'Distraction attempts stopped',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Completion',
                value: _formatPercent((daily?.habitCompletionRate ?? 0) * 100),
                subtitle: 'Habit completion today',
              ),
            ),
          ],
        ),
        if (snapshot.todayCard != null) ...[
          const SizedBox(height: 10),
          _ShareCardContainer(
            title: 'Today card',
            child: _TodayCard(
              card: snapshot.todayCard!,
              score: wakeScore > 0 ? wakeScore : snapshot.todayCard!.attentionScore,
            ),
          ),
        ],
        if (snapshot.weeklyCard != null) ...[
          const SizedBox(height: 10),
          _ShareCardContainer(
            title: 'Weekly transformation',
            child: _WeeklyTransformationCardView(card: snapshot.weeklyCard!),
          ),
        ],
        if (snapshot.ceoCard != null) ...[
          const SizedBox(height: 10),
          _ShareCardContainer(
            title: 'CEO completion',
            child: _CeoCardView(card: snapshot.ceoCard!),
          ),
        ],
        if (weekly != null) ...[
          const SizedBox(height: 10),
          _DetailListCard(
            title: 'Streaks',
            items: [
              _DetailItem('Focus streak', '${daily?.focusStreakValue ?? 0} days'),
              _DetailItem('CEO streak', '${daily?.ceoStreakValue ?? 0} days'),
              _DetailItem('Habit streak', '${daily?.habitStreakValue ?? 0} days'),
              _DetailItem('Full discipline days', '${snapshot.heatmap.where((cell) => cell.attentionScore >= 75).length} / ${snapshot.heatmap.length}'),
            ],
          ),
        ],
      ],
    );
  }
}

class _WeekPage extends StatelessWidget {
  final AdvancedStatsSnapshot snapshot;

  const _WeekPage({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final weekly = snapshot.weekly;
    if (weekly == null) {
      return const _EmptyStatsPage(message: 'No weekly stats available yet.');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Weekly discipline',
                value: '${weekly.weeklyAttentionScore}',
                subtitle: '${weekly.weeklyTransformationDelta >= 0 ? '+' : ''}${weekly.weeklyTransformationDelta.toStringAsFixed(0)} vs last week',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Consistency',
                value: _formatPercent(weekly.consistencyPercent),
                subtitle: 'Qualified discipline days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DetailListCard(
          title: 'Execution',
          items: [
            _DetailItem('Deep work', _formatMinutes(weekly.totalDeepWorkTimeMinutes)),
            _DetailItem('CEO time', _formatMinutes(weekly.totalCeoTimeMinutes)),
            _DetailItem('Time recovered', _formatMinutes(weekly.totalTimeRecoveredMinutes)),
            _DetailItem('Distractions blocked', '${weekly.totalDistractionsBlocked}'),
            _DetailItem('Average focus session', '${weekly.averageFocusSessionLengthMinutes.toStringAsFixed(0)}m'),
            _DetailItem('Completion rate', _formatPercent(weekly.completionRate)),
          ],
        ),
        const SizedBox(height: 10),
        _DetailListCard(
          title: 'Behavior windows',
          items: [
            _DetailItem('Best focus window', weekly.bestFocusWindow ?? 'Not enough data'),
            _DetailItem('Most distracting app', weekly.mostDistractingApp ?? 'Not enough data'),
            _DetailItem(
              'Most distracting time',
              weekly.mostDistractingTimeWindow ?? 'Not enough data',
            ),
            _DetailItem('Screen time trend', '${weekly.screenTimeTrend.toStringAsFixed(1)}%'),
            _DetailItem('Leaderboard percentile', weekly.percentile.toStringAsFixed(0)),
          ],
        ),
      ],
    );
  }
}

class _MonthPage extends StatelessWidget {
  final AdvancedStatsSnapshot snapshot;
  final List<Habit> habits;
  final List<HabitCompletion> habitYearCompletions;

  const _MonthPage({
    required this.snapshot,
    this.habits = const [],
    this.habitYearCompletions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final monthly = snapshot.monthly;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        if (monthly != null) ...[
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Month discipline',
                  value: '${monthly.monthlyAttentionScore}',
                  subtitle: monthly.month,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Sessions',
                  value: '${monthly.totalSessionsCompleted}',
                  subtitle: '${monthly.totalSessionsBroken} broken',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DetailListCard(
            title: 'Monthly totals',
            items: [
              _DetailItem('Focus time', _formatMinutes(monthly.totalFocusTimeMinutes)),
              _DetailItem('CEO time', _formatMinutes(monthly.totalCeoTimeMinutes)),
              _DetailItem('Deep work', _formatMinutes(monthly.totalDeepWorkTimeMinutes)),
              _DetailItem('Time recovered', _formatMinutes(monthly.totalTimeRecoveredMinutes)),
              _DetailItem('Habits completed', '${monthly.totalHabitsCompleted}'),
              _DetailItem('Best week score', '${monthly.bestWeekAttentionScore}'),
              _DetailItem('Lowest screen-time day', monthly.lowestScreenTimeDay ?? 'N/A'),
              _DetailItem('Longest session', '${monthly.longestSessionOfMonth}m'),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _HabitMonthOverviewSection(
          habits: habits,
          completions: habitYearCompletions,
        ),
        const SizedBox(height: 10),
        if (snapshot.heatmapCard != null)
          _ShareCardContainer(
            title: '30 day discipline heatmap',
            child: _HeatmapCardView(card: snapshot.heatmapCard!),
          )
        else
          const _EmptyStatsPage(message: 'No heatmap data available yet.'),
      ],
    );
  }
}

class _LifetimePage extends StatelessWidget {
  final AdvancedStatsSnapshot snapshot;

  const _LifetimePage({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final lifetime = snapshot.lifetime;
    if (lifetime == null) {
      return const _EmptyStatsPage(message: 'No lifetime stats available yet.');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Recovered life',
                value: '${lifetime.lifeRecoveredDays.toStringAsFixed(1)}d',
                subtitle: 'Recovered from distraction',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Best streak',
                value: '${lifetime.highestStreakEver}d',
                subtitle: _localizedRankDisplay(context, lifetime.currentRank),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DetailListCard(
          title: 'Lifetime totals',
          items: [
            _DetailItem('Focus time', _formatMinutes(lifetime.totalFocusTimeMinutes)),
            _DetailItem('CEO time', _formatMinutes(lifetime.totalCeoTimeMinutes)),
            _DetailItem('Deep work', _formatMinutes(lifetime.totalDeepWorkTimeMinutes)),
            _DetailItem('Distractions blocked', '${lifetime.totalDistractionsBlocked}'),
            _DetailItem('Focus sessions completed', '${lifetime.totalFocusSessionsCompleted}'),
            _DetailItem('CEO sessions completed', '${lifetime.totalCeoSessionsCompleted}'),
            _DetailItem('Habits completed', '${lifetime.totalHabitsCompleted}'),
            _DetailItem('Best attention score', '${lifetime.bestAttentionScoreEver}'),
            _DetailItem('Lowest screen time', '${lifetime.lowestScreenTimeEver}m'),
          ],
        ),
        if (snapshot.milestoneCards.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...snapshot.milestoneCards.map(
            (milestone) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ShareCardContainer(
                title: milestone.milestoneType.toUpperCase(),
                child: _MilestoneCardView(card: milestone),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightsPage extends StatelessWidget {
  final AdvancedStatsSnapshot snapshot;
  final DashboardSnapshot? dashboardSnapshot;

  const _InsightsPage({
    required this.snapshot,
    required this.dashboardSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    final wakeScore = dashboardSnapshot == null
        ? 0
        : PerformanceScoreService.build(dashboard: dashboardSnapshot!).wake.score;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        if (snapshot.insights.isEmpty)
          const _EmptyStatsPage(message: 'Not enough data for insights yet.')
        else
          ...snapshot.insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      insight.message,
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (snapshot.todayCard != null) ...[
          const SizedBox(height: 4),
          _ShareCardContainer(
            title: 'Screenshot summary',
            child: _TodayCard(
              card: snapshot.todayCard!,
              score: wakeScore > 0 ? wakeScore : snapshot.todayCard!.attentionScore,
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Advanced stats unavailable', style: AppTypography.title3),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.subhead.copyWith(color: AppColors.secondaryLabel),
                ),
                const SizedBox(height: 14),
                LiquidButton(label: 'Retry', onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption1),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.title2.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption1.copyWith(color: AppColors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CompactMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface.withValues(alpha: 0.76),
        border: Border.all(color: AppColors.border, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption2),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailListCard extends StatelessWidget {
  final String title;
  final List<_DetailItem> items;

  const _DetailListCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.subhead.copyWith(color: AppColors.secondaryLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.right,
                      style: AppTypography.callout.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreSectionCard extends StatelessWidget {
  final String title;
  final int score;
  final Color accent;
  final List<_DetailItem> items;

  const _ScoreSectionCard({
    required this.title,
    required this.score,
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            '$score',
            style: AppTypography.heroNumber.copyWith(color: accent),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.right,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCardContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _ShareCardContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.overline.copyWith(color: AppColors.accent)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final TodayShareCard card;
  final int score;

  const _TodayCard({required this.card, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceMuted, AppColors.surface],
        ),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today', style: AppTypography.overline),
          const SizedBox(height: 8),
          Text('${card.attentionScore}/100', style: AppTypography.title1.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniShareMetric(label: 'Deep Work', value: _formatMinutes(card.deepWorkTimeMinutes))),
              Expanded(child: _MiniShareMetric(label: 'Blocked', value: '${card.distractionsBlocked}')),
              Expanded(child: _MiniShareMetric(label: 'Streak', value: '${card.currentStreak}d')),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTransformationCardView extends StatelessWidget {
  final WeeklyTransformationCard card;

  const _WeeklyTransformationCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceMuted, AppColors.surface],
        ),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This week', style: AppTypography.overline),
          const SizedBox(height: 10),
          Text(
            '${card.attentionDelta >= 0 ? '+' : ''}${card.attentionDelta.toStringAsFixed(0)} discipline',
            style: AppTypography.title3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniShareMetric(
                  label: 'Screen',
                  value: '${card.screenTimeNowMinutes}m',
                ),
              ),
              Expanded(
                child: _MiniShareMetric(
                  label: 'Recovered',
                  value: _formatMinutes(card.timeRecoveredMinutes),
                ),
              ),
              Expanded(
                child: _MiniShareMetric(
                  label: 'Consistency',
                  value: _formatPercent(card.consistencyPercent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CeoCardView extends StatelessWidget {
  final CeoCompletionCard card;

  const _CeoCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceMuted, AppColors.surface],
        ),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Blackout mode', style: AppTypography.overline),
                const SizedBox(height: 8),
                Text(
                  '${card.sessionDurationMinutes} min',
                  style: AppTypography.title2.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  card.completedWithoutExit ? 'Completed without exit' : 'Broken early',
                  style: AppTypography.subhead.copyWith(color: AppColors.secondaryLabel),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CompactMetric(label: 'Streak impact', value: '${card.streakImpact}'),
        ],
      ),
    );
  }
}

class _MilestoneCardView extends StatelessWidget {
  final MilestoneShareCard card;

  const _MilestoneCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceMuted, AppColors.surface],
        ),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title, style: AppTypography.title3.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            card.subtitle,
            style: AppTypography.subhead.copyWith(color: AppColors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCardView extends StatelessWidget {
  final HeatmapShareCard card;

  const _HeatmapCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    final cells = card.cells.length > 30 ? card.cells.sublist(card.cells.length - 30) : card.cells;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniShareMetric(label: 'Best score', value: '${card.bestScore}'),
            ),
            Expanded(
              child: _MiniShareMetric(
                label: 'Consistency',
                value: '${card.consistencyPercent}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: cells.map((cell) => _HeatCell(cell: cell)).toList(growable: false),
        ),
      ],
    );
  }
}

class _MiniShareMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniShareMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption2),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.callout.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  final HeatmapCell cell;

  const _HeatCell({required this.cell});

  @override
  Widget build(BuildContext context) {
    final base = AppColors.accentSurfaceSoft;
    final color = switch (cell.intensityLevel) {
      0 => Color.alphaBlend(AppColors.error.withValues(alpha: 0.16), AppColors.surface),
      1 => Color.alphaBlend(base.withValues(alpha: 0.52), AppColors.surface),
      2 => Color.alphaBlend(base.withValues(alpha: 0.72), AppColors.surface),
      3 => Color.alphaBlend(AppColors.accentSurfaceStrong, AppColors.surface),
      _ => Color.alphaBlend(AppColors.accent.withValues(alpha: 0.26), AppColors.surface),
    };

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
    );
  }
}

class _EmptyStatsPage extends StatelessWidget {
  final String message;

  const _EmptyStatsPage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.subhead.copyWith(color: AppColors.secondaryLabel),
        ),
      ),
    );
  }
}

class _HabitMonthOverviewSection extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitCompletion> completions;

  const _HabitMonthOverviewSection({
    required this.habits,
    required this.completions,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const _DetailListCard(
        title: 'Habit completion',
        items: [_DetailItem('4 week view', 'No habits created yet')],
      );
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final firstWeekStart = _startOfWeek(monthStart);
    final weekStarts = List.generate(
      4,
      (index) => firstWeekStart.add(Duration(days: index * 7)),
    );

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '4 week habit view',
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'See habit completion week by week across the current month.',
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(34, 34),
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => _HabitYearOverviewPage(
                        habits: habits,
                        completions: completions,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View year',
                  style: AppTypography.callout.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...weekStarts.map(
            (weekStart) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HabitWeekBoard(
                weekStart: weekStart,
                habits: habits,
                completions: completions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitWeekBoard extends StatelessWidget {
  final DateTime weekStart;
  final List<Habit> habits;
  final List<HabitCompletion> completions;

  const _HabitWeekBoard({
    required this.weekStart,
    required this.habits,
    required this.completions,
  });

  @override
  Widget build(BuildContext context) {
    final completionIndex = _completionIndex(completions);
    final sortedHabits = [...habits]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBackgroundStrong,
        border: Border.all(color: AppColors.cardBorder, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${DateFormat('MMM d").format(weekStart)} — ${DateFormat('MMM d').format(weekStart.add(const Duration(days: 6)))}',
            style: AppTypography.caption1.copyWith(
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Habit',
                  style: AppTypography.overline.copyWith(
                    fontSize: 10,
                    color: AppColors.tertiaryLabel,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              ...const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map(
                (label) => SizedBox(
                  width: 24,
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.overline.copyWith(
                        fontSize: 10,
                        color: AppColors.tertiaryLabel,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sortedHabits.map(
            (habit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      habit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...List.generate(7, (index) {
                    final day = weekStart.add(Duration(days: index));
                    final status = _habitDayStatus(
                      habit: habit,
                      day: day,
                      completionsByHabit: completionIndex[habit.id] ?? const {},
                    );
                    return SizedBox(
                      width: 24,
                      child: Center(
                        child: _HabitMiniCell(status: status),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitMiniCell extends StatelessWidget {
  final _HabitDayStatus status;

  const _HabitMiniCell({required this.status});

  @override
  Widget build(BuildContext context) {
    if (!status.isScheduled) {
      return Text(
        '·',
        style: AppTypography.caption2.copyWith(
          color: AppColors.quaternaryLabel,
        ),
      );
    }

    final Color fill;
    final Color border;
    if (status.completed) {
      fill = AppColors.success.withValues(alpha: 0.86);
      border = AppColors.success.withValues(alpha: 0.95);
    } else if (status.missed) {
      fill = AppColors.error.withValues(alpha: 0.16);
      border = AppColors.error.withValues(alpha: 0.55);
    } else {
      fill = AppColors.surfaceMuted.withValues(alpha: 0.3);
      border = AppColors.borderStrong.withValues(alpha: 0.8);
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: fill,
        border: Border.all(color: border, width: 0.8),
      ),
    );
  }
}

class _HabitYearOverviewPage extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitCompletion> completions;

  const _HabitYearOverviewPage({
    required this.habits,
    required this.completions,
  });

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.7)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: AppColors.accent),
        ),
        middle: Text('Habit Year', style: AppTypography.headline),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          children: [
            Text(
              '$year completion heatmap',
              style: AppTypography.title3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Green means your scheduled habits were completed. Red means they were missed.',
              style: AppTypography.subhead.copyWith(
                color: AppColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(
              12,
              (monthIndex) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HabitMonthHeatmapCard(
                  monthStart: DateTime(year, monthIndex + 1, 1),
                  habits: habits,
                  completions: completions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitMonthHeatmapCard extends StatelessWidget {
  final DateTime monthStart;
  final List<Habit> habits;
  final List<HabitCompletion> completions;

  const _HabitMonthHeatmapCard({
    required this.monthStart,
    required this.habits,
    required this.completions,
  });

  @override
  Widget build(BuildContext context) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final firstGridDay = _startOfWeek(monthStart);
    final lastGridDay = _endOfWeek(monthEnd);
    final completionIndex = _completionIndex(completions);
    final days = <DateTime>[];
    for (
      var day = firstGridDay;
      !day.isAfter(lastGridDay);
      day = day.add(const Duration(days: 1))
    ) {
      days.add(day);
    }

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM').format(monthStart),
            style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: days.map((day) {
              final status = _dayAggregate(
                day: day,
                habits: habits,
                completionsByHabit: completionIndex,
              );
              return _HabitYearCell(
                status: status,
                inMonth: day.month == monthStart.month,
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HabitYearCell extends StatelessWidget {
  final _HabitAggregateStatus status;
  final bool inMonth;

  const _HabitYearCell({required this.status, required this.inMonth});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.surfaceMuted.withValues(alpha: inMonth ? 0.34 : 0.14);
    Color border = AppColors.border;

    if (status.expected > 0) {
      if (status.completed >= status.expected) {
        color = AppColors.success.withValues(alpha: inMonth ? 0.84 : 0.42);
        border = AppColors.success.withValues(alpha: inMonth ? 0.95 : 0.45);
      } else if (status.completed == 0) {
        color = AppColors.error.withValues(alpha: inMonth ? 0.18 : 0.1);
        border = AppColors.error.withValues(alpha: inMonth ? 0.55 : 0.26);
      } else {
        color = AppColors.primaryOrange.withValues(alpha: inMonth ? 0.24 : 0.12);
        border = AppColors.primaryOrange.withValues(alpha: inMonth ? 0.48 : 0.22);
      }
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color,
        border: Border.all(color: border, width: 0.7),
      ),
    );
  }
}

class _HabitDayStatus {
  final bool isScheduled;
  final bool completed;
  final bool missed;

  const _HabitDayStatus({
    required this.isScheduled,
    required this.completed,
    required this.missed,
  });
}

class _HabitAggregateStatus {
  final int expected;
  final int completed;

  const _HabitAggregateStatus({
    required this.expected,
    required this.completed,
  });
}

Map<String, Map<String, HabitCompletion>> _completionIndex(
  List<HabitCompletion> completions,
) {
  final mapped = <String, Map<String, HabitCompletion>>{};
  for (final completion in completions) {
    mapped.putIfAbsent(completion.habitId, () => {})[completion.date] =
        completion;
  }
  return mapped;
}

_HabitDayStatus _habitDayStatus({
  required Habit habit,
  required DateTime day,
  required Map<String, HabitCompletion> completionsByHabit,
}) {
  final createdDay = DateTime(
    habit.createdAt.year,
    habit.createdAt.month,
    habit.createdAt.day,
  );
  final normalizedDay = DateTime(day.year, day.month, day.day);
  final dayNum = normalizedDay.weekday == DateTime.sunday
      ? 7
      : normalizedDay.weekday;
  final isScheduled =
      !normalizedDay.isBefore(createdDay) &&
      (habit.isDaily ||
          (habit.specificDays != null &&
              habit.specificDays!.contains(dayNum)));
  if (!isScheduled) {
    return const _HabitDayStatus(
      isScheduled: false,
      completed: false,
      missed: false,
    );
  }

  final key = DateFormat('yyyy-MM-dd').format(normalizedDay);
  final completion = completionsByHabit[key];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final isPast = normalizedDay.isBefore(today);

  return _HabitDayStatus(
    isScheduled: true,
    completed: completion?.completed == true,
    missed: isPast && completion != null && !completion.completed,
  );
}

_HabitAggregateStatus _dayAggregate({
  required DateTime day,
  required List<Habit> habits,
  required Map<String, Map<String, HabitCompletion>> completionsByHabit,
}) {
  var expected = 0;
  var completed = 0;
  for (final habit in habits) {
    final status = _habitDayStatus(
      habit: habit,
      day: day,
      completionsByHabit: completionsByHabit[habit.id] ?? const {},
    );
    if (!status.isScheduled) continue;
    expected++;
    if (status.completed) completed++;
  }
  return _HabitAggregateStatus(expected: expected, completed: completed);
}

DateTime _startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime _endOfWeek(DateTime date) {
  final start = _startOfWeek(date);
  return start.add(const Duration(days: 6));
}

class _DetailItem {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);
}

String _formatMinutes(int minutes) {
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }
  return '${minutes}m';
}

String _formatPercent(num value) => '${value.toStringAsFixed(0)}%';

String _localizedRankDisplay(BuildContext context, String rank) => rank;
