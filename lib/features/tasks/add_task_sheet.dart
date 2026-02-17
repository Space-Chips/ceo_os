import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Add task modal — Cupertino HIG sheet with Important/Urgent toggles.
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TaskPriority _priority = TaskPriority.none;
  DateTime? _dueDate;
  bool _isImportant = false;
  bool _isUrgent = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addTask() {
    if (_titleCtrl.text.trim().isEmpty) return;
    context.read<TaskProvider>().addTask(
      Task(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        isImportant: _isImportant,
        isUrgent: _isUrgent,
      ),
    );
    Navigator.of(context).pop();
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        decoration: const BoxDecoration(
          color: AppColors.secondarySystemBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Clear'),
                    onPressed: () {
                      setState(() => _dueDate = null);
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime:
                    _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                onDateTimeChanged: (date) => setState(() => _dueDate = date),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryLabel,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'New Task',
                style: AppTypography.title3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Task Name
              CupertinoTextField(
                controller: _titleCtrl,
                placeholder: 'What needs to be done?',
                autofocus: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                style: AppTypography.body,
                placeholderStyle: AppTypography.body.copyWith(
                  color: AppColors.tertiaryLabel,
                ),
                cursorColor: AppColors.systemBlue,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Description
              CupertinoTextField(
                controller: _descCtrl,
                placeholder: 'Add a note (optional)',
                maxLines: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                style: AppTypography.body,
                placeholderStyle: AppTypography.body.copyWith(
                  color: AppColors.tertiaryLabel,
                ),
                cursorColor: AppColors.systemBlue,
              ),
              const SizedBox(height: AppSpacing.md),

              // Priority
              Text(
                'Priority',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = _priority == p;
                  final label = switch (p) {
                    TaskPriority.urgent => 'Urgent',
                    TaskPriority.high => 'High',
                    TaskPriority.medium => 'Med',
                    TaskPriority.low => 'Low',
                    TaskPriority.none => 'None',
                  };
                  final color = switch (p) {
                    TaskPriority.urgent => AppColors.systemRed,
                    TaskPriority.high => AppColors.systemOrange,
                    TaskPriority.medium => AppColors.systemYellow,
                    TaskPriority.low => AppColors.systemBlue,
                    TaskPriority.none => AppColors.tertiaryLabel,
                  };
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: p != TaskPriority.none ? AppSpacing.xs : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.18)
                                : AppColors.tertiarySystemBackground,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: AppTypography.caption1.copyWith(
                                color: isSelected
                                    ? color
                                    : AppColors.secondaryLabel,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Eisenhower toggles
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eisenhower Matrix',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Important', style: AppTypography.body),
                        CNSwitch(
                          value: _isImportant,
                          onChanged: (v) => setState(() => _isImportant = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Urgent', style: AppTypography.body),
                        CNSwitch(
                          value: _isUrgent,
                          onChanged: (v) => setState(() => _isUrgent = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Due Date
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiarySystemBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 18,
                        color: AppColors.secondaryLabel,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                            : 'Set due date',
                        style: AppTypography.body.copyWith(
                          color: _dueDate != null
                              ? AppColors.label
                              : AppColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: CNButton(label: 'Create Task', onPressed: _addTask),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
