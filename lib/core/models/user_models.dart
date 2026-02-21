class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserRank {
  final String id;
  final String createdBy;
  final String? rankName;
  final int? rankLevel;
  final double? screenTimeAvgMinutes;
  final int? winStreakBonus;
  final int? totalRankPoints;
  final int? daysAtCurrentRank;
  final String? previousRankName;
  final String? lastRankChangeDate;
  final DateTime createdAt;

  UserRank({
    required this.id,
    required this.createdBy,
    this.rankName,
    this.rankLevel,
    this.screenTimeAvgMinutes,
    this.winStreakBonus,
    this.totalRankPoints,
    this.daysAtCurrentRank,
    this.previousRankName,
    this.lastRankChangeDate,
    required this.createdAt,
  });

  factory UserRank.fromJson(Map<String, dynamic> json) {
    return UserRank(
      id: json['id'],
      createdBy: json['created_by'],
      rankName: json['rank_name'],
      rankLevel: json['rank_level'],
      screenTimeAvgMinutes: json['screen_time_avg_minutes'] != null
          ? (json['screen_time_avg_minutes'] as num).toDouble()
          : null,
      winStreakBonus: json['win_streak_bonus'],
      totalRankPoints: json['total_rank_points'],
      daysAtCurrentRank: json['days_at_current_rank'],
      previousRankName: json['previous_rank_name'],
      lastRankChangeDate: json['last_rank_change_date'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // toJson omitted as usually we update specific fields not replacing exact row with this map
}

class WinStreak {
  final String id;
  final String createdBy;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletedSessions;
  final int totalFailedSessions;
  final String? lastSessionDate;
  final DateTime createdAt;

  WinStreak({
    required this.id,
    required this.createdBy,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletedSessions = 0,
    this.totalFailedSessions = 0,
    this.lastSessionDate,
    required this.createdAt,
  });

  factory WinStreak.fromJson(Map<String, dynamic> json) {
    return WinStreak(
      id: json['id'],
      createdBy: json['created_by'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      totalCompletedSessions: json['total_completed_sessions'] ?? 0,
      totalFailedSessions: json['total_failed_sessions'] ?? 0,
      lastSessionDate: json['last_session_date'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class LeaderboardEntry {
  final String id;
  final String createdBy;
  final int? rankLevel;
  final String? rankName;
  final int? winStreak;
  final double? screenTimeAvgMinutes;
  final int? percentile;
  final bool optedIn;
  final DateTime? lastSyncDate;
  final DateTime createdAt;

  LeaderboardEntry({
    required this.id,
    required this.createdBy,
    this.rankLevel,
    this.rankName,
    this.winStreak,
    this.screenTimeAvgMinutes,
    this.percentile,
    this.optedIn = true,
    this.lastSyncDate,
    required this.createdAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'],
      createdBy: json['created_by'],
      rankLevel: json['rank_level'],
      rankName: json['rank_name'],
      winStreak: json['win_streak'],
      screenTimeAvgMinutes: json['screen_time_avg_minutes'] != null
          ? (json['screen_time_avg_minutes'] as num).toDouble()
          : null,
      percentile: json['percentile'],
      optedIn: json['opted_in'] ?? true,
      lastSyncDate: json['last_sync_date'] != null
          ? DateTime.parse(json['last_sync_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class FriendConnection {
  final String id;
  final String createdBy;
  final String? friendEmail;
  final String? friendName;
  final int? friendRankLevel;
  final String? friendRankName;
  final int? friendWinStreak;
  final DateTime? lastUpdated;
  final DateTime createdAt;

  FriendConnection({
    required this.id,
    required this.createdBy,
    this.friendEmail,
    this.friendName,
    this.friendRankLevel,
    this.friendRankName,
    this.friendWinStreak,
    this.lastUpdated,
    required this.createdAt,
  });

  factory FriendConnection.fromJson(Map<String, dynamic> json) {
    return FriendConnection(
      id: json['id'],
      createdBy: json['created_by'],
      friendEmail: json['friend_email'],
      friendName: json['friend_name'],
      friendRankLevel: json['friend_rank_level'],
      friendRankName: json['friend_rank_name'],
      friendWinStreak: json['friend_win_streak'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
