import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'habit_gallery_sheet.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../../components/neo_mono_text.dart';

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
    showCupertinoModalPopup<void>(
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
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: Icon(CupertinoIcons.back, color: AppColors.primaryOrange),
        ),
        middle: NeoMonoText(
          'HABITS',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddHabit,
          child: Icon(CupertinoIcons.plus, color: AppColors.primaryOrange),
        ),
        backgroundColor: AppColors.background.withValues(alpha: 0.86),
        border: null,
      ),
      child: AmbientBackdrop(
        child: SafeArea(
          child: Consumer<HabitProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return Center(
                  child: CupertinoActivityIndicator(
                    color: AppColors.primaryOrange,
                  ),
                );
              }

              final habits = provider.habitsWithCompletedBottom;
              if (habits.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_seal,
                            size: 34,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No habits yet',
                            style: AppTypography.headline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first habit to start tracking consistency.',
                            textAlign: TextAlign.center,
                            style: AppTypography.subhead.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 18),
                          LiquidButton(
                            label: 'Add habit',
                            icon: CupertinoIcons.plus,
                            onPressed: _showAddHabit,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: habits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return _HabitRow(
                    habit: habit,
                    onTap: () => _openCompletionPage(habit),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;

  const _HabitRow({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.28),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                (habit.icon?.trim().isNotEmpty ?? false) ? habit.icon! : '✓',
                style: AppTypography.title3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.category ?? (habit.isDaily ? 'Daily' : 'Scheduled'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: AppColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}
