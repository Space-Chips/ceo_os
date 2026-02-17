import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_progress_ring.dart';
import 'add_task_sheet.dart';

/// Tasks screen — HIG grouped list + Eisenhower Matrix with CNSegmentedControl.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _viewIndex = 0; // 0 = List, 1 = Matrix
  int _filterIndex = 0; // 0=All, 1=Today, 2=Upcoming, 3=Done

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadSampleData();
    });
  }

  void _showAddTask() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          // ── Large Title Nav Bar ──
          CupertinoSliverNavigationBar(
            largeTitle: const Text('My Tasks'),
            backgroundColor: AppColors.systemBackground,
            border: null,
            trailing: GestureDetector(
              onTap: _showAddTask,
              child: const CNIcon(symbol: CNSymbol('plus.circle.fill')),
            ),
          ),

          // ── View Toggle: List / Matrix ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: CNSegmentedControl(
                labels: const ['List', 'Matrix'],
                selectedIndex: _viewIndex,
                onValueChanged: (i) => setState(() => _viewIndex = i),
              ),
            ),
          ),

          if (_viewIndex == 0) ..._buildListView(),
          if (_viewIndex == 1) ..._buildMatrixView(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // LIST VIEW
  // ──────────────────────────────────────────────────────

  List<Widget> _buildListView() {
    return [
      // Filter chips
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: CNSegmentedControl(
            labels: const ['All', 'Today', 'Upcoming', 'Done'],
            selectedIndex: _filterIndex,
            onValueChanged: (i) => setState(() => _filterIndex = i),
          ),
        ),
      ),

      // Task list
      Consumer<TaskProvider>(
        builder: (context, prov, _) {
          final tasks = switch (_filterIndex) {
            0 => prov.incompleteTasks,
            1 => prov.todayTasks,
            2 => prov.upcomingTasks,
            3 => prov.completedTasks,
            _ => prov.incompleteTasks,
          };

          if (tasks.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CNIcon(symbol: CNSymbol('checkmark.circle')),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No tasks',
                      style: AppTypography.title3.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap + to add your first task',
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ).copyWith(bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Dismissible(
                    key: ValueKey(task.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => prov.deleteTask(task.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.systemRed,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusGrouped,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.white,
                        size: 22,
                      ),
                    ),
                    child: _TaskTile(
                      task: task,
                      onToggle: () => prov.toggleTask(task.id),
                    ),
                  ),
                );
              }, childCount: tasks.length),
            ),
          );
        },
      ),
    ];
  }

  // ──────────────────────────────────────────────────────
  // EISENHOWER MATRIX VIEW
  // ──────────────────────────────────────────────────────

  List<Widget> _buildMatrixView() {
    return [
      Consumer<TaskProvider>(
        builder: (context, prov, _) {
          return SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md).copyWith(bottom: 120),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Top row: Q1 + Q2
                  Row(
                    children: [
                      Expanded(
                        child: _MatrixQuadrant(
                          title: 'Do First',
                          subtitle: 'Urgent & Important',
                          color: AppColors.systemRed,
                          icon: CupertinoIcons.bolt_fill,
                          tasks: prov.doFirstTasks,
                          onToggle: (id) => prov.toggleTask(id),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MatrixQuadrant(
                          title: 'Schedule',
                          subtitle: 'Important',
                          color: AppColors.systemBlue,
                          icon: CupertinoIcons.calendar,
                          tasks: prov.scheduleTasks,
                          onToggle: (id) => prov.toggleTask(id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Bottom row: Q3 + Q4
                  Row(
                    children: [
                      Expanded(
                        child: _MatrixQuadrant(
                          title: 'Delegate',
                          subtitle: 'Urgent',
                          color: AppColors.systemOrange,
                          icon: CupertinoIcons.person_2,
                          tasks: prov.delegateTasks,
                          onToggle: (id) => prov.toggleTask(id),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MatrixQuadrant(
                          title: 'Eliminate',
                          subtitle: 'Neither',
                          color: AppColors.tertiaryLabel,
                          icon: CupertinoIcons.trash,
                          tasks: prov.eliminateTasks,
                          onToggle: (id) => prov.toggleTask(id),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────
// EISENHOWER MATRIX QUADRANT
// ─────────────────────────────────────────────────────────────────────

class _MatrixQuadrant extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<Task> tasks;
  final ValueChanged<String> onToggle;

  const _MatrixQuadrant({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.tasks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          children: [
            // Color strip at top
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(height: 3, color: color),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: AppTypography.headline.copyWith(
                          color: color,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Center(
                        child: Text(
                          'None',
                          style: AppTypography.footnote.copyWith(
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ),
                    )
                  else
                    ...tasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: GestureDetector(
                          onTap: () => onToggle(task.id),
                          child: Row(
                            children: [
                              Icon(
                                task.isComplete
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                size: 18,
                                color: task.isComplete
                                    ? AppColors.systemGreen
                                    : AppColors.tertiaryLabel,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: AppTypography.subhead.copyWith(
                                    decoration: task.isComplete
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isComplete
                                        ? AppColors.tertiaryLabel
                                        : AppColors.label,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TASK TILE — HIG grouped cell style (44pt min touch target)
// ─────────────────────────────────────────────────────────────────────

class _TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  const _TaskTile({required this.task, required this.onToggle});

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _handleTap() {
    _anim.forward().then((_) => _anim.reverse());
    widget.onToggle();
  }

  Color get _priorityColor => switch (widget.task.priority) {
    TaskPriority.urgent => AppColors.systemRed,
    TaskPriority.high => AppColors.systemOrange,
    TaskPriority.medium => AppColors.systemYellow,
    TaskPriority.low => AppColors.systemBlue,
    TaskPriority.none => AppColors.tertiaryLabel,
  };

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      decoration: BoxDecoration(
        color: AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        child: Stack(
          children: [
            // Priority accent strip
            if (task.priority != TaskPriority.none)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: _priorityColor),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Animated checkbox
                  GestureDetector(
                    onTap: _handleTap,
                    child: SizedBox(
                      width: AppSpacing.minTouchTarget,
                      height: AppSpacing.minTouchTarget,
                      child: Center(
                        child: ScaleTransition(
                          scale: _scale,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              task.isComplete
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              key: ValueKey(task.isComplete),
                              size: 24,
                              color: task.isComplete
                                  ? _priorityColor
                                  : AppColors.tertiaryLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.isComplete
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isComplete
                                ? AppColors.tertiaryLabel
                                : AppColors.label,
                          ),
                        ),
                        if (task.dueDate != null ||
                            task.subtasks.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              if (task.dueDate != null) ...[
                                // Due date capsule badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: task.isOverdue
                                        ? AppColors.systemRed.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.tertiarySystemBackground,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    _formatDate(task.dueDate!),
                                    style: AppTypography.caption2.copyWith(
                                      color: task.isOverdue
                                          ? AppColors.systemRed
                                          : AppColors.secondaryLabel,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              if (task.subtasks.isNotEmpty) ...[
                                if (task.dueDate != null)
                                  const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${task.subtasks.where((s) => s.isComplete).length}/${task.subtasks.length}',
                                  style: AppTypography.caption2.copyWith(
                                    color: AppColors.secondaryLabel,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Progress mini ring
                  if (task.subtasks.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    CeoProgressRing(
                      progress: task.subtaskProgress,
                      size: 28,
                      strokeWidth: 3,
                      gradientColors: [_priorityColor, _priorityColor],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day));
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}/${date.day}';
  }
}
