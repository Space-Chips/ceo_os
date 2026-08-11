import '../models/advanced_stats_models.dart';
import '../models/stats_event_models.dart';

class AdvancedStatsRepository {
  final List<StatsEvent> _events = [];
  DailyStats? _daily;
  WeeklyStats? _weekly;
  MonthlyStats? _monthly;
  LifetimeStats? _lifetime;

  Future<void> logEvent(StatsEventInput input) async {
    _events.add(
      StatsEvent(
        eventType: input.eventType,
        eventTime: input.eventTime,
        sourceKey: input.sourceKey,
        payload: input.payload,
      ),
    );
  }

  Future<List<StatsEvent>> getEventsForDay(DateTime day) async => _events;
  Future<void> upsertDailyStats(DailyStats stats) async => _daily = stats;
  Future<void> upsertWeeklyStats(WeeklyStats stats) async => _weekly = stats;
  Future<void> upsertMonthlyStats(MonthlyStats stats) async => _monthly = stats;
  Future<void> upsertLifetimeStats(LifetimeStats stats) async => _lifetime = stats;
  Future<DailyStats?> getDailyStats(DateTime day) async => _daily;
  Future<WeeklyStats?> getWeeklyStats(DateTime weekStart) async => _weekly;
  Future<MonthlyStats?> getMonthlyStats(String month) async => _monthly;
  Future<LifetimeStats?> getLifetimeStats() async => _lifetime;
  Future<AdvancedStatsSnapshot> getSnapshot() async {
    return AdvancedStatsSnapshot(
      daily: _daily,
      weekly: _weekly,
      monthly: _monthly,
      lifetime: _lifetime,
    );
  }
}
