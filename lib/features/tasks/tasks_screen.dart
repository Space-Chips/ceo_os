import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../focus/focus_starter_sheet.dart';
import 'add_task_sheet.dart';
import 'task_detail_sheet.dart';

enum _TaskTab { list, matrix, history }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskTab _activeTab = _TaskTab.list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<TaskProvider>();
      await prov.loadTasksWithCompleted(includeCompleted: true);
      await prov.loadEvents();
      await prov.loadGroups();
    });
  }

  void _showAddTask() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddTaskSheet(),
    );
  }

  void _showFocusStarter() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const FocusStarterSheet(),
    );
  }

  void _openTask(ParetoTask task, TaskProvider prov) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => TaskDetailSheet(
        task: task,
        onToggleComplete: () async {
          if (task.completed) {
            await prov.uncompleteTask(task.id);
          } else {
            await prov.completeTask(task.id);
          }
          await prov.loadEvents();
        },
        onDelete: () async {
          await prov.deleteTask(task.id);
          await prov.loadEvents();
        },
      ),
    );
  }

  int _importanceWeight(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return 4;
      case 'essential':
      case 'high':
        return 3;
      case 'average':
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  int _timeWeight(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'less_than_30min':
      case '15m':
      case '30m':
        return 6;
      case '1_hour':
      case '1h':
        return 5;
      case '2_hours':
      case '2h':
        return 4;
      case 'half_day':
        return 3;
      case '1_day':
        return 2;
      case 'several_days':
      case '4h+':
        return 1;
      default:
        return 0;
    }
  }

  int _durationMinutes(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'less_than_30min':
      case '15m':
      case '30m':
        return 30;
      case '1_hour':
      case '1h':
        return 60;
      case '2_hours':
      case '2h':
        return 120;
      case 'half_day':
        return 240;
      case '1_day':
        return 480;
      case 'several_days':
      case '4h+':
        return 720;
      default:
        return 45;
    }
  }

  String _importanceLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return 'Critical';
      case 'essential':
      case 'high':
        return 'High';
      case 'average':
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'None';
    }
  }

  String _durationLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'less_than_30min':
      case '15m':
      case '30m':
        return '30m';
      case '1_hour':
      case '1h':
        return '1h';
      case '2_hours':
      case '2h':
        return '2h';
      case 'half_day':
        return 'Half day';
      case '1_day':
        return '1 day';
      case 'several_days':
      case '4h+':
        return 'Multi-day';
      default:
        return 'Unplanned';
    }
  }

  bool _isImportant(ParetoTask task) =>
      _importanceWeight(task.importanceLevel) >= 3;

  bool _isQuick(ParetoTask task) => _timeWeight(task.timeDuration) >= 5;

  int _priorityScore(ParetoTask task) =>
      (_importanceWeight(task.importanceLevel) * 10) +
      _timeWeight(task.timeDuration);

  _DueInfo _dueInfo(DateTime? deadline) {
    if (deadline == null) {
      return const _DueInfo(
        label: 'No date',
        color: AppColors.tertiaryLabel,
        isOverdue: false,
      );
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = d.difference(today).inDays;
    if (diff < 0) {
      return _DueInfo(
        label: 'Overdue ${diff.abs()}d',
        color: AppColors.error,
        isOverdue: true,
      );
    }
    if (diff == 0) {
      return const _DueInfo(
        label: 'Due today',
        color: AppColors.primaryOrange,
        isOverdue: false,
      );
    }
    if (diff == 1) {
      return const _DueInfo(
        label: 'Tomorrow',
        color: AppColors.warning,
        isOverdue: false,
      );
    }
    return _DueInfo(
      label: DateFormat('EEE d MMM').format(deadline),
      color: AppColors.secondaryLabel,
      isOverdue: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: const NeoMonoText(
          'TO-DO',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showFocusStarter,
              child: const Icon(
                CupertinoIcons.timer,
                color: AppColors.primaryOrange,
                size: 19,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showAddTask,
              child: const Icon(
                CupertinoIcons.add,
                color: AppColors.primaryOrange,
                size: 19,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: Consumer<TaskProvider>(
        builder: (context, prov, _) {
          final allTasks = [...prov.tasks];
          final uncompleted = allTasks.where((t) => !t.completed).toList();
          final completed = allTasks.where((t) => t.completed).toList();

          uncompleted.sort((a, b) {
            final score = _priorityScore(b).compareTo(_priorityScore(a));
            if (score != 0) return score;
            final aDeadline = a.deadline;
            final bDeadline = b.deadline;
            if (aDeadline == null && bDeadline == null) {
              return b.createdAt.compareTo(a.createdAt);
            }
            if (aDeadline == null) return 1;
            if (bDeadline == null) return -1;
            return aDeadline.compareTo(bDeadline);
          });

          completed.sort((a, b) {
            final aDate = a.completedDate ?? a.createdAt;
            final bDate = b.completedDate ?? b.createdAt;
            return bDate.compareTo(aDate);
          });

          final now = DateTime.now();
          final startToday = DateTime(now.year, now.month, now.day);

          final overdue = <ParetoTask>[];
          final dueToday = <ParetoTask>[];
          final nextUp = <ParetoTask>[];

          for (final task in uncompleted) {
            if (task.deadline == null) {
              nextUp.add(task);
              continue;
            }
            final day = DateTime(
              task.deadline!.year,
              task.deadline!.month,
              task.deadline!.day,
            );
            if (day.isBefore(startToday)) {
              overdue.add(task);
            } else if (day == startToday) {
              dueToday.add(task);
            } else {
              nextUp.add(task);
            }
          }

          final quickWins = uncompleted.where((t) => _isQuick(t)).length;
          final todayLoadMinutes = dueToday.fold<int>(
            0,
            (acc, t) => acc + _durationMinutes(t.timeDuration),
          );

          final nextBestTask = overdue.isNotEmpty
              ? overdue.first
              : (dueToday.isNotEmpty
                    ? dueToday.first
                    : (nextUp.isNotEmpty ? nextUp.first : null));

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  child: Row(
                    children: [
                      _metric('Open', '${uncompleted.length}'),
                      _metric('Done', '${completed.length}'),
                      _metric('Quick wins', '$quickWins'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.clock_fill,
                        size: 14,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          overdue.isNotEmpty
                              ? '${overdue.length} overdue task${overdue.length > 1 ? 's' : ''} need immediate action.'
                              : dueToday.isEmpty
                              ? 'No tasks due today. Pull one high-impact item from Next Up.'
                              : 'Today load: $todayLoadMinutes min planned across ${dueToday.length} task${dueToday.length > 1 ? 's' : ''}.',
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _tabChip('LIST', _TaskTab.list),
                    const SizedBox(width: 8),
                    _tabChip('MATRIX', _TaskTab.matrix),
                    const SizedBox(width: 8),
                    _tabChip('HISTORY', _TaskTab.history),
                  ],
                ),
                const SizedBox(height: 14),
                if (_activeTab == _TaskTab.list) ...[
                  if (nextBestTask != null)
                    _NextActionCard(
                      task: nextBestTask,
                      dueInfo: _dueInfo(nextBestTask.deadline),
                      importanceLabel: _importanceLabel(
                        nextBestTask.importanceLevel,
                      ),
                      durationLabel: _durationLabel(nextBestTask.timeDuration),
                      onOpen: () => _openTask(nextBestTask, prov),
                      onComplete: () async {
                        await prov.completeTask(nextBestTask.id);
                        await prov.loadEvents();
                      },
                    ),
                  if (nextBestTask != null) const SizedBox(height: 14),
                  if (uncompleted.isEmpty)
                    _empty(
                      'No open tasks. Add one and define priority + duration.',
                    )
                  else ...[
                    if (overdue.isNotEmpty) ...[
                      _TaskSection(
                        title: 'Overdue',
                        hint: 'Clear these first to regain control',
                        tasks: overdue,
                        emptyLabel: 'No overdue tasks',
                        onOpen: (task) => _openTask(task, prov),
                        onComplete: (task) async {
                          await prov.completeTask(task.id);
                          await prov.loadEvents();
                        },
                        importanceLabel: _importanceLabel,
                        durationLabel: _durationLabel,
                        dueInfo: _dueInfo,
                        highAttention: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (dueToday.isNotEmpty) ...[
                      _TaskSection(
                        title: 'Due Today',
                        hint: 'Execution list for today',
                        tasks: dueToday,
                        emptyLabel: 'Nothing due today',
                        onOpen: (task) => _openTask(task, prov),
                        onComplete: (task) async {
                          await prov.completeTask(task.id);
                          await prov.loadEvents();
                        },
                        importanceLabel: _importanceLabel,
                        durationLabel: _durationLabel,
                        dueInfo: _dueInfo,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _TaskSection(
                      title: 'Next Up',
                      hint: 'Upcoming and backlog tasks',
                      tasks: nextUp,
                      emptyLabel: 'No queued tasks',
                      onOpen: (task) => _openTask(task, prov),
                      onComplete: (task) async {
                        await prov.completeTask(task.id);
                        await prov.loadEvents();
                      },
                      importanceLabel: _importanceLabel,
                      durationLabel: _durationLabel,
                      dueInfo: _dueInfo,
                    ),
                  ],
                ],
                if (_activeTab == _TaskTab.matrix) ...[
                  _MatrixQuad(
                    title: 'Quick + Important',
                    subtitle: 'Do now',
                    tasks: uncompleted
                        .where((t) => _isImportant(t) && _isQuick(t))
                        .toList(),
                    onOpen: (task) => _openTask(task, prov),
                  ),
                  const SizedBox(height: 10),
                  _MatrixQuad(
                    title: 'Slow + Important',
                    subtitle: 'Plan blocks',
                    tasks: uncompleted
                        .where((t) => _isImportant(t) && !_isQuick(t))
                        .toList(),
                    onOpen: (task) => _openTask(task, prov),
                  ),
                  const SizedBox(height: 10),
                  _MatrixQuad(
                    title: 'Quick + Not important',
                    subtitle: 'Batch / delegate',
                    tasks: uncompleted
                        .where((t) => !_isImportant(t) && _isQuick(t))
                        .toList(),
                    onOpen: (task) => _openTask(task, prov),
                  ),
                  const SizedBox(height: 10),
                  _MatrixQuad(
                    title: 'Slow + Not important',
                    subtitle: 'Eliminate',
                    tasks: uncompleted
                        .where((t) => !_isImportant(t) && !_isQuick(t))
                        .toList(),
                    onOpen: (task) => _openTask(task, prov),
                  ),
                ],
                if (_activeTab == _TaskTab.history) ...[
                  if (allTasks.isEmpty)
                    _empty('No task history yet.')
                  else
                    ...(() {
                      final history = [...allTasks];
                      history.sort((a, b) {
                        final aDate = a.completedDate ?? a.createdAt;
                        final bDate = b.completedDate ?? b.createdAt;
                        return bDate.compareTo(aDate);
                      });
                      return history.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HistoryRow(
                            task: task,
                            onToggle: () async {
                              if (task.completed) {
                                await prov.uncompleteTask(task.id);
                              } else {
                                await prov.completeTask(task.id);
                              }
                              await prov.loadEvents();
                            },
                            onDelete: () async {
                              await prov.deleteTask(task.id);
                              await prov.loadEvents();
                            },
                            onOpen: () => _openTask(task, prov),
                          ),
                        ),
                      );
                    })(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tabChip(String label, _TaskTab tab) {
    final selected = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? AppColors.primaryOrange.withValues(alpha: 0.16)
                : AppColors.backgroundLight.withValues(alpha: 0.45),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange.withValues(alpha: 0.35)
                  : AppColors.glassBorder,
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.mono.copyWith(
                fontSize: 10,
                color: selected
                    ? AppColors.primaryOrange
                    : AppColors.secondaryLabel,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 14,
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String message) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Center(
        child: Text(
          message,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.tertiaryLabel,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NextActionCard extends StatelessWidget {
  final ParetoTask task;
  final _DueInfo dueInfo;
  final String importanceLabel;
  final String durationLabel;
  final VoidCallback onOpen;
  final Future<void> Function() onComplete;

  const _NextActionCard({
    required this.task,
    required this.dueInfo,
    required this.importanceLabel,
    required this.durationLabel,
    required this.onOpen,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      border: Border.all(
        color: dueInfo.isOverdue
            ? AppColors.error.withValues(alpha: 0.35)
            : AppColors.primaryOrange.withValues(alpha: 0.3),
        width: 0.6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT BEST TASK',
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: dueInfo.isOverdue
                  ? AppColors.error
                  : AppColors.primaryOrange,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TaskBadge(label: importanceLabel),
              _TaskBadge(label: durationLabel),
              _TaskBadge(label: dueInfo.label, color: dueInfo.color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'OPEN',
                  onTap: onOpen,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: 'DONE',
                  onTap: () {
                    onComplete();
                  },
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isPrimary
              ? AppColors.primaryOrange.withValues(alpha: 0.18)
              : AppColors.backgroundLight.withValues(alpha: 0.6),
          border: Border.all(
            color: isPrimary
                ? AppColors.primaryOrange.withValues(alpha: 0.45)
                : AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: isPrimary
                  ? AppColors.primaryOrange
                  : AppColors.secondaryLabel,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final String hint;
  final List<ParetoTask> tasks;
  final String emptyLabel;
  final void Function(ParetoTask task) onOpen;
  final Future<void> Function(ParetoTask task) onComplete;
  final String Function(String? raw) importanceLabel;
  final String Function(String? raw) durationLabel;
  final _DueInfo Function(DateTime? deadline) dueInfo;
  final bool highAttention;

  const _TaskSection({
    required this.title,
    required this.hint,
    required this.tasks,
    required this.emptyLabel,
    required this.onOpen,
    required this.onComplete,
    required this.importanceLabel,
    required this.durationLabel,
    required this.dueInfo,
    this.highAttention = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      border: highAttention
          ? Border.all(
              color: AppColors.error.withValues(alpha: 0.25),
              width: 0.6,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: highAttention ? AppColors.error : AppColors.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            Text(
              emptyLabel,
              style: AppTypography.mono.copyWith(
                fontSize: 10,
                color: AppColors.tertiaryLabel,
              ),
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskRow(
                  task: task,
                  importanceLabel: importanceLabel(task.importanceLevel),
                  durationLabel: durationLabel(task.timeDuration),
                  dueInfo: dueInfo(task.deadline),
                  onComplete: () => onComplete(task),
                  onOpen: () => onOpen(task),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final ParetoTask task;
  final String importanceLabel;
  final String durationLabel;
  final _DueInfo dueInfo;
  final Future<void> Function() onComplete;
  final VoidCallback onOpen;

  const _TaskRow({
    required this.task,
    required this.importanceLabel,
    required this.durationLabel,
    required this.dueInfo,
    required this.onComplete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = () {
      switch (importanceLabel.toLowerCase()) {
        case 'critical':
          return AppColors.error;
        case 'high':
          return AppColors.primaryOrange;
        case 'medium':
          return AppColors.warning;
        default:
          return AppColors.secondaryLabel;
      }
    }();

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.backgroundLight.withValues(alpha: 0.35),
          border: Border.all(color: AppColors.glassBorder, width: 0.45),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async => onComplete(),
              child: Container(
                width: 46,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryOrange.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                  color: AppColors.primaryOrange.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    'DONE',
                    style: AppTypography.mono.copyWith(
                      fontSize: 8,
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _TaskBadge(label: importanceLabel, color: priorityColor),
                      _TaskBadge(
                        label: durationLabel,
                        color: AppColors.secondaryLabel,
                      ),
                      _TaskBadge(label: dueInfo.label, color: dueInfo.color),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 13,
              color: AppColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const _TaskBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.secondaryLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.mono.copyWith(fontSize: 9, color: c),
      ),
    );
  }
}

class _MatrixQuad extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ParetoTask> tasks;
  final void Function(ParetoTask task) onOpen;

  const _MatrixQuad({
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.label,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${tasks.length}',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Text(
              'No tasks',
              style: AppTypography.mono.copyWith(
                fontSize: 10,
                color: AppColors.tertiaryLabel,
              ),
            )
          else
            ...tasks
                .take(4)
                .map(
                  (task) => GestureDetector(
                    onTap: () => onOpen(task),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${task.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono.copyWith(
                          fontSize: 10,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ParetoTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _HistoryRow({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = task.completed
        ? AppColors.success
        : AppColors.tertiaryLabel;
    return GestureDetector(
      onTap: onOpen,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 14,
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                task.completed
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 21,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      color: task.completed
                          ? AppColors.tertiaryLabel
                          : AppColors.label,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.completed
                        ? 'Completed ${DateFormat('MMM d').format(task.completedDate ?? task.createdAt)}'
                        : 'Open task',
                    style: AppTypography.mono.copyWith(
                      fontSize: 10,
                      color: AppColors.tertiaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                CupertinoIcons.delete,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueInfo {
  final String label;
  final Color color;
  final bool isOverdue;

  const _DueInfo({
    required this.label,
    required this.color,
    required this.isOverdue,
  });
}
