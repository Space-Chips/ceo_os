import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/habit_models.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/home_widgets/widget_views.dart';

class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final sampleTasks = <ParetoTask>[
      ParetoTask(
        id: 't1',
        title: 'Widgets',
        createdBy: 'demo',
        createdAt: DateTime.now(),
      ),
      ParetoTask(
        id: 't2',
        title: 'Check bugs',
        createdBy: 'demo',
        createdAt: DateTime.now(),
      ),
      ParetoTask(
        id: 't3',
        title: 'Soumettre…',
        createdBy: 'demo',
        createdAt: DateTime.now(),
      ),
      ParetoTask(
        id: 't4',
        title: 'Android',
        createdBy: 'demo',
        createdAt: DateTime.now(),
      ),
    ];

    final sampleHabits = <Habit>[
      Habit(
        id: 'h1',
        createdBy: 'demo',
        title: 'je',
        createdAt: DateTime.now(),
      ),
      Habit(
        id: 'h2',
        createdBy: 'demo',
        title: 'Workout',
        createdAt: DateTime.now(),
      ),
      Habit(
        id: 'h3',
        createdBy: 'demo',
        title: 'Read',
        createdAt: DateTime.now(),
      ),
    ];

    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day).subtract(
        Duration(days: 6 - i),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Widget Gallery', style: AppTypography.headline),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _SectionTitle('Small (170×170)'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _PreviewBox(
                title: 'To‑Do (Filled)',
                child: TodoWidgetSquareView(language: language, pending: sampleTasks),
              ),
              _PreviewBox(
                title: 'To‑Do (Empty)',
                child: TodoWidgetSquareView(language: language, pending: const []),
              ),
              _PreviewBox(
                title: 'Habits Today (Filled)',
                child: HabitsTodayWidgetSquareView(
                  language: language,
                  habits: sampleHabits,
                  completed: 0,
                  total: 3,
                  completedHabitIds: const {},
                ),
              ),
              _PreviewBox(
                title: 'Habits Today (Empty)',
                child: HabitsTodayWidgetSquareView(
                  language: language,
                  habits: const [],
                  completed: 0,
                  total: 0,
                  completedHabitIds: const {},
                ),
              ),
              _PreviewBox(
                title: 'Dashboard (Filled)',
                child: DashboardWidgetSquareView(
                  language: language,
                  tasksDone: 9,
                  tasksTotal: 16,
                  habitsDone: 0,
                  habitsTotal: 3,
                  eventsCount: 0,
                  progressPercent: 42,
                ),
              ),
              _PreviewBox(
                title: 'Focus',
                child: FocusWidgetSquareView(language: language, durationMinutes: 25),
              ),
              _PreviewBox(
                title: 'Blackout',
                child: BlackoutWidgetSquareView(language: language, durationMinutes: 120),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle('Medium (360×180)'),
          const SizedBox(height: 12),
          _PreviewBoxMedium(
            title: 'Dashboard (Medium)',
            child: DashboardWidgetRectangularView(
              language: language,
              dateLabel: 'Today',
              tasksDone: 9,
              tasksTotal: 16,
              habitsDone: 0,
              habitsTotal: 3,
              eventsCount: 0,
              progressPercent: 42,
              nextTitle: 'No events today',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.title3.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.label,
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final String title;
  final Widget child;

  const _PreviewBox({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.caption1.copyWith(color: AppColors.secondaryLabel)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(width: 170, height: 170, child: child),
        ),
      ],
    );
  }
}

class _PreviewBoxMedium extends StatelessWidget {
  final String title;
  final Widget child;

  const _PreviewBoxMedium({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.caption1.copyWith(color: AppColors.secondaryLabel)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(width: 360, height: 180, child: child),
        ),
      ],
    );
  }
}
