import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/habit_models.dart';
import '../models/task_models.dart';
import '../providers/ceo_mode_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/task_provider.dart';
import '../repositories/feature_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/home_widgets/widget_views.dart';

enum CeoWidgetMode { todo, dashboard, habits }

extension CeoWidgetModeParsing on CeoWidgetMode {
  static CeoWidgetMode? tryParse(String? raw) {
    if (raw == null) return null;
    for (final mode in CeoWidgetMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }
}

class _CeoWidgetCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> lines;
  final bool large;
  final Widget? childOverride;

  const _CeoWidgetCard({
    required this.title,
    this.subtitle,
    this.lines = const <String>[],
    this.large = false,
    this.childOverride,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.cardBackgroundAlt],
          ),
          borderRadius: BorderRadius.circular(large ? 28 : 24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            large ? 22 : 16,
            large ? 18 : 16,
            large ? 22 : 16,
            large ? 18 : 16,
          ),
          child: childOverride ?? _defaultContent(),
        ),
      ),
    );
  }

  Widget _defaultContent() {
    final maxLines = large ? 6 : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headline.copyWith(
            fontSize: large ? 17 : 15,
            fontWeight: FontWeight.w800,
            color: AppColors.label,
            letterSpacing: 0,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              fontSize: large ? 12 : 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLabel,
              letterSpacing: 0,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Text(
                    '-',
                    style: AppTypography.title2.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.tertiaryLabel,
                      letterSpacing: 0,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in lines.take(maxLines)) ...[
                      _CeoLine(text: line, large: large),
                      const SizedBox(height: 7),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CeoLine extends StatelessWidget {
  final String text;
  final bool large;

  const _CeoLine({required this.text, required this.large});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: large ? 7 : 6,
          height: large ? 7 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
              letterSpacing: 0,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _CeoTodoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> lines;
  final bool large;

  const _CeoTodoCard._({
    required this.title,
    required this.subtitle,
    required this.lines,
    required this.large,
  });

  factory _CeoTodoCard.small({
    required String title,
    required String subtitle,
    required List<String> lines,
  }) {
    return _CeoTodoCard._(
      title: title,
      subtitle: subtitle,
      lines: lines,
      large: false,
    );
  }

  factory _CeoTodoCard.large({
    required String title,
    required String subtitle,
    required List<String> lines,
  }) {
    return _CeoTodoCard._(
      title: title,
      subtitle: subtitle,
      lines: lines,
      large: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CeoWidgetCard(
      title: title,
      subtitle: '${lines.length} $subtitle',
      lines: lines,
      large: large,
    );
  }
}

class _CeoDashboardCard extends StatelessWidget {
  final String title;
  final String tasksLabel;
  final String habitsLabel;
  final String eventsLabel;
  final int pendingTasks;
  final int completedTasks;
  final int completedHabits;
  final int totalHabits;
  final int eventsCount;
  final String nextEventTitle;
  final String nextEventTime;
  final bool large;

  const _CeoDashboardCard._({
    required this.title,
    required this.tasksLabel,
    required this.habitsLabel,
    required this.eventsLabel,
    required this.pendingTasks,
    required this.completedTasks,
    required this.completedHabits,
    required this.totalHabits,
    required this.eventsCount,
    required this.nextEventTitle,
    required this.nextEventTime,
    required this.large,
  });

  factory _CeoDashboardCard.small({
    required String title,
    required String tasksLabel,
    required String habitsLabel,
    required String eventsLabel,
    required int pendingTasks,
    required int completedHabits,
    required int totalHabits,
    required int eventsCount,
  }) {
    return _CeoDashboardCard._(
      title: title,
      tasksLabel: tasksLabel,
      habitsLabel: habitsLabel,
      eventsLabel: eventsLabel,
      pendingTasks: pendingTasks,
      completedTasks: 0,
      completedHabits: completedHabits,
      totalHabits: totalHabits,
      eventsCount: eventsCount,
      nextEventTitle: '',
      nextEventTime: '',
      large: false,
    );
  }

  factory _CeoDashboardCard.large({
    required String title,
    required String tasksLabel,
    required String habitsLabel,
    required String eventsLabel,
    required int pendingTasks,
    required int completedTasks,
    required int completedHabits,
    required int totalHabits,
    required int eventsCount,
    required String nextEventTitle,
    required String nextEventTime,
  }) {
    return _CeoDashboardCard._(
      title: title,
      tasksLabel: tasksLabel,
      habitsLabel: habitsLabel,
      eventsLabel: eventsLabel,
      pendingTasks: pendingTasks,
      completedTasks: completedTasks,
      completedHabits: completedHabits,
      totalHabits: totalHabits,
      eventsCount: eventsCount,
      nextEventTitle: nextEventTitle,
      nextEventTime: nextEventTime,
      large: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CeoWidgetCard(
      title: title,
      large: large,
      childOverride: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(
              fontSize: large ? 17 : 15,
              fontWeight: FontWeight.w800,
              color: AppColors.label,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _metric(tasksLabel, pendingTasks, large)),
                const SizedBox(width: 8),
                Expanded(
                  child: _metric(
                    habitsLabel,
                    totalHabits == 0
                        ? completedHabits
                        : '$completedHabits/$totalHabits',
                    large,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _metric(eventsLabel, eventsCount, large)),
              ],
            ),
          ),
          if (large && nextEventTitle.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              nextEventTime.trim().isEmpty
                  ? nextEventTitle
                  : '$nextEventTime - $nextEventTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption1.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryLabel,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, Object value, bool large) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBackgroundStrong.withValues(alpha: 0.7),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title3.copyWith(
              fontSize: large ? 23 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.accent,
              letterSpacing: 0,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption2.copyWith(
              fontSize: large ? 10 : 9,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLabel,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CeoHabitsTodayCard extends StatelessWidget {
  final String title;
  final String subtitlePrefix;
  final List<String> lines;
  final int completedHabits;
  final int totalHabits;
  final bool large;

  const _CeoHabitsTodayCard._({
    required this.title,
    required this.subtitlePrefix,
    required this.lines,
    required this.completedHabits,
    required this.totalHabits,
    required this.large,
  });

  factory _CeoHabitsTodayCard.small({
    required String title,
    required String subtitlePrefix,
    required List<String> lines,
    required int completedHabits,
    required int totalHabits,
  }) {
    return _CeoHabitsTodayCard._(
      title: title,
      subtitlePrefix: subtitlePrefix,
      lines: lines,
      completedHabits: completedHabits,
      totalHabits: totalHabits,
      large: false,
    );
  }

  factory _CeoHabitsTodayCard.large({
    required String title,
    required String subtitlePrefix,
    required List<String> lines,
    required int completedHabits,
    required int totalHabits,
  }) {
    return _CeoHabitsTodayCard._(
      title: title,
      subtitlePrefix: subtitlePrefix,
      lines: lines,
      completedHabits: completedHabits,
      totalHabits: totalHabits,
      large: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CeoWidgetCard(
      title: title,
      subtitle: '$subtitlePrefix $completedHabits/$totalHabits',
      lines: lines,
      large: large,
    );
  }
}

class _CeoHabitsTableCard extends StatelessWidget {
  final String title;
  final List<Habit> habits;
  final List<DateTime> days;
  final Map<String, Set<String>> completionsDone;
  final Map<String, Set<String>> completionsFailed;
  final bool large;

  const _CeoHabitsTableCard._({
    required this.title,
    required this.habits,
    required this.days,
    required this.completionsDone,
    required this.completionsFailed,
    required this.large,
  });

  factory _CeoHabitsTableCard.large({
    required String title,
    required List<Habit> habits,
    required List<DateTime> days,
    required Map<String, Set<String>> completionsDone,
    required Map<String, Set<String>> completionsFailed,
  }) {
    return _CeoHabitsTableCard._(
      title: title,
      habits: habits,
      days: days,
      completionsDone: completionsDone,
      completionsFailed: completionsFailed,
      large: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shownHabits = habits.take(4).toList();
    final shownDays = days.take(7).toList();
    return _CeoWidgetCard(
      title: title,
      large: large,
      childOverride: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.label,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: shownHabits.isEmpty
                ? Center(
                    child: Text(
                      '-',
                      style: AppTypography.title2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.tertiaryLabel,
                        letterSpacing: 0,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 96),
                          for (final day in shownDays)
                            Expanded(
                              child: Text(
                                DateFormat('E').format(day).substring(0, 1),
                                textAlign: TextAlign.center,
                                style: AppTypography.caption2.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.tertiaryLabel,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final habit in shownHabits) ...[
                        Expanded(child: _habitRow(habit, shownDays)),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _habitRow(Habit habit, List<DateTime> shownDays) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            habit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.label,
              letterSpacing: 0,
            ),
          ),
        ),
        for (final day in shownDays)
          Expanded(
            child: Center(
              child: _habitDot(
                done: _containsDay(completionsDone[habit.id], day),
                failed: _containsDay(completionsFailed[habit.id], day),
              ),
            ),
          ),
      ],
    );
  }

  Widget _habitDot({required bool done, required bool failed}) {
    final color = done
        ? AppColors.success
        : failed
        ? AppColors.error
        : AppColors.borderStrong.withValues(alpha: 0.65);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || failed ? color : AppColors.cardBackgroundStrong,
        border: Border.all(color: color, width: 1.4),
      ),
    );
  }

  bool _containsDay(Set<String>? values, DateTime day) {
    if (values == null || values.isEmpty) return false;
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return values.contains(key);
  }
}

class CeoHomeWidgetService {
  static const String appGroupId = 'group.com.wakeapp.ceoos';

  static const String androidQualifiedProvider =
      'com.wakeapp.ceoos.CeoHomeWidgetProvider';

  static const List<String> iOSWidgetKinds = <String>[
    'com.wakeapp.ceoos.widget.todo',
    'com.wakeapp.ceoos.widget.dashboard',
    'com.wakeapp.ceoos.widget.habits',
    'com.wakeapp.ceoos.widget.habits.table',
    'com.wakeapp.ceoos.widget.focus',
    'com.wakeapp.ceoos.widget.blackout',
  ];

  static const String keyDefaultMode = 'ceo_widget_default_mode';
  static const String keyEnabledTodo = 'ceo_widget_enabled_todo';
  static const String keyEnabledDashboard = 'ceo_widget_enabled_dashboard';
  static const String keyEnabledHabitsToday = 'ceo_widget_enabled_habits_today';
  static const String keyEnabledFocus = 'ceo_widget_enabled_focus';
  static const String keyEnabledBlackout = 'ceo_widget_enabled_blackout';

  static const String _keyTodoSmall = 'ceo_widget_todo_small';
  static const String _keyTodoLarge = 'ceo_widget_todo_large';
  static const String _keyDashboardSmall = 'ceo_widget_dashboard_small';
  static const String _keyDashboardLarge = 'ceo_widget_dashboard_large';
  static const String _keyHabitsSmall = 'ceo_widget_habits_small';
  static const String _keyHabitsLarge = 'ceo_widget_habits_large';
  static const String _keyFocusSmall = 'ceo_widget_focus_small';
  static const String _keyFocusLarge = 'ceo_widget_focus_large';
  static const String _keyBlackoutSmall = 'ceo_widget_blackout_small';
  static const String _keyBlackoutLarge = 'ceo_widget_blackout_large';

  static const String keyFocusDurationMinutes = 'ceo_widget_focus_duration';
  static const String keyBlackoutDurationMinutes =
      'ceo_widget_blackout_duration';

  static const String keyTodoItems = 'ceo_widget_data_todo_items';
  static const String keyTodoRemaining = 'ceo_widget_data_todo_remaining';
  static const String keyHabitsItems = 'ceo_widget_data_habits_items';
  static const String keyHabitsCompleted = 'ceo_widget_data_habits_completed';
  static const String keyHabitsTotal = 'ceo_widget_data_habits_total';
  static const String keyHabitsTableHabits =
      'ceo_widget_data_habits_table_habits';
  static const String keyHabitsTableDays = 'ceo_widget_data_habits_table_days';
  static const String keyHabitsTableStatesJson =
      'ceo_widget_data_habits_table_states_json';
  static const String keyHabitsTableMore = 'ceo_widget_data_habits_table_more';
  static const String keyDashboardTodoDone =
      'ceo_widget_data_dashboard_todo_done';
  static const String keyDashboardTodoTotal =
      'ceo_widget_data_dashboard_todo_total';
  static const String keyDashboardHabitsDone =
      'ceo_widget_data_dashboard_habits_done';
  static const String keyDashboardHabitsTotal =
      'ceo_widget_data_dashboard_habits_total';
  static const String keyDashboardEvents = 'ceo_widget_data_dashboard_events';
  static const String keyDashboardProgress =
      'ceo_widget_data_dashboard_progress';
  static const String keyDashboardMessage = 'ceo_widget_data_dashboard_message';
  static const String keyBlackoutIsOn = 'ceo_widget_blackout_is_on';
  static const String keyBlackoutUntil = 'ceo_widget_blackout_until';
  static const String keyBlackoutBlockedApps =
      'ceo_widget_blackout_blocked_apps';

  static Future<void> ensureInitialized() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  static Future<void> renderAndUpdateAll({
    required TaskProvider tasks,
    required HabitProvider habits,
    required LanguageProvider language,
    CeoModeProvider? ceoMode,
    FocusProvider? focus,
  }) async {
    await ensureInitialized();

    final enabledTodo =
        await HomeWidget.getWidgetData<bool>(
          keyEnabledTodo,
          defaultValue: true,
        ) ??
        true;
    final enabledDashboard =
        await HomeWidget.getWidgetData<bool>(
          keyEnabledDashboard,
          defaultValue: true,
        ) ??
        true;
    final enabledHabits =
        await HomeWidget.getWidgetData<bool>(
          keyEnabledHabitsToday,
          defaultValue: true,
        ) ??
        true;
    final enabledFocus =
        await HomeWidget.getWidgetData<bool>(
          keyEnabledFocus,
          defaultValue: false,
        ) ??
        false;
    final enabledBlackout =
        await HomeWidget.getWidgetData<bool>(
          keyEnabledBlackout,
          defaultValue: false,
        ) ??
        false;

    await habits.loadWidgetCompletionsForLast7Days();

    final pendingTasks = tasks.tasks.where((t) => !t.completed).toList()
      ..sort((a, b) {
        final aScore = _taskPriorityScore(a);
        final bScore = _taskPriorityScore(b);
        return bScore.compareTo(aScore);
      });
    final completedTasks = tasks.tasks.where((t) => t.completed).toList();
    final totalTasks = pendingTasks.length + completedTasks.length;
    final doneTasks = completedTasks.length;

    final todayHabits = habits.habitsWithCompletedBottom;
    final totalHabits = todayHabits.length;
    final doneHabits = habits.completedToday;

    final todayEvents = _eventsToday(tasks);
    final eventsCount = todayEvents.length;
    final nextEvent = todayEvents.isEmpty ? null : todayEvents.first;
    final nextEventTitle = nextEvent?.title ?? '';
    final nextEventTime = nextEvent?.eventTime ?? '';
    final dateLabel = DateFormat(
      'EEE d MMM',
      language.languageCode,
    ).format(DateTime.now());

    final defaultMode =
        await HomeWidget.getWidgetData<String>(
          keyDefaultMode,
          defaultValue: '',
        ) ??
        '';

    final futures = <Future<dynamic>>[
      HomeWidget.saveWidgetData<String>(keyDefaultMode, defaultMode),
    ];

    if (enabledTodo) {
      futures.addAll([
        HomeWidget.saveWidgetData<int>(keyTodoRemaining, pendingTasks.length),
        HomeWidget.saveWidgetData<List<String>>(
          keyTodoItems,
          pendingTasks.take(3).map((t) => t.title).toList(),
        ),
        HomeWidget.renderFlutterWidget(
          _CeoTodoCard.small(
            title: language.t('widget_mode_todo'),
            subtitle: language.t('today'),
            lines: pendingTasks.map((task) => task.title).take(4).toList(),
          ),
          key: _keyTodoSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          _CeoTodoCard.large(
            title: language.t('widget_mode_todo'),
            subtitle: language.t('today'),
            lines: pendingTasks.map((task) => task.title).take(7).toList(),
          ),
          key: _keyTodoLarge,
          logicalSize: const Size(360, 180),
          pixelRatio: 2,
        ),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyTodoSmall, null),
        HomeWidget.saveWidgetData<String>(_keyTodoLarge, null),
      ]);
    }

    if (enabledDashboard) {
      final progressDenom = totalTasks + totalHabits;
      final progress = progressDenom == 0
          ? 0.0
          : ((doneTasks + doneHabits) / progressDenom).clamp(0.0, 1.0);
      final progressPercent = (progress * 100).round().clamp(0, 100);
      final nextTitle = nextEventTitle.isEmpty
          ? language.t('widget_no_events_today')
          : nextEventTime.isEmpty
          ? nextEventTitle
          : '$nextEventTime - $nextEventTitle';

      futures.addAll([
        HomeWidget.saveWidgetData<int>(keyDashboardTodoDone, doneTasks),
        HomeWidget.saveWidgetData<int>(keyDashboardTodoTotal, totalTasks),
        HomeWidget.saveWidgetData<int>(keyDashboardHabitsDone, doneHabits),
        HomeWidget.saveWidgetData<int>(keyDashboardHabitsTotal, totalHabits),
        HomeWidget.saveWidgetData<int>(keyDashboardEvents, eventsCount),
        HomeWidget.saveWidgetData<int>(keyDashboardProgress, progressPercent),
        HomeWidget.saveWidgetData<String>(keyDashboardMessage, nextTitle),
        HomeWidget.renderFlutterWidget(
          _CeoDashboardCard.small(
            title: language.t('widget_mode_dashboard'),
            tasksLabel: language.t('tasks'),
            habitsLabel: language.t('habits'),
            eventsLabel: language.t('events'),
            pendingTasks: pendingTasks.length,
            completedHabits: doneHabits,
            totalHabits: totalHabits,
            eventsCount: eventsCount,
          ),
          key: _keyDashboardSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          _CeoDashboardCard.large(
            title: language.t('widget_mode_dashboard'),
            tasksLabel: language.t('tasks'),
            habitsLabel: language.t('habits'),
            eventsLabel: language.t('events'),
            pendingTasks: pendingTasks.length,
            completedTasks: doneTasks,
            completedHabits: doneHabits,
            totalHabits: totalHabits,
            eventsCount: eventsCount,
            nextEventTitle: nextEventTitle,
            nextEventTime: nextEventTime,
          ),
          key: _keyDashboardLarge,
          logicalSize: const Size(360, 180),
          pixelRatio: 2,
        ),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyDashboardSmall, null),
        HomeWidget.saveWidgetData<String>(_keyDashboardLarge, null),
      ]);
    }

    if (enabledHabits) {
      final habitsTableHabits = todayHabits.take(4).toList();
      final habitsTableDays = habits.widgetLast7Days.take(7).toList();
      futures.addAll([
        HomeWidget.saveWidgetData<int>(keyHabitsCompleted, doneHabits),
        HomeWidget.saveWidgetData<int>(keyHabitsTotal, totalHabits),
        HomeWidget.saveWidgetData<List<String>>(
          keyHabitsItems,
          todayHabits.take(3).map((h) => h.title).toList(),
        ),
        HomeWidget.saveWidgetData<List<String>>(
          keyHabitsTableHabits,
          habitsTableHabits.map((habit) => habit.title).toList(),
        ),
        HomeWidget.saveWidgetData<List<String>>(
          keyHabitsTableDays,
          habitsTableDays.map(_compactDayLabel).toList(),
        ),
        HomeWidget.saveWidgetData<String>(
          keyHabitsTableStatesJson,
          jsonEncode(
            _habitsTableStates(
              habits: habitsTableHabits,
              days: habitsTableDays,
              completionsDone: habits.widgetCompletionMapLast7Days,
            ),
          ),
        ),
        HomeWidget.saveWidgetData<int>(
          keyHabitsTableMore,
          (todayHabits.length - habitsTableHabits.length).clamp(0, 999),
        ),
        HomeWidget.renderFlutterWidget(
          _CeoHabitsTodayCard.small(
            title: language.t('widget_mode_habits_today'),
            subtitlePrefix: language.t('widget_completed'),
            lines: todayHabits
                .map(
                  (habit) =>
                      '${habits.isHabitCompletedToday(habit.id) ? 'Done' : 'Open'} ${habit.title}',
                )
                .toList(),
            completedHabits: doneHabits,
            totalHabits: totalHabits,
          ),
          key: _keyHabitsSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          _CeoHabitsTableCard.large(
            title: language.t('widget_mode_habits'),
            habits: todayHabits,
            days: habits.widgetLast7Days,
            completionsDone: habits.widgetCompletionMapLast7Days,
            completionsFailed: habits.widgetFailedMapLast7Days,
          ),
          key: _keyHabitsLarge,
          logicalSize: const Size(360, 180),
          pixelRatio: 2,
        ),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<List<String>>(
          keyHabitsTableHabits,
          const <String>[],
        ),
        HomeWidget.saveWidgetData<List<String>>(
          keyHabitsTableDays,
          const <String>[],
        ),
        HomeWidget.saveWidgetData<String>(keyHabitsTableStatesJson, '[]'),
        HomeWidget.saveWidgetData<int>(keyHabitsTableMore, 0),
        HomeWidget.saveWidgetData<String>(_keyHabitsSmall, null),
        HomeWidget.saveWidgetData<String>(_keyHabitsLarge, null),
      ]);
    }

    if (enabledFocus) {
      final focusDuration =
          await HomeWidget.getWidgetData<int>(
            keyFocusDurationMinutes,
            defaultValue: 25,
          ) ??
          25;
      final clampedDuration = focusDuration.clamp(5, 180);
      futures.addAll([
        HomeWidget.saveWidgetData<int>(
          keyFocusDurationMinutes,
          clampedDuration,
        ),
        HomeWidget.renderFlutterWidget(
          FocusWidgetSquareView(
            language: language,
            durationMinutes: clampedDuration,
          ),
          key: _keyFocusSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          FocusWidgetRectangularView(
            language: language,
            durationMinutes: clampedDuration,
          ),
          key: _keyFocusLarge,
          logicalSize: const Size(360, 180),
          pixelRatio: 2,
        ),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyFocusSmall, null),
        HomeWidget.saveWidgetData<String>(_keyFocusLarge, null),
      ]);
    }

    if (enabledBlackout) {
      final blackoutDuration =
          await HomeWidget.getWidgetData<int>(
            keyBlackoutDurationMinutes,
            defaultValue: 120,
          ) ??
          120;
      final clampedDuration = blackoutDuration.clamp(15, 240);
      futures.add(
        HomeWidget.saveWidgetData<int>(
          keyBlackoutDurationMinutes,
          clampedDuration,
        ),
      );

      final isOn = ceoMode?.isSessionActive ?? false;
      futures.add(HomeWidget.saveWidgetData<bool>(keyBlackoutIsOn, isOn));
      if (isOn && ceoMode != null) {
        final until = DateTime.now().add(
          Duration(seconds: ceoMode.sessionRemainingSeconds),
        );
        futures.add(
          HomeWidget.saveWidgetData<String>(
            keyBlackoutUntil,
            DateFormat('HH:mm').format(until),
          ),
        );
      } else {
        futures.add(HomeWidget.saveWidgetData<String>(keyBlackoutUntil, null));
      }

      try {
        final blockedApps = await FeatureRepository().getBlockedApps();
        futures.add(
          HomeWidget.saveWidgetData<int>(
            keyBlackoutBlockedApps,
            blockedApps.length,
          ),
        );
      } catch (_) {
        futures.add(HomeWidget.saveWidgetData<int>(keyBlackoutBlockedApps, 0));
      }

      futures.addAll([
        HomeWidget.renderFlutterWidget(
          BlackoutWidgetSquareView(
            language: language,
            durationMinutes: clampedDuration,
          ),
          key: _keyBlackoutSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          BlackoutWidgetRectangularView(
            language: language,
            durationMinutes: clampedDuration,
            isActive: isOn,
          ),
          key: _keyBlackoutLarge,
          logicalSize: const Size(360, 180),
          pixelRatio: 2,
        ),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyBlackoutSmall, null),
        HomeWidget.saveWidgetData<String>(_keyBlackoutLarge, null),
      ]);
    }

    await Future.wait(futures);

    if (Platform.isIOS) {
      for (final kind in iOSWidgetKinds) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
    }
    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidQualifiedProvider,
        name: 'CeoHomeWidgetProvider',
      );
    }
  }

  static String imageKeyFor(CeoWidgetMode mode, {required bool large}) {
    switch (mode) {
      case CeoWidgetMode.todo:
        return large ? _keyTodoLarge : _keyTodoSmall;
      case CeoWidgetMode.dashboard:
        return large ? _keyDashboardLarge : _keyDashboardSmall;
      case CeoWidgetMode.habits:
        return large ? _keyHabitsLarge : _keyHabitsSmall;
    }
  }

  static List<CalendarEvent> _eventsToday(TaskProvider tasks) {
    final now = DateTime.now();
    final key =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final events = tasks.events.where((e) => e.eventDate == key).toList();
    events.sort((a, b) => (a.eventTime ?? '').compareTo(b.eventTime ?? ''));
    return events;
  }

  static int _taskPriorityScore(ParetoTask task) {
    final raw = task.importanceLevel ?? task.impactLevel ?? '';
    final normalized = raw.toLowerCase().trim();
    final importance = switch (normalized) {
      'critical' || 'high' || 'a' || '3' => 3,
      'medium' || 'b' || '2' => 2,
      'low' || 'c' || '1' => 1,
      _ => 0,
    };
    final order = task.sortOrder ?? 999;
    return (importance * 1000) - order;
  }

  static String _compactDayLabel(DateTime day) {
    return DateFormat('E').format(day).substring(0, 1).toUpperCase();
  }

  static List<List<int>> _habitsTableStates({
    required List<Habit> habits,
    required List<DateTime> days,
    required Map<String, Set<String>> completionsDone,
  }) {
    return habits
        .map((habit) {
          final completedDays = completionsDone[habit.id] ?? const <String>{};
          return days
              .map((day) => completedDays.contains(_dateKey(day)) ? 1 : 0)
              .toList(growable: false);
        })
        .toList(growable: false);
  }

  static String _dateKey(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }
}
