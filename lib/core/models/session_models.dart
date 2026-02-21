class CeoModeSession {
  final String id;
  final String createdBy;
  final bool active;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final int? approvedAppsCount;
  final DateTime createdAt;

  CeoModeSession({
    required this.id,
    required this.createdBy,
    this.active = false,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.approvedAppsCount,
    required this.createdAt,
  });

  factory CeoModeSession.fromJson(Map<String, dynamic> json) {
    return CeoModeSession(
      id: json['id'],
      createdBy: json['created_by'],
      active: json['active'] ?? false,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      durationMinutes: json['duration_minutes'],
      approvedAppsCount: json['approved_apps_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class FocusSession {
  final String id;
  final String createdBy;
  final int? durationMinutes;
  final bool completed;
  final bool earlyExit;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? actualDurationMinutes;
  final DateTime createdAt;

  FocusSession({
    required this.id,
    required this.createdBy,
    this.durationMinutes,
    this.completed = false,
    this.earlyExit = false,
    this.startTime,
    this.endTime,
    this.actualDurationMinutes,
    required this.createdAt,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'],
      createdBy: json['created_by'],
      durationMinutes: json['duration_minutes'],
      completed: json['completed'] ?? false,
      earlyExit: json['early_exit'] ?? false,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      actualDurationMinutes: json['actual_duration_minutes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ScreenTimeLog {
  final String id;
  final String createdBy;
  final String? entityType;
  final String? entityName;
  final int? durationSeconds;
  final String? date;
  final DateTime? startTime;
  final DateTime? endTime;
  final int awarenessNotificationsShown;
  final DateTime createdAt;

  ScreenTimeLog({
    required this.id,
    required this.createdBy,
    this.entityType,
    this.entityName,
    this.durationSeconds,
    this.date,
    this.startTime,
    this.endTime,
    this.awarenessNotificationsShown = 0,
    required this.createdAt,
  });

  factory ScreenTimeLog.fromJson(Map<String, dynamic> json) {
    return ScreenTimeLog(
      id: json['id'],
      createdBy: json['created_by'],
      entityType: json['entity_type'],
      entityName: json['entity_name'],
      durationSeconds: json['duration_seconds'],
      date: json['date'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      awarenessNotificationsShown: json['awareness_notifications_shown'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RestPeriod {
  final String id;
  final String createdBy;
  final String? startTime;
  final String? endTime;
  final bool active;
  final DateTime createdAt;

  RestPeriod({
    required this.id,
    required this.createdBy,
    this.startTime,
    this.endTime,
    this.active = true,
    required this.createdAt,
  });

  factory RestPeriod.fromJson(Map<String, dynamic> json) {
    return RestPeriod(
      id: json['id'],
      createdBy: json['created_by'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
