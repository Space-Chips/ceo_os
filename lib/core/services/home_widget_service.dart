import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../providers/ceo_mode_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/language_provider.dart';
import '../repositories/feature_repository.dart';
import '../providers/task_provider.dart';
import '../models/task_models.dart';
import '../widgets/home_widgets/widget_views.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/habit_models.dart';

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
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CeoWidgetCard(
      title: title,
      subtitle: '',
      lines: const [],
      childOverride: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.label,
              ),
            ),
            const SizedBox(height: 14),
            _metricRow(
              label: tasksLabel,
              value: '$pendingTasks',
            ),
            const SizedBox(height: 10),
            _metricRow(
              label: habitsLabel,
              value: '$completedHabits/$totalHabits',
            ),
            const SizedBox(height: 10),
            _metricRow(label: eventsLabel, value: '$eventsCount'),
            if (nextEventTitle.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                nextEventTime.isEmpty
                    ? nextEventTitle
                    : '$nextEventTime — $nextEventTitle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.callout.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.subhead.copyWith(
              fontSize: 12,
              color: AppColors.secondaryLabel.withValues(alpha: 0.75),
            ),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.callout.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.label.withValues(alpha: 0.9),
          ),
        ),
      ],
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
    final maxLines = large ? 5 : 3;
    return _CeoWidgetCard(
      title: title,
      subtitle: '$subtitlePrefix $completedHabits/$totalHabits',
      lines: lines.take(maxLines).toList(),
    );
  }
}

class _CeoHabitsTableCard extends StatelessWidget {
  final String title;
  final List<Habit> habits;
  final bool Function(String habitId) isDone;
  final bool large;

  const _CeoHabitsTableCard._({
    required this.title,
    required this.habits,
    required this.isDone,
    required this.large,
  });

  factory _CeoHabitsTableCard.small({
    required String title,
    required List<Habit> habits,
    required bool Function(String habitId) isDone,
  }) {
    return _CeoHabitsTableCard._(
      title: title,
      habits: habits,
      isDone: isDone,
      large: false,
    );
  }

  factory _CeoHabitsTableCard.large({
    required String title,
    required List<Habit> habits,
    required bool Function(String habitId) isDone,
  }) {
    return _CeoHabitsTableCard._(
      title: title,
      habits: habits,
      isDone: isDone,
      large: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = habits.take(large ? 8 : 4).toList();
    return _CeoWidgetCard(
      title: title,
      subtitle: 'Table',
      lines: const [],
      childOverride: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title — Table',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.label,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final habit in items)
                  _habitChip(habit.id, habit.title),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitChip(String id, String title) {
    final done = isDone(id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: done
            ? AppColors.accent.withValues(alpha: 0.18)
            : AppColors.pillBackground,
        border: Border.all(
          color: done
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.pillBorder,
        ),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption1.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: done ? AppColors.accent : AppColors.label.withValues(alpha: 0.9),
        ),
      ),
    );
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

  // Native widget data keys (read by SwiftUI widgets).
  static const String keyTodoItems = 'ceo_widget_data_todo_items';
  static const String keyTodoRemaining = 'ceo_widget_data_todo_remaining';
  static const String keyHabitsItems = 'ceo_widget_data_habits_items';
  static const String keyHabitsCompleted = 'ceo_widget_data_habits_completed';
  static const String keyHabitsTotal = 'ceo_widget_data_habits_total';
  static const String keyDashboardTodoDone = 'ceo_widget_data_dashboard_todo_done';
  static const String keyDashboardTodoTotal =
      'ceo_widget_data_dashboard_todo_total';
  static const String keyDashboardHabitsDone =
      'ceo_widget_data_dashboard_habits_done';
  static const String keyDashboardHabitsTotal =
      'ceo_widget_data_dashboard_habits_total';
  static const String keyDashboardEvents = 'ceo_widget_data_dashboard_events';
  static const String keyDashboardProgress =
      'ceo_widget_data_dashboard_progress';
  static const String keyDashboardMessage =
      'ceo_widget_data_dashboard_message';
  static const String keyBlackoutIsOn = 'ceo_widget_blackout_is_on';
  static const String keyBlackoutUntil = 'ceo_widget_blackout_until';
  static const String keyBlackoutBlockedApps = 'ceo_widget_blackout_blocked_apps';
  static const String keyHabitsTableHabits =
      'ceo_widget_data_habits_table_habits';
  static const String keyHabitsTableDays = 'ceo_widget_data_habits_table_days';
  static const String keyHabitsTableStatesJson =
      'ceo_widget_data_habits_table_states_json';
  static const String keyHabitsTableMore = 'ceo_widget_data_habits_table_more';

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

    final enabledTodo = await HomeWidget.getWidgetData<bool>(
          keyEnabledTodo,
          defaultValue: true,
        ) ??
        true;
    final enabledDashboard = await HomeWidget.getWidgetData<bool>(
          keyEnabledDashboard,
          defaultValue: true,
        ) ??
        true;
    final enabledHabits = await HomeWidget.getWidgetData<bool>(
          keyEnabledHabits,
          defaultValue: true,
        ) ??
        true;

    final pendingTasks = tasks.tasks.where((t) => !t.completed).toList();
    final completedTasks = tasks.tasks.where((t) => t.completed).toList();
    final todayHabits = habits.habits;
    final todayHabitsLines = todayHabits
        .take(5)
        .map((h) {
          final done = habits.isHabitCompletedToday(h.id);
          return '${done ? '✓' : '•'} ${h.title}';
        })
        .toList();

    final todoLines = pendingTasks.map((t) => t.title).toList();
    final habitsLines = habitList
        .take(3)
        .map((h) {
          final done = habits.isHabitCompletedToday(h.id);
          return '${done ? '✓' : '•'} ${h.title}';
        })
        .toList();

    final defaultMode =
        (await HomeWidget.getWidgetData<String>(
          keyDefaultMode,
          defaultValue: '',
        )) ??
        '';

    final futures = <Future<dynamic>>[
      HomeWidget.saveWidgetData<String>(keyDefaultMode, defaultMode),
    ];

    if (enabledTodo) {
      futures.addAll([
        HomeWidget.renderFlutterWidget(
          _CeoTodoCard.small(
            title: language.t('widget_mode_todo'),
            subtitle: "${language.t('today")} • ${pendingTasks.length} ${language.t('widget_remaining')}',
            tasks: pendingTasks,
            language: language,
          ),
          key: _keyTodoSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          _CeoTodoCard.large(
            title: language.t('widget_mode_todo'),
            subtitle: "${pendingTasks.length} ${language.t('widget_remaining")}',
            tasks: pendingTasks,
            language: language,
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
      final progressDenom = (totalTasks + totalHabits);
      final progress = progressDenom == 0
          ? 0.0
          : ((doneTasks + doneHabits) / progressDenom).clamp(0.0, 1.0);
      final progressPercent = (progress * 100).round().clamp(0, 100);
      futures.addAll([
        HomeWidget.saveWidgetData<int>(keyDashboardTodoDone, doneTasks),
        HomeWidget.saveWidgetData<int>(keyDashboardTodoTotal, totalTasks),
        HomeWidget.saveWidgetData<int>(keyDashboardHabitsDone, doneHabits),
        HomeWidget.saveWidgetData<int>(keyDashboardHabitsTotal, totalHabits),
        HomeWidget.saveWidgetData<int>(keyDashboardEvents, eventsCount),
        HomeWidget.saveWidgetData<int>(keyDashboardProgress, progressPercent),
        HomeWidget.saveWidgetData<String>(
          keyDashboardMessage,
          nextEventTitle.isEmpty
              ? language.t('widget_no_events_today')
              : (nextEventTime.isEmpty
                    ? nextEventTitle
                    : '$nextEventTime — $nextEventTitle'),
        ),
      ]);
      futures.addAll([
        HomeWidget.renderFlutterWidget(
          DashboardWidgetSquareView(
            language: language,
            tasksDone: doneTasks,
            tasksTotal: totalTasks,
            habitsDone: doneHabits,
            habitsTotal: totalHabits,
            eventsCount: eventsCount,
            progressPercent: progressPercent,
          ),
          key: _keyDashboardSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          DashboardWidgetRectangularView(
            language: language,
            dateLabel: dateLabel,
            tasksDone: doneTasks,
            tasksTotal: totalTasks,
            habitsDone: doneHabits,
            habitsTotal: totalHabits,
            eventsCount: eventsCount,
            progressPercent: progressPercent,
            nextTitle: nextEventTitle.isEmpty
                ? language.t('widget_no_events_today')
                : (nextEventTime.isEmpty
                    ? nextEventTitle
                    : '$nextEventTime — $nextEventTitle'),
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
      futures.addAll([
        HomeWidget.renderFlutterWidget(
          HabitsTodayWidgetSquareView(
            language: language,
            habits: todayHabits,
          ),
          key: _keyHabitsSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.saveWidgetData<String>(_keyHabitsLarge, null),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyHabitsSmall, null),
        HomeWidget.saveWidgetData<String>(_keyHabitsLarge, null),
      ]);
    }

    if (enabledHabitsTable) {
      final tableDays = habits.widgetLast7Days;
      final tableDone = habits.widgetCompletionMapLast7Days;
      final tableFailed = habits.widgetFailedMapLast7Days;
      final isFr = language.languageCode.toLowerCase().trim() == 'fr';
      final dayLabels = isFr
          ? <String>['L', 'M', 'M', 'J', 'V', 'S', 'D']
          : <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

      final topHabits = habits.habitsWithCompletedBottom.take(4).toList();
      final states = <List<int>>[];
      for (final habit in topHabits) {
        final done = tableDone[habit.id] ?? const <String>{};
        final failed = tableFailed[habit.id] ?? const <String>{};
        final row = <int>[];
        for (final day in tableDays) {
          final key =
              "${day.year}-${day.month.toString().padLeft(2, '0")}-${day.day.toString().padLeft(2, '0')}';
          if (done.contains(key)) {
            row.add(1);
          } else if (failed.contains(key)) {
            row.add(2);
          } else {
            row.add(0);
          }
        }
        states.add(row);
      }
      futures.addAll([
        HomeWidget.saveWidgetData<List<String>>(
          keyHabitsTableHabits,
          topHabits.map((h) => h.title).toList(),
        ),
        HomeWidget.saveWidgetData<List<String>>(keyHabitsTableDays, dayLabels),
        HomeWidget.saveWidgetData<String>(keyHabitsTableStatesJson, jsonEncode(states)),
        HomeWidget.saveWidgetData<int>(
          keyHabitsTableMore,
          (habits.habitsWithCompletedBottom.length - topHabits.length).clamp(
            0,
            999,
          ),
        ),
      ]);
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyHabitsTableSmall, null),
        HomeWidget.renderFlutterWidget(
          HabitsTableWidgetRectangularView(
            language: language,
            habits: habits.habitsWithCompletedBottom,
            days: tableDays,
            completionsDone: tableDone,
            completionsFailed: tableFailed,
          ),
          key: _keyHabitsTableLarge,
          logicalSize: const Size(360, 180),
          pixelRatio: 2,
        ),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyHabitsTableSmall, null),
        HomeWidget.saveWidgetData<String>(_keyHabitsTableLarge, null),
      ]);
    }

    if (enabledFocus) {
      final focusDuration =
          (await HomeWidget.getWidgetData<int>(
            keyFocusDurationMinutes,
            defaultValue: 25,
          )) ??
          25;
      futures.add(HomeWidget.saveWidgetData<int>(
        keyFocusDurationMinutes,
        focusDuration.clamp(5, 180),
      ));
      futures.addAll([
        HomeWidget.renderFlutterWidget(
          FocusWidgetSquareView(
            language: language,
            durationMinutes: focusDuration.clamp(5, 180),
          ),
          key: _keyFocusSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.saveWidgetData<String>(_keyFocusLarge, null),
      ]);
    } else {
      futures.addAll([
        HomeWidget.saveWidgetData<String>(_keyFocusSmall, null),
        HomeWidget.saveWidgetData<String>(_keyFocusLarge, null),
      ]);
    }

    if (enabledBlackout) {
      final blackoutDuration =
          (await HomeWidget.getWidgetData<int>(
            keyBlackoutDurationMinutes,
            defaultValue: 120,
          )) ??
          120;
      futures.add(
        HomeWidget.saveWidgetData<int>(
          keyBlackoutDurationMinutes,
          blackoutDuration.clamp(15, 240),
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
          HomeWidget.saveWidgetData<int>(keyBlackoutBlockedApps, blockedApps.length),
        );
      } catch (_) {
        futures.add(HomeWidget.saveWidgetData<int>(keyBlackoutBlockedApps, 0));
      }
      futures.addAll([
        HomeWidget.renderFlutterWidget(
          BlackoutWidgetSquareView(
            language: language,
            durationMinutes: blackoutDuration.clamp(15, 240),
          ),
          key: _keyBlackoutSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.saveWidgetData<String>(_keyBlackoutLarge, null),
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
        "${now.year}-${now.month.toString().padLeft(2, '0")}-${now.day.toString().padLeft(2, '0')}';
    final events = tasks.events.where((e) => e.eventDate == key).toList();
    events.sort((a, b) => (a.eventTime ?? '').compareTo(b.eventTime ?? ''));
    return events;
  }
}

class _CeoWidgetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> lines;
  final Widget? childOverride;

  const _CeoWidgetCard({
    required this.title,
    required this.subtitle,
    required this.lines,
    this.childOverride,
  });

  factory _CeoWidgetCard.smallTodo({
    required String title,
    required String subtitle,
    required List<String> lines,
  }) {
    return _CeoWidgetCard(
      title: title,
      subtitle: subtitle,
      lines: lines,
    );
  }

  factory _CeoWidgetCard.largeTodo({
    required String title,
    required String subtitle,
    required List<String> lines,
  }) {
    return _CeoWidgetCard(
      title: title,
      subtitle: subtitle,
      lines: lines,
    );
  }

  factory _CeoWidgetCard.smallDashboard({
    required String title,
    required String tasksLabel,
    required String habitsLabel,
    required int pendingTasks,
    required int completedTasks,
    required int completedHabits,
    required int totalHabits,
  }) {
    return _CeoWidgetCard(
      title: title,
      subtitle:
          '$tasksLabel $pendingTasks pending • $completedTasks done\n$habitsLabel $completedHabits/$totalHabits today',
      lines: const [],
    );
  }

  factory _CeoWidgetCard.largeDashboard({
    required String title,
    required String tasksLabel,
    required String habitsLabel,
    required int pendingTasks,
    required int completedTasks,
    required int completedHabits,
    required int totalHabits,
  }) {
    return _CeoWidgetCard(
      title: title,
      subtitle:
          '$tasksLabel $pendingTasks pending • $completedTasks done\n$habitsLabel $completedHabits/$totalHabits today',
      lines: const [],
    );
  }

  factory _CeoWidgetCard.smallHabits({
    required String title,
    required String subtitlePrefix,
    required List<String> lines,
    required int completedHabits,
    required int totalHabits,
  }) {
    return _CeoWidgetCard(
      title: title,
      subtitle: '$subtitlePrefix $completedHabits/$totalHabits today',
      lines: lines,
    );
  }

  factory _CeoWidgetCard.largeHabits({
    required String title,
    required String subtitlePrefix,
    required List<String> lines,
    required int completedHabits,
    required int totalHabits,
  }) {
    return _CeoWidgetCard(
      title: title,
      subtitle: '$subtitlePrefix $completedHabits/$totalHabits today',
      lines: lines,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sectionBackground.withValues(alpha: 0.95),
            AppColors.background,
          ],
        ),
        border: Border.all(color: AppColors.borderStrong, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 42,
            offset: Offset(0, 18),
            spreadRadius: -18,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child:
          childOverride ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.label,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subhead.copyWith(
                  fontSize: 12,
                  height: 1.25,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                ),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.callout.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.label.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }
}

// Recovered class _CeoTodoCard @ 2026-05-02T16:40:07.088Z
class _CeoTodoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ParetoTask> tasks;
  final LanguageProvider language;
  final bool large;

  const _CeoTodoCard._({
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.language,
    required this.large,
  });

  factory _CeoTodoCard.small({
    required String title,
    required String subtitle,
    required List<ParetoTask> tasks,
    required LanguageProvider language,
  }) {
    return _CeoTodoCard._(
      title: title,
      subtitle: subtitle,
      tasks: tasks,
      language: language,
      large: false,
    );
  }

  factory _CeoTodoCard.large({
    required String title,
    required String subtitle,
    required List<ParetoTask> tasks,
    required LanguageProvider language,
  }) {
    return _CeoTodoCard._(
      title: title,
      subtitle: subtitle,
      tasks: tasks,
      language: language,
      large: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxItems = large ? 4 : 3;
    final items = tasks.take(maxItems).toList();
    return _CeoBaseCard(
      headerTitle: title,
      headerSubtitle: subtitle,
      child: items.isEmpty
          ? _CeoEmptyState(
              title: language.t('widget_no_tasks'),
              subtitle: language.t('widget_add_tasks_hint'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                for (final task in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Text(
                          '○',
                          style: AppTypography.callout.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLabel.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.callout.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.label.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (tasks.length > maxItems) ...[
                  const SizedBox(height: 2),
                  Text(
                    "+${tasks.length - maxItems} ${language.t('widget_more")}',
                    style: AppTypography.caption1.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // Recovered static_field _keyHabitsTableLarge @ 2026-05-02T16:40:07.088Z
  static const String _keyHabitsTableLarge = 'ceo_widget_habits_table_large';

  // Recovered static_field _keyHabitsTableSmall @ 2026-05-02T16:40:07.088Z
  static const String _keyHabitsTableSmall = 'ceo_widget_habits_table_small';

  // Recovered static_field keyEnabledHabits @ 2026-05-16T08:52:19.742Z
  static const String keyEnabledHabits = 'ceo_widget_enabled_habits';
}
