import '../models/family_time_models.dart';

class FamilyTimeRepositoryException implements Exception {
  final String message;
  const FamilyTimeRepositoryException(this.message);
  @override
  String toString() => message;
}

class FamilyTimeRepository {
  static const _defaultMember = FamilyTimeMember(
    id: 'me',
    label: 'You',
    role: 'admin',
  );

  Future<FamilyTimeGroupBundle?> getActiveGroupBundle() async => null;

  Future<List<FamilyTimeGroupBundle>> getMyGroups() async => const [];

  Future<FamilyTimeGroupBundle?> createGroup(String name) async {
    return FamilyTimeGroupBundle(
      group: FamilyTimeGroup(id: name, name: name, inviteToken: name),
      myMembership: _defaultMember,
    );
  }

  Future<FamilyTimeGroupBundle?> joinGroupByToken({String? token}) async {
    token ??= 'family';
    return FamilyTimeGroupBundle(
      group: FamilyTimeGroup(id: token, name: 'Family', inviteToken: token),
      myMembership: _defaultMember,
    );
  }

  Future<bool> updateGroupSanction({
    required String groupId,
    required String sanctionText,
  }) async {
    return true;
  }

  Future<bool> addBlockedApp({
    required String groupId,
    required String appName,
  }) async {
    return true;
  }

  Future<bool> addBlockedSite({
    required String groupId,
    required String domain,
  }) async {
    return true;
  }

  Future<FamilyTimeSession?> startSession({
    required String groupId,
    required int durationMinutes,
  }) async {
    return FamilyTimeSession(
      id: '${groupId}_session',
      durationMinutes: durationMinutes,
      startsAt: DateTime.now(),
    );
  }

  Future<bool> acceptSession({
    required String sessionId,
    required String groupId,
  }) async {
    return true;
  }

  Future<FamilyTimeSession?> getLatestSession(String groupId) async {
    return FamilyTimeSession(id: '${groupId}_session');
  }

  Future<List<FamilyTimeMember>> getMembers(String groupId) async => const [];

  Future<List<FamilyTimeBlockedApp>> getBlockedApps(String groupId) async =>
      const [];

  Future<List<FamilyTimeBlockedSite>> getBlockedSites(String groupId) async =>
      const [];

  String buildInviteLink(String inviteToken) =>
      'https://wakeapp.family/join/$inviteToken';

  Future<bool> inviteMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    return true;
  }

  Future<bool> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    return true;
  }

  Future<bool> removeBlockedApp({
    required String groupId,
    required String appId,
  }) async {
    return true;
  }

  Future<bool> removeBlockedSite({
    required String groupId,
    required String siteId,
  }) async {
    return true;
  }

  Future<bool> leaveSessionAfterCountdown({
    required String sessionId,
    required String groupId,
  }) async {
    return true;
  }

  Future<List<FamilyTimeSessionParticipant>> getSessionParticipants(
    String sessionId,
  ) async {
    return const [];
  }

  Future<List<FamilyTimeSessionEvent>> getSessionEvents(String sessionId) async {
    return const [];
  }
}
