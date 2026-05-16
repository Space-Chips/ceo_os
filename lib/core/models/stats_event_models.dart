enum StatsEventType { dashboardOpened }

class StatsEventInput {
  final StatsEventType eventType;
  final DateTime eventTime;
  final String sourceKey;
  final Map<String, dynamic> payload;

  const StatsEventInput({
    required this.eventType,
    required this.eventTime,
    required this.sourceKey,
    this.payload = const {},
  });
}

class StatsEvent {
  final StatsEventType eventType;
  final DateTime eventTime;
  final String sourceKey;
  final Map<String, dynamic> payload;

  const StatsEvent({
    required this.eventType,
    required this.eventTime,
    required this.sourceKey,
    this.payload = const {},
  });
}
