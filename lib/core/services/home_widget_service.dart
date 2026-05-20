import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/task_models.dart';
import '../providers/ceo_mode_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/task_provider.dart';
import '../repositories/feature_repository.dart';
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

  static const String keyTodoItems = 'ceo_widget_data_todo_items';
  static const String keyTodoRemaining = 'ceo_widget_data_todo_remaining';
  static const String keyHabitsItems = 'ceo_widget_data_habits_items';
  static const String keyHabitsCompleted = 'ceo_widget_data_habits_completed';
  static const String keyHabitsTotal = 'ceo_widget_data_habits_total';
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
          TodoWidgetSquareView(language: language, pending: pendingTasks),
          key: _keyTodoSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          TodoWidgetSquareView(language: language, pending: pendingTasks),
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
            nextTitle: nextTitle,
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
        HomeWidget.saveWidgetData<int>(keyHabitsCompleted, doneHabits),
        HomeWidget.saveWidgetData<int>(keyHabitsTotal, totalHabits),
        HomeWidget.saveWidgetData<List<String>>(
          keyHabitsItems,
          todayHabits.take(3).map((h) => h.title).toList(),
        ),
        HomeWidget.renderFlutterWidget(
          HabitsTodayWidgetSquareView(
            language: language,
            habits: todayHabits,
            completed: doneHabits,
            total: totalHabits,
          ),
          key: _keyHabitsSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          HabitsTableWidgetRectangularView(
            language: language,
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
}
