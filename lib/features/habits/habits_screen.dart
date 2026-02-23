import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, LinearProgressIndicator;
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

  void _switchTab(int index) {
    setState(() => _activeTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: const NeoMonoText(
          'HABITS',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddHabit,
          child: const Icon(
            CupertinoIcons.plus,
            color: AppColors.primaryOrange,
            size: 20,
          ),
        ),
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _TabButton(
                    label: 'GRID',
                    isActive: _activeTab == 0,
                    onTap: () => _switchTab(0),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'GOALS',
                    isActive: _activeTab == 1,
                    onTap: () => _switchTab(1),
                  ),
                ],
              ),
            ),

            // Page Content
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
          ],
        ),
      ),
    );
  }
}

// ── Tab Button ──

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryOrange.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primaryOrange.withValues(alpha: 0.4)
                : AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.primaryOrange : AppColors.tertiaryLabel,
            letterSpacing: 1.5,
          ),
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
          return const Center(
            child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
          );
        }

        if (prov.habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.flame,
                  size: 48,
                  color: AppColors.tertiaryLabel,
                ),
                const SizedBox(height: 16),
                const NeoMonoText(
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
        final isOnTrack = scorePercent >= 90;
        final isAtRisk = scorePercent >= 70 && !isOnTrack;

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
                          'HABIT',
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
                color: isOnTrack
                    ? AppColors.success.withValues(alpha: 0.4)
                    : isAtRisk
                    ? AppColors.primaryOrange.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
                width: 0.5,
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
                            'WEEK SCORE',
                            style: AppTypography.mono.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$scorePercent%',
                        style: AppTypography.mono.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isOnTrack
                              ? AppColors.success
                              : isAtRisk
                              ? AppColors.primaryOrange
                              : AppColors.error,
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
                          isOnTrack
                              ? AppColors.success
                              : isAtRisk
                              ? AppColors.primaryOrange
                              : AppColors.error,
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

            // ── Habit List ──
            ...prov.habitsWithCompletedBottom.map(
              (habit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => widget.onOpenHabit(habit),
                  child: _HabitTile(
                    habit: habit,
                    onToggle: () => prov.toggleHabit(habit.id),
                  ),
                ),
              ),
            ),
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
          color: AppColors.error.withValues(alpha: 0.15),
        ),
        child: const Icon(
          CupertinoIcons.xmark,
          size: 10,
          color: AppColors.error,
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
  WeeklyContract? _contract;
  WeeklyHabitScore? _weeklyScore;
  bool _loading = true;

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
      _loading = false;
    });
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
                      const Icon(
                        CupertinoIcons.star,
                        size: 48,
                        color: AppColors.tertiaryLabel,
                      ),
                      const SizedBox(height: 16),
                      const NeoMonoText(
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
                            const Icon(
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
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.25),
                width: 0.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'WEEK CONTRACT',
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () async {
                          await context.push('/rewards');
                          await _load();
                        },
                        child: Text(
                          'MANAGE',
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const CupertinoActivityIndicator(
                      color: AppColors.primaryOrange,
                    )
                  else if (_contract == null)
                    Text(
                      'No contract for this week. Create one in Rewards.',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.tertiaryLabel,
                      ),
                    )
                  else ...[
                    Text(
                      '${_contract!.weekStartDate} → ${_contract!.weekEndDate}',
                      style: AppTypography.mono.copyWith(
                        fontSize: 9,
                        color: AppColors.tertiaryLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _contractPill(
                            label: 'Reward',
                            value: _contract!.rewardText?.isNotEmpty == true
                                ? _contract!.rewardText!
                                : 'Not set',
                            positive: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _contractPill(
                            label: 'Sanction',
                            value: _contract!.sanctionText?.isNotEmpty == true
                                ? _contract!.sanctionText!
                                : 'Not set',
                            positive: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Threshold ${_contract!.successThresholdPercentage}% • Current ${_weeklyScore?.successPercentage ?? 0}% • ${_contract!.committed ? 'Committed' : 'Not committed'}',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
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
