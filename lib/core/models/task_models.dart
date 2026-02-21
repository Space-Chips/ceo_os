class TaskGroup {
  final String id;
  final String createdBy;
  final String name;
  final String? color;
  final DateTime createdAt;

  TaskGroup({
    required this.id,
    required this.createdBy,
    required this.name,
    this.color,
    required this.createdAt,
  });

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
    return TaskGroup(
      id: json['id'],
      createdBy: json['created_by'],
      name: json['name'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ParetoTask {
  final String id;
  final String createdBy;
  final String title;
  final String? importanceLevel;
  final String? timeDuration;
  final bool completed;
  final DateTime? completedDate;
  final String? impactLevel;
  final int? sortOrder;
  final String? groupId;
  final DateTime createdAt;

  ParetoTask({
    required this.id,
    required this.createdBy,
    required this.title,
    this.importanceLevel,
    this.timeDuration,
    this.completed = false,
    this.completedDate,
    this.impactLevel,
    this.sortOrder,
    this.groupId,
    required this.createdAt,
  });

  factory ParetoTask.fromJson(Map<String, dynamic> json) {
    return ParetoTask(
      id: json['id'],
      createdBy: json['created_by'],
      title: json['title'],
      importanceLevel: json['importance_level'],
      timeDuration: json['time_duration'],
      completed: json['completed'] ?? false,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
      impactLevel: json['impact_level'],
      sortOrder: json['sort_order'],
      groupId: json['group_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class CalendarEvent {
  final String id;
  final String createdBy;
  final String title;
  final String? description;
  final String? eventDate;
  final String? eventTime;
  final DateTime? notification24hTime;
  final DateTime? notification2hTime;
  final bool notification24hSent;
  final bool notification2hSent;
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.createdBy,
    required this.title,
    this.description,
    this.eventDate,
    this.eventTime,
    this.notification24hTime,
    this.notification2hTime,
    this.notification24hSent = false,
    this.notification2hSent = false,
    required this.createdAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      createdBy: json['created_by'],
      title: json['title'],
      description: json['description'],
      eventDate: json['event_date'],
      eventTime: json['event_time'],
      notification24hTime: json['notification_24h_time'] != null
          ? DateTime.parse(json['notification_24h_time'])
          : null,
      notification2hTime: json['notification_2h_time'] != null
          ? DateTime.parse(json['notification_2h_time'])
          : null,
      notification24hSent: json['notification_24h_sent'] ?? false,
      notification2hSent: json['notification_2h_sent'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class EventType {
  final String id;
  final String createdBy;
  final String? name;
  final String? color;
  final String? icon;
  final DateTime createdAt;

  EventType({
    required this.id,
    required this.createdBy,
    this.name,
    this.color,
    this.icon,
    required this.createdAt,
  });

  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      id: json['id'],
      createdBy: json['created_by'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Note {
  final String id;
  final String createdBy;
  final String? content;
  final String? title;
  final DateTime? updatedDate;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.createdBy,
    this.content,
    this.title,
    this.updatedDate,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      createdBy: json['created_by'],
      content: json['content'],
      title: json['title'],
      updatedDate: json['updated_date'] != null
          ? DateTime.parse(json['updated_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Objective {
  final String id;
  final String createdBy;
  final String? title;
  final bool archived;
  final DateTime createdAt;

  Objective({
    required this.id,
    required this.createdBy,
    this.title,
    this.archived = false,
    required this.createdAt,
  });

  factory Objective.fromJson(Map<String, dynamic> json) {
    return Objective(
      id: json['id'],
      createdBy: json['created_by'],
      title: json['title'],
      archived: json['archived'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}