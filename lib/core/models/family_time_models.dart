class FamilyTimeGroup {
  final String id;
  final String name;
  final String inviteToken;
  final String? sanctionText;

  const FamilyTimeGroup({
    required this.id,
    required this.name,
    this.inviteToken = '',
    this.sanctionText,
  });
}

class FamilyTimeMember {
  final String id;
  final String label;
  final String role;
  final int quitPoints;

  const FamilyTimeMember({
    required this.id,
    required this.label,
    this.role = 'member',
    this.quitPoints = 0,
  });

  bool get isAdmin => role == 'admin' || role == 'owner';
}

class FamilyTimeBlockedApp {
  final String id;
  final String appName;

  const FamilyTimeBlockedApp({required this.id, required this.appName});
}

class FamilyTimeBlockedSite {
  final String id;
  final String urlDomain;

  const FamilyTimeBlockedSite({required this.id, required this.urlDomain});
}

class FamilyTimeGroupBundle {
  final FamilyTimeGroup group;
  final FamilyTimeMember myMembership;

  const FamilyTimeGroupBundle({
    required this.group,
    required this.myMembership,
  });

  String get id => group.id;
}

class FamilyTimeSession {
  final String id;
  final String status;
  final int durationMinutes;
  final DateTime? startsAt;

  const FamilyTimeSession({
    required this.id,
    this.status = 'pending',
    this.durationMinutes = 0,
    this.startsAt,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed' || status == 'ended';
}

class FamilyTimeSessionParticipant {
  final String memberId;
  final DateTime? acceptedAt;
  final DateTime? leftAt;

  const FamilyTimeSessionParticipant({
    this.memberId = '',
    this.acceptedAt,
    this.leftAt,
  });
}

class FamilyTimeSessionEvent {
  final String message;
  final DateTime createdAt;

  const FamilyTimeSessionEvent({this.message = '', required this.createdAt});
}
