import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/providers/ceo_mode_provider.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/services/home_widget_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class WidgetConfigurationScreen extends StatefulWidget {
  const WidgetConfigurationScreen({super.key});

  @override
  State<WidgetConfigurationScreen> createState() =>
      _WidgetConfigurationScreenState();
}

class _WidgetConfigurationScreenState extends State<WidgetConfigurationScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _enabledTodo = false;
  bool _enabledDashboard = false;
  bool _enabledHabitsToday = false;
  bool _enabledFocus = false;
  bool _enabledBlackout = false;
  CeoWidgetMode? _defaultMode;

  String _t(String key) => context.watch<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _setEnabled({
    bool? todo,
    bool? dashboard,
    bool? habits,
  }) async {
    if (_saving) return;
    final tasks = context.read<TaskProvider>();
    final habitsProvider = context.read<HabitProvider>();
    final language = context.read<LanguageProvider>();
    final ceoMode = context.read<CeoModeProvider>();
    final focusProvider = context.read<FocusProvider>();
    setState(() {
      _saving = true;
      if (todo != null) _enabledTodo = todo;
      if (dashboard != null) _enabledDashboard = dashboard;
      if (habitsToday != null) _enabledHabitsToday = habitsToday;
      if (focus != null) _enabledFocus = focus;
      if (blackout != null) _enabledBlackout = blackout;
    });
    try {
      await Future.wait([
        if (todo != null)
          HomeWidget.saveWidgetData<bool>(
            CeoHomeWidgetService.keyEnabledTodo,
            todo,
          ),
        if (dashboard != null)
          HomeWidget.saveWidgetData<bool>(
            CeoHomeWidgetService.keyEnabledDashboard,
            dashboard,
          ),
        if (habitsToday != null)
          HomeWidget.saveWidgetData<bool>(
            CeoHomeWidgetService.keyEnabledHabitsToday,
            habitsToday,
          ),
        if (focus != null)
          HomeWidget.saveWidgetData<bool>(
            CeoHomeWidgetService.keyEnabledFocus,
            focus,
          ),
        if (blackout != null)
          HomeWidget.saveWidgetData<bool>(
            CeoHomeWidgetService.keyEnabledBlackout,
            blackout,
          ),
      ]);
      await _ensureWidgetDataLoaded(tasks: tasks, habits: habitsProvider);
      await CeoHomeWidgetService.renderAndUpdateAll(
        tasks: tasks,
        habits: habitsProvider,
        language: language,
        ceoMode: ceoMode,
        focus: focusProvider,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await CeoHomeWidgetService.ensureInitialized();
    final rawDefault = await HomeWidget.getWidgetData<String>(
      CeoHomeWidgetService.keyDefaultMode,
      defaultValue: '',
    );
    final enabledTodo = await HomeWidget.getWidgetData<bool>(
      CeoHomeWidgetService.keyEnabledTodo,
      defaultValue: false,
    );
    final enabledDashboard = await HomeWidget.getWidgetData<bool>(
      CeoHomeWidgetService.keyEnabledDashboard,
      defaultValue: false,
    );
    final enabledHabits = await HomeWidget.getWidgetData<bool>(
      CeoHomeWidgetService.keyEnabledHabitsToday,
      defaultValue: false,
    );
    final enabledFocus = await HomeWidget.getWidgetData<bool>(
      CeoHomeWidgetService.keyEnabledFocus,
      defaultValue: false,
    );
    final enabledBlackout = await HomeWidget.getWidgetData<bool>(
      CeoHomeWidgetService.keyEnabledBlackout,
      defaultValue: false,
    );
    setState(() {
      _defaultMode = CeoWidgetModeParsing.tryParse(rawDefault);
      _enabledTodo = enabledTodo ?? false;
      _enabledDashboard = enabledDashboard ?? false;
      _enabledHabitsToday = enabledHabits ?? false;
      _enabledFocus = enabledFocus ?? false;
      _enabledBlackout = enabledBlackout ?? false;
      _loading = false;
    });
  }

  Future<void> _setDefaultMode(CeoWidgetMode? mode) async {
    if (_saving) return;
    final tasks = context.read<TaskProvider>();
    final habits = context.read<HabitProvider>();
    final language = context.read<LanguageProvider>();
    final ceoMode = context.read<CeoModeProvider>();
    final focusProvider = context.read<FocusProvider>();
    final focus = context.read<FocusProvider>();
    setState(() {
      _saving = true;
      _defaultMode = mode;
    });
    try {
      await HomeWidget.saveWidgetData<String>(
        CeoHomeWidgetService.keyDefaultMode,
        mode?.name,
      );
      await _ensureWidgetDataLoaded(tasks: tasks, habits: habits);
      await CeoHomeWidgetService.renderAndUpdateAll(
        tasks: tasks,
        habits: habits,
        language: language,
        ceoMode: ceoMode,
        focus: focusProvider,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _renderNow() async {
    if (_saving) return;
    final tasks = context.read<TaskProvider>();
    final habits = context.read<HabitProvider>();
    final language = context.read<LanguageProvider>();
    final ceoMode = context.read<CeoModeProvider>();
    setState(() => _saving = true);
    try {
      await _ensureWidgetDataLoaded(tasks: tasks, habits: habits);
      await CeoHomeWidgetService.renderAndUpdateAll(
        tasks: tasks,
        habits: habits,
        language: language,
        ceoMode: ceoMode,
        focus: focusProvider,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _ensureWidgetDataLoaded({
    required TaskProvider tasks,
    required HabitProvider habits,
  }) async {
    await Future.wait([
      tasks.loadTasksWithCompleted(includeCompleted: true),
      tasks.loadEvents(),
      habits.loadData(),
    ]);
  }

  Future<void> _pinAndroidWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      qualifiedAndroidName: CeoHomeWidgetService.androidQualifiedProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: _loading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: AppColors.primaryOrange,
                  ),
                )
              : Column(
                  children: [
                    _topBar(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          const SizedBox(height: 6),
                          _sectionTitle(_t('widget_configuration_widgets')),
                          const SizedBox(height: 12),
                          _widgetToggleCard(
                            label: _t('widget_mode_todo'),
                            icon: CupertinoIcons.check_mark_circled_solid,
                            value: _enabledTodo,
                            onChanged: (value) => _setEnabled(todo: value),
                          ),
                          const SizedBox(height: 10),
                          _widgetToggleCard(
                            label: _t('widget_mode_dashboard'),
                            icon: CupertinoIcons.rectangle_3_offgrid_fill,
                            value: _enabledDashboard,
                            onChanged: (value) => _setEnabled(dashboard: value),
                          ),
                          const SizedBox(height: 10),
                          _widgetToggleCard(
                            label: _t('widget_mode_habits_today'),
                            icon: CupertinoIcons.flame_fill,
                            value: _enabledHabitsToday,
                            onChanged: (value) =>
                                _setEnabled(habitsToday: value),
                          ),
                          const SizedBox(height: 10),
                          _widgetToggleCard(
                            label: _t('widget_mode_focus'),
                            icon: CupertinoIcons.timer,
                            value: _enabledFocus,
                            onChanged: (value) => _setEnabled(focus: value),
                          ),
                          const SizedBox(height: 10),
                          _widgetToggleCard(
                            label: _t('widget_mode_blackout'),
                            icon: CupertinoIcons.moon_stars_fill,
                            value: _enabledBlackout,
                            onChanged: (value) => _setEnabled(blackout: value),
                          ),
                          const SizedBox(height: 22),
                          if (Platform.isAndroid) ...[
                            _sectionTitle(_t('widget_configuration_default')),
                            const SizedBox(height: 12),
                            _defaultModeCard(
                              mode: null,
                              label: _t('widget_default_none'),
                              icon: CupertinoIcons.xmark_circle_fill,
                            ),
                            const SizedBox(height: 10),
                            _defaultModeCard(
                              mode: CeoWidgetMode.todo,
                              label: _t('widget_mode_todo'),
                              icon: CupertinoIcons.check_mark_circled_solid,
                            ),
                            const SizedBox(height: 10),
                            _defaultModeCard(
                              mode: CeoWidgetMode.dashboard,
                              label: _t('widget_mode_dashboard'),
                              icon: CupertinoIcons.rectangle_3_offgrid_fill,
                            ),
                            const SizedBox(height: 10),
                            _defaultModeCard(
                              mode: CeoWidgetMode.habits,
                              label: _t('widget_mode_habits'),
                              icon: CupertinoIcons.flame_fill,
                            ),
                            const SizedBox(height: 22),
                          ],
                          _sectionTitle(_t('widget_configuration_actions')),
                          const SizedBox(height: 12),
                          _actionButton(
                            label: _t('widget_configuration_refresh'),
                            icon: CupertinoIcons.arrow_2_circlepath,
                            onTap: _renderNow,
                          ),
                          if (Platform.isAndroid) ...[
                            const SizedBox(height: 10),
                            _actionButton(
                              label: _t('widget_configuration_add_android'),
                              icon: CupertinoIcons.add_circled_solid,
                              onTap: _pinAndroidWidget,
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            _t('widget_configuration_hint'),
                            style: AppTypography.subhead.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.secondaryLabel.withValues(
                                alpha: 0.62,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Row(
        children: [
          _iconButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          Text(
            _t('widget_configuration'),
            style: AppTypography.title2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.accent,
            ),
          ),
          const Spacer(),
          Opacity(
            opacity: 0,
            child: _iconButton(icon: CupertinoIcons.back, onTap: null),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback? onTap}) {
    return _WidgetPressable(
      onTap: onTap,
      pressedScale: 0.94,
      borderRadius: 12,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.topBarControlBackground,
          border: Border.all(color: AppColors.topBarControlBorder, width: 1),
        ),
        child: Icon(icon, size: 18, color: AppColors.secondaryLabel),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.overline.copyWith(
        fontSize: 11,
        letterSpacing: 2,
        color: AppColors.secondaryLabel.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _defaultModeCard({
    required CeoWidgetMode? mode,
    required String label,
    required IconData icon,
  }) {
    final selected = _defaultMode == mode;
    return _WidgetPressable(
      onTap: _saving ? null : () => _setDefaultMode(mode),
      pressedScale: 0.98,
      borderRadius: 18,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.cardBackgroundAlt,
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.55)
                : AppColors.borderStrong,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow,
              blurRadius: 30,
              offset: Offset(0, 10),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.topBarControlBackground,
                border: Border.all(color: AppColors.topBarControlBorder),
              ),
              child: Icon(icon, color: AppColors.label, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title3.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_saving && selected)
              CupertinoActivityIndicator(color: AppColors.primaryOrange)
            else
              Icon(
                selected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color: selected ? AppColors.accent : AppColors.tertiaryLabel,
              ),
          ],
        ),
      ),
    );
  }

  Widget _widgetToggleCard({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.cardBackgroundAlt,
        border: Border.all(color: AppColors.borderStrong, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 30,
            offset: Offset(0, 10),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.topBarControlBackground,
              border: Border.all(color: AppColors.topBarControlBorder),
            ),
            child: Icon(icon, color: AppColors.label, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title3.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.label,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            onChanged: _saving ? null : onChanged,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _WidgetPressable(
      onTap: _saving ? null : onTap,
      pressedScale: 0.98,
      borderRadius: 16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.pillBackground,
          border: Border.all(color: AppColors.pillBorder, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.label.withValues(alpha: 0.9), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.callout.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.label.withValues(alpha: 0.88),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.tertiaryLabel.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double borderRadius;

  const _WidgetPressable({
    required this.child,
    required this.onTap,
    required this.pressedScale,
    required this.borderRadius,
  });

  @override
  State<_WidgetPressable> createState() => _WidgetPressableState();
}

class _WidgetPressableState extends State<_WidgetPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
