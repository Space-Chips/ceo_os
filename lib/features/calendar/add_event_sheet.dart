import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, TimeOfDay;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/task_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/glass_card.dart';
import '../../components/glass_input_field.dart';

enum AddEventPreset { standard, focusPlan }

class AddEventSheet extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? initialTime;
  final AddEventPreset preset;
  final int? presetDurationMinutes;

  const AddEventSheet({
    super.key,
    this.selectedDate,
    this.initialTime,
    this.preset = AddEventPreset.standard,
    this.presetDurationMinutes,
  });

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final FeatureRepository _featureRepository = FeatureRepository();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 60;
  bool _loadingTypes = true;
  List<EventType> _eventTypes = const [];
  String? _selectedEventTypeId;
  bool _isBirthday = false;
  bool _isFocusSession = false;
  bool _focusRepeatsWeekly = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _selectedTime = widget.initialTime;
    if (widget.preset == AddEventPreset.focusPlan) {
      _isFocusSession = true;
      _durationMinutes = (widget.presetDurationMinutes ?? 45).clamp(15, 180);
      _selectedTime ??= const TimeOfDay(hour: 9, minute: 0);
    }
    _loadEventTypes();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEventTypes() async {
    setState(() => _loadingTypes = true);
    try {
      final types = await _featureRepository.getEventTypes();
      if (!mounted) return;
      setState(() {
        _eventTypes = types;
        _loadingTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eventTypes = const [];
        _loadingTypes = false;
      });
    }
  }

  Future<void> _addEvent() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
        : null;

    if (_isFocusSession && timeStr == null) {
      if (mounted) {
        _toast(_t('calendar_add_event_focus_requires_start_time'));
      }
      return;
    }

    final recurrenceRule = _isBirthday
        ? 'yearly'
        : (_isFocusSession && _focusRepeatsWeekly)
        ? 'weekly'
        : null;
    final sourceType = _isBirthday
        ? 'birthday'
        : _isFocusSession
        ? 'focus_plan'
        : 'manual';

    await context.read<TaskProvider>().addCalendarEvent(
      title: _titleCtrl.text.trim(),
      date: dateStr,
      time: _isBirthday ? null : timeStr,
      durationMinutes: _isBirthday ? null : _durationMinutes,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      sourceType: sourceType,
      recurrenceRule: recurrenceRule,
      eventTypeId: _selectedEventTypeId,
    );

    if (mounted) Navigator.of(context).pop();
  }

  String _t(String key) => context.read<LanguageProvider>().t(key);

  void _toast(String text) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(_t('calendar_add_event_error_title')),
        content: Text(text),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('ok')),
          ),
        ],
      ),
    );
  }

  void _toggleBirthday() {
    setState(() {
      _isBirthday = !_isBirthday;
      if (_isBirthday) {
        _isFocusSession = false;
        _focusRepeatsWeekly = false;
        _selectedTime = null;
      } else {
        _focusRepeatsWeekly = false;
      }
    });
  }

  void _toggleFocusSession() {
    setState(() {
      _isFocusSession = !_isFocusSession;
      if (_isFocusSession) {
        _isBirthday = false;
        _selectedTime ??= const TimeOfDay(hour: 9, minute: 0);
      } else {
        _focusRepeatsWeekly = false;
      }
    });
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: AppColors.secondaryLabel,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        _t('done'),
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  onDateTimeChanged: (val) =>
                      setState(() => _selectedDate = val),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () {
                        setState(() => _selectedTime = null);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'CLEAR',
                        style: TextStyle(
                          color: AppColors.secondaryLabel,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        _t('done'),
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    _selectedTime?.hour ?? 9,
                    _selectedTime?.minute ?? 0,
                  ),
                  onDateTimeChanged: (val) => setState(
                    () => _selectedTime = TimeOfDay.fromDateTime(val),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _adjustDuration(int delta) {
    setState(() {
      _durationMinutes = (_durationMinutes + delta).clamp(15, 480).toInt();
    });
  }

  String _timeLabel() {
    final time = _selectedTime;
    if (time == null) return _t('calendar_event_all_day');
    final dt = DateTime(2000, 1, 1, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Color _typeColor(EventType type) {
    final raw = (type.color ?? '').trim();
    switch (raw.toLowerCase()) {
      case 'blue':
        return const Color(0xFF60A5FA);
      case 'green':
        return const Color(0xFF34D399);
      case 'purple':
        return const Color(0xFFA78BFA);
      case 'pink':
        return const Color(0xFFF472B6);
      case 'orange':
        return const Color(0xFFFB923C);
      case 'red':
        return const Color(0xFFEF4444);
      case 'yellow':
        return const Color(0xFFFACC15);
      case 'teal':
        return const Color(0xFF2DD4BF);
    }

    var value = raw.replaceAll('#', '');
    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return AppColors.primaryOrange;
    return Color(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.88),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t('calendar_add_event_title'),
                    style: AppTypography.mono.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassInputField(
                    placeholder: 'Title',
                    controller: _titleCtrl,
                    autofocus: true,
                  ),
                  const SizedBox(height: 10),
                  GlassInputField(
                    placeholder: 'Description (Optional)',
                    controller: _descCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('Event Type'),
                  const SizedBox(height: 8),
                  if (_loadingTypes)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      borderRadius: 12,
                      child: Row(
                        children: [
                          CupertinoActivityIndicator(
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading types…',
                            style: AppTypography.mono.copyWith(
                              fontSize: 11,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_eventTypes.isEmpty)
                    Text(
                      'No event type configured. You can create some from "Types".',
                      style: AppTypography.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.tertiaryLabel,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _eventTypes.map((type) {
                        final selected = _selectedEventTypeId == type.id;
                        final color = _typeColor(type);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedEventTypeId = selected ? null : type.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: color.withValues(
                                alpha: selected ? 0.28 : 0.13,
                              ),
                              border: Border.all(
                                color: color.withValues(
                                  alpha: selected ? 0.9 : 0.45,
                                ),
                                width: selected ? 1.2 : 0.7,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  type.name ?? 'Type',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.label,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Date'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showDatePicker,
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                borderRadius: 12,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'MMM d, y',
                                      ).format(_selectedDate),
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.calendar,
                                      size: 14,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Time'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showTimePicker,
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                borderRadius: 12,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _timeLabel(),
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 12,
                                        color: _selectedTime != null
                                            ? AppColors.label
                                            : AppColors.tertiaryLabel,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.clock,
                                      size: 14,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('Duration (minutes)'),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    borderRadius: 12,
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          color: AppColors.accentMuted,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () => _adjustDuration(-15),
                          child: Icon(
                            CupertinoIcons.minus,
                            size: 14,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              '$_durationMinutes',
                              style: AppTypography.mono.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.label,
                              ),
                            ),
                            Text(
                              'MIN',
                              style: AppTypography.mono.copyWith(
                                fontSize: 9,
                                color: AppColors.tertiaryLabel,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          color: AppColors.accentMuted,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () => _adjustDuration(15),
                          child: Icon(
                            CupertinoIcons.add,
                            size: 14,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: AppColors.backgroundLight.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: AppTypography.mono.copyWith(
                              fontSize: 13,
                              color: AppColors.label,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _addEvent,
                          child: Text(
                            _isBirthday
                                ? 'Create Birthday'
                                : _isFocusSession
                                ? 'Plan Session'
                                : 'Create',
                            style: AppTypography.mono.copyWith(
                              fontSize: 13,
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.body.copyWith(
      fontSize: 12,
      color: AppColors.secondaryLabel.withValues(alpha: 0.7),
      letterSpacing: 2,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _selectionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color accentColor = const Color(0xFF4C7DFF),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? accentColor.withValues(alpha: 0.15)
              : AppColors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            color: AppColors.label,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String placeholder,
    bool autofocus = false,
    int maxLines = 1,
    double minHeight = 48,
    double opacity = 1,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: CupertinoTextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        decoration: null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        placeholder: placeholder,
        placeholderStyle: AppTypography.body.copyWith(
          fontSize: 14,
          color: AppColors.secondaryLabel.withValues(alpha: 0.6 * opacity),
        ),
        style: AppTypography.body.copyWith(
          fontSize: 14,
          color: AppColors.label.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _pickerField({required String label, required IconData icon}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: AppColors.label,
            ),
          ),
          Icon(icon, size: 16, color: AppColors.secondaryLabel),
        ],
      ),
    );
  }

  Widget _durationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.label),
      ),
    );
  }
}
