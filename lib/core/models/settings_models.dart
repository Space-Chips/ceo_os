class AppSettings {
  final String id;
  final String createdBy;
  final List<String>? activeApps;
  final String themePreset;
  final String languageCode;
  final bool notificationsEnabled;
  final bool habitNotificationsEnabled;
  final bool calendarNotificationsEnabled;
  final bool focusNotificationsEnabled;
  final String? onboardingGoal;
  final String? onboardingDiscipline;
  final String? onboardingFocusChallenge;
  final DateTime? themeUpdatedAt;
  final DateTime createdAt;

  AppSettings({
    required this.id,
    required this.createdBy,
    this.activeApps,
    required this.themePreset,
    this.languageCode = 'en',
    this.notificationsEnabled = true,
    this.habitNotificationsEnabled = true,
    this.calendarNotificationsEnabled = true,
    this.focusNotificationsEnabled = true,
    this.onboardingGoal,
    this.onboardingDiscipline,
    this.onboardingFocusChallenge,
    this.themeUpdatedAt,
    required this.createdAt,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'],
      createdBy: json['created_by'],
      activeApps: json['active_apps'] != null
          ? List<String>.from(json['active_apps'])
          : null,
      themePreset: json['theme_preset'] ?? 'midnight_blue',
      languageCode: json['language_code'] ?? 'en',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      habitNotificationsEnabled: json['habit_notifications_enabled'] ?? true,
      calendarNotificationsEnabled:
          json['calendar_notifications_enabled'] ?? true,
      focusNotificationsEnabled: json['focus_notifications_enabled'] ?? true,
      onboardingGoal: json['onboarding_goal'],
      onboardingDiscipline: json['onboarding_discipline'],
      onboardingFocusChallenge: json['onboarding_focus_challenge'],
      themeUpdatedAt: json['theme_updated_at'] != null
          ? DateTime.parse(json['theme_updated_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AppConfig {
  final String id;
  final String? configKey;
  final Map<String, dynamic>? configValue;
  final DateTime createdAt;

  AppConfig({
    required this.id,
    this.configKey,
    this.configValue,
    required this.createdAt,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'],
      configKey: json['config_key'],
      configValue: json['config_value'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BlockedApp {
  final String id;
  final String createdBy;
  final String? appName;
  final int? timeLimitMinutes;
  final DateTime createdAt;

  BlockedApp({
    required this.id,
    required this.createdBy,
    this.appName,
    this.timeLimitMinutes,
    required this.createdAt,
  });

  factory BlockedApp.fromJson(Map<String, dynamic> json) {
    return BlockedApp(
      id: json['id'],
      createdBy: json['created_by'],
      appName: json['app_name'],
      timeLimitMinutes: json['time_limit_minutes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BlockedWebsite {
  final String id;
  final String createdBy;
  final String? urlDomain;
  final int? timeLimitMinutes;
  final DateTime createdAt;

  BlockedWebsite({
    required this.id,
    required this.createdBy,
    this.urlDomain,
    this.timeLimitMinutes,
    required this.createdAt,
  });

  factory BlockedWebsite.fromJson(Map<String, dynamic> json) {
    return BlockedWebsite(
      id: json['id'],
      createdBy: json['created_by'],
      urlDomain: json['url_domain'],
      timeLimitMinutes: json['time_limit_minutes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RestPeriod {
  final String id;
  final String createdBy;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool active;
  final String reason;
  final DateTime createdAt;

  RestPeriod({
    required this.id,
    required this.createdBy,
    this.startTime,
    this.endTime,
    this.active = true,
    this.reason = 'flemme',
    required this.createdAt,
  });

  factory RestPeriod.fromJson(Map<String, dynamic> json) {
    final rawReason = (json['reason'] as String?)?.trim();
    return RestPeriod(
      id: json['id'],
      createdBy: json['created_by'],
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'])
          : null,
      active: json['active'] ?? true,
      reason: (rawReason == null || rawReason.isEmpty) ? 'flemme' : rawReason,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ApprovedApp {
  final String id;
  final String createdBy;
  final String? appName;
  final bool approved;
  final bool essential;
  final String? icon;
  final DateTime createdAt;

  ApprovedApp({
    required this.id,
    required this.createdBy,
    this.appName,
    this.approved = true,
    this.essential = false,
    this.icon,
    required this.createdAt,
  });

  factory ApprovedApp.fromJson(Map<String, dynamic> json) {
    return ApprovedApp(
      id: json['id'],
      createdBy: json['created_by'],
      appName: json['app_name'],
      approved: json['approved'] ?? true,
      essential: json['essential'] ?? false,
      icon: json['icon'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
