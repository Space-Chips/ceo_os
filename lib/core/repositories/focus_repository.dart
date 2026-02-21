import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/block_list_model.dart';
import '../services/supabase_service.dart';

class FocusRepository {
  final SupabaseService _supabaseService;

  FocusRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  // --- Block Lists ---

  Future<List<BlockList>> getBlockLists() async {
    try {
      final response = await _client
          .from('block_lists')
          .select()
          .eq('created_by', _currentUserId);

      return (response as List).map((data) => BlockList.fromJson(data)).toList();
    } catch (e) {
      print('Error getting block lists: $e');
      return [];
    }
  }

  Future<void> saveBlockList(BlockList list) async {
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
    await _client.from('block_lists').delete().eq('id', id);
  }

  // --- Focus Sessions ---

  Future<void> logFocusSession({
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    String? blockListId,
    bool completed = true,
  }) async {
    await _client.from('focus_sessions').insert({
      'created_by': _currentUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'block_list_id': blockListId,
      'completed': completed,
    });
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
}
