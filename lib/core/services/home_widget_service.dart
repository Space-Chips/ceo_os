import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';

import '../providers/habit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
    'com.wakeapp.ceoos.widget.habits.table',
  ];

  static const String keyDefaultMode = 'ceo_widget_default_mode';
  static const String keyEnabledTodo = 'ceo_widget_enabled_todo';
  static const String keyEnabledDashboard = 'ceo_widget_enabled_dashboard';
  static const String keyEnabledHabits = 'ceo_widget_enabled_habits';
  static const String keyFocusDurationMinutes =
      'ceo_widget_focus_duration_minutes';

  static const String _keyTodoSmall = 'ceo_widget_todo_small';
  static const String _keyTodoLarge = 'ceo_widget_todo_large';
  static const String _keyDashboardSmall = 'ceo_widget_dashboard_small';
  static const String _keyDashboardLarge = 'ceo_widget_dashboard_large';
  static const String _keyHabitsSmall = 'ceo_widget_habits_small';
  static const String _keyHabitsLarge = 'ceo_widget_habits_large';

  static Future<void> ensureInitialized() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  static Future<void> renderAndUpdateAll({
    required TaskProvider tasks,
    required HabitProvider habits,
    required LanguageProvider language,
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
          keyEnabledHabits,
          defaultValue: true,
        ) ??
        true;

    final pendingTasks = tasks.tasks.where((t) => !t.completed).toList();
    final completedTasks = tasks.tasks.where((t) => t.completed).toList();
    final habitList = habits.habitsWithCompletedBottom;

    final todoLines = pendingTasks.map((t) => t.title).toList();
    final habitsLines = habitList.take(3).map((h) {
      final done = habits.isHabitCompletedToday(h.id);
      return '${done ? '✓' : '•'} ${h.title}';
    }).toList();

    final defaultMode =
        (await HomeWidget.getWidgetData<String>(
          keyDefaultMode,
          defaultValue: CeoWidgetMode.dashboard.name,
        )) ??
        CeoWidgetMode.dashboard.name;

    final futures = <Future<dynamic>>[
      HomeWidget.saveWidgetData<String>(keyDefaultMode, defaultMode),
    ];

    if (enabledTodo) {
      futures.addAll([
        HomeWidget.renderFlutterWidget(
          _CeoWidgetCard.smallTodo(
            title: language.t('widget_mode_todo'),
            subtitle: language.t('today'),
            lines: todoLines.take(4).toList(),
          ),
          key: _keyTodoSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          _CeoWidgetCard.largeTodo(
            title: language.t('widget_mode_todo'),
            subtitle: language.t('today'),
            lines: todoLines.take(7).toList(),
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
      futures.addAll([
        HomeWidget.renderFlutterWidget(
          _CeoWidgetCard.smallDashboard(
            title: language.t('widget_mode_dashboard'),
            tasksLabel: language.t('tasks'),
            habitsLabel: language.t('habits'),
            pendingTasks: pendingTasks.length,
            completedTasks: completedTasks.length,
            completedHabits: habits.completedToday,
            totalHabits: habits.habits.length,
          ),
          key: _keyDashboardSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          _CeoWidgetCard.largeDashboard(
            title: language.t('widget_mode_dashboard'),
            tasksLabel: language.t('tasks'),
            habitsLabel: language.t('habits'),
            pendingTasks: pendingTasks.length,
            completedTasks: completedTasks.length,
            completedHabits: habits.completedToday,
            totalHabits: habits.habits.length,
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
          _CeoWidgetCard.smallHabits(
            title: language.t('widget_mode_habits'),
            subtitlePrefix: language.t('widget_completed'),
            lines: habitsLines,
            completedHabits: habits.completedToday,
            totalHabits: habits.habits.length,
          ),
          key: _keyHabitsSmall,
          logicalSize: const Size(170, 170),
          pixelRatio: 2,
        ),
        HomeWidget.renderFlutterWidget(
          _CeoWidgetCard.largeHabits(
            title: language.t('widget_mode_habits'),
            subtitlePrefix: language.t('widget_completed'),
            lines: habitsLines,
            completedHabits: habits.completedToday,
            totalHabits: habits.habits.length,
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
}

class _CeoWidgetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> lines;

  const _CeoWidgetCard({
    required this.title,
    required this.subtitle,
    required this.lines,
  });

  factory _CeoWidgetCard.smallTodo({
    required String title,
    required String subtitle,
    required List<String> lines,
  }) {
    return _CeoWidgetCard(title: title, subtitle: subtitle, lines: lines);
  }

  factory _CeoWidgetCard.largeTodo({
    required String title,
    required String subtitle,
    required List<String> lines,
  }) {
    return _CeoWidgetCard(title: title, subtitle: subtitle, lines: lines);
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
