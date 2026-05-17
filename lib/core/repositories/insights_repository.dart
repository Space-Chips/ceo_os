import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/apple_review_compliance.dart';
import '../models/insights_models.dart';
import '../config/apple_review_compliance.dart';
import '../services/supabase_service.dart';
import '../utils/app_logger.dart';

class InsightsRepository {
  final SupabaseService _supabaseService;

  InsightsRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  bool _isMissingFieldError(PostgrestException error, List<String> fields) {
    return error.code == 'PGRST204' ||
        error.code == '42703' ||
        fields.any((field) => error.message.contains(field));
  }

  Future<List<Map<String, dynamic>>> _selectTasks(String fields) async {
    final response = await _client
        .from('pareto_tasks')
        .select(fields)
        .eq('created_by', _currentUserId);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchTasksForSnapshot() async {
    try {
      return await _selectTasks(
        'id, completed, deadline, created_at, importance_level, time_duration, duration_minutes',
      );
    } on PostgrestException catch (e) {
      if (!_isMissingFieldError(e, [
        'deadline',
        'importance_level',
        'time_duration',
        'duration_minutes',
      ])) {
        rethrow;
      }
      try {
        return await _selectTasks(
          'id, completed, created_at, importance_level, time_duration, duration_minutes',
        );
      } on PostgrestException catch (fallbackError) {
        if (!_isMissingFieldError(fallbackError, [
          'importance_level',
          'time_duration',
          'duration_minutes',
        ])) {
          rethrow;
        }
        try {
          return await _selectTasks('id, completed, deadline, created_at');
        } on PostgrestException catch (basicError) {
          if (!_isMissingFieldError(basicError, ['deadline'])) rethrow;
          return _selectTasks('id, completed, created_at');
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchOptionalAdvancedDaily(String today) async {
    try {
      final response = await _client
          .from('advanced_daily_stats')
          .select(
            'attention_score, deep_work_time_minutes, focus_sessions_completed, focus_sessions_broken, ceo_sessions_broken, distractions_blocked, time_recovered_minutes',
          )
          .eq('created_by', _currentUserId)
          .eq('date', today)
          .maybeSingle();
      return response == null ? null : Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('advanced_daily_stats') || e.code == '42P01') {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchOptionalAdvancedLifetime() async {
    if (!AppleReviewCompliance.allowAdvancedStats) {
      return null;
    }
    try {
      final response = await _client
          .from('advanced_lifetime_stats')
          .select('highest_streak_ever')
          .eq('created_by', _currentUserId)
          .maybeSingle();
      return response == null ? null : Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('advanced_lifetime_stats') || e.code == '42P01') {
        return null;
      }
      rethrow;
    }
  }

  int _estimatedTaskMinutes(Map<String, dynamic> task) {
    final minutes = (task['duration_minutes'] as num?)?.toInt();
    if (minutes != null && minutes > 0) return minutes;
    final raw = (task['time_duration'] as String?)?.trim().toLowerCase();
    switch (raw) {
      case '30 min':
      case '30m':
        return 30;
      case '45 min':
      case '45m':
        return 45;
      case '1 hour':
      case '1h':
      case '1 hr':
        return 60;
      case '1.5 hours':
      case '1.5h':
      case '90 min':
        return 90;
      case '2 hours':
      case '2h':
        return 120;
      case 'half day':
        return 240;
      case 'full day':
        return 480;
      case 'several days':
        return 960;
      default:
        return 0;
    }
  }

  Future<DashboardSnapshot> getDashboardSnapshot() async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final weekAgo = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(const Duration(days: 6)));
      final nextWeek = DateFormat(
        'yyyy-MM-dd',
      ).format(now.add(const Duration(days: 7)));

      final tasks = await _fetchTasksForSnapshot();

      final habitsFuture = _client
          .from('habits')
          .select('id')
          .eq('created_by', _currentUserId)
          .eq('archived', false);

      final habitCompletionsTodayFuture = _client
          .from('habit_completions')
          .select('id, habit_id, completed')
          .eq('created_by', _currentUserId)
          .eq('date', today)
          .eq('completed', true);

      final habitCompletionsRangeFuture = _client
          .from('habit_completions')
          .select('date, completed')
          .eq('created_by', _currentUserId)
          .eq('completed', true)
          .gte('date', weekAgo)
          .lte('date', today)
          .order('date', ascending: false);

      final focusFuture = _client
          .from('focus_sessions')
          .select('duration_minutes, completed, start_time')
          .eq('created_by', _currentUserId)
          .eq('completed', true)
          .gte(
            'start_time',
            now.subtract(const Duration(days: 7)).toIso8601String(),
          );

      final eventsFuture = _client
          .from('calendar_events')
          .select('id, event_date')
          .eq('created_by', _currentUserId)
          .gte('event_date', today)
          .lte('event_date', nextWeek);

      final rankFuture = _client
          .from('user_ranks')
          .select('rank_level, rank_name, total_rank_points')
          .eq('created_by', _currentUserId)
          .maybeSingle();

      final Future<dynamic> percentileFuture =
          AppleReviewCompliance.allowSocialScreenTimeSurfaces
          ? _client
                .from('leaderboard_entries')
                .select('percentile')
                .eq('created_by', _currentUserId)
                .maybeSingle()
          : Future.value(null);

      final results = await Future.wait<dynamic>([
        habitsFuture,
        habitCompletionsTodayFuture,
        habitCompletionsRangeFuture,
        focusFuture,
        eventsFuture,
        rankFuture,
        percentileFuture,
        _fetchOptionalAdvancedDaily(today),
        _fetchOptionalAdvancedLifetime(),
      ]);

      final habits = (results[0] as List).cast<Map<String, dynamic>>();
      final habitCompletionsToday = (results[1] as List)
          .cast<Map<String, dynamic>>();
      final habitCompletionsRange = (results[2] as List)
          .cast<Map<String, dynamic>>();
      final focusSessions = (results[3] as List).cast<Map<String, dynamic>>();
      final events = (results[4] as List).cast<Map<String, dynamic>>();
      final rank = results[5] as Map<String, dynamic>?;
      final percentile = results[6] as Map<String, dynamic>?;
      final advancedDaily = results[7] as Map<String, dynamic>?;
      final advancedLifetime = results[8] as Map<String, dynamic>?;

      final completedTasks = tasks
          .where((t) => (t['completed'] as bool?) ?? false)
          .length;
      final crucialTasks = tasks.where(
        (t) => ((t['importance_level'] as String?) ?? '').toLowerCase() == 'crucial',
      );
      final crucialTasksCompleted = crucialTasks.where(
        (t) => (t['completed'] as bool?) ?? false,
      ).length;
      final estimatedTaskMinutesPlanned = tasks.fold<int>(
        0,
        (sum, task) => sum + _estimatedTaskMinutes(task),
      );
      final estimatedTaskMinutesCompleted = tasks
          .where((t) => (t['completed'] as bool?) ?? false)
          .fold<int>(0, (sum, task) => sum + _estimatedTaskMinutes(task));

      int tasksDueToday = 0;
      int overdueTasks = 0;
      for (final task in tasks) {
        final rawDeadline = task['deadline'];
        if (rawDeadline == null) continue;
        final deadline = DateTime.tryParse(rawDeadline.toString());
        if (deadline == null) continue;
        final taskDay = DateTime(deadline.year, deadline.month, deadline.day);
        final todayDay = DateTime(now.year, now.month, now.day);
        if (taskDay == todayDay) tasksDueToday++;
        if (taskDay.isBefore(todayDay) &&
            !((task['completed'] as bool?) ?? false)) {
          overdueTasks++;
        }
      }

      final focusMinutes = focusSessions.fold<int>(
        0,
        (sum, s) => sum + ((s['duration_minutes'] as num?)?.toInt() ?? 0),
      );

      final streak = _calculateStreak(
        habitCompletionsRange
            .map((e) => e['date']?.toString())
            .whereType<String>()
            .toSet(),
        today,
      );
      final activeHabitDays = habitCompletionsRange
          .map((e) => e['date']?.toString())
          .whereType<String>()
          .toSet()
          .length;
      final weeklyHabitCompletionRate = habits.isEmpty
          ? 0.0
          : (habitCompletionsRange.length / (habits.length * 7)).clamp(0, 1)
              .toDouble();

      return DashboardSnapshot(
        totalTasks: tasks.length,
        completedTasks: completedTasks,
        crucialTasksTotal: crucialTasks.length,
        crucialTasksCompleted: crucialTasksCompleted,
        estimatedTaskMinutesPlanned: estimatedTaskMinutesPlanned,
        estimatedTaskMinutesCompleted: estimatedTaskMinutesCompleted,
        tasksDueToday: tasksDueToday,
        overdueTasks: overdueTasks,
        totalHabits: habits.length,
        habitsCompletedToday: habitCompletionsToday.length,
        weeklyHabitCompletionRate: weeklyHabitCompletionRate,
        activeHabitDays: activeHabitDays,
        currentHabitStreak: streak,
        bestHabitStreak: (advancedLifetime?['highest_streak_ever'] as num?)?.toInt() ?? streak,
        totalFocusMinutes7d: focusMinutes,
        focusSessions7d: focusSessions.length,
        attentionScoreToday: (advancedDaily?['attention_score'] as num?)?.toInt() ?? 0,
        deepWorkMinutesToday: (advancedDaily?['deep_work_time_minutes'] as num?)?.toInt() ?? 0,
        focusSessionsCompletedToday:
            (advancedDaily?['focus_sessions_completed'] as num?)?.toInt() ?? 0,
        earlyExitsToday:
            ((advancedDaily?['focus_sessions_broken'] as num?)?.toInt() ?? 0) +
            ((advancedDaily?['ceo_sessions_broken'] as num?)?.toInt() ?? 0),
        distractionsBlockedToday:
            (advancedDaily?['distractions_blocked'] as num?)?.toInt() ?? 0,
        recoveredTimeMinutesToday:
            (advancedDaily?['time_recovered_minutes'] as num?)?.toInt() ?? 0,
        eventsNext7d: events.length,
        rankLevel: (rank?['rank_level'] as num?)?.toInt() ?? 0,
        rankName: (rank?['rank_name'] as String?) ?? 'Asleep',
        rankPoints: (rank?['total_rank_points'] as num?)?.toInt() ?? 0,
        percentile: (percentile?['percentile'] as num?)?.toInt() ?? 0,
        insights: [],
      );
    } catch (e) {
      AppLogger.error('Error building dashboard snapshot.', e);
      return const DashboardSnapshot(
        totalTasks: 0,
        completedTasks: 0,
        crucialTasksTotal: 0,
        crucialTasksCompleted: 0,
        estimatedTaskMinutesPlanned: 0,
        estimatedTaskMinutesCompleted: 0,
        tasksDueToday: 0,
        overdueTasks: 0,
        totalHabits: 0,
        habitsCompletedToday: 0,
        weeklyHabitCompletionRate: 0,
        activeHabitDays: 0,
        currentHabitStreak: 0,
        bestHabitStreak: 0,
        totalFocusMinutes7d: 0,
        focusSessions7d: 0,
        attentionScoreToday: 0,
        deepWorkMinutesToday: 0,
        focusSessionsCompletedToday: 0,
        earlyExitsToday: 0,
        distractionsBlockedToday: 0,
        recoveredTimeMinutesToday: 0,
        eventsNext7d: 0,
        rankLevel: 0,
        rankName: 'Asleep',
        rankPoints: 0,
        percentile: 0,
        insights: [],
      );
    }
  }

  int _calculateStreak(Set<String> completedDates, String today) {
    if (completedDates.isEmpty) return 0;
    var cursor = DateTime.parse(today);
    var streak = 0;

    while (true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(cursor);
      if (!completedDates.contains(dateStr)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
