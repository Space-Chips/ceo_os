class Habit {
  final String id;
  final String createdBy;
  final String title;
  final String? icon;
  final String? category;
  final String? quote;
  final String frequencyType; // 'daily', 'specific_days', 'interval'
  final int? intervalDays;
  final String targetType; // 'all', 'amount'
  final int? targetValue;
  final String? targetUnit;
  final String? reminderTime; // 'HH:MM'
  final bool autoPopup;
  final String? colorTheme;
  final bool archived;
  final bool isDaily;
  final List<int>? specificDays;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.createdBy,
    required this.title,
    this.icon,
    this.category,
    this.quote,
    this.frequencyType = 'daily',
    this.intervalDays,
    this.targetType = 'all',
    this.targetValue,
    this.targetUnit,
    this.reminderTime,
    this.autoPopup = false,
    this.colorTheme,
    this.archived = false,
    this.isDaily = true,
    this.specificDays,
    required this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      createdBy: json['created_by'],
      title: json['title'],
      icon: json['icon'],
      category: json['category'],
      quote: json['quote'],
      frequencyType: json['frequency_type'] ?? 'daily',
      intervalDays: json['interval_days'],
      targetType: json['target_type'] ?? 'all',
      targetValue: json['target_value'],
      targetUnit: json['target_unit'],
      reminderTime: json['reminder_time'],
      autoPopup: json['auto_popup'] ?? false,
      colorTheme: json['color_theme'],
      archived: json['archived'] ?? false,
      isDaily: json['is_daily'] ?? true,
      specificDays: json['specific_days'] != null
          ? List<int>.from(json['specific_days'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': icon,
      'category': category,
      'quote': quote,
      'frequency_type': frequencyType,
      'interval_days': intervalDays,
      'target_type': targetType,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'reminder_time': reminderTime,
      'auto_popup': autoPopup,
      'color_theme': colorTheme,
      'is_daily': isDaily,
      'specific_days': specificDays,
      'archived': archived,
    };
  }
}

class HabitCompletion {
  final String id;
  final String habitId;
  final String date; // Format: YYYY-MM-DD
  final String? state;
  final bool completed;
  final String createdBy;
  final DateTime? checkedInDate;
  final DateTime createdAt;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    this.state,
    this.completed = false,
    required this.createdBy,
    this.checkedInDate,
    required this.createdAt,
  });

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'],
      habitId: json['habit_id'],
      date: json['date'],
      state: json['state'],
      completed: json['completed'] ?? false,
      createdBy: json['created_by'],
      checkedInDate: json['checked_in_date'] != null
          ? DateTime.parse(json['checked_in_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final String createdBy;
  final String content;
  final String date;
  final DateTime createdAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.createdBy,
    required this.content,
    required this.date,
    required this.createdAt,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'],
      habitId: json['habit_id'],
      createdBy: json['created_by'],
      content: json['content'],
      date: json['date'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class WeeklyHabitScore {
  final String id;
  final String createdBy;
  final String? weekStartDate;
  final String? weekEndDate;
  final int? totalExpected;
  final int? totalCompleted;
  final int? successPercentage;
  final int? thresholdPercentage;
  final bool? thresholdMet;
  final DateTime? calculatedDate;
  final DateTime createdAt;

  WeeklyHabitScore({
    required this.id,
    required this.createdBy,
    this.weekStartDate,
    this.weekEndDate,
    this.totalExpected,
    this.totalCompleted,
    this.successPercentage,
    this.thresholdPercentage,
    this.thresholdMet,
    this.calculatedDate,
    required this.createdAt,
  });

  factory WeeklyHabitScore.fromJson(Map<String, dynamic> json) {
    return WeeklyHabitScore(
      id: json['id'],
      createdBy: json['created_by'],
      weekStartDate: json['week_start_date'],
      weekEndDate: json['week_end_date'],
      totalExpected: json['total_expected'],
      totalCompleted: json['total_completed'],
      successPercentage: json['success_percentage'],
      thresholdPercentage: json['threshold_percentage'],
      thresholdMet: json['threshold_met'],
      calculatedDate: json['calculated_date'] != null
          ? DateTime.parse(json['calculated_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class WeeklyContract {
  final String id;
  final String createdBy;
  final String? weekStartDate;
  final String? weekEndDate;
  final String? rewardText;
  final String? sanctionText;
  final int successThresholdPercentage;
  final bool committed;
  final bool evaluated;
  final String outcomeGrade;
  final int? actualSuccessPercentage;
  final DateTime? evaluatedDate;
  final DateTime createdAt;

  WeeklyContract({
    required this.id,
    required this.createdBy,
    this.weekStartDate,
    this.weekEndDate,
    this.rewardText,
    this.sanctionText,
    this.successThresholdPercentage = 90,
    this.committed = false,
    this.evaluated = false,
    this.outcomeGrade = 'pending',
    this.actualSuccessPercentage,
    this.evaluatedDate,
    required this.createdAt,
  });

  factory WeeklyContract.fromJson(Map<String, dynamic> json) {
    return WeeklyContract(
      id: json['id'],
      createdBy: json['created_by'],
      weekStartDate: json['week_start_date'],
      weekEndDate: json['week_end_date'],
      rewardText: json['reward_text'],
      sanctionText: json['sanction_text'],
      successThresholdPercentage: json['success_threshold_percentage'] ?? 90,
      committed: json['committed'] ?? false,
      evaluated: json['evaluated'] ?? false,
      outcomeGrade: json['outcome_grade'] ?? 'pending',
      actualSuccessPercentage: json['actual_success_percentage'],
      evaluatedDate: json['evaluated_date'] != null
          ? DateTime.parse(json['evaluated_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
