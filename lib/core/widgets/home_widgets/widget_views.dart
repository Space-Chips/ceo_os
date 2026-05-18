import 'package:flutter/cupertino.dart';

import '../../models/habit_models.dart';
import '../../models/task_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/language_provider.dart';
import '../../../features/tasks/task_importance_theme.dart';
import 'widget_design_tokens.dart';

class WidgetRoot extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  final BoxDecoration? decorationOverride;

  const WidgetRoot({
    super.key,
    required this.padding,
    required this.child,
    this.decorationOverride,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: decorationOverride ?? WidgetDesignTokens.outerDecoration(),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class TodoWidgetSquareView extends StatelessWidget {
  final LanguageProvider language;
  final List<ParetoTask> pending;

  const TodoWidgetSquareView({
    super.key,
    required this.language,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = pending.length;
    final items = pending.take(3).toList();
    return WidgetRoot(
      padding: WidgetDesignTokens.padSquare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To‑Do', style: WidgetDesignTokens.title),
          const SizedBox(height: 4),
          Text(
            "${language.t('today')} · $remaining ${language.t('widget_remaining')}",
            style: WidgetDesignTokens.subtitle,
          ),
          const SizedBox(height: 12),
          Text('YOUR PRIORITIES', style: WidgetDesignTokens.section),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  language.t('widget_no_tasks'),
                  style: AppTypography.title3.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.85),
                  ),
                ),
              ),
            )
          else ...[
            for (var i = 0; i < items.length; i++) ...[
              _TodoRow(index: i + 1, task: items[i]),
              if (i != items.length - 1) const SizedBox(height: 8),
            ],
            if (remaining > 3) ...[
              const SizedBox(height: 8),
              Text(
                "+${remaining - 3} ${language.t('widget_more')}",
                style: WidgetDesignTokens.subtitle,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  final int index;
  final ParetoTask task;

  const _TodoRow({required this.index, required this.task});

  @override
  Widget build(BuildContext context) {
    final importance = task.importanceLevel ?? task.impactLevel;
    final cardStyle = TaskImportanceTheme.card(importance);
    final badge = cardStyle.badge;
    final badgeLabel = TaskImportanceTheme.detailLabel(importance);
    final duration = (task.timeDuration ?? '').trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WidgetDesignTokens.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardStyle.start, cardStyle.end],
        ),
        border: Border.all(color: cardStyle.border.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBackgroundAlt,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTypography.caption1.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLabel.withValues(alpha: 0.9),
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.label,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: badge.background,
                        border: Border.all(color: badge.border),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTypography.caption1.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: badge.text,
                          height: 1,
                        ),
                      ),
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: AppTypography.caption1.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryLabel.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardWidgetSquareView extends StatelessWidget {
  final LanguageProvider language;
  final int tasksDone;
  final int tasksTotal;
  final int habitsDone;
  final int habitsTotal;
  final int eventsCount;
  final int progressPercent;

  const DashboardWidgetSquareView({
    super.key,
    required this.language,
    required this.tasksDone,
    required this.tasksTotal,
    required this.habitsDone,
    required this.habitsTotal,
    required this.eventsCount,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return WidgetRoot(
      padding: WidgetDesignTokens.padSquare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetDesignTokens.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DashboardMetricCard(
                        label: language.t('widget_metric_todo'),
                        value: '$tasksDone/$tasksTotal',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DashboardMetricCard(
                        label: language.t('widget_metric_habits'),
                        value: '$habitsDone/$habitsTotal',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DashboardMetricCard(
                  label: language.t('widget_metric_events'),
                  value: '$eventsCount',
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: _ProgressBar(percent: progressPercent)),
                    const SizedBox(width: 10),
                    Text(
                      '$progressPercent%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WidgetDesignTokens.primaryText,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _DashboardMetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.cardBackgroundAlt.withValues(alpha: 0.42),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.52)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption1.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: WidgetDesignTokens.secondaryText,
                height: 1,
              ),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.callout.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WidgetDesignTokens.primaryText,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardWidgetRectangularView extends StatelessWidget {
  final LanguageProvider language;
  final String dateLabel;
  final int tasksDone;
  final int tasksTotal;
  final int habitsDone;
  final int habitsTotal;
  final int eventsCount;
  final int progressPercent;
  final String nextTitle;

  const DashboardWidgetRectangularView({
    super.key,
    required this.language,
    required this.dateLabel,
    required this.tasksDone,
    required this.tasksTotal,
    required this.habitsDone,
    required this.habitsTotal,
    required this.eventsCount,
    required this.progressPercent,
    required this.nextTitle,
  });

  @override
  Widget build(BuildContext context) {
    return WidgetRoot(
      padding: WidgetDesignTokens.padRect,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WidgetDesignTokens.title.copyWith(
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WidgetDesignTokens.subtitle.copyWith(
                              fontSize: 15,
                              color: WidgetDesignTokens.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.largeTitle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: WidgetDesignTokens.primaryText,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ProgressBar(percent: progressPercent),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricChip(
                        label: language.t('widget_metric_todo'),
                        value: '$tasksDone/$tasksTotal',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricChip(
                        label: language.t('widget_metric_habits'),
                        value: '$habitsDone/$habitsTotal',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricChip(
                        label: language.t('widget_metric_events'),
                        value: '$eventsCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 140,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: WidgetDesignTokens.innerSurface(
              tint: const Color(0xFF22252C),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT', style: WidgetDesignTokens.section),
                const SizedBox(height: 8),
                Text(
                  nextTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: WidgetDesignTokens.primaryText.withValues(
                      alpha: 0.95,
                    ),
                    height: 1.15,
                  ),
                ),
                const Spacer(),
                Text(
                  'Today',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WidgetDesignTokens.subtitle.copyWith(
                    fontSize: 14,
                    color: WidgetDesignTokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.cardBackgroundAlt.withValues(alpha: 0.38),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: WidgetDesignTokens.secondaryText,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.callout.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WidgetDesignTokens.primaryText,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class HabitsTodayWidgetSquareView extends StatelessWidget {
  final LanguageProvider language;
  final List<Habit> habits;
  final int completed;
  final int total;

  const HabitsTodayWidgetSquareView({
    super.key,
    required this.language,
    required this.habits,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final items = habits.take(3).toList();
    final more = (habits.length - items.length).clamp(0, 999);
    final title = language.t('widget_mode_habits_today').toUpperCase();

    return WidgetRoot(
      padding: WidgetDesignTokens.padSquare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: WidgetDesignTokens.section)),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardBackgroundAlt,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.add,
                  size: 18,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${language.t('today')} · $completed/$total ${language.t('widget_completed')}",
            style: WidgetDesignTokens.subtitle,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: WidgetDesignTokens.innerSurface(
                tint: const Color(0xFF191B20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  WidgetDesignTokens.radiusInner,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _HabitsTodayRow(title: items[i].title, index: i + 1),
                      if (i != items.length - 1)
                        Container(
                          height: 1,
                          color: AppColors.border.withValues(alpha: 0.55),
                        ),
                    ],
                    if (items.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            language.t('widget_no_habits'),
                            style: WidgetDesignTokens.subtitle,
                          ),
                        ),
                      )
                    else if (more > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "+$more ${language.t('widget_more')}",
                            style: WidgetDesignTokens.subtitle.copyWith(
                              fontSize: 11,
                              color: AppColors.secondaryLabel.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsTodayRow extends StatelessWidget {
  final String title;
  final int index;

  const _HabitsTodayRow({required this.title, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title3.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WidgetDesignTokens.primaryText,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBackgroundAlt,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.65),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTypography.callout.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: WidgetDesignTokens.secondaryText,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HabitsTableWidgetRectangularView extends StatelessWidget {
  final LanguageProvider language;
  final List<Habit> habits;
  final List<DateTime> days;
  final Map<String, Set<String>> completionsDone;
  final Map<String, Set<String>> completionsFailed;

  const HabitsTableWidgetRectangularView({
    super.key,
    required this.language,
    required this.habits,
    required this.days,
    required this.completionsDone,
    required this.completionsFailed,
  });

  @override
  Widget build(BuildContext context) {
    final isFr = language.languageCode.toLowerCase().trim() == 'fr';
    final dayLabels = isFr
        ? const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
        : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final items = habits.take(3).toList();

    return WidgetRoot(
      padding: WidgetDesignTokens.padRect,
      child: Container(
        decoration: WidgetDesignTokens.innerSurface(
          tint: const Color(0xFF191B20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Habits Table', style: WidgetDesignTokens.title),
              const SizedBox(height: 2),
              Text(
                language.t('widget_last_7_days'),
                style: WidgetDesignTokens.subtitle,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      'Habit',
                      style: WidgetDesignTokens.subtitle.copyWith(fontSize: 11),
                    ),
                  ),
                  for (final label in dayLabels)
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: WidgetDesignTokens.subtitle.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryLabel.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              for (final habit in items) ...[
                _HabitsTableRow(
                  habit: habit,
                  days: days,
                  completionsDone: completionsDone,
                  completionsFailed: completionsFailed,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitsTableRow extends StatelessWidget {
  final Habit habit;
  final List<DateTime> days;
  final Map<String, Set<String>> completionsDone;
  final Map<String, Set<String>> completionsFailed;

  const _HabitsTableRow({
    required this.habit,
    required this.days,
    required this.completionsDone,
    required this.completionsFailed,
  });

  @override
  Widget build(BuildContext context) {
    final doneDates = completionsDone[habit.id] ?? const <String>{};
    final failedDates = completionsFailed[habit.id] ?? const <String>{};
    final today = DateTime.now();
    final todayKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            habit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.callout.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.label.withValues(alpha: 0.92),
              height: 1,
            ),
          ),
        ),
        for (final day in days)
          Expanded(
            child: Center(
              child: _cellSymbol(
                day: day,
                doneDates: doneDates,
                failedDates: failedDates,
                todayKey: todayKey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _cellSymbol({
    required DateTime day,
    required Set<String> doneDates,
    required Set<String> failedDates,
    required String todayKey,
  }) {
    final key =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final isDone = doneDates.contains(key);
    if (isDone) {
      return Text(
        '✔',
        style: AppTypography.callout.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.success,
          height: 1,
        ),
      );
    }
    final isFailed = failedDates.contains(key);
    if (isFailed) {
      return Text(
        'x',
        style: AppTypography.callout.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.error,
          height: 1,
        ),
      );
    }
    final isToday = key == todayKey;
    if (isToday) {
      return Text(
        '○',
        style: AppTypography.callout.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.error,
          height: 1,
        ),
      );
    }
    return Text(
      '-',
      style: AppTypography.callout.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppColors.error,
        height: 1,
      ),
    );
  }
}

enum WidgetActionVariant { focus, blackout }

class WidgetActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetActionVariant variant;
  final String? prominentValue;

  const WidgetActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.variant,
    this.prominentValue,
  });

  @override
  Widget build(BuildContext context) {
    final accent = variant == WidgetActionVariant.focus
        ? AppColors.accent
        : AppColors.error;
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.14),
          const Color(0xFF12141A),
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
      ),
      child: prominentValue == null
          ? Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: accent.withValues(alpha: 0.18),
                    border: Border.all(color: accent.withValues(alpha: 0.28)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 18,
                    color: accent.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: WidgetDesignTokens.primaryText,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption1.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: WidgetDesignTokens.secondaryText,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: accent.withValues(alpha: 0.18),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 18,
                        color: accent.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: WidgetDesignTokens.primaryText,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  prominentValue!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.largeTitle.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: WidgetDesignTokens.primaryText.withValues(
                      alpha: 0.98,
                    ),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: WidgetDesignTokens.secondaryText,
                    height: 1,
                  ),
                ),
              ],
            ),
    );
  }
}

class FocusWidgetSquareView extends StatelessWidget {
  final LanguageProvider language;
  final int durationMinutes;

  const FocusWidgetSquareView({
    super.key,
    required this.language,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return WidgetRoot(
      padding: WidgetDesignTokens.padSquare,
      decorationOverride: BoxDecoration(
        borderRadius: BorderRadius.circular(WidgetDesignTokens.radiusOuter),
        gradient: WidgetDesignTokens.focusGradient,
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.85),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetDesignTokens.title.copyWith(fontSize: 22),
          ),
          const Spacer(),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.78,
              child: _ActionPill(
                icon: CupertinoIcons.play_fill,
                title: 'Start',
                subtitle: '$durationMinutes min',
                variant: WidgetActionVariant.focus,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class BlackoutWidgetSquareView extends StatelessWidget {
  final LanguageProvider language;
  final int durationMinutes;

  const BlackoutWidgetSquareView({
    super.key,
    required this.language,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final hours = durationMinutes ~/ 60;
    final label = hours >= 1 ? '$hours h' : '$durationMinutes min';
    return WidgetRoot(
      padding: WidgetDesignTokens.padSquare,
      decorationOverride: BoxDecoration(
        borderRadius: BorderRadius.circular(WidgetDesignTokens.radiusOuter),
        gradient: WidgetDesignTokens.blackoutGradient,
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.85),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blackout',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetDesignTokens.title.copyWith(fontSize: 22),
          ),
          const Spacer(),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.78,
              child: _ActionPill(
                icon: CupertinoIcons.lock_fill,
                title: 'Start',
                subtitle: label,
                variant: WidgetActionVariant.blackout,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetActionVariant variant;

  const _ActionPill({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final accent = variant == WidgetActionVariant.focus
        ? AppColors.accent
        : AppColors.error;
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.14),
          const Color(0xFF12141A),
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent.withValues(alpha: 0.95)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.callout.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: WidgetDesignTokens.primaryText,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption1.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WidgetDesignTokens.secondaryText,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int percent;

  const _ProgressBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final p = (percent.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: AppColors.pillBackground,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: p,
            child: Container(color: AppColors.accent.withValues(alpha: 0.85)),
          ),
        ),
      ),
    );
  }
}
