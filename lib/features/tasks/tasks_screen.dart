import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show FontWeight;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'add_task_sheet.dart';
import 'task_detail_sheet.dart';
import 'task_importance_theme.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';

enum _TaskTab { list, matrix, history }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final PremiumRepository _premiumRepository = PremiumRepository();
  final PageController _pageController = PageController();
  _TaskTab _activeTab = _TaskTab.list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TaskProvider>().loadTasksWithCompleted(
        includeCompleted: true,
      );
    });
  }

  double _taskCardBorderWidth(String? importanceRaw) {
    switch ((importanceRaw ?? '').toLowerCase()) {
      case 'essential':
      case 'high':
        return AppColors.isDark ? 0.42 : 0.5;
      case 'average':
      case 'medium':
        return AppColors.isDark ? 0.4 : 0.48;
      default:
        return AppColors.isDark ? 1 : 1.1;
    }
  }

  double _importanceBadgeBorderWidth(String? importanceRaw) {
    switch ((importanceRaw ?? '').toLowerCase()) {
      case 'essential':
      case 'high':
        return AppColors.isDark ? 0.82 : 0.88;
      case 'average':
      case 'medium':
        return AppColors.isDark ? 0.8 : 0.86;
      default:
        return AppColors.isDark ? 1 : 1.05;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showAddTask() async {
    final check = await _premiumRepository.canCreateTask();
    if (!mounted) return;
    if (!check.allowed) {
      await showPremiumGateDialog(context, check);
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddTaskSheet(),
    );
  }

  Future<void> _showTaskDetail(ParetoTask task) async {
    final provider = context.read<TaskProvider>();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => TaskDetailSheet(
        task: task,
        onToggleComplete: () async {
          if (task.completed) {
            await provider.uncompleteTask(task.id);
          } else {
            await provider.completeTask(task.id);
          }
        },
        onDelete: () => provider.deleteTask(task.id),
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

  int _priorityScore(ParetoTask task) =>
      (_importanceWeight(task.importanceLevel) * 10) +
      _timeWeight(task.timeDuration);

  bool _isImportant(ParetoTask task) =>
      _importanceWeight(task.importanceLevel) >= 3;

  bool _isQuick(ParetoTask task) => _timeWeight(task.timeDuration) >= 5;

  List<ParetoTask> _recentWeekTasks(List<ParetoTask> tasks) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final filtered = tasks.where((task) {
      if (!task.createdAt.isBefore(cutoff)) return true;
      final done = task.completedDate;
      if (done != null && !done.isBefore(cutoff)) return true;
      return false;
    }).toList();
    filtered.sort((a, b) {
      final aDate = a.completedDate ?? a.createdAt;
      final bDate = b.completedDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  _TaskPalette _paletteForImportance(String? importanceRaw) {
    final style = TaskImportanceTheme.card(importanceRaw);
    return _TaskPalette(
      border: style.border,
      start: style.start,
      end: style.end,
      badgeBg: style.badge.background,
      badgeBorder: style.badge.border,
      badgeText: style.badge.text,
    );
  }

  String _importanceLabel(String? raw, LanguageProvider language) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return language.t('tasks_importance_crucial');
      case 'essential':
      case 'high':
        return language.t('tasks_importance_essential');
      case 'average':
      case 'medium':
        return language.t('tasks_importance_average');
      case 'low':
      default:
        return language.t('tasks_importance_low');
    }
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
        return language.t('tasks_duration_1_hour');
    }
  }

  String _swipeHint(LanguageProvider language) {
    switch (_activeTab) {
      case _TaskTab.list:
        return language.t('tasks_swipe_hint_list');
      case _TaskTab.matrix:
        return language.t('tasks_swipe_hint_matrix');
      case _TaskTab.history:
        return language.t('tasks_swipe_hint_history');
    }
  }

  String _titleByTab(LanguageProvider language) {
    switch (_activeTab) {
      case _TaskTab.list:
        return language.t('tasks_tab_title_todo');
      case _TaskTab.matrix:
        return language.t('tasks_tab_title_matrix');
      case _TaskTab.history:
        return language.t('tasks_tab_title_history');
    }
  }

  String _subtitleByTab(LanguageProvider language) {
    switch (_activeTab) {
      case _TaskTab.list:
        return language.t('tasks_tab_subtitle_todo');
      case _TaskTab.matrix:
        return language.t('tasks_tab_subtitle_matrix');
      case _TaskTab.history:
        return language.t('tasks_tab_subtitle_history');
    }
  }

  void _setActiveTab(_TaskTab nextTab) {
    if (_activeTab == nextTab) return;
    final tabs = _TaskTab.values;
    final nextIndex = tabs.indexOf(nextTab);
    // Drive the PageView so tab-button taps stay in sync with the finger-
    // linked scroll. onPageChanged will then update _activeTab.
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _activeTab = nextTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: Consumer<TaskProvider>(
            builder: (context, prov, _) {
              final allTasks = [...prov.tasks];
              final uncompleted = allTasks.where((t) => !t.completed).toList();
              uncompleted.sort(
                (a, b) => _priorityScore(b).compareTo(_priorityScore(a)),
              );
              final topFive = uncompleted.take(5).toList();
              final others = uncompleted.skip(5).toList();
              final recentWeekTasks = _recentWeekTasks(allTasks);

              final quickImportant = uncompleted.where(
                (t) => _isImportant(t) && _isQuick(t),
              );
              final slowImportant = uncompleted.where(
                (t) => _isImportant(t) && !_isQuick(t),
              );
              final quickNotImportant = uncompleted.where(
                (t) => !_isImportant(t) && _isQuick(t),
              );
              final slowNotImportant = uncompleted.where(
                (t) => !_isImportant(t) && !_isQuick(t),
              );

              // PageView gives the same finger-linked, calm horizontal scroll
              // as the Habits screen — both panels move together with the
              // gesture rather than fading in on drag-end. This unifies the
              // scroll grammar across Habits / Tasks / Calendar.
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Column(
                  children: [
                    _topRow(language),
                    const SizedBox(height: AppSpacing.sm),
                    _titleBlock(language),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          final tabs = _TaskTab.values;
                          if (index < 0 || index >= tabs.length) return;
                          setState(() => _activeTab = tabs[index]);
                        },
                        children: [
                          _buildListTab(
                            key: const ValueKey('list'),
                            language: language,
                            topFive: topFive,
                            others: others,
                            onAdd: _showAddTask,
                            onOpenTask: _showTaskDetail,
                          ),
                          _buildMatrixTab(
                            key: const ValueKey('matrix'),
                            language: language,
                            quickImportant: quickImportant.toList(),
                            slowImportant: slowImportant.toList(),
                            quickNotImportant: quickNotImportant.toList(),
                            slowNotImportant: slowNotImportant.toList(),
                            onOpenTask: _showTaskDetail,
                          ),
                          _buildHistoryTab(
                            key: const ValueKey('history'),
                            language: language,
                            tasks: recentWeekTasks,
                            onToggle: (task) async {
                              if (task.completed) {
                                await prov.uncompleteTask(task.id);
                              } else {
                                await prov.completeTask(task.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _swipeHint(language),
                      style: AppTypography.caption1.copyWith(
                        fontSize: 12,
                        color: AppColors.tertiaryLabel.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topRow(LanguageProvider language) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CupertinoButton(
            // Generous hit area — chevron + label tap as one continuous 44pt
            // target, per Apple HIG.
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            minimumSize: const Size(44, 44),
            onPressed: () => context.go('/home'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.arrow_left,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 6),
                Text(
                  language.t('home'),
                  style: AppTypography.subhead.copyWith(
                    fontSize: 15,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleBlock(LanguageProvider language) {
    final isMatrix = _activeTab == _TaskTab.matrix;
    final titleSize = isMatrix ? 40.0 : 44.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            _titleByTab(language),
            style: AppTypography.largeTitle.copyWith(
              fontSize: titleSize,
              color: AppColors.label,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -1.1,
            ),
          ),
        ),
        if (_subtitleByTab(language).isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _subtitleByTab(language),
            style: AppTypography.overline.copyWith(
              fontSize: 12,
              color: AppColors.tertiaryLabel.withValues(alpha: 0.6),
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListTab({
    required Key key,
    required LanguageProvider language,
    required List<ParetoTask> topFive,
    required List<ParetoTask> others,
    required Future<void> Function() onAdd,
    required Future<void> Function(ParetoTask task) onOpenTask,
  }) {
    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Container(
              width: 2,
              height: 28,
              color: AppColors.glassHighlight.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                language.t('tasks_your_priorities'),
                style: AppTypography.title2.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label,
                ),
              ),
            ),
            _DarkGlassAddButton(onTap: onAdd),
          ],
        ),
        const SizedBox(height: 12),
        if (topFive.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 18,
            level: GlassCardLevel.standard,
            showEdgeGlow: true,
            border: Border.all(color: AppColors.glassBorder, width: 0.65),
            child: Column(
              children: [
                Text(
                  language.t('tasks_no_priorities'),
                  style: AppTypography.mono.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  language.t('tasks_no_priorities_subtitle'),
                  textAlign: TextAlign.center,
                  style: AppTypography.mono.copyWith(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          )
        else
          ...topFive.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _priorityCard(
                rank: index + 1,
                language: language,
                task: task,
                onTap: () => onOpenTask(task),
              ),
            );
          }),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 2, height: 24, color: AppColors.tertiaryLabel),
              const SizedBox(width: 10),
              Text(
                language.t('tasks_other_tasks'),
                style: AppTypography.overline.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tertiaryLabel.withValues(alpha: 0.72),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...others.asMap().entries.map((entry) {
            final idx = entry.key;
            final task = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _otherTaskCard(
                rank: idx + 6,
                language: language,
                task: task,
                onTap: () => onOpenTask(task),
              ),
            );
          }),
        ],
        if (topFive.isNotEmpty) ...[
          const SizedBox(height: 16),
          Center(
            // Match the top-right "+" button (_DarkGlassAddButton) exactly:
            // same fill, same border color and width, same corner radius, same
            // icon size and tint. The only difference is this one also shows
            // the "Add Task" label, so we extend the height/width to fit.
            child: _PressScale(
              onTap: onAdd,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: AppColors.topBarControlBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.topBarControlBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.add,
                      size: 20,
                      color: AppColors.label,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Task',
                      style: AppTypography.mono.copyWith(
                        fontSize: 15,
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _priorityCard({
    required int rank,
    required LanguageProvider language,
    required ParetoTask task,
    required Future<void> Function() onTap,
  }) {
    final palette = _paletteForImportance(task.importanceLevel);
    // Symmetric cascade: each subsequent priority is inset from both sides so
    // it stays visually centered while becoming progressively narrower —
    // Apple-style tapering rather than a one-sided shrink.
    final cascadeInset = ((rank - 1).clamp(0, 6)) * 7.0;
    return _PressScale(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: cascadeInset),
        // Slightly larger padding to give each card more presence — matches
        // the model's perceived "weight" while staying within iOS row-height
        // conventions.
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          // Softer, more iOS-like rounding (24 → 20).
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
          ),
          // Discreet colored ring; the importance is carried by the badge,
          // not the card outline.
          border: Border.all(
            color: palette.border.withValues(alpha: 0.32),
            width: _taskCardBorderWidth(task.importanceLevel),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(
                alpha: AppColors.isDark ? 0.10 : 0.05,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank chip — no border, slightly bigger (44 → 48) so it matches
            // the more generous card padding.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.topBarControlBackground,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: AppTypography.footnote.copyWith(
                    fontSize: 17,
                    color: AppColors.label.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.label,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _importanceBadge(task, palette, language: language),
                      const SizedBox(width: 10),
                      Text(
                        _durationLabel(task.timeDuration, language),
                        style: AppTypography.mono.copyWith(
                          fontSize: 14,
                          color: AppColors.secondaryLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otherTaskCard({
    required int rank,
    required LanguageProvider language,
    required ParetoTask task,
    required Future<void> Function() onTap,
  }) {
    final palette = _paletteForImportance(task.importanceLevel);
    return _PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
          ),
          border: Border.all(
            color: AppColors.border,
            width: _taskCardBorderWidth(task.importanceLevel),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(
                alpha: AppColors.isDark ? 0.16 : 0.09,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.topBarControlBackground,
                border: Border.all(
                  color: AppColors.topBarControlBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: AppTypography.footnote.copyWith(
                    fontSize: 16,
                    color: AppColors.tertiaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _importanceBadge(
                        task,
                        palette,
                        compact: true,
                        language: language,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _durationLabel(task.timeDuration, language),
                        style: AppTypography.caption1.copyWith(
                          fontSize: 11,
                          color: AppColors.tertiaryLabel.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _importanceBadge(
    ParetoTask task,
    _TaskPalette palette, {
    required LanguageProvider language,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: palette.badgeBg,
        border: Border.all(
          color: palette.badgeBorder,
          width: _importanceBadgeBorderWidth(task.importanceLevel),
        ),
      ),
      child: Text(
        _importanceLabel(task.importanceLevel, language),
        style: AppTypography.overline.copyWith(
          fontSize: compact ? 10 : 12,
          color: palette.badgeText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildMatrixTab({
    required Key key,
    required LanguageProvider language,
    required List<ParetoTask> quickImportant,
    required List<ParetoTask> slowImportant,
    required List<ParetoTask> quickNotImportant,
    required List<ParetoTask> slowNotImportant,
    required Future<void> Function(ParetoTask task) onOpenTask,
  }) {
    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        if (language.t('tasks_matrix_impact_axis').isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                language.t('tasks_matrix_impact_axis'),
                style: AppTypography.overline.copyWith(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: AppColors.tertiaryLabel.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _matrixQuadrant(
                language: language,
                title: language.t('tasks_matrix_do_now'),
                subtitle: language.t('tasks_matrix_do_now_subtitle'),
                accent: AppColors.error.withValues(alpha: 0.35),
                overlay: AppColors.error.withValues(alpha: 0.08),
                tasks: quickImportant,
                onTapTask: onOpenTask,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _matrixQuadrant(
                language: language,
                title: language.t('tasks_matrix_plan'),
                subtitle: language.t('tasks_matrix_plan_subtitle'),
                accent: AppColors.activeBorder,
                overlay: AppColors.accentSurfaceSoft.withValues(alpha: 0.5),
                tasks: slowImportant,
                onTapTask: onOpenTask,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _matrixQuadrant(
                language: language,
                title: language.t('tasks_matrix_if_time'),
                subtitle: language.t('tasks_matrix_if_time_subtitle'),
                accent: AppColors.warning.withValues(alpha: 0.35),
                overlay: AppColors.warning.withValues(alpha: 0.08),
                tasks: quickNotImportant,
                onTapTask: onOpenTask,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _matrixQuadrant(
                language: language,
                title: language.t('tasks_matrix_eliminate'),
                subtitle: language.t('tasks_matrix_eliminate_subtitle'),
                accent: AppColors.borderStrong,
                overlay: AppColors.label.withValues(alpha: 0.04),
                tasks: slowNotImportant,
                onTapTask: onOpenTask,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              language.t('tasks_matrix_time_axis'),
              style: AppTypography.overline.copyWith(
                fontSize: 11,
                letterSpacing: 2,
                color: AppColors.tertiaryLabel.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _matrixQuadrant({
    required LanguageProvider language,
    required String title,
    required String subtitle,
    required Color accent,
    required Color overlay,
    required List<ParetoTask> tasks,
    required Future<void> Function(ParetoTask task) onTapTask,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 268),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
          ),
          border: Border.all(color: accent, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(
                alpha: AppColors.isDark ? 0.18 : 0.1,
              ),
              blurRadius: AppColors.isDark ? 18 : 14,
              offset: Offset(0, AppColors.isDark ? 8 : 6),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [overlay, overlay.withValues(alpha: 0)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.overline.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption1.copyWith(
                    fontSize: 12,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 14),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        language.t('tasks_empty'),
                        textAlign: TextAlign.center,
                        style: AppTypography.subhead.copyWith(
                          fontSize: 13,
                          color: AppColors.tertiaryLabel.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  )
                else
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PressScale(
                        onTap: () => onTapTask(task),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.surfaceMuted,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headline.copyWith(
                              fontSize: 16,
                              color: AppColors.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab({
    required Key key,
    required LanguageProvider language,
    required List<ParetoTask> tasks,
    required Future<void> Function(ParetoTask task) onToggle,
  }) {
    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow.withValues(
                    alpha: AppColors.isDark ? 0.18 : 0.1,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              language.t('tasks_history_empty'),
              textAlign: TextAlign.center,
              style: AppTypography.subhead.copyWith(
                fontSize: 13,
                color: AppColors.secondaryLabel.withValues(alpha: 0.78),
              ),
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _historyCard(
                language: language,
                task: task,
                onToggle: () => onToggle(task),
              ),
            ),
          ),
      ],
    );
  }

  Widget _historyCard({
    required LanguageProvider language,
    required ParetoTask task,
    required Future<void> Function() onToggle,
  }) {
    final badgeStyle = _historyBadgeStyle(task.importanceLevel);
    final completedDate = task.completedDate;
    return Opacity(
      opacity: task.completed ? 0.9 : 1,
      child: _PressScale(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow.withValues(
                  alpha: AppColors.isDark ? 0.16 : 0.09,
                ),
                blurRadius: AppColors.isDark ? 14 : 12,
                offset: Offset(0, AppColors.isDark ? 7 : 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline.copyWith(
                        fontSize: 16,
                        color: task.completed
                            ? AppColors.label.withValues(alpha: 0.7)
                            : AppColors.label,
                        fontWeight: FontWeight.w600,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.secondaryLabel.withValues(
                          alpha: 0.85,
                        ),
                        decorationThickness: task.completed ? 1.6 : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _HistoryBadge(
                          label: _importanceLabel(
                            task.importanceLevel,
                            language,
                          ),
                          style: badgeStyle,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _durationLabel(task.timeDuration, language),
                          style: AppTypography.caption1.copyWith(
                            fontSize: 11,
                            color: AppColors.tertiaryLabel.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                        if (task.completed && completedDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d').format(completedDate),
                            style: AppTypography.caption1.copyWith(
                              fontSize: 12,
                              color: AppColors.secondaryLabel.withValues(
                                alpha: 0.7,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onToggle,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.label.withValues(alpha: 0),
                    border: Border.all(
                      color: task.completed
                          ? AppColors.success
                          : AppColors.white.withValues(alpha: 0.12),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.check_mark,
                      size: 16,
                      color: task.completed
                          ? AppColors.success
                          : AppColors.white.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryBadgeStyle {
  final Color background;
  final Color border;
  final Color text;

  const _HistoryBadgeStyle({
    required this.background,
    required this.border,
    required this.text,
  });
}

class _HistoryBadge extends StatelessWidget {
  final String label;
  final _HistoryBadgeStyle style;

  const _HistoryBadge({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: style.text,
        ),
      ),
    );
  }
}

_HistoryBadgeStyle _historyBadgeStyle(String? raw) {
  final style = TaskImportanceTheme.badge(raw);
  return _HistoryBadgeStyle(
    background: style.background,
    border: style.border,
    text: style.text,
  );
}

class _TaskPalette {
  final Color border;
  final Color start;
  final Color end;
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeText;
  Color get glow => border.withValues(alpha: 0.45);

  const _TaskPalette({
    required this.border,
    required this.start,
    required this.end,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeText,
  });
}

class _DarkGlassAddButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _DarkGlassAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.topBarControlBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.topBarControlBorder, width: 1),
        ),
        child: Center(
          child: Icon(CupertinoIcons.add, color: AppColors.label, size: 20),
        ),
      ),
    );
  }
}

class _FloatingPrimaryAddTaskButton extends StatelessWidget {
  final String label;
  final Future<void> Function() onTap;

  const _FloatingPrimaryAddTaskButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sectionBackground, AppColors.cardBackgroundAlt],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStrong, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(
                alpha: AppColors.isDark ? 0.18 : 0.1,
              ),
              blurRadius: AppColors.isDark ? 16 : 12,
              offset: Offset(0, AppColors.isDark ? 8 : 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.add,
                size: 18,
                color: AppColors.secondaryLabel,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.callout.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onTap;

  const _PressScale({required this.child, this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  Future<void> _handleTap() async {
    final onTap = widget.onTap;
    if (onTap == null) return;
    await onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 1.01 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap == null ? null : _handleTap,
          child: widget.child,
        ),
      ),
    );
  }
}
