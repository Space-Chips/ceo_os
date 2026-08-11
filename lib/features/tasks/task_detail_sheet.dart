import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'task_importance_theme.dart';

class TaskDetailSheet extends StatelessWidget {
  final ParetoTask task;
  final Future<void> Function()? onToggleComplete;
  final Future<void> Function()? onDelete;

  const TaskDetailSheet({
    super.key,
    required this.task,
    this.onToggleComplete,
    this.onDelete,
  });

  Color get _priorityColor {
    return TaskImportanceTheme.accent(task.importanceLevel);
  }

  String _formatDate(DateTime d, LanguageProvider language) {
    final locale = language.languageCode.toLowerCase();
    return DateFormat('MMM d, y', locale).format(d);
  }

  String _durationLabel(String? raw, LanguageProvider language) {
    switch ((raw ?? '').toLowerCase()) {
      case 'less_than_30min':
      case '15m':
      case '30m':
        return '30m';
      case '1_hour':
      case '1h':
        return language.t('tasks_duration_1_hour');
      case '2_hours':
      case '2h':
        return language.t('tasks_duration_2_hours');
      case 'half_day':
        return language.t('tasks_duration_half_day');
      case '1_day':
        return language.t('tasks_duration_1_day');
      case 'several_days':
      case '4h+':
        return language.t('tasks_duration_several_days');
      default:
        return language.t('tasks_duration_unplanned');
    }
  }

  String _importanceLabel(String? raw) {
    return TaskImportanceTheme.detailLabel(raw);
  }

  String? _deadlineUrgency(DateTime? d) {
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff < 0) return 'tasks_overdue';
    if (diff == 0) return 'tasks_due_today';
    if (diff == 1) return 'tasks_due_tomorrow';
    if (diff <= 3) return 'tasks_due_soon';
    return null;
  }

  Future<void> _runAndClose(
    BuildContext context,
    Future<void> Function()? action,
  ) async {
    if (action == null) return;
    final navigator = Navigator.of(context);
    await action();
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final urgencyLabel = _deadlineUrgency(task.deadline);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  task.title,
                  style: AppTypography.mono.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.label,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      _importanceLabel(task.importanceLevel),
                      _priorityColor,
                    ),
                    _chip(
                      _durationLabel(task.timeDuration, language),
                      AppColors.secondaryLabel,
                    ),
                    if (task.deadline != null)
                      _chip(
                        '${language.t('tasks_due')} ${_formatDate(task.deadline!, language)}',
                        urgencyLabel == 'tasks_overdue'
                            ? AppColors.error
                            : AppColors.primaryOrange,
                      ),
                    if (urgencyLabel != null)
                      _chip(
                        language.t(urgencyLabel),
                        urgencyLabel == 'tasks_overdue'
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.glassBorder,
                ),
                const SizedBox(height: 24),
                Text(
                  language.t('tasks_description'),
                  style: AppTypography.mono.copyWith(
                    fontSize: 10,
                    color: AppColors.tertiaryLabel,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if ((task.description ?? '').trim().isNotEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 16,
                    child: Text(
                      task.description ?? '',
                      style: AppTypography.mono.copyWith(
                        fontSize: 13,
                        color: AppColors.secondaryLabel,
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      language.t('tasks_no_description'),
                      style: AppTypography.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.tertiaryLabel,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: LiquidButton(
                        label: task.completed
                            ? language.t('tasks_reopen_task')
                            : language.t('tasks_mark_done'),
                        fullWidth: true,
                        onPressed: () async =>
                            _runAndClose(context, onToggleComplete),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async => _runAndClose(context, onDelete),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.error.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                            width: 0.6,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.delete,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${language.t('tasks_created')} ${_formatDate(task.createdAt, language)}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 9,
                    color: AppColors.quaternaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.mono.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
