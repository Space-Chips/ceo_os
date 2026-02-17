import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_button.dart';
import '../../core/widgets/ceo_text_field.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.none;
  DateTime? _dueDate;
  final List<TextEditingController> _subtaskControllers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSubtask() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accent,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      setState(() {
        _dueDate = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 23,
          time?.minute ?? 59,
        );
      });
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;

    final task = Task(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      subtasks: _subtaskControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => SubTask(title: c.text.trim()))
          .toList(),
    );

    context.read<TaskProvider>().addTask(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLighter,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('New Task', style: AppTypography.headingLarge),
            const SizedBox(height: AppSpacing.lg),

            // Title
            CeoTextField(
              hint: 'What needs to be done?',
              controller: _titleController,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            CeoTextField(
              hint: 'Add details (optional)',
              controller: _descController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Priority
            Text('Priority', style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            )),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: TaskPriority.values.where((p) => p != TaskPriority.none).map((p) {
                final isSelected = _priority == p;
                final color = _priorityColor(p);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = isSelected ? TaskPriority.none : p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                        ),
                      ),
                      child: Text(
                        p.name[0].toUpperCase() + p.name.substring(1),
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected ? color : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Due date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: _dueDate != null
                          ? AppColors.accent
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _dueDate != null
                          ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                          : 'Set due date',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _dueDate != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Subtasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtasks', style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                )),
                GestureDetector(
                  onTap: _addSubtask,
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Add', style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accent,
                      )),
                    ],
                  ),
                ),
              ],
            ),
            if (_subtaskControllers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ..._subtaskControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textTertiary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Subtask ${entry.key + 1}',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeSubtask(entry.key),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: AppSpacing.xl),

            // Save button
            CeoButton(
              label: 'Create Task',
              icon: Icons.add,
              expand: true,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
      default:
        return AppColors.textTertiary;
    }
  }
}
