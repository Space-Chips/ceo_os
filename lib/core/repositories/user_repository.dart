import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_models.dart';
import '../services/supabase_service.dart';

class UserRepository {
  final SupabaseService _supabaseService;

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

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      // TODO: Handle error properly
      print('Error getting profile: $e');
      return null;
    }
  }

  Future<UserRank?> getUserRank() async {
    try {
      final response = await _client
          .from('user_ranks')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();

      if (response == null) return null;
      return UserRank.fromJson(response);
    } catch (e) {
      print('Error getting rank: $e');
      return null;
    }
  }

  Future<WinStreak?> getWinStreak() async {
    try {
      final response = await _client
          .from('win_streaks')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();

      if (response == null) return null;
      return WinStreak.fromJson(response);
    } catch (e) {
      print('Error getting streak: $e');
      return null;
    }
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
      print('Error getting leaderboard: $e');
      return [];
    }
  }
}
