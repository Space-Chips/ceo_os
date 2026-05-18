import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'task_importance_theme.dart';
import '../../components/glass_input_field.dart';
import '../../components/liquid_button.dart';

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

  final _importances = ['crucial', 'essential', 'average', 'low'];
  final _durations = [
    'less_than_30min',
    '1_hour',
    '2_hours',
    'half_day',
    '1_day',
    'several_days',
  ];

  String _labelForImportance(String value, LanguageProvider language) {
    switch (value) {
      case 'crucial':
        return language.t('tasks_importance_crucial');
      case 'essential':
        return language.t('tasks_importance_essential');
      case 'average':
        return language.t('tasks_importance_average');
      case 'low':
        return language.t('tasks_importance_low');
      default:
        return value;
    }
  }

  Color _importanceColor(String value) => TaskImportanceTheme.accent(value);

  String _labelForDuration(String value, LanguageProvider language) {
    switch (value) {
      case 'less_than_30min':
        return language.t('tasks_duration_under_30min');
      case '1_hour':
        return language.t('tasks_duration_1_hour');
      case '2_hours':
        return language.t('tasks_duration_2_hours');
      case 'half_day':
        return language.t('tasks_duration_half_day');
      case '1_day':
        return language.t('tasks_duration_1_day');
      case 'several_days':
        return language.t('tasks_duration_several_days');
      default:
        return value;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    final result = await context.read<TaskProvider>().addTask(
      _titleCtrl.text.trim(),
      importance: _importance,
      duration: _duration,
      groupId: null,
      deadline: _deadline,
      description: null,
      syncToCalendar: _deadline != null && _syncToCalendar,
    );

    if (!mounted) return;
    if (!result.allowed) {
      await showPremiumGateDialog(context, result);
      return;
    }
    Navigator.of(context).pop();
  }

  void _showDeadlinePicker() {
    final language = context.read<LanguageProvider>();
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
                      language.t('tasks_picker_clear'),
                      style: AppTypography.mono.copyWith(
                        fontSize: 12,
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
                      language.t('tasks_picker_done'),
                      style: AppTypography.mono.copyWith(
                        fontSize: 12,
                        color: AppColors.primaryOrange,
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

  void _showAddGroup() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: CupertinoAlertDialog(
          title: Text(
            'NEW_GROUP_PROTOCOL',
            style: AppTypography.mono.copyWith(fontSize: 14),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: _groupCtrl,
              placeholder: 'GROUP_NAME',
              style: AppTypography.mono.copyWith(color: Colors.white),
              placeholderStyle: AppTypography.mono.copyWith(
                color: AppColors.tertiaryLabel,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.secondaryLabel),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'CREATE',
                style: TextStyle(color: AppColors.primaryOrange),
              ),
              onPressed: () async {
                if (_groupCtrl.text.isNotEmpty) {
                  await context.read<TaskProvider>().addTaskGroup(
                    _groupCtrl.text,
                  );
                  _groupCtrl.clear();
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeadline(DateTime d, LanguageProvider language) {
    final locale = language.languageCode.toLowerCase();
    return DateFormat('MMM d, y', locale).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  language.t('tasks_new_task'),
                  style: AppTypography.title1.copyWith(
                    fontSize: 30,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 24),

                GlassInputField(
                  placeholder: language.t('tasks_task_title_placeholder'),
                  controller: _titleCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _showDeadlinePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: _deadline != null
                          ? AppColors.accent.withValues(alpha: 0.14)
                          : AppColors.inputBackground.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _deadline != null
                            ? AppColors.activeBorder
                            : AppColors.inputBorder,
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 17,
                          color: _deadline != null
                              ? AppColors.accent
                              : AppColors.tertiaryLabel,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _deadline != null
                              ? _formatDeadline(_deadline!, language)
                              : language.t('tasks_set_deadline'),
                          style: AppTypography.callout.copyWith(
                            fontSize: 14,
                            color: _deadline != null
                                ? AppColors.accentText
                                : AppColors.secondaryLabel,
                          ),
                        ),
                        const Spacer(),
                        if (_deadline != null)
                          GestureDetector(
                            onTap: () => setState(() => _deadline = null),
                            child: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SYNC_DEADLINE_TO_CALENDAR',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                    CupertinoSwitch(
                      value: _syncToCalendar,
                      activeTrackColor: AppColors.primaryOrange,
                      onChanged: (value) =>
                          setState(() => _syncToCalendar = value),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Group Selection
                _sectionLabel('ASSIGN_GROUP'),
                const SizedBox(height: 12),
                Consumer<TaskProvider>(
                  builder: (context, prov, _) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _GroupChip(
                          label: 'NONE',
                          isSelected: _selectedGroup == null,
                          onTap: () => setState(() => _selectedGroup = null),
                        ),
                        ...prov.groups.map(
                          (g) => _GroupChip(
                            label: g.name.toUpperCase(),
                            isSelected: _selectedGroup?.id == g.id,
                            onTap: () => setState(() => _selectedGroup = g),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showAddGroup,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryOrange.withOpacity(0.5),
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.plus,
                              size: 14,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(language.t('tasks_priority')),
                          const SizedBox(height: 12),
                          Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground.withValues(
                                alpha: 0.72,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.inputBorder,
                                width: 0.8,
                              ),
                            ),
                            child: CupertinoPicker(
                              itemExtent: 32,
                              selectionOverlay: _pickerSelectionOverlay(),
                              onSelectedItemChanged: (i) {
                                setState(() => _importance = _importances[i]);
                              },
                              children: _importances
                                  .map(
                                    (e) => Center(
                                      child: Text(
                                        _labelForImportance(e, language),
                                        style: AppTypography.callout.copyWith(
                                          fontSize: 13,
                                          color: _importanceColor(e),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(language.t('tasks_est_duration')),
                          const SizedBox(height: 12),
                          Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground.withValues(
                                alpha: 0.72,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.inputBorder,
                                width: 0.8,
                              ),
                            ),
                            child: CupertinoPicker(
                              itemExtent: 32,
                              selectionOverlay: _pickerSelectionOverlay(),
                              scrollController: FixedExtentScrollController(
                                initialItem: 1,
                              ),
                              onSelectedItemChanged: (i) {
                                setState(() => _duration = _durations[i]);
                              },
                              children: _durations
                                  .map(
                                    (e) => Center(
                                      child: Text(
                                        _labelForDuration(e, language),
                                        style: AppTypography.callout.copyWith(
                                          fontSize: 13,
                                          color: AppColors.label,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                LiquidButton(
                  label: language.t('tasks_initialize_task'),
                  fullWidth: true,
                  onPressed: _addTask,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerSelectionOverlay() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.85)),
      color: AppColors.white.withValues(alpha: 0.04),
    ),
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.overline.copyWith(
      fontSize: 11,
      color: AppColors.tertiaryLabel,
      letterSpacing: 0.6,
    ),
  );
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GroupChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? AppColors.primaryOrange.withValues(alpha: 0.16)
                : AppColors.cardBackgroundAlt,
            border: Border.all(
              color: isSelected ? AppColors.primaryOrange : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: isSelected ? AppColors.primaryOrange : AppColors.label,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
