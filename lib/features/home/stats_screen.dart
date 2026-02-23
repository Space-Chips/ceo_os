import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/models/insights_models.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/repositories/habit_repository.dart';
import '../../core/repositories/insights_repository.dart';
import '../../core/repositories/task_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final InsightsRepository _insightsRepository = InsightsRepository();
  final TaskRepository _taskRepository = TaskRepository();
  final HabitRepository _habitRepository = HabitRepository();

  DashboardSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  List<ParetoTask> _topTasks = const [];
  List<CalendarEvent> _upcomingEvents = const [];
  List<Habit> _todayHabits = const [];
  List<Habit> _yesterdayHabits = const [];
  final Map<String, bool> _yesterdayStates = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isScheduled(Habit habit, DateTime date) {
    if (habit.isDaily) return true;
    if (habit.specificDays == null || habit.specificDays!.isEmpty) return true;
    final day = date.weekday % 7;
    return habit.specificDays!.contains(day);
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final snapshot = await _insightsRepository.getDashboardSnapshot();
      final allTasks = await _taskRepository.getTasks(includeCompleted: true);
      final allEvents = await _taskRepository.getAllEvents();
      final habits = await _habitRepository.getHabits();
      final yesterdayCompletions = await _habitRepository.getCompletionsForDate(
        yesterday,
      );

      final uncompletedTasks = allTasks.where((t) => !t.completed).toList()
        ..sort((a, b) => _taskScore(b).compareTo(_taskScore(a)));

      final upcoming =
          allEvents.where((event) {
            final dateText = event.eventDate;
            final timeText = event.eventTime;
            if (dateText == null || dateText.isEmpty) return false;
            final parts = dateText.split('-');
            if (parts.length != 3) return false;
            final year = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final day = int.tryParse(parts[2]);
            if (year == null || month == null || day == null) return false;

            var eventDateTime = DateTime(year, month, day, 23, 59);
            if (timeText != null && timeText.isNotEmpty) {
              final clean = timeText.split(':');
              if (clean.length >= 2) {
                final h = int.tryParse(clean[0]) ?? 0;
                final m = int.tryParse(clean[1]) ?? 0;
                eventDateTime = DateTime(year, month, day, h, m);
              }
            }
            return eventDateTime.isAfter(now);
          }).toList()..sort((a, b) {
            final aKey = '${a.eventDate ?? ''} ${a.eventTime ?? '23:59'}';
            final bKey = '${b.eventDate ?? ''} ${b.eventTime ?? '23:59'}';
            return aKey.compareTo(bKey);
          });

      final yesterdayMap = {
        for (final c in yesterdayCompletions) c.habitId: c.completed,
      };

      final todayHabits = habits.where((h) => _isScheduled(h, today)).toList();
      final yesterdayHabits = habits
          .where((h) => _isScheduled(h, yesterday))
          .toList();

      _yesterdayStates
        ..clear()
        ..addEntries(
          yesterdayHabits.map(
            (h) => MapEntry(h.id, yesterdayMap[h.id] ?? false),
          ),
        );

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _topTasks = uncompletedTasks.take(3).toList();
        _upcomingEvents = upcoming.take(5).toList();
        _todayHabits = todayHabits;
        _yesterdayHabits = yesterdayHabits;
        _error = null;
        _loading = false;
      });

      if (mounted) {
        await context.read<HabitProvider>().loadData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmYesterday() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final provider = context.read<HabitProvider>();

    for (final habit in _yesterdayHabits) {
      await provider.setHabitCompletionForDate(
        habitId: habit.id,
        date: yesterday,
        completed: _yesterdayStates[habit.id] ?? false,
        state: 'validated',
      );
    }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(
        child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
      );
    } else if (_snapshot == null) {
      body = Center(
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dashboard unavailable',
                style: AppTypography.mono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: AppTypography.mono.copyWith(
                  fontSize: 10,
                  color: AppColors.tertiaryLabel,
                ),
              ),
              const SizedBox(height: 12),
              LiquidButton(label: 'RETRY', onPressed: _load),
            ],
          ),
        ),
      );
    } else {
      body = SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              child: Row(
                children: [
                  _metric('Score', '${_snapshot!.productivityScore}'),
                  _metric(
                    'Rank',
                    '${_snapshot!.rankName} L${_snapshot!.rankLevel}',
                  ),
                  _metric('Top %', '${_snapshot!.percentile}'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_yesterdayHabits.isNotEmpty)
              GlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.28),
                  width: 0.6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Yesterday Validation'),
                    const SizedBox(height: 10),
                    ..._yesterdayHabits.map(
                      (habit) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _yesterdayStates[habit.id] =
                                !(_yesterdayStates[habit.id] ?? false);
                          }),
                          child: Row(
                            children: [
                              Icon(
                                (_yesterdayStates[habit.id] ?? false)
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                size: 16,
                                color: (_yesterdayStates[habit.id] ?? false)
                                    ? AppColors.success
                                    : AppColors.tertiaryLabel,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  habit.title,
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 11,
                                    color: AppColors.secondaryLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LiquidButton(
                      label: 'CONFIRM_YESTERDAY',
                      fullWidth: true,
                      onPressed: _confirmYesterday,
                    ),
                  ],
                ),
              ),
            if (_yesterdayHabits.isNotEmpty) const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('Habits for Today'),
                  const SizedBox(height: 10),
                  if (_todayHabits.isEmpty)
                    Text(
                      'No habits scheduled today.',
                      style: AppTypography.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.tertiaryLabel,
                      ),
                    )
                  else
                    ..._todayHabits.map((habit) {
                      final completed = context
                          .read<HabitProvider>()
                          .isHabitCompletedToday(habit.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              completed
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              size: 16,
                              color: completed
                                  ? AppColors.success
                                  : AppColors.tertiaryLabel,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                habit.title,
                                style: AppTypography.mono.copyWith(
                                  fontSize: 11,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('Top Tasks'),
                  const SizedBox(height: 10),
                  if (_topTasks.isEmpty)
                    Text(
                      'No open tasks.',
                      style: AppTypography.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.tertiaryLabel,
                      ),
                    )
                  else
                    ..._topTasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '${_taskScore(task)}',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: AppTypography.mono.copyWith(
                                  fontSize: 11,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('Upcoming Events'),
                  const SizedBox(height: 10),
                  if (_upcomingEvents.isEmpty)
                    Text(
                      'No upcoming events.',
                      style: AppTypography.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.tertiaryLabel,
                      ),
                    )
                  else
                    ..._upcomingEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              event.eventTime ?? '--:--',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.title,
                                style: AppTypography.mono.copyWith(
                                  fontSize: 11,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                            ),
                            Text(
                              event.eventDate ?? '',
                              style: AppTypography.mono.copyWith(
                                fontSize: 9,
                                color: AppColors.tertiaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('Indexes'),
                  const SizedBox(height: 10),
                  _kv(
                    'Task completion index',
                    '${(_snapshot!.taskCompletionRate * 100).round()}%',
                  ),
                  _kv(
                    'Habit completion index',
                    '${(_snapshot!.habitCompletionRate * 100).round()}%',
                  ),
                  _kv(
                    'Execution load',
                    '${_snapshot!.totalFocusMinutes7d}m / 7d',
                  ),
                  _kv(
                    'Planning index',
                    '${_snapshot!.eventsNext7d} scheduled events',
                  ),
                  _kv(
                    'Consistency index',
                    '${_snapshot!.currentHabitStreak} day streak',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
          'DASHBOARD',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _load,
          child: const Icon(
            CupertinoIcons.refresh,
            color: AppColors.primaryOrange,
            size: 19,
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: body,
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
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.mono.copyWith(
        fontSize: 11,
        color: AppColors.primaryOrange,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
