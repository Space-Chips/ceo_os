import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/insights_models.dart';
import '../services/supabase_service.dart';

class InsightsRepository {
  final SupabaseService _supabaseService;

  InsightsRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> _fetchTasksForSnapshot() async {
    try {
      final response = await _client
          .from('pareto_tasks')
          .select('id, completed, deadline, created_at')
          .eq('created_by', _currentUserId);
      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      final missingDeadline =
          e.code == 'PGRST204' ||
          e.code == '42703' ||
          e.message.contains('deadline');
      if (!missingDeadline) rethrow;
      final response = await _client
          .from('pareto_tasks')
          .select('id, completed, created_at')
          .eq('created_by', _currentUserId);
      return (response as List).cast<Map<String, dynamic>>();
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

      final percentileFuture = _client
          .from('leaderboard_entries')
          .select('percentile')
          .eq('created_by', _currentUserId)
          .maybeSingle();

      final results = await Future.wait<dynamic>([
        habitsFuture,
        habitCompletionsTodayFuture,
        habitCompletionsRangeFuture,
        focusFuture,
        eventsFuture,
        rankFuture,
        percentileFuture,
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

      final completedTasks = tasks
          .where((t) => (t['completed'] as bool?) ?? false)
          .length;

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

      return DashboardSnapshot(
        totalTasks: tasks.length,
        completedTasks: completedTasks,
        tasksDueToday: tasksDueToday,
        overdueTasks: overdueTasks,
        totalHabits: habits.length,
        habitsCompletedToday: habitCompletionsToday.length,
        currentHabitStreak: streak,
        totalFocusMinutes7d: focusMinutes,
        focusSessions7d: focusSessions.length,
        eventsNext7d: events.length,
        rankLevel: (rank?['rank_level'] as num?)?.toInt() ?? 1,
        rankName: (rank?['rank_name'] as String?) ?? 'Starter',
        rankPoints: (rank?['total_rank_points'] as num?)?.toInt() ?? 0,
        percentile: (percentile?['percentile'] as num?)?.toInt() ?? 0,
        insights: const [],
      );
    } catch (e) {
      print('Error building dashboard snapshot: $e');
      return const DashboardSnapshot(
        totalTasks: 0,
        completedTasks: 0,
        tasksDueToday: 0,
        overdueTasks: 0,
        totalHabits: 0,
        habitsCompletedToday: 0,
        currentHabitStreak: 0,
        totalFocusMinutes7d: 0,
        focusSessions7d: 0,
        eventsNext7d: 0,
        rankLevel: 1,
        rankName: 'Starter',
        rankPoints: 0,
        percentile: 0,
        insights: const [],
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

  List<String> _buildInsights({
    required double taskCompletionRate,
    required double habitCompletionRate,
    required int focusMinutes7d,
    required int tasksDueToday,
    required int overdueTasks,
    required int eventsNext7d,
    required int currentStreak,
  }) {
    final insights = <String>[];

    if (overdueTasks > 0) {
      insights.add(
        'You have $overdueTasks overdue tasks. Clear 1 today to reduce drag.',
      );
    }

    if (tasksDueToday > 0) {
      insights.add(
        '$tasksDueToday tasks are due today. Prioritize Critical and High first.',
      );
    }

    if (focusMinutes7d < 150) {
      insights.add(
        'Deep work is low this week. Schedule at least two 45-minute focus blocks.',
      );
    } else {
      insights.add(
        'Great focus consistency: ${(focusMinutes7d / 60).toStringAsFixed(1)}h in 7 days.',
      );
    }

    if (habitCompletionRate < 0.6) {
      insights.add(
        'Habit adherence is below 60%. Reduce active habits or set easier targets.',
      );
    } else {
      insights.add(
        'Habit adherence is strong today. Keep the streak alive before evening.',
      );
    }

    if (taskCompletionRate >= 0.8) {
      insights.add(
        'Excellent task execution. You are operating at high throughput.',
      );
    }

    if (eventsNext7d == 0) {
      insights.add(
        'No calendar plan for the next 7 days. Add deadlines and focus blocks.',
      );
    }

    if (currentStreak >= 7) {
      insights.add('You are on a $currentStreak-day streak. Protect momentum.');
    }

    return insights.take(6).toList();
  }
}
