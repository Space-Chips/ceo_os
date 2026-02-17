import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_progress_ring.dart';
import 'add_habit_sheet.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadSampleData();
    });
  }

  void _showAddHabit() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddHabitSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Daily Habits'),
            backgroundColor: AppColors.systemBackground,
            border: null,
            trailing: GestureDetector(
              onTap: _showAddHabit,
              child: const Icon(
                CupertinoIcons.plus_circle_fill,
                color: AppColors.systemBlue,
                size: 28,
              ),
            ),
          ),

          // ── Weekly Progress Strip ──
          SliverToBoxAdapter(
            child: Consumer<HabitProvider>(
              builder: (context, prov, _) => _WeeklyStrip(provider: prov),
            ),
          ),

          // ── Horizontal Habit Cards ──
          SliverToBoxAdapter(
            child: Consumer<HabitProvider>(
              builder: (context, prov, _) {
                if (prov.habits.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: prov.habits.length,
                    itemBuilder: (context, i) =>
                        _HabitCard(habit: prov.habits[i]),
                  ),
                );
              },
            ),
          ),

          // ── Today's summary ──
          SliverToBoxAdapter(
            child: Consumer<HabitProvider>(
              builder: (context, prov, _) {
                final done = prov.completedToday;
                final total = prov.habits.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySystemBackground,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusGrouped,
                      ),
                    ),
                    child: Row(
                      children: [
                        CeoProgressRing(
                          progress: total > 0 ? done / total : 0.0,
                          size: 44,
                          strokeWidth: 4,
                          gradientColors: [
                            AppColors.systemGreen,
                            AppColors.systemMint,
                          ],
                          child: Text(
                            '$done',
                            style: AppTypography.headline.copyWith(
                              color: AppColors.systemGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$done of $total completed',
                              style: AppTypography.headline,
                            ),
                            Text(
                              'Today\'s progress',
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Habit List with swipe-to-complete ──
          Consumer<HabitProvider>(
            builder: (context, prov, _) {
              if (prov.habits.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.flame,
                          size: 40,
                          color: AppColors.tertiaryLabel,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No habits yet',
                          style: AppTypography.title3.copyWith(
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tap + to create one',
                          style: AppTypography.subhead.copyWith(
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ).copyWith(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _HabitTile(
                        habit: prov.habits[i],
                        onToggle: () => prov.toggleHabit(prov.habits[i].id),
                      ),
                    );
                  }, childCount: prov.habits.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyStrip extends StatelessWidget {
  final HabitProvider provider;
  const _WeeklyStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final date = weekStart.add(Duration(days: i));
            final isToday = date.day == now.day && date.month == now.month;
            return Column(
              children: [
                Text(
                  days[i],
                  style: AppTypography.caption2.copyWith(
                    color: isToday
                        ? AppColors.systemBlue
                        : AppColors.tertiaryLabel,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday
                        ? AppColors.systemBlue
                        : const Color(0x00000000),
                    border: isToday
                        ? null
                        : Border.all(
                            color: AppColors.tertiarySystemBackground,
                            width: 1.5,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: AppTypography.caption1.copyWith(
                        color: isToday
                            ? CupertinoColors.white
                            : AppColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ).toIso8601String().split('T').first;
    final done = habit.completions[today] ?? 0;
    final progress = (done / habit.dailyTarget).clamp(0.0, 1.0);

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(habit.icon, size: 22, color: habit.color),
              CeoProgressRing(
                progress: progress,
                size: 28,
                strokeWidth: 3,
                gradientColors: [habit.color, habit.color],
              ),
            ],
          ),
          const Spacer(),
          Text(
            habit.name,
            style: AppTypography.callout.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$done/${habit.dailyTarget}',
            style: AppTypography.caption2.copyWith(
              color: AppColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatefulWidget {
  final Habit habit;
  final VoidCallback onToggle;
  const _HabitTile({required this.habit, required this.onToggle});
  @override
  State<_HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<_HabitTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _streakAnim;

  @override
  void initState() {
    super.initState();
    _streakAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _streakAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ).toIso8601String().split('T').first;
    final done = h.completions[today] ?? 0;
    final isComplete = done >= h.dailyTarget;

    return Dismissible(
      key: ValueKey(h.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        widget.onToggle();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.systemGreen,
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        ),
        child: const Icon(
          CupertinoIcons.checkmark_alt,
          color: CupertinoColors.white,
          size: 28,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        decoration: BoxDecoration(
          color: AppColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: h.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(h.icon, size: 20, color: h.color),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name + streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        if (h.currentStreak > 0) ...[
                          ScaleTransition(
                            scale: Tween(begin: 0.9, end: 1.1).animate(
                              CurvedAnimation(
                                parent: _streakAnim,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.flame_fill,
                              size: 14,
                              color: AppColors.systemOrange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${h.currentStreak} day streak',
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.systemOrange,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          '${h.weeklyRate}%/wk',
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tap to complete
              GestureDetector(
                onTap: widget.onToggle,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isComplete
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    key: ValueKey(isComplete),
                    size: 28,
                    color: isComplete
                        ? AppColors.systemGreen
                        : AppColors.tertiaryLabel,
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
