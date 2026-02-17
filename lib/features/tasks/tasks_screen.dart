import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/platform/adaptive_widgets.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_card.dart';
import '../../core/widgets/ceo_chip.dart';
import 'add_task_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadSampleData();
    });
  }

  List<Task> _getFilteredTasks(TaskProvider provider) {
    switch (_filter) {
      case 'Today':
        return provider.todayTasks;
      case 'Upcoming':
        return provider.upcomingTasks;
      case 'Done':
        return provider.completedTasks;
      default:
        return provider.incompleteTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tasks', style: AppTypography.displayMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Consumer<TaskProvider>(
                        builder: (_, provider, __) => Text(
                          '${provider.incompleteTasks.length} remaining',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Consumer<TaskProvider>(
                    builder: (_, provider, __) {
                      final total = provider.tasks.length;
                      final done = provider.completedTasks.length;
                      final pct = total > 0 ? (done / total * 100).round() : 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentMuted,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '$pct%',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Today', 'Upcoming', 'Done'].map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: CeoChip(
                        label: filter,
                        isSelected: _filter == filter,
                        onTap: () => setState(() => _filter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Task list
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (_, provider, __) {
                    final tasks = _getFilteredTasks(provider);
                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_circle,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _filter == 'Done'
                                  ? 'No completed tasks yet'
                                  : 'All clear!',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _TaskTile(task: tasks[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTaskSheet(),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  const _TaskTile({required this.task});

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => provider.deleteTask(task.id),
      child: CeoCard(
        showAccentStrip: task.priority != TaskPriority.none,
        accentStripColor: _priorityColor(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Adaptive checkbox
            AdaptiveCheckbox(
              value: task.isComplete,
              onChanged: (_) => provider.toggleTask(task.id),
              activeColor: AppColors.accent,
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.bodyLarge.copyWith(
                      decoration:
                          task.isComplete ? TextDecoration.lineThrough : null,
                      color: task.isComplete
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (task.subtasks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                            child: LinearProgressIndicator(
                              value: task.subtaskProgress,
                              minHeight: 3,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${task.subtasks.where((s) => s.isComplete).length}/${task.subtasks.length}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 12,
                          color: task.isOverdue
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat('MMM d, h:mm a').format(task.dueDate!),
                          style: AppTypography.caption.copyWith(
                            color: task.isOverdue
                                ? AppColors.error
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
