import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
      context.read<HabitProvider>().loadData();
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
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: CupertinoColors.transparent),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const NeoMonoText(
                  'DAILY_PROTOCOLS',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: AppColors.background.withValues(alpha: 0.8),
                border: null,
              ),

              SliverToBoxAdapter(
                child: Consumer<HabitProvider>(
                  builder: (context, prov, _) => _WeeklyStrip(provider: prov),
                ),
              ),

              SliverToBoxAdapter(
                child: Consumer<HabitProvider>(
                  builder: (context, prov, _) {
                    if (prov.habits.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: prov.habits.length,
                        itemBuilder: (context, i) =>
                            _HabitCard(habit: prov.habits[i]),
                      ),
                    );
                  },
                ),
              ),

              Consumer<HabitProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading && prov.habits.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    );
                  }

                  if (prov.habits.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: NeoMonoText(
                          'NO_ACTIVE_PROTOCOLS',
                          fontSize: 14,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ).copyWith(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
          Positioned(
            right: 24,
            bottom: 40,
            child: FloatingAddButton(onPressed: _showAddHabit),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final date = weekStart.add(Duration(days: i));
            final isToday = date.day == now.day && date.month == now.month;
            return Column(
              children: [
                Text(
                  days[i],
                  style: AppTypography.mono.copyWith(
                    fontSize: 10,
                    color: isToday
                        ? AppColors.primaryOrange
                        : AppColors.tertiaryLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday
                        ? AppColors.primaryOrange
                        : CupertinoColors.transparent,
                    border: isToday
                        ? null
                        : Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: AppTypography.mono.copyWith(
                        fontSize: 12,
                        color: isToday
                            ? AppColors.white
                            : AppColors.secondaryLabel,
                        fontWeight: FontWeight.bold,
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

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'bolt': return CupertinoIcons.bolt_fill;
      case 'flame': return CupertinoIcons.flame_fill;
      case 'drop': return CupertinoIcons.drop_fill;
      case 'heart': return CupertinoIcons.heart_fill;
      case 'star': return CupertinoIcons.star_fill;
      case 'timer': return CupertinoIcons.timer;
      case 'briefcase': return CupertinoIcons.briefcase_fill;
      case 'book': return CupertinoIcons.book_fill;
      default: return CupertinoIcons.bolt_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HabitProvider>();
    final isDone = prov.isHabitCompletedToday(habit.id);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _getIconData(habit.icon),
                  size: 20,
                  color: AppColors.primaryOrange,
                ),
                if (isDone)
                  const Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    size: 20,
                    color: AppColors.success,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              habit.title.toUpperCase(),
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              isDone ? 'PROTOCOL_COMPLETE' : 'PENDING...',
              style: AppTypography.mono.copyWith(
                fontSize: 8,
                color: isDone ? AppColors.success : AppColors.tertiaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  const _HabitTile({required this.habit, required this.onToggle});

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'bolt': return CupertinoIcons.bolt_fill;
      case 'flame': return CupertinoIcons.flame_fill;
      case 'drop': return CupertinoIcons.drop_fill;
      case 'heart': return CupertinoIcons.heart_fill;
      case 'star': return CupertinoIcons.star_fill;
      case 'timer': return CupertinoIcons.timer;
      case 'briefcase': return CupertinoIcons.briefcase_fill;
      case 'book': return CupertinoIcons.book_fill;
      default: return CupertinoIcons.bolt_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HabitProvider>();
    final isComplete = prov.isHabitCompletedToday(habit.id);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconData(habit.icon),
              size: 18,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  habit.isDaily ? 'RECURRING_DAILY' : 'RECURRING_WEEKLY',
                  style: AppTypography.mono.copyWith(
                    fontSize: 10,
                    color: AppColors.tertiaryLabel,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isComplete
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 28,
              color: isComplete ? AppColors.success : AppColors.tertiaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
