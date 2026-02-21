import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'add_habit_sheet.dart';
import 'habit_gallery_sheet.dart';
import 'habit_completion_page.dart';

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
      navigationBar: CupertinoNavigationBar(
        middle: const NeoMonoText(
          'DAILY_PROTOCOLS',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        border: null,
      ),
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
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                child: Consumer<HabitProvider>(
                  builder: (context, prov, _) => _WeeklyStrip(provider: prov),
                ),
              ),

              SliverToBoxAdapter(
                child: Consumer<HabitProvider>(
                  builder: (context, prov, _) => _GlobalHeatmap(provider: prov),
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
                        final habit = prov.habits[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _openCompletionPage(habit),
                            child: _HabitTile(
                              habit: habit,
                              onToggle: () => prov.toggleHabit(habit.id),
                            ),
                          ),
                        );
                      }, childCount: prov.habits.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
          Positioned(
            right: 24,
            bottom: 110,
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

class _GlobalHeatmap extends StatefulWidget {
  final HabitProvider provider;
  const _GlobalHeatmap({required this.provider});

  @override
  State<_GlobalHeatmap> createState() => _GlobalHeatmapState();
}

class _GlobalHeatmapState extends State<_GlobalHeatmap> {
  Map<String, double> _completionRatios = {};

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 27));
    final comps = await widget.provider.getCompletionsForRange(start, now);
    final totalHabits = widget.provider.habits.length;

    if (totalHabits == 0) return;

    final Map<String, int> counts = {};
    for (var c in comps.where((c) => c.completed)) {
      counts[c.date] = (counts[c.date] ?? 0) + 1;
    }

    final Map<String, double> ratios = {};
    for (int i = 0; i < 28; i++) {
      final date = start.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      ratios[dateStr] = (counts[dateStr] ?? 0) / totalHabits;
    }

    setState(() => _completionRatios = ratios);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 27));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(28, (i) {
                final date = start.add(Duration(days: i));
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final ratio = _completionRatios[dateStr] ?? 0.0;
                
                return Container(
                  width: (MediaQuery.of(context).size.width - 40 - 32 - (7 * 6)) / 7,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ratio == 0 ? AppColors.backgroundLight : AppColors.primaryOrange.withOpacity(ratio.clamp(0.1, 1.0)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.glassBorder, width: 0.5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            NeoMonoText('GLOBAL_CONSISTENCY_MATRIX', fontSize: 9, color: AppColors.tertiaryLabel),
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
              color: isComplete ? AppColors.primaryOrange.withOpacity(0.2) : AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconData(habit.icon),
              size: 18,
              color: isComplete ? AppColors.primaryOrange : AppColors.primaryOrange.withOpacity(0.6),
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
                    color: isComplete ? AppColors.label : AppColors.label.withOpacity(0.8),
                  ),
                ),
                Text(
                  isComplete ? 'PROTOCOL_LOCKED' : (habit.isDaily ? 'RECURRING_DAILY' : 'RECURRING_WEEKLY'),
                  style: AppTypography.mono.copyWith(
                    fontSize: 10,
                    color: isComplete ? AppColors.success : AppColors.tertiaryLabel,
                  ),
                ),
              ],
            ),
          ),
          if (isComplete)
            const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.success, size: 24),
        ],
      ),
    );
  }
}
