import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_card.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Habits', style: AppTypography.displayMedium),
                  Consumer<HabitProvider>(
                    builder: (_, provider, __) {
                      final total = provider.habits.length;
                      final done = provider.habits
                          .where((h) => h.isCompletedOn(DateTime.now()))
                          .length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successMuted,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '$done / $total today',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Build consistency, one day at a time',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Weekly heatmap strip
              _WeeklyStrip(),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Habit list
              Expanded(
                child: Consumer<HabitProvider>(
                  builder: (_, provider, __) {
                    if (provider.habits.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.flame,
                                size: 64, color: AppColors.textMuted),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No habits yet',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: provider.habits.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, index) {
                        return _HabitTile(habit: provider.habits[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddHabitSheet(),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _WeeklyStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Consumer<HabitProvider>(
      builder: (_, provider, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final date = now.subtract(Duration(days: 6 - index));
            final isToday = index == 6;
            final totalHabits = provider.habits.length;
            final completedHabits = provider.habits
                .where((h) => h.isCompletedOn(date))
                .length;
            final ratio =
                totalHabits > 0 ? completedHabits / totalHabits : 0.0;

            return Column(
              children: [
                Text(
                  dayNames[(date.weekday - 1) % 7],
                  style: AppTypography.caption.copyWith(
                    color: isToday
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ratio > 0
                        ? AppColors.accent.withValues(
                            alpha: 0.1 + ratio * 0.5)
                        : isToday
                            ? AppColors.surfaceLight
                            : AppColors.surface,
                    border: isToday
                        ? Border.all(color: AppColors.accent, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: AppTypography.labelMedium.copyWith(
                        color: isToday
                            ? AppColors.accent
                            : ratio > 0
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HabitProvider>();
    final isCompletedToday = habit.isCompletedOn(DateTime.now());
    final completionsToday = habit.completionsOn(DateTime.now());

    return CeoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Streak ring
          CeoProgressRing(
            progress: habit.weeklyRate,
            size: 52,
            strokeWidth: 4,
            gradientColors: [
              habit.color,
              habit.color.withValues(alpha: 0.6),
            ],
            child: Icon(
              habit.icon,
              size: 20,
              color: habit.color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name, style: AppTypography.headingSmall),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(CupertinoIcons.flame,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '${habit.currentStreak} day streak',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '$completionsToday/${habit.targetPerDay}',
                      style: AppTypography.caption.copyWith(
                        color: isCompletedToday
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Check-in button
          GestureDetector(
            onTap: () {
              if (isCompletedToday) {
                provider.uncheckIn(habit.id);
              } else {
                provider.checkIn(habit.id);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? habit.color
                    : habit.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: isCompletedToday
                    ? null
                    : Border.all(
                        color: habit.color.withValues(alpha: 0.3)),
              ),
              child: Icon(
                isCompletedToday
                    ? CupertinoIcons.checkmark_alt
                    : CupertinoIcons.add,
                color: isCompletedToday ? Colors.white : habit.color,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
