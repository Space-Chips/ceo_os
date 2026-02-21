import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, TimeOfDay;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../components/components.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AddEventSheet extends StatefulWidget {
  final DateTime? selectedDate;
  const AddEventSheet({super.key, this.selectedDate});

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _addEvent() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
        : null;

    await context.read<TaskProvider>().addCalendarEvent(
      title: _titleCtrl.text.trim(),
      date: dateStr,
      time: timeStr,
      description: _descCtrl.text.trim(),
    );

    if (mounted) Navigator.of(context).pop();
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('CANCEL', style: TextStyle(color: AppColors.secondaryLabel, fontSize: 12)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('DONE', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  onDateTimeChanged: (val) => setState(() => _selectedDate = val),
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
            color: AppColors.background.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('CLEAR', style: TextStyle(color: AppColors.secondaryLabel, fontSize: 12)),
                      onPressed: () {
                        setState(() => _selectedTime = null);
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('DONE', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => Navigator.pop(context),
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
                  onDateTimeChanged: (val) =>
                      setState(() => _selectedTime = TimeOfDay.fromDateTime(val)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          color: AppColors.background.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
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

                const NeoMonoText('NEW_EVENT_PROTOCOL', fontSize: 18, fontWeight: FontWeight.bold),
                const SizedBox(height: 24),

                GlassInputField(
                  placeholder: 'EVENT_TITLE...',
                  controller: _titleCtrl,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                GlassInputField(
                  placeholder: 'DESCRIPTION_OPTIONAL...',
                  controller: _descCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('EVENT_DATE'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _showDatePicker,
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              borderRadius: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMM d, y').format(_selectedDate).toUpperCase(),
                                    style: AppTypography.mono.copyWith(fontSize: 12),
                                  ),
                                  const Icon(CupertinoIcons.calendar, size: 14, color: AppColors.primaryOrange),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('EVENT_TIME'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _showTimePicker,
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              borderRadius: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    (_selectedTime != null
                                        ? _selectedTime!.format(context)
                                        : 'ALL_DAY').toUpperCase(),
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 12,
                                      color: _selectedTime != null
                                          ? AppColors.label
                                          : AppColors.tertiaryLabel,
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.clock, size: 14, color: AppColors.primaryOrange),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                LiquidButton(
                  label: 'COMMIT_EVENT',
                  fullWidth: true,
                  onPressed: _addEvent,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel, letterSpacing: 1.5),
  );
}