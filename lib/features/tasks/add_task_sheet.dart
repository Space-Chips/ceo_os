import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  String _importance = 'crucial';
  String _duration = '1_hour';
  DateTime? _deadline;
  bool _syncToCalendar = true;

  static const _importances = ['crucial', 'essential', 'average'];
  static const _durations = [
    'less_than_30min',
    '1_hour',
    '2_hours',
    'half_day',
  ];

  static const Map<String, String> _importanceLabels = {
    'crucial': 'Crucial',
    'essential': 'Essential',
    'average': 'Average',
  };

  static const Map<String, String> _durationLabels = {
    'less_than_30min': 'Under 30 min',
    '1_hour': '1 hour',
    '2_hours': '2 hours',
    'half_day': 'Half day',
  };

  Color _importanceColor(String value) {
    switch (value) {
      case 'crucial':
        return const Color(0xFFFF453A);
      case 'essential':
        return const Color(0xFFFF9F0A);
      case 'average':
        return const Color(0xFFFFD60A);
      default:
        return AppColors.secondaryLabel;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    await context.read<TaskProvider>().addTask(
      _titleCtrl.text.trim(),
      importance: _importance,
      duration: _duration,
      deadline: _deadline,
      syncToCalendar: _deadline != null && _syncToCalendar,
    );

    if (mounted) Navigator.of(context).pop();
  }

  void _showDeadlinePicker() {
    final initial = _deadline ?? DateTime.now().add(const Duration(days: 1));
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Clear',
                      style: AppTypography.callout.copyWith(
                        fontSize: 15,
                        color: AppColors.error,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _deadline = null);
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: AppTypography.callout.copyWith(
                        fontSize: 15,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: DateTime.now(),
                onDateTimeChanged: (d) => setState(() => _deadline = d),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeadline(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  BoxDecoration _fieldDecoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.cardBackgroundStrong.withValues(alpha: 0.52),
        AppColors.cardBase.withValues(alpha: 0.38),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppColors.glassBorder.withValues(alpha: 0.20),
      width: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<TaskProvider>();
    const ctaLabel = 'Create task';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: AppColors.glassBorder.withValues(alpha: 0.30),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'New Task',
                  style: AppTypography.largeTitle.copyWith(
                    fontSize: 38,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.9,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 56,
                  decoration: _fieldDecoration(),
                  alignment: Alignment.center,
                  child: CupertinoTextField(
                    controller: _titleCtrl,
                    placeholder: 'Task title',
                    autofocus: true,
                    style: AppTypography.callout.copyWith(
                      fontSize: 16,
                      color: AppColors.label,
                      fontWeight: FontWeight.w500,
                    ),
                    placeholderStyle: AppTypography.callout.copyWith(
                      fontSize: 16,
                      color: AppColors.tertiaryLabel,
                      fontWeight: FontWeight.w400,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: null,
                    cursorColor: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showDeadlinePicker,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: _fieldDecoration(),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 18,
                          color: _deadline != null
                              ? AppColors.label
                              : AppColors.tertiaryLabel,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _deadline != null
                                ? _formatDeadline(_deadline!)
                                : 'Set deadline',
                            style: AppTypography.callout.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _deadline != null
                                  ? AppColors.label
                                  : AppColors.tertiaryLabel,
                            ),
                          ),
                        ),
                        if (_deadline != null)
                          GestureDetector(
                            onTap: () => setState(() => _deadline = null),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 18,
                              color: AppColors.tertiaryLabel,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: _fieldDecoration(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sync deadline to calendar',
                          style: AppTypography.callout.copyWith(
                            fontSize: 16,
                            color: AppColors.label,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.92,
                        child: CupertinoSwitch(
                          value: _syncToCalendar,
                          activeTrackColor: const Color(0xFF34C759),
                          inactiveTrackColor: AppColors.glassBorder.withValues(
                            alpha: 0.40,
                          ),
                          thumbColor: AppColors.label,
                          onChanged: (value) =>
                              setState(() => _syncToCalendar = value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StackedSelectorCard(
                        label: 'Priority',
                        items: _importances,
                        selected: _importance,
                        labelFor: (v) => _importanceLabels[v] ?? v,
                        colorFor: _importanceColor,
                        onSelect: (v) => setState(() => _importance = v),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StackedSelectorCard(
                        label: 'Estimated duration',
                        items: _durations,
                        selected: _duration,
                        labelFor: (v) => _durationLabels[v] ?? v,
                        colorFor: null,
                        onSelect: (v) => setState(() => _duration = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                LiquidButton(
                  label: ctaLabel,
                  fullWidth: true,
                  onPressed: _addTask,
                  height: 56,
                  borderRadius: 28,
                  gradient: [
                    AppColors.label.withValues(alpha: 0.96),
                    AppColors.label.withValues(alpha: 0.74),
                  ],
                  labelStyle: AppTypography.callout.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StackedSelectorCard extends StatefulWidget {
  final String label;
  final List<String> items;
  final String selected;
  final String Function(String) labelFor;
  final Color Function(String)? colorFor;
  final ValueChanged<String> onSelect;

  const _StackedSelectorCard({
    required this.label,
    required this.items,
    required this.selected,
    required this.labelFor,
    required this.colorFor,
    required this.onSelect,
  });

  @override
  State<_StackedSelectorCard> createState() => _StackedSelectorCardState();
}

class _StackedSelectorCardState extends State<_StackedSelectorCard> {
  late FixedExtentScrollController _ctrl;

  int get _initialIndex {
    final i = widget.items.indexOf(widget.selected);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(initialItem: _initialIndex);
  }

  @override
  void didUpdateWidget(covariant _StackedSelectorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.items.indexOf(widget.selected);
    if (newIndex >= 0 &&
        _ctrl.hasClients &&
        _ctrl.selectedItem != newIndex) {
      _ctrl.animateToItem(
        newIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.items.indexOf(widget.selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            widget.label,
            style: AppTypography.callout.copyWith(
              fontSize: 14,
              color: AppColors.tertiaryLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 168,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cardBackgroundStrong.withValues(alpha: 0.52),
                AppColors.cardBase.withValues(alpha: 0.38),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.20),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CupertinoPicker.builder(
              scrollController: _ctrl,
              itemExtent: 38,
              diameterRatio: 1.7,
              squeeze: 1.0,
              magnification: 1.0,
              useMagnifier: false,
              selectionOverlay: const SizedBox.shrink(),
              onSelectedItemChanged: (i) {
                widget.onSelect(widget.items[i]);
              },
              childCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = index == selectedIndex;
                final color =
                    widget.colorFor?.call(item) ?? AppColors.label;
                return Center(
                  child: isSelected
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.label.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.label.withValues(alpha: 0.85),
                              width: 0.9,
                            ),
                          ),
                          child: Text(
                            widget.labelFor(item),
                            style: AppTypography.callout.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        )
                      : Text(
                          widget.labelFor(item),
                          style: AppTypography.callout.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
