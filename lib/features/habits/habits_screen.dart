import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'habit_gallery_sheet.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  int _activeTab = 0; // 0 = grid, 1 = goals
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showAddHabit() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const HabitGallerySheet(),
    );
  }

  void _openCompletionPage(Habit habit) {
    context.push('/habits/complete', extra: habit);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => context.go('/home'),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.back,
                          size: 21,
                          color: AppColors.secondaryLabel,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Home',
                          style: AppTypography.callout.copyWith(
                            fontSize: 16,
                            color: AppColors.secondaryLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: _showAddHabit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        color: AppColors.cardBackgroundStrong.withValues(
                          alpha: 0.54,
                        ),
                        border: Border.all(
                          color: AppColors.glassBorder.withValues(alpha: 0.42),
                          width: 0.55,
                        ),
                      ),
                      child: Text(
                        _activeTab == 0 ? '+ Habit' : '+ Goal',
                        style: AppTypography.callout.copyWith(
                          fontSize: 16,
                          color: AppColors.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Habits',
                  style: AppTypography.largeTitle.copyWith(
                    fontSize: 56,
                    height: 1,
                    color: AppColors.label,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _activeTab = i),
                children: [
                  _GridTab(onOpenHabit: _openCompletionPage),
                  const _GoalsTab(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                _activeTab == 0
                    ? 'Swipe right for Goals & Contract →'
                    : '← Swipe left for Habits Grid',
                textAlign: TextAlign.center,
                style: AppTypography.mono.copyWith(
                  fontSize: 10,
                  color: AppColors.tertiaryLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: GRID — Weekly habit grid + score (V1-style)
// ══════════════════════════════════════════════════════════════════

class _GridTab extends StatefulWidget {
  final Function(Habit) onOpenHabit;
  const _GridTab({required this.onOpenHabit});

  @override
  State<_GridTab> createState() => _GridTabState();
}

class _GridTabState extends State<_GridTab> {
  Map<String, Map<String, HabitCompletion>> _weeklyCompletions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeeklyData());
  }

  Future<void> _loadWeeklyData() async {
    final prov = context.read<HabitProvider>();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final completions = await prov.getCompletionsForRange(weekStart, weekEnd);

    final Map<String, Map<String, HabitCompletion>> mapped = {};
    for (final c in completions) {
      mapped.putIfAbsent(c.habitId, () => {})[c.date] = c;
    }

    if (mounted) setState(() => _weeklyCompletions = mapped);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading && prov.habits.isEmpty) {
          return Center(
            child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
          );
        }

        if (prov.habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.flame,
                  size: 48,
                  color: AppColors.tertiaryLabel,
                ),
                const SizedBox(height: 16),
                NeoMonoText(
                  'NO_HABITS',
                  fontSize: 14,
                  color: AppColors.secondaryLabel,
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        // Calculate weekly score
        int totalExpected = 0;
        int totalCompleted = 0;
        for (final habit in prov.habits) {
          for (int d = 0; d < 7; d++) {
            final day = weekStart.add(Duration(days: d));
            final dayNum = day.weekday % 7; // 0=Sun, 1=Mon...
            final isScheduled =
                habit.isDaily ||
                (habit.specificDays != null &&
                    habit.specificDays!.contains(dayNum));
            if (!isScheduled) continue;

            final dayStr = DateFormat('yyyy-MM-dd').format(day);
            final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
            final isToday =
                day.day == now.day &&
                day.month == now.month &&
                day.year == now.year;

            if (isPast || isToday) {
              totalExpected++;
              final comp = _weeklyCompletions[habit.id]?[dayStr];
              if (comp != null && comp.completed) totalCompleted++;
            }
          }
        }
        final scorePercent = totalExpected > 0
            ? ((totalCompleted / totalExpected) * 100).round()
            : 0;
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ).copyWith(bottom: 100),
          children: [
            // ── Weekly Grid ──
            GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: 18,
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Habit',
                          style: AppTypography.mono.copyWith(
                            fontSize: 8,
                            color: AppColors.tertiaryLabel,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...dayLabels.map(
                        (l) => SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              l,
                              style: AppTypography.mono.copyWith(
                                fontSize: 9,
                                color: AppColors.tertiaryLabel,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Grid rows
                  ...prov.habitsWithCompletedBottom.map(
                    (habit) => _HabitGridRow(
                      habit: habit,
                      weekStart: weekStart,
                      weeklyCompletions: _weeklyCompletions[habit.id] ?? {},
                      onTap: () => widget.onOpenHabit(habit),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Weekly Score Card ──
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              border: Border.all(
                color: AppColors.glassBorder.withValues(alpha: 0.5),
                width: 0.55,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('MMM d').format(weekStart)} — ${DateFormat('MMM d').format(weekStart.add(const Duration(days: 6)))}',
                            style: AppTypography.mono.copyWith(
                              fontSize: 8,
                              color: AppColors.tertiaryLabel,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Week Score',
                            style: AppTypography.mono.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.9,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$scorePercent%',
                        style: AppTypography.mono.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: scorePercent / 100,
                        backgroundColor: AppColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.success.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalCompleted / $totalExpected',
                        style: AppTypography.mono.copyWith(
                          fontSize: 9,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                      Text(
                        'TARGET 90%',
                        style: AppTypography.mono.copyWith(
                          fontSize: 9,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ── Habit Grid Row ──

class _HabitGridRow extends StatelessWidget {
  final Habit habit;
  final DateTime weekStart;
  final Map<String, HabitCompletion> weeklyCompletions;
  final VoidCallback onTap;

  const _HabitGridRow({
    required this.habit,
    required this.weekStart,
    required this.weeklyCompletions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                habit.title,
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.secondaryLabel,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...List.generate(7, (d) {
              final day = weekStart.add(Duration(days: d));
              final dayStr = DateFormat('yyyy-MM-dd').format(day);
              final dayNum = day.weekday % 7;

              final isScheduled =
                  habit.isDaily ||
                  (habit.specificDays != null &&
                      habit.specificDays!.contains(dayNum));
              final isPast = day.isBefore(today);
              final isToday = day.isAtSameMomentAs(today);

              if (!isScheduled) {
                return SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '·',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.quaternaryLabel,
                      ),
                    ),
                  ),
                );
              }

              final comp = weeklyCompletions[dayStr];
              final isCompleted = comp != null && comp.completed;

              return SizedBox(
                width: 32,
                child: Center(
                  child: _DayCell(
                    isCompleted: isCompleted,
                    isMissed: isPast && !isCompleted && !isToday,
                    isToday: isToday,
                    isFuture: !isPast && !isToday,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Day Cell ──

class _DayCell extends StatelessWidget {
  final bool isCompleted;
  final bool isMissed;
  final bool isToday;
  final bool isFuture;

  const _DayCell({
    required this.isCompleted,
    required this.isMissed,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: 0.2),
        ),
        child: const Icon(
          CupertinoIcons.checkmark,
          size: 12,
          color: AppColors.success,
        ),
      );
    }

    if (isMissed) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.78),
            width: 1.1,
          ),
        ),
      );
    }

    if (isToday) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      );
    }

    // Future
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: GOALS (objectives + weekly contract)
// ══════════════════════════════════════════════════════════════════

class _GoalsTab extends StatefulWidget {
  const _GoalsTab();

  @override
  State<_GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<_GoalsTab> {
  final FeatureRepository _repo = FeatureRepository();
  final TextEditingController _rewardController = TextEditingController();
  final TextEditingController _sanctionController = TextEditingController();
  WeeklyContract? _contract;
  WeeklyHabitScore? _weeklyScore;
  bool _loading = true;
  bool _saving = false;
  int _threshold = 90;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contract = await _repo.getCurrentWeeklyContract();
    final scores = await _repo.getWeeklyHabitScores(limit: 1);
    final score = scores.isNotEmpty ? scores.first : null;
    if (!mounted) return;
    setState(() {
      _contract = contract;
      _weeklyScore = score;
      _rewardController.text = contract?.rewardText ?? '';
      _sanctionController.text = contract?.sanctionText ?? '';
      _threshold = contract?.successThresholdPercentage ?? 90;
      _loading = false;
    });
  }

  Future<void> _commitContract() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repo.upsertCurrentWeeklyContract(
        reward: _rewardController.text.trim(),
        sanction: _sanctionController.text.trim(),
        threshold: _threshold,
        committed: true,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _sanctionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, prov, _) {
        final categories = <String, List<Habit>>{};
        for (final habit in prov.habitsWithCompletedBottom) {
          final cat = habit.category ?? 'General';
          categories.putIfAbsent(cat, () => []).add(habit);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ).copyWith(bottom: 100),
          children: [
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.star,
                        size: 48,
                        color: AppColors.tertiaryLabel,
                      ),
                      const SizedBox(height: 16),
                      NeoMonoText(
                        'NO_GOALS',
                        fontSize: 14,
                        color: AppColors.secondaryLabel,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add habits with categories to see goals here',
                        style: AppTypography.mono.copyWith(
                          fontSize: 10,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...categories.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.scope,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.length} habits',
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 9,
                                      color: AppColors.tertiaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 0.5, color: AppColors.glassBorder),
                        const SizedBox(height: 8),
                        ...entry.value.map(
                          (habit) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  prov.isHabitCompletedToday(habit.id)
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                  size: 16,
                                  color: prov.isHabitCompletedToday(habit.id)
                                      ? AppColors.success
                                      : AppColors.tertiaryLabel,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    habit.title,
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 11,
                                      color: AppColors.secondaryLabel,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _weekContractCard(),
          ],
        );
      },
    );
  }

  Widget _weekContractCard() {
    final committed = _contract?.committed ?? false;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.8),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                size: 16,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Week Contract',
                style: AppTypography.headline.copyWith(
                  fontSize: 16,
                  color: AppColors.label,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                committed ? 'Committed' : 'Draft',
                style: AppTypography.mono.copyWith(
                  fontSize: 10,
                  color: committed ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            CupertinoActivityIndicator(color: AppColors.primaryOrange)
          else ...[
            GlassInputField(
              controller: _rewardController,
              placeholder: 'Reward if successful',
            ),
            const SizedBox(height: 10),
            GlassInputField(
              controller: _sanctionController,
              placeholder: 'Sanction if failed',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Threshold $_threshold%',
                  style: AppTypography.callout.copyWith(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Current ${_weeklyScore?.successPercentage ?? 0}%',
                  style: AppTypography.mono.copyWith(
                    fontSize: 10,
                    color: AppColors.tertiaryLabel,
                  ),
                ),
              ],
            ),
            CupertinoSlider(
              value: _threshold.toDouble(),
              min: 60,
              max: 100,
              divisions: 8,
              activeColor: AppColors.primaryOrange,
              onChanged: committed
                  ? null
                  : (value) => setState(() => _threshold = value.round()),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: committed || _saving ? null : _commitContract,
              child: Container(
                width: double.infinity,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: committed
                        ? [
                            AppColors.surface.withValues(alpha: 0.72),
                            AppColors.surfaceMuted.withValues(alpha: 0.72),
                          ]
                        : const [Color(0xFFFF934D), Color(0xFFFFC36A)],
                  ),
                ),
                child: _saving
                    ? CupertinoActivityIndicator(color: AppColors.onAccent)
                    : Text(
                        committed ? 'Contract committed' : 'Commit Contract',
                        style: AppTypography.callout.copyWith(
                          fontSize: 15,
                          color: committed
                              ? AppColors.secondaryLabel
                              : AppColors.onAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contractPill({
    required String label,
    required String value,
    required bool positive,
  }) {
    final color = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.mono.copyWith(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Habit Tile ──

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  const _HabitTile({required this.habit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HabitProvider>();
    final isComplete = prov.isHabitCompletedToday(habit.id);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isComplete
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 22,
              color: isComplete ? AppColors.success : AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              habit.title.toUpperCase(),
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isComplete ? AppColors.tertiaryLabel : AppColors.label,
                decoration: isComplete ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            habit.isDaily ? 'DAILY' : 'WEEKLY',
            style: AppTypography.mono.copyWith(
              fontSize: 8,
              color: AppColors.tertiaryLabel,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
