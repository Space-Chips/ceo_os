import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/apple_review_compliance.dart';
import '../models/block_list_model.dart';
import '../models/user_models.dart';
import '../services/family_controls_local_store.dart';
import '../services/supabase_service.dart';
import '../utils/app_logger.dart';

class FocusRepository {
  final SupabaseService _supabaseService;
  final FamilyControlsLocalStore _familyControlsLocalStore;

  FocusRepository({
    SupabaseService? supabaseService,
    FamilyControlsLocalStore? familyControlsLocalStore,
  }) : _supabaseService = supabaseService ?? SupabaseService(),
       _familyControlsLocalStore =
           familyControlsLocalStore ?? FamilyControlsLocalStore();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser?.id ?? "";
  bool get _useLocalFamilyControlsStorage =>
      AppleReviewCompliance.exposesLocalOnlyFamilyControls;

  // --- Block Lists ---

  Future<List<BlockList>> getBlockLists() async {
    if (_useLocalFamilyControlsStorage) {
      return _familyControlsLocalStore.getBlockLists();
    }
    try {
      final response = await _client
          .from('block_lists')
          .select()
          .eq('created_by', _currentUserId);

      return (response as List)
          .map((data) => BlockList.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting block lists.', e);
      return [];
    }
  }

  Future<void> saveBlockList(BlockList list) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.saveBlockList(list);
      return;
    }
    await _client.from('block_lists').upsert({
      'id': list.id,
      'created_by': _currentUserId,
      'name': list.name,
      'adult_blocking': list.adultBlocking,
      'blocked_package_names': list.blockedPackageNames,
      'blocked_categories': list.blockedCategories,
      'is_active': list.isActive,
    });
  }

  Future<void> updateActiveBlockList(String? activeId) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.setActiveBlockList(activeId);
      return;
    }
    // Set all to false first
    await _client
        .from('block_lists')
        .update({'is_active': false})
        .eq('created_by', _currentUserId);

    // Set the specific one to true
    if (activeId != null) {
      await _client
          .from('block_lists')
          .update({'is_active': true})
          .eq('id', activeId)
          .eq('created_by', _currentUserId);
    }
  }

  Future<void> deleteBlockList(String id) async {
    if (_useLocalFamilyControlsStorage) {
      await _familyControlsLocalStore.deleteBlockList(id);
      return;
    }
    await _client
        .from('block_lists')
        .delete()
        .eq('id', id)
        .eq('created_by', _currentUserId);
  }

  // --- Focus Sessions ---

  Future<void> logFocusSession({
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    String? blockListId,
    bool completed = true,
  }) async {
    final persistedBlockListId = _useLocalFamilyControlsStorage
        ? null
        : blockListId;
    await _client.from('focus_sessions').insert({
      'created_by': _currentUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'block_list_id': persistedBlockListId,
      'completed': completed,
    });
    await _refreshWinStreakForSession(completed: completed, endTime: endTime);
  }

  Future<List<Map<String, dynamic>>> getRecentSessions() async {
    try {
      return await _client
          .from('focus_sessions')
          .select()
          .eq('created_by', _currentUserId)
          .order('created_at', ascending: false)
          .limit(10);
    } catch (e) {
      return [];
    }
  }

  Future<int> getCompletedSessionCount() async {
    try {
      final response = await _client
          .from('focus_sessions')
          .select('id')
          .eq('created_by', _currentUserId)
          .eq('completed', true);

      return (response as List).length;
    } catch (e) {
      AppLogger.error('Error counting focus sessions.', e);
      return 0;
    }
  }

  Future<void> _refreshWinStreakForSession({
    required bool completed,
    required DateTime endTime,
  }) async {
    try {
      final today = DateTime(endTime.year, endTime.month, endTime.day);
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year.toString().padLeft(4, '0')}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}';

      final current = await _client
          .from('win_streaks')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();

      final currentStreak = (current?['current_streak'] as num?)?.toInt() ?? 0;
      final longestStreak = (current?['longest_streak'] as num?)?.toInt() ?? 0;
      final totalCompleted =
          (current?['total_completed_sessions'] as num?)?.toInt() ?? 0;
      final totalFailed =
          (current?['total_failed_sessions'] as num?)?.toInt() ?? 0;
      final lastSessionDate = (current?['last_session_date'] as String?)
          ?.trim();

      var nextCurrentStreak = currentStreak;
      var nextLongestStreak = longestStreak;
      var nextTotalCompleted = totalCompleted;
      var nextTotalFailed = totalFailed;
      var nextLastSessionDate = lastSessionDate;

      if (completed) {
        nextTotalCompleted += 1;
        if (lastSessionDate == todayKey) {
          nextCurrentStreak = currentStreak == 0 ? 1 : currentStreak;
        } else if (lastSessionDate == yesterdayKey) {
          nextCurrentStreak = currentStreak + 1;
        } else {
          nextCurrentStreak = 1;
        }
        nextLongestStreak = nextCurrentStreak > longestStreak
            ? nextCurrentStreak
            : longestStreak;
        nextLastSessionDate = todayKey;
      } else {
        nextTotalFailed += 1;
      }

      await _client.from('win_streaks').upsert({
        'created_by': _currentUserId,
        'current_streak': nextCurrentStreak,
        'longest_streak': nextLongestStreak,
        'total_completed_sessions': nextTotalCompleted,
        'total_failed_sessions': nextTotalFailed,
        'last_session_date': nextLastSessionDate,
      }, onConflict: 'created_by');
    } catch (e) {
      AppLogger.error('Error refreshing win streak after session.', e);
    }
  }

  Future<WinStreak?> getOrRepairWinStreak() async {
    try {
      final current = await _client
          .from('win_streaks')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();
      final repaired = await _rebuildWinStreakFromSessions(existing: current);
      if (repaired == null) return null;
      return WinStreak.fromJson(repaired);
    } catch (e) {
      AppLogger.error('Error getting repaired win streak.', e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _rebuildWinStreakFromSessions({
    Map<String, dynamic>? existing,
  }) async {
    try {
      final sessions = await _client
          .from('focus_sessions')
          .select('completed, end_time, created_at')
          .eq('created_by', _currentUserId)
          .order('end_time', ascending: true);

      final rows = (sessions as List)
          .cast<Map<String, dynamic>>()
          .where(
            (row) =>
                row['completed'] == true &&
                (row['end_time'] ?? row['created_at']) != null,
          )
          .toList(growable: false);

      final completedDays = <DateTime>{};
      for (final row in rows) {
        final raw = (row['end_time'] ?? row['created_at']) as String?;
        final parsed = raw == null ? null : DateTime.tryParse(raw);
        if (parsed == null) continue;
        completedDays.add(DateTime(parsed.year, parsed.month, parsed.day));
      }

      final sortedDays = completedDays.toList()..sort();
      var longestStreak = 0;
      var currentRun = 0;
      DateTime? previousDay;
      for (final day in sortedDays) {
        if (previousDay != null && day.difference(previousDay).inDays == 1) {
          currentRun += 1;
        } else {
          currentRun = 1;
        }
        if (currentRun > longestStreak) longestStreak = currentRun;
        previousDay = day;
      }

      var currentStreak = 0;
      String? lastSessionDate;
      if (sortedDays.isNotEmpty) {
        final latestDay = sortedDays.last;
        lastSessionDate =
            '${latestDay.year.toString().padLeft(4, '0')}-'
            '${latestDay.month.toString().padLeft(2, '0')}-'
            '${latestDay.day.toString().padLeft(2, '0')}';

        final today = DateTime.now();
        final todayDay = DateTime(today.year, today.month, today.day);
        final age = todayDay.difference(latestDay).inDays;
        if (age <= 1) {
          currentStreak = 1;
          for (var i = sortedDays.length - 2; i >= 0; i--) {
            final newer = sortedDays[i + 1];
            final older = sortedDays[i];
            if (newer.difference(older).inDays == 1) {
              currentStreak += 1;
              continue;
            }
            break;
          }
        }
      }

      final totalCompleted = rows.length;
      final allSessions = (sessions as List).cast<Map<String, dynamic>>();
      final totalFailed = allSessions
          .where((row) => row['completed'] != true)
          .length;

      final currentStreakExisting =
          (existing?['current_streak'] as num?)?.toInt() ?? 0;
      final longestStreakExisting =
          (existing?['longest_streak'] as num?)?.toInt() ?? 0;
      final totalCompletedExisting =
          (existing?['total_completed_sessions'] as num?)?.toInt() ?? 0;
      final totalFailedExisting =
          (existing?['total_failed_sessions'] as num?)?.toInt() ?? 0;
      final lastSessionDateExisting =
          (existing?['last_session_date'] as String?)?.trim();

      final unchanged =
          currentStreakExisting == currentStreak &&
          longestStreakExisting == longestStreak &&
          totalCompletedExisting == totalCompleted &&
          totalFailedExisting == totalFailed &&
          lastSessionDateExisting == lastSessionDate;

      if (!unchanged) {
        await _client.from('win_streaks').upsert({
          'created_by': _currentUserId,
          'current_streak': currentStreak,
          'longest_streak': longestStreak,
          'total_completed_sessions': totalCompleted,
          'total_failed_sessions': totalFailed,
          'last_session_date': lastSessionDate,
        }, onConflict: 'created_by');

        if (AppleReviewCompliance.allowSocialScreenTimeSurfaces) {
          await _client
              .from('leaderboard_entries')
              .update({
                'win_streak': currentStreak,
                'last_sync_date': DateTime.now().toIso8601String(),
              })
              .eq('created_by', _currentUserId);
        }

        await _client
            .from('user_ranks')
            .update({'win_streak_bonus': currentStreak})
            .eq('created_by', _currentUserId);
      }

      final refreshed = await _client
          .from('win_streaks')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();
      return refreshed;
    } catch (e) {
      AppLogger.error('Error rebuilding win streak from sessions.', e);
      return existing;
    }
  }
}
