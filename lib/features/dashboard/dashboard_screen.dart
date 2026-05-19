import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/repositories/habit_repository.dart';
import '../../core/repositories/insights_repository.dart';
import '../../core/repositories/task_repository.dart';
import '../../core/services/performance_score_service.dart';
import '../../core/services/stats_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../tasks/task_importance_theme.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressScale({required this.child, this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
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
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  final HabitRepository _habitRepository = HabitRepository();
  final InsightsRepository _insightsRepository = InsightsRepository();
  final StatsEngine _statsEngine = StatsEngine.instance;
  HabitProvider? _habitProvider;
  TaskProvider? _taskProvider;
  Timer? _refreshDebounce;

  bool _loading = true;
  String? _error;
  int _wakeScore = 0;

  List<ParetoTask> _topTasks = const [];
  List<CalendarEvent> _todayEvents = const [];
  List<Habit> _todayHabits = const [];
  List<Habit> _yesterdayHabits = const [];
  final Map<String, bool> _yesterdayStates = {};
  final Set<String> _todayHabitMarks = <String>{};

  bool _isConfirmingYesterday = false;

  String _t(String key) => context.read<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final habitProvider = context.read<HabitProvider>();
    final taskProvider = context.read<TaskProvider>();

    if (!identical(_habitProvider, habitProvider)) {
      _habitProvider?.removeListener(_handleSourceDataChanged);
      _habitProvider = habitProvider;
      _habitProvider?.addListener(_handleSourceDataChanged);
    }

    if (!identical(_taskProvider, taskProvider)) {
      _taskProvider?.removeListener(_handleSourceDataChanged);
      _taskProvider = taskProvider;
      _taskProvider?.addListener(_handleSourceDataChanged);
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _habitProvider?.removeListener(_handleSourceDataChanged);
    _taskProvider?.removeListener(_handleSourceDataChanged);
    super.dispose();
  }

  void _handleSourceDataChanged() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      unawaited(_load());
    });
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  int _habitWeekday(DateTime value) =>
      value.weekday == DateTime.sunday ? 7 : value.weekday;

  String _dateKey(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  String _todayMarksStorageKey(DateTime today) =>
      'dashboard_today_habit_marks_${_dateKey(today)}';

  bool _isScheduled(Habit habit, DateTime day) {
    if (habit.isDaily) return true;
    final specificDays = habit.specificDays;
    if (specificDays == null || specificDays.isEmpty) return true;
    return specificDays.contains(_habitWeekday(day));
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

  int _taskScore(ParetoTask task) =>
      (_importanceWeight(task.importanceLevel) * 10) +
      _timeWeight(task.timeDuration);

  String _importanceLabel(String? raw) {
    return TaskImportanceTheme.dashboardLabel(raw);
  }

  Color _importanceColor(String? raw) {
    return TaskImportanceTheme.badge(raw).text;
  }

  String _durationLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'less_than_30min':
      case '15m':
      case '30m':
        return _t('dashboard_duration_30m');
      case '1_hour':
      case '1h':
        return _t('dashboard_duration_1h');
      case '2_hours':
      case '2h':
        return _t('dashboard_duration_2h');
      case 'half_day':
        return _t('dashboard_duration_half_day');
      case '1_day':
        return _t('dashboard_duration_1_day');
      case 'several_days':
      case '4h+':
        return _t('dashboard_duration_several_days');
      default:
        return _t('dashboard_duration_1h');
    }
  }

  DateTime? _parseEventDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return _dateOnly(parsed);

    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  int _eventTimeSortKey(String? raw) {
    if (raw == null || raw.isEmpty) return 24 * 60;
    final parts = raw.split(':');
    if (parts.length < 2) return 24 * 60;
    final hour = int.tryParse(parts[0]) ?? 24;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  String _eventTimeLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = (int.tryParse(parts[0]) ?? 0).toString().padLeft(2, '0');
    final minute = (int.tryParse(parts[1]) ?? 0).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _persistTodayMarks(DateTime today) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _todayMarksStorageKey(today),
      _todayHabitMarks.toList(),
    );
  }

  Future<void> _toggleTodayHabitMark(String habitId) async {
    final today = _dateOnly(DateTime.now());
    setState(() {
      if (_todayHabitMarks.contains(habitId)) {
        _todayHabitMarks.remove(habitId);
      } else {
        _todayHabitMarks.add(habitId);
      }
    });
    await _persistTodayMarks(today);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final now = DateTime.now();
      final today = _dateOnly(now);
      final yesterday = today.subtract(const Duration(days: 1));

      int wakeScore = _wakeScore;
      try {
        final statsSnapshot = await _statsEngine.buildSnapshot(now: now);
        final dashboardSnapshot = await _insightsRepository
            .getDashboardSnapshot();
        final bundle = PerformanceScoreService.build(
          dashboard: dashboardSnapshot,
          daily: statsSnapshot.daily,
          weekly: statsSnapshot.weekly,
          lifetime: statsSnapshot.lifetime,
        );
        wakeScore = bundle.wake.score;
      } catch (_) {}

      final results = await Future.wait([
        _taskRepository.getTasks(includeCompleted: true),
        _taskRepository.getAllEvents(),
        _habitRepository.getHabits(),
        _habitRepository.getCompletionsForDate(yesterday),
      ]);

      final allTasks = results[0] as List<ParetoTask>;
      final allEvents = results[1] as List<CalendarEvent>;
      final allHabits = results[2] as List<Habit>;
      final yesterdayCompletions = results[3] as List<HabitCompletion>;

      final openTasks = allTasks.where((t) => !t.completed).toList()
        ..sort((a, b) => _taskScore(b).compareTo(_taskScore(a)));

      final todayEvents =
          allEvents.where((event) {
            final eventDay = _parseEventDate(event.eventDate);
            if (eventDay == null) return false;
            return eventDay == today;
          }).toList()..sort((a, b) {
            final byTime = _eventTimeSortKey(
              a.eventTime,
            ).compareTo(_eventTimeSortKey(b.eventTime));
            if (byTime != 0) return byTime;
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });

      final yesterdayCompletionMap = {
        for (final item in yesterdayCompletions) item.habitId: item,
      };

      final todayHabits = allHabits.where((habit) {
        final created = _dateOnly(habit.createdAt);
        if (created.isAfter(today)) return false;
        return _isScheduled(habit, today);
      }).toList();

      final unresolvedYesterday = allHabits.where((habit) {
        final created = _dateOnly(habit.createdAt);
        if (created.isAfter(yesterday)) return false;
        if (!_isScheduled(habit, yesterday)) return false;
        return yesterdayCompletionMap[habit.id] == null;
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_todayMarksStorageKey(today)) ?? [];
      final restoredMarks = stored.toSet()
        ..retainWhere((id) => todayHabits.any((habit) => habit.id == id));

      if (!mounted) return;
      setState(() {
        _topTasks = openTasks.take(3).toList();
        _todayEvents = todayEvents;
        _todayHabits = todayHabits;
        _yesterdayHabits = unresolvedYesterday;
        _yesterdayStates
          ..clear()
          ..addEntries(
            unresolvedYesterday.map((habit) => MapEntry(habit.id, false)),
          );
        _todayHabitMarks
          ..clear()
          ..addAll(restoredMarks);
        _wakeScore = wakeScore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmYesterday() async {
    if (_isConfirmingYesterday || _yesterdayHabits.isEmpty) return;
    final provider = context.read<HabitProvider>();
    final yesterday = _dateOnly(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    setState(() => _isConfirmingYesterday = true);

    try {
      for (final habit in _yesterdayHabits) {
        await provider.setHabitCompletionForDate(
          habitId: habit.id,
          date: yesterday,
          completed: _yesterdayStates[habit.id] ?? false,
          state: 'validated',
        );
      }
      await _load();
    } finally {
      if (mounted) {
        setState(() => _isConfirmingYesterday = false);
      }
    }
  }

  Future<void> _completeTask(ParetoTask task) async {
    await context.read<TaskProvider>().completeTask(task.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.92, -0.96),
                      radius: 0.44,
                      colors: [
                        const Color(0xFF5078FF).withValues(alpha: 0.12),
                        CupertinoColors.transparent,
                      ],
                      stops: const [0, 1],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(),
                    const SizedBox(height: 12),
                    Text(
                      _t('dashboard_control_center'),
                      style: AppTypography.largeTitle.copyWith(
                        fontSize: 42,
                        height: 0.95,
                        letterSpacing: -1.4,
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_error != null &&
        _topTasks.isEmpty &&
        _todayHabits.isEmpty &&
        _todayEvents.isEmpty &&
        _yesterdayHabits.isEmpty) {
      return Center(
        child: _PressScale(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _panelDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('dashboard_unavailable'),
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption1.copyWith(
                    fontSize: 11,
                    color: AppColors.tertiaryLabel,
                  ),
                ),
                const SizedBox(height: 12),
                LiquidButton(
                  label: _t('retry'),
                  onPressed: _load,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _wakeScoreCard(),
        const SizedBox(height: 18),
        if (_yesterdayHabits.isNotEmpty) ...[
          _yesterdayValidationCard(),
          const SizedBox(height: 18),
        ],
        _prioritiesCard(),
        const SizedBox(height: 18),
        _todayHabitsCard(),
        const SizedBox(height: 18),
        _todayScheduleCard(),
      ],
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () => context.go('/home'),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.arrow_left,
                size: 21,
                color: AppColors.secondaryLabel,
              ),
              const SizedBox(width: 6),
              Text(
                _t('home'),
                style: AppTypography.subhead.copyWith(
                  fontSize: 14,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _load,
          child: Icon(
            CupertinoIcons.refresh,
            size: 18,
            color: AppColors.tertiaryLabel,
          ),
        ),
      ],
    );
  }

  Widget _attentionScoreCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: _panelDecoration(
        accentColor: AppColors.accent.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Attention Score',
            style: AppTypography.title3.copyWith(
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_attentionScore',
            style: AppTypography.heroNumber.copyWith(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
        ],
      ),
    );
  }

  int get _attentionScore => _wakeScore;

  Widget _wakeScoreCard() => _attentionScoreCard();

  Widget _yesterdayValidationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(
        accentColor: AppColors.primaryOrange.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habits from yesterday',
            style: AppTypography.title2.copyWith(
              fontSize: 25,
              color: const Color(0xFFFFE0BC),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t('dashboard_complete_validation_to_continue'),
            style: AppTypography.callout.copyWith(
              fontSize: 14,
              color: AppColors.primaryOrange.withValues(alpha: 0.84),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ..._yesterdayHabits.map(
            (habit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _isConfirmingYesterday
                    ? null
                    : () => setState(() {
                        _yesterdayStates[habit.id] =
                            !(_yesterdayStates[habit.id] ?? false);
                      }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF161616),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.07),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (_yesterdayStates[habit.id] ?? false)
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        size: 24,
                        color: (_yesterdayStates[habit.id] ?? false)
                            ? const Color(0xFF3B82F6)
                            : AppColors.tertiaryLabel,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          habit.title,
                          style: AppTypography.headline.copyWith(
                            fontSize: 17,
                            color: AppColors.label,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          LiquidButton(
            label: _isConfirmingYesterday
                ? _t('dashboard_confirming')
                : _t('dashboard_confirm'),
            fullWidth: true,
            isLoading: _isConfirmingYesterday,
            icon: CupertinoIcons.check_mark,
            gradient: const [Color(0xFF3C82FF), Color(0xFF3262E3)],
            onPressed: _confirmYesterday,
          ),
        ],
      ),
    );
  }

  Widget _prioritiesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: _t('tasks_your_priorities'),
            onViewAll: () => context.push('/tasks'),
          ),
          const SizedBox(height: 10),
          if (_topTasks.isEmpty)
            Text(
              'No open tasks.',
              style: AppTypography.subhead.copyWith(
                fontSize: 12,
                color: AppColors.tertiaryLabel,
              ),
            )
          else
            ..._topTasks.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final task = entry.value;
              final levelColor = _importanceColor(task.importanceLevel);
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: GestureDetector(
                  onTap: () => _completeTask(task),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.floatingGlassGradient.first.withValues(
                            alpha: 0.88,
                          ),
                          AppColors.floatingGlassGradient.last.withValues(
                            alpha: 0.78,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.glassBorder.withValues(alpha: 0.76),
                        width: 0.74,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: AppColors.background.withValues(alpha: 0.55),
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: AppTypography.mono.copyWith(
                                fontSize: 20,
                                color: AppColors.tertiaryLabel,
                                fontWeight: FontWeight.w900,
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
                                  fontSize: 16,
                                  color: AppColors.label,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(9),
                                      color: levelColor.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color: levelColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        width: 0.7,
                                      ),
                                    ),
                                    child: Text(
                                      _importanceLabel(task.importanceLevel),
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 11,
                                        color: levelColor,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _durationLabel(task.timeDuration),
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 11,
                                      color: AppColors.tertiaryLabel,
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
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _todayHabitsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      level: GlassCardLevel.standard,
      showEdgeGlow: true,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.8),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Habits for today',
            trailingIcon: CupertinoIcons.add,
            onTrailingTap: () => context.push('/habits'),
          ),
          const SizedBox(height: 10),
          if (_todayHabits.isEmpty)
            Text(
              'No habits scheduled today.',
              style: AppTypography.subhead.copyWith(
                fontSize: 12,
                color: AppColors.tertiaryLabel,
              ),
            )
          else
            ..._todayHabits.asMap().entries.map((entry) {
              final habit = entry.value;
              final index = entry.key + 1;
              final marked = _todayHabitMarks.contains(habit.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _toggleTodayHabitMark(habit.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: marked
                            ? [
                                AppColors.floatingGlassGradient.first
                                    .withValues(alpha: 0.52),
                                AppColors.floatingGlassGradient.last.withValues(
                                  alpha: 0.44,
                                ),
                              ]
                            : [
                                AppColors.floatingGlassGradient.first
                                    .withValues(alpha: 0.9),
                                AppColors.floatingGlassGradient.last.withValues(
                                  alpha: 0.78,
                                ),
                              ],
                      ),
                      border: Border.all(
                        color: marked
                            ? AppColors.glassBorder.withValues(alpha: 0.42)
                            : AppColors.glassBorder.withValues(alpha: 0.75),
                        width: 0.7,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headline.copyWith(
                              fontSize: 17,
                              color: marked
                                  ? AppColors.tertiaryLabel
                                  : AppColors.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.white.withValues(alpha: 0.05),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: AppTypography.footnote.copyWith(
                                fontSize: 15,
                                color: marked
                                    ? AppColors.tertiaryLabel
                                    : AppColors.secondaryLabel,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _todayScheduleCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      level: GlassCardLevel.standard,
      showEdgeGlow: true,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.8),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Schedule',
            onViewAll: () => context.push('/calendar'),
          ),
          const SizedBox(height: 10),
          if (_todayEvents.isEmpty)
            Text(
              'No events scheduled today.',
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                color: AppColors.tertiaryLabel,
              ),
            )
          else
            ..._todayEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [Color(0xFF1A1A1A), Color(0xFF111111)],
                    ),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.background.withValues(alpha: 0.56),
                        ),
                        child: Text(
                          _eventTimeLabel(event.eventTime),
                          style: AppTypography.callout.copyWith(
                            fontSize: 14,
                            color: AppColors.secondaryLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline.copyWith(
                            fontSize: 16,
                            color: AppColors.label,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    VoidCallback? onViewAll,
    IconData? trailingIcon,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTypography.overline.copyWith(
              fontSize: 14,
              letterSpacing: 1.2,
              color: AppColors.label.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onViewAll != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onViewAll,
            child: Text(
              '${_t('dashboard_view_all')} >',
              style: AppTypography.callout.copyWith(
                fontSize: 13,
                color: AppColors.secondaryLabel.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (trailingIcon != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onTrailingTap,
            child: Icon(trailingIcon, size: 24, color: AppColors.tertiaryLabel),
          ),
      ],
    );
  }

  BoxDecoration _panelDecoration({Color? accentColor}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cardBackgroundStrong, AppColors.cardBase],
      ),
      border: Border.all(color: AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: AppColors.glassShadow.withValues(alpha: 0.3),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        if (accentColor != null)
          BoxShadow(
            color: accentColor,
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: -20,
          ),
      ],
    );
  }
}

class _PriorityBadgeStyle {
  final Color background;
  final Color border;
  final Color text;
  final Color glow;

  const _PriorityBadgeStyle({
    required this.background,
    required this.border,
    required this.text,
    required this.glow,
  });
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final _PriorityBadgeStyle style;

  const _PriorityBadge({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: style.background,
        border: Border.all(color: style.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: style.glow,
            blurRadius: 10,
            offset: const Offset(0, 0),
            spreadRadius: -7,
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          fontSize: 11,
          color: style.text,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

_PriorityBadgeStyle _priorityBadgeStyle(String? raw) {
  final style = TaskImportanceTheme.badge(raw);
  return _PriorityBadgeStyle(
    background: style.background,
    border: style.border,
    text: style.text,
    glow: style.glow,
  );
}
