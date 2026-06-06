import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_models.dart';
import 'focus_repository.dart';
import '../services/offline_cache.dart';
import '../services/supabase_service.dart';
import '../services/write_queue.dart';
import '../utils/app_logger.dart';

class UserRepository {
  final SupabaseService _supabaseService;
  late final FocusRepository _focusRepository = FocusRepository(
    supabaseService: _supabaseService,
  );

  UserRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  Future<Profile?> getProfile() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', _currentUserId)
          .maybeSingle();

      if (response == null) {
        await OfflineCache.writeList('profile_v1', const []);
        return null;
      }
      await OfflineCache.writeList('profile_v1', [
        response.cast<String, dynamic>(),
      ]);
      return Profile.fromJson(response);
    } catch (e) {
      AppLogger.error('Error getting profile.', e);
      final cached = await OfflineCache.readList('profile_v1');
      if (cached == null || cached.isEmpty) return null;
      try {
        return Profile.fromJson(cached.first);
      } catch (_) {
        return null;
      }
    }
  }

  Future<UserRank?> getUserRank() async {
    try {
      final response = await _client
          .from('user_ranks')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();

      if (response == null) {
        await OfflineCache.writeList('user_rank_v1', const []);
      } else {
        await OfflineCache.writeList('user_rank_v1', [
          response.cast<String, dynamic>(),
        ]);
      }
      final rank = response == null ? null : UserRank.fromJson(response);
      return await _resolveBronzeFallback(rank);
    } catch (e) {
      AppLogger.error('Error getting rank.', e);
      final cached = await OfflineCache.readList('user_rank_v1');
      if (cached == null || cached.isEmpty) return null;
      try {
        return UserRank.fromJson(cached.first);
      } catch (_) {
        return null;
      }
    }
  }

  Future<UserRank?> _resolveBronzeFallback(UserRank? current) async {
    final currentLevel = current?.rankLevel ?? 0;
    final currentName = (current?.rankName ?? '').trim().toLowerCase();
    final alreadyUnlockedBronze =
        currentLevel >= 1 ||
        {
          'bronze',
          'silver',
          'gold',
          'platinum',
          'diamond',
          'immortal',
          'awakened',
        }.contains(currentName);

    if (alreadyUnlockedBronze) return current;

    try {
      final profile = await _client
          .from('profiles')
          .select('created_at')
          .eq('id', _currentUserId)
          .maybeSingle();
      if (profile == null) return current;

      final createdAtRaw = profile['created_at'] as String?;
      final createdAt = createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw)
          : null;
      if (createdAt == null) return current;

      final nowUtc = DateTime.now().toUtc();
      final todayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
      final createdUtc = createdAt.toUtc();
      final createdDateUtc = DateTime.utc(
        createdUtc.year,
        createdUtc.month,
        createdUtc.day,
      );
      final daysInApp = todayUtc.difference(createdDateUtc).inDays + 1;
      if (daysInApp < 7) return current;

      final focusSessions = await _client
          .from('focus_sessions')
          .select('id')
          .eq('created_by', _currentUserId)
          .eq('completed', true);
      final focusCompleted = (focusSessions as List).length;
      if (focusCompleted < 1) return current;

      final streakRow = await _client
          .from('win_streaks')
          .select('current_streak')
          .eq('created_by', _currentUserId)
          .maybeSingle();
      final streak = (streakRow?['current_streak'] as num?)?.toInt() ?? 0;
      final today = DateTime.now().toIso8601String().split('T').first;

      await _client.from('user_ranks').upsert({
        'created_by': _currentUserId,
        'rank_name': 'Bronze',
        'rank_level': 1,
        'total_rank_points': current?.totalRankPoints ?? 0,
        'win_streak_bonus': current?.winStreakBonus ?? streak,
        'previous_rank_name': current?.rankName,
        'last_rank_change_date': today,
      });

      await _client.from('leaderboard_entries').upsert({
        'created_by': _currentUserId,
        'rank_level': 1,
        'rank_name': 'Bronze',
        'win_streak': streak,
        'last_sync_date': DateTime.now().toIso8601String(),
      });

      final freshResponse = await _client
          .from('user_ranks')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();
      if (freshResponse != null) return UserRank.fromJson(freshResponse);

      return UserRank(
        id: current?.id ?? _currentUserId,
        createdBy: _currentUserId,
        rankName: 'Bronze',
        rankLevel: 1,
        screenTimeAvgMinutes: current?.screenTimeAvgMinutes,
        winStreakBonus: current?.winStreakBonus ?? streak,
        totalRankPoints: current?.totalRankPoints ?? 0,
        daysAtCurrentRank: current?.daysAtCurrentRank,
        previousRankName: current?.rankName,
        lastRankChangeDate: today,
        createdAt: current?.createdAt ?? DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Error resolving local Bronze fallback.', e);
      return current;
    }
  }

  Future<WinStreak?> getWinStreak() async {
    return _focusRepository.getOrRepairWinStreak();
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await _client
          .from('leaderboard_entries')
          .select()
          .order('rank_level', ascending: false)
          .limit(100);

      return (response as List)
          .map((data) => LeaderboardEntry.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting leaderboard.', e);
      return [];
    }
  }

  Future<void> refreshLeaderboardForMe() async {
    try {
      await _client.rpc(
        'refresh_user_gamification',
        params: {'p_user': _currentUserId},
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' ||
          e.message.contains('refresh_user_gamification')) {
        return;
      }
      AppLogger.error('Error refreshing leaderboard metrics.', e);
    } catch (e) {
      AppLogger.error('Error refreshing leaderboard metrics.', e);
    }
  }

  Future<Profile> upsertProfile({String? fullName, String? avatarUrl}) async {
    final user = _client.auth.currentUser!;
    final payload = {
      'id': _currentUserId,
      'email': user.email,
      'full_name': fullName ?? user.userMetadata?['full_name'],
      'avatar_url': avatarUrl,
    };

    final response = await _client
        .from('profiles')
        .upsert(payload)
        .select()
        .single();

    return Profile.fromJson(response);
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (payload.isEmpty) return;

    final match = {'id': _currentUserId};
    try {
      await _client.from('profiles').update(payload).eq('id', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'profiles',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  Future<List<FriendConnection>> getFriendConnections() async {
    try {
      final response = await _client
          .from('friend_connections')
          .select()
          .eq('created_by', _currentUserId)
          .order('friend_rank_level', ascending: false)
          .order('friend_win_streak', ascending: false)
          .order('last_updated', ascending: false);

      return (response as List)
          .map((data) => FriendConnection.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting friend connections.', e);
      return [];
    }
  }

  Future<void> upsertFriendConnection({
    required String friendEmail,
    String? friendName,
  }) async {
    final normalizedEmail = friendEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ArgumentError('Friend email is required.');
    }

    final myEmail = _client.auth.currentUser?.email?.trim().toLowerCase();
    if (myEmail != null && normalizedEmail == myEmail) {
      throw ArgumentError('You cannot add your own account as a friend.');
    }

    String? friendUserId;
    var resolvedName = friendName?.trim() ?? '';
    int? resolvedRankLevel;
    String? resolvedRankName;
    int? resolvedWinStreak;
    var resolvedUpdatedAt = DateTime.now();

    try {
      final profile = await _client
          .from('profiles')
          .select('id, full_name')
          .ilike('email', normalizedEmail)
          .limit(1)
          .maybeSingle();

      if (profile != null) {
        friendUserId = profile['id'] as String?;
        final profileName = (profile['full_name'] as String?)?.trim();
        if (resolvedName.isEmpty &&
            profileName != null &&
            profileName.isNotEmpty) {
          resolvedName = profileName;
        }
      }
    } catch (e) {
      AppLogger.error(
        'Unable to resolve friend profile for $normalizedEmail.',
        e,
      );
    }

    if (friendUserId != null && friendUserId == _currentUserId) {
      throw ArgumentError('You cannot add your own account as a friend.');
    }

    if (friendUserId != null) {
      try {
        final leaderboard = await _client
            .from('leaderboard_entries')
            .select('rank_level, rank_name, win_streak, last_sync_date')
            .eq('created_by', friendUserId)
            .eq('opted_in', true)
            .limit(1)
            .maybeSingle();

        if (leaderboard != null) {
          resolvedRankLevel = (leaderboard['rank_level'] as num?)?.toInt();
          resolvedRankName = leaderboard['rank_name'] as String?;
          resolvedWinStreak = (leaderboard['win_streak'] as num?)?.toInt();
          final lastSyncRaw = leaderboard['last_sync_date'] as String?;
          final parsedLastSync = lastSyncRaw != null
              ? DateTime.tryParse(lastSyncRaw)
              : null;
          if (parsedLastSync != null) {
            resolvedUpdatedAt = parsedLastSync;
          }
        }
      } catch (e) {
        AppLogger.error(
          'Unable to resolve friend leaderboard for $normalizedEmail.',
          e,
        );
      }
    }

    if (resolvedName.isEmpty) {
      resolvedName = normalizedEmail.split('@').first;
    }

    final existing = await _client
        .from('friend_connections')
        .select('id')
        .eq('created_by', _currentUserId)
        .eq('friend_email', normalizedEmail)
        .limit(1)
        .maybeSingle();

    final payload = <String, dynamic>{
      'friend_email': normalizedEmail,
      'friend_name': resolvedName,
      'last_updated': resolvedUpdatedAt.toIso8601String(),
    };
    if (resolvedRankLevel != null) {
      payload['friend_rank_level'] = resolvedRankLevel;
    }
    if (resolvedRankName != null && resolvedRankName.trim().isNotEmpty) {
      payload['friend_rank_name'] = resolvedRankName.trim();
    }
    if (resolvedWinStreak != null) {
      payload['friend_win_streak'] = resolvedWinStreak;
    }

    if (existing == null) {
      await _client.from('friend_connections').insert({
        'created_by': _currentUserId,
        ...payload,
      });
      return;
    }

    await _client
        .from('friend_connections')
        .update(payload)
        .eq('id', existing['id'])
        .eq('created_by', _currentUserId);
  }

  Future<void> deleteFriendConnection(String id) async {
    await _client
        .from('friend_connections')
        .delete()
        .eq('created_by', _currentUserId)
        .eq('id', id);
  }

  Future<Map<String, String>> getPublicIdentityLabelsByUserIds(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};

    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('id', ids);

      final map = <String, String>{};
      for (final row in (response as List)) {
        final id = (row['id'] as String?)?.trim();
        if (id == null || id.isEmpty) continue;

        final fullName = (row['full_name'] as String?)?.trim();
        final email = (row['email'] as String?)?.trim();
        if (fullName != null && fullName.isNotEmpty) {
          map[id] = fullName;
        } else if (email != null && email.isNotEmpty) {
          map[id] = email.split('@').first;
        }
      }
      return map;
    } catch (e) {
      AppLogger.error('Error getting public profile labels.', e);
      return {};
    }
  }

  Future<void> syncFriendConnections() async {
    try {
      final current = await getFriendConnections();
      for (final friend in current) {
        final email = (friend.friendEmail ?? '').trim();
        if (email.isEmpty) continue;
        await upsertFriendConnection(
          friendEmail: email,
          friendName: friend.friendName,
        );
      }
    } catch (e) {
      AppLogger.error('Error syncing friend connections.', e);
    }
  }
}
