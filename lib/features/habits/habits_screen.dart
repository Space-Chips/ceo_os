import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../components/ambient_backdrop.dart';
import 'add_habit_sheet.dart';

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
      builder: (_) => const AddHabitSheet(),
    );
  }

  void _openCompletionPage(Habit habit) {
    // Completion page removed — tapping a habit row in the grid is now a no-op.
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
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
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                color: AppColors.cardBackgroundStrong
                                    .withValues(alpha: 0.54),
                                border: Border.all(
                                  color: AppColors.glassBorder.withValues(
                                    alpha: 0.30,
                                  ),
                                  width: 0.5,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int>? onChanged;

  const _ThresholdSlider({
    required this.value,
    required this.min,
    required this.max,
    this.step = 5,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const thumbSize = 26.0;
    const trackHeight = 3.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usableWidth = width - thumbSize;
        final progress = ((value - min) / (max - min)).clamp(0.0, 1.0);
        final thumbX = progress * usableWidth;
        final trackVerticalCenter = (thumbSize + 4 - trackHeight) / 2;

        void handlePos(double dx) {
          if (onChanged == null) return;
          final pos = (dx - thumbSize / 2).clamp(0.0, usableWidth);
          final newProgress = pos / usableWidth;
          final rawValue = min + newProgress * (max - min);
          final snapped = ((rawValue / step).round()) * step;
          onChanged!(snapped.clamp(min, max));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) =>
              handlePos(details.localPosition.dx),
          onTapDown: (details) => handlePos(details.localPosition.dx),
          child: SizedBox(
            height: thumbSize + 4,
            width: width,
            child: Stack(
              children: [
                // Inactive track (full background)
                Positioned(
                  top: trackVerticalCenter,
                  left: thumbSize / 2,
                  right: thumbSize / 2,
                  height: trackHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Active track (theme-aware label, left of thumb)
                Positioned(
                  top: trackVerticalCenter,
                  left: thumbSize / 2,
                  width: thumbX,
                  height: trackHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.label.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Thumb (label-colored circle, theme-aware)
                Positioned(
                  left: thumbX,
                  top: 2,
                  width: thumbSize,
                  height: thumbSize,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.label,
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.40),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glassShadow.withValues(alpha: 0.32),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HabitsTitle extends StatelessWidget {
  const _HabitsTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Bottom padding sets the gap between the screen title and the first
      // GlassCard. Bumped from 14 → 24 for a more breathing layout.
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Habits',
          style: AppTypography.largeTitle.copyWith(
            fontSize: 52,
            height: 1,
            color: AppColors.label,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
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
          return Center(
            child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
          );
        }

        if (prov.habits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showCupertinoModalPopup(
                  context: context,
                  builder: (_) => const AddHabitSheet(),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackgroundStrong.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.30),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.plus,
                        size: 18,
                        color: AppColors.secondaryLabel,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Create your first habit',
                        style: AppTypography.callout.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 100),
          children: [
            const _HabitsTitle(),
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

            // Spacing between Weekly Grid and Weekly Score cards
            // (bumped 20 → 28 for a more breathing layout).
            const SizedBox(height: 28),

            // ── Weekly Score Card ──
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              border: Border.all(
                color: AppColors.glassBorder.withValues(alpha: 0.5),
                width: 0.9,
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
  final Set<String> _collapsedGoals = <String>{};

  void _toggleGoalCollapsed(String goalKey) {
    setState(() {
      if (_collapsedGoals.contains(goalKey)) {
        _collapsedGoals.remove(goalKey);
      } else {
        _collapsedGoals.add(goalKey);
      }
    });
  }

  Future<void> _confirmDeleteHabit(
    BuildContext context,
    HabitProvider prov,
    Habit habit,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text('Delete habit?'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('"${habit.title}" will be permanently removed.'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await prov.deleteHabit(habit.id);
    }
  }

  Future<void> _confirmDeleteGoal(
    BuildContext context,
    HabitProvider prov,
    String goalName,
    List<Habit> habits,
  ) async {
    final count = habits.length;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text('Delete goal?'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '"$goalName" and its $count habit${count > 1 ? "s" : ""} '
            'will be permanently removed.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final habit in habits) {
        await prov.deleteHabit(habit.id);
      }
    }
  }

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
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 100),
          children: [
            const _HabitsTitle(),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showCupertinoModalPopup(
                    context: context,
                    builder: (_) => const AddHabitSheet(),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackgroundStrong.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.glassBorder.withValues(alpha: 0.30),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.plus,
                          size: 18,
                          color: AppColors.secondaryLabel,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Create your first goal',
                          style: AppTypography.callout.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...categories.entries.map((entry) {
                final isCollapsed = _collapsedGoals.contains(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    borderRadius: 24,
                    showEdgeGlow: false,
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.30),
                      width: 0.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.secondaryLabel.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.scope,
                                size: 20,
                                color: AppColors.label,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _toggleGoalCollapsed(entry.key),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: AppTypography.headline
                                                .copyWith(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.label,
                                                  letterSpacing: -0.2,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${entry.value.length} habit'
                                            '${entry.value.length > 1 ? "s" : ""}',
                                            style: AppTypography.footnote
                                                .copyWith(
                                                  fontSize: 12,
                                                  color: AppColors.secondaryLabel
                                                      .withValues(alpha: 0.62),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedRotation(
                                      turns: isCollapsed ? -0.25 : 0,
                                      duration: const Duration(milliseconds: 180),
                                      child: Icon(
                                        CupertinoIcons.chevron_down,
                                        size: 18,
                                        color: AppColors.tertiaryLabel
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _confirmDeleteGoal(
                                context,
                                prov,
                                entry.key,
                                entry.value,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                child: Icon(
                                  CupertinoIcons.trash,
                                  size: 20,
                                  color: const Color(0xFFF7626B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: isCollapsed
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Container(
                                      height: 0.55,
                                      color: AppColors.glassBorder.withValues(
                                        alpha: 0.38,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...entry.value.map(
                                      (habit) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              prov.isHabitCompletedToday(
                                                    habit.id,
                                                  )
                                                  ? CupertinoIcons
                                                        .checkmark_circle_fill
                                                  : CupertinoIcons.circle,
                                              size: 17,
                                              color:
                                                  prov.isHabitCompletedToday(
                                                    habit.id,
                                                  )
                                                  ? AppColors.success
                                                  : AppColors.tertiaryLabel
                                                        .withValues(alpha: 0.7),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                habit.title,
                                                style: AppTypography.callout
                                                    .copyWith(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: AppColors
                                                          .tertiaryLabel
                                                          .withValues(
                                                            alpha: 0.92,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => _confirmDeleteHabit(
                                                context,
                                                prov,
                                                habit,
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                child: Icon(
                                                  CupertinoIcons.trash,
                                                  size: 15,
                                                  color: const Color(
                                                    0xFFF7626B,
                                                  ).withValues(alpha: 0.85),
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
                      ],
                    ),
                  ),
                );
              }),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderRadius: 22,
      showEdgeGlow: false,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.30),
        width: 0.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                size: 18,
                color: AppColors.secondaryLabel,
              ),
              const SizedBox(width: 8),
              Text(
                'Week Contract',
                style: AppTypography.headline.copyWith(
                  fontSize: 17,
                  color: AppColors.label,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (committed)
                Text(
                  '${_weeklyScore?.successPercentage ?? 0}%',
                  style: AppTypography.mono.copyWith(
                    fontSize: 18,
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            CupertinoActivityIndicator(color: AppColors.primaryOrange)
          else ...[
            const SizedBox(height: 2),
            _contractInput(
              controller: _rewardController,
              placeholder: 'Reward if successful',
            ),
            const SizedBox(height: 10),
            _contractInput(
              controller: _sanctionController,
              placeholder: 'Sanction if failed',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Threshold $_threshold%',
                  style: AppTypography.callout.copyWith(
                    fontSize: 14,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (!committed)
                  Text(
                    'Current ${_weeklyScore?.successPercentage ?? 0}%',
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      color: AppColors.tertiaryLabel,
                    ),
                  ),
              ],
            ),
            _ThresholdSlider(
              value: _threshold,
              min: 60,
              max: 100,
              step: 5,
              onChanged: committed
                  ? null
                  : (v) => setState(() => _threshold = v),
            ),
            if (committed) ...[
              const SizedBox(height: 10),
              Text(
                'Locked after commitment for the current week.',
                style: AppTypography.subhead.copyWith(
                  fontSize: 12,
                  color: AppColors.tertiaryLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 14),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: committed || _saving ? null : _commitContract,
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: committed
                        ? [
                            AppColors.surface.withValues(alpha: 0.72),
                            AppColors.surfaceMuted.withValues(alpha: 0.72),
                          ]
                        : [
                            AppColors.label.withValues(alpha: 0.92),
                            AppColors.secondaryLabel.withValues(alpha: 0.84),
                          ],
                  ),
                  border: Border.all(
                    color: AppColors.border.withValues(
                      alpha: committed ? 0.30 : 0.40,
                    ),
                    width: 0.5,
                  ),
                  boxShadow: committed
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.glassShadow.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            spreadRadius: -8,
                          ),
                        ],
                ),
                child: _saving
                    ? CupertinoActivityIndicator(color: AppColors.background)
                    : Text(
                        committed ? 'Contract committed' : 'Commit Contract',
                        style: AppTypography.callout.copyWith(
                          fontSize: 17,
                          color: committed
                              ? AppColors.secondaryLabel
                              : AppColors.background,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contractInput({
    required TextEditingController controller,
    required String placeholder,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      style: AppTypography.callout.copyWith(
        fontSize: 15,
        color: AppColors.label,
        fontWeight: FontWeight.w600,
      ),
      placeholderStyle: AppTypography.callout.copyWith(
        fontSize: 15,
        color: AppColors.secondaryLabel.withValues(alpha: 0.68),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.cardBackgroundStrong.withValues(alpha: 0.64),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.30),
          width: 0.5,
        ),
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
