import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Divider; // Explicitly import Colors and Divider
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'add_task_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _isMatrixView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
      context.read<TaskProvider>().loadGroups();
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
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const NeoMonoText(
                  'TASKS',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: AppColors.background.withOpacity(0.8),
                border: null,
                stretch: true,
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _isMatrixView = !_isMatrixView),
                  child: Icon(
                    _isMatrixView ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),

              Consumer<TaskProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading && prov.tasks.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CupertinoActivityIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    );
                  }

                  final tasks = prov.tasks.where((t) => !t.completed).toList();

                  if (tasks.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.square_list,
                              size: 48,
                              color: AppColors.tertiaryLabel,
                            ),
                            const SizedBox(height: 16),
                            const NeoMonoText(
                              'NO_ACTIVE_TASKS',
                              fontSize: 14,
                              color: AppColors.secondaryLabel,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_isMatrixView) {
                    return _EisenhowerMatrix(tasks: tasks, onToggle: (id) => prov.completeTask(id));
                  }

                  // Group tasks by groupId
                  final groupedTasks = <String?, List<ParetoTask>>{};
                  for (final task in tasks) {
                    groupedTasks.putIfAbsent(task.groupId, () => []).add(task);
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ).copyWith(bottom: 150),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final groupId = groupedTasks.keys.elementAt(index);
                        final groupTasks = groupedTasks[groupId]!;
                        final group = prov.groups.where((g) => g.id == groupId).firstOrNull;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: 4, 
                                bottom: 12, 
                                top: index == 0 ? 0 : 24,
                              ),
                              child: NeoMonoText(
                                group?.name.toUpperCase() ?? 'GENERAL_TASKS',
                                fontSize: 11,
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GlassCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 24,
                              child: Column(
                                children: List.generate(groupTasks.length, (i) {
                                  final task = groupTasks[i];
                                  return Column(
                                    children: [
                                      _TaskTile(
                                        task: task,
                                        onToggle: () => prov.completeTask(task.id),
                                      ),
                                      if (i < groupTasks.length - 1)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: Divider(
                                            height: 1,
                                            thickness: 0.5,
                                            color: AppColors.glassBorder,
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        );
                      }, childCount: groupedTasks.length),
                    ),
                  );
                },
              ),
            ],
          ),

          Positioned(
            right: 24,
            bottom: 40,
            child: FloatingAddButton(onPressed: _showAddTask),
          ),
        ],
      ),
    );
  }
}

class _EisenhowerMatrix extends StatelessWidget {
  final List<ParetoTask> tasks;
  final Function(String) onToggle;

  const _EisenhowerMatrix({required this.tasks, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    // Quadrants:
    // 1: Critical/High Importance + Short Duration (Do First)
    // 2: Medium Importance + Short Duration (Schedule)
    // 3: High Importance + Long Duration (Delegate/Break down)
    // 4: Low Importance (Eliminate/Backlog)
    
    // Simplification for prototype:
    final q1 = tasks.where((t) => t.importanceLevel == 'Critical' || t.importanceLevel == 'High').toList();
    final q2 = tasks.where((t) => t.importanceLevel == 'Medium').toList();
    final q3 = tasks.where((t) => t.importanceLevel == 'Low').toList();
    final q4 = tasks.where((t) => t.importanceLevel == null).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(20).copyWith(bottom: 150),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildListDelegate([
          _MatrixQuadrant(title: 'DO_FIRST', tasks: q1, color: AppColors.error, onToggle: onToggle),
          _MatrixQuadrant(title: 'SCHEDULE', tasks: q2, color: AppColors.primaryOrange, onToggle: onToggle),
          _MatrixQuadrant(title: 'DELEGATE', tasks: q3, color: AppColors.secondaryLabel, onToggle: onToggle),
          _MatrixQuadrant(title: 'ELIMINATE', tasks: q4, color: AppColors.tertiaryLabel, onToggle: onToggle),
        ]),
      ),
    );
  }
}

class _MatrixQuadrant extends StatelessWidget {
  final String title;
  final List<ParetoTask> tasks;
  final Color color;
  final Function(String) onToggle;

  const _MatrixQuadrant({
    required this.title,
    required this.tasks,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeoMonoText(
                  title,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Icon(CupertinoIcons.check_mark, size: 16, color: color.withOpacity(0.3)),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      return GestureDetector(
                        onTap: () => onToggle(task.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.circle, size: 12, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title.toUpperCase(),
                                  style: AppTypography.mono.copyWith(fontSize: 9, color: AppColors.label),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final ParetoTask task;
  final VoidCallback onToggle;
  const _TaskTile({required this.task, required this.onToggle});

  Color get _priorityColor {
    switch (task.importanceLevel) {
      case 'Critical':
        return AppColors.error;
      case 'High':
        return AppColors.primaryOrange;
      case 'Medium':
        return AppColors.primaryOrange.withOpacity(0.6);
      case 'Low':
        return AppColors.secondaryLabel;
      default:
        return AppColors.tertiaryLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              task.completed
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 24,
              color: task.completed
                  ? AppColors.success
                  : AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.completed
                        ? AppColors.tertiaryLabel
                        : AppColors.label,
                  ),
                ),
                if (task.timeDuration != null ||
                    task.importanceLevel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (task.timeDuration != null)
                        Text(
                          task.timeDuration!,
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      if (task.timeDuration != null &&
                          task.importanceLevel != null)
                        const SizedBox(width: 8),
                      if (task.importanceLevel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.importanceLevel!.toUpperCase(),
                            style: AppTypography.mono.copyWith(
                              fontSize: 9,
                              color: _priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
