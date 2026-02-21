import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_models.dart';
import '../services/supabase_service.dart';

class SessionRepository {
  final SupabaseService _supabaseService;

  SessionRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  // CEO Mode
  Future<CeoModeSession?> getActiveCeoSession() async {
    try {
      final response = await _client
          .from('ceo_mode_sessions')
          .select()
          .eq('created_by', _currentUserId)
          .eq('active', true)
          .maybeSingle();

      if (response == null) return null;
      return CeoModeSession.fromJson(response);
    } catch (e) {
      print('Error getting active CEO session: $e');
      return null;
    }
  }

  Future<void> startCeoSession(int durationMinutes) async {
    await _client.from('ceo_mode_sessions').insert({
      'created_by': _currentUserId,
      'active': true,
      'start_time': DateTime.now().toIso8601String(),
      'duration_minutes': durationMinutes,
    });
  }

  Future<void> endCeoSession(String sessionId) async {
    await _client
        .from('ceo_mode_sessions')
        .update({'active': false, 'end_time': DateTime.now().toIso8601String()})
        .eq('id', sessionId);
  }

  // Focus Session
  Future<void> logFocusSession(
    int durationMinutes, {
    required bool completed,
  }) async {
    await _client.from('focus_sessions').insert({
      'created_by': _currentUserId,
      'duration_minutes': durationMinutes,
      'completed': completed,
      'start_time': DateTime.now()
          .subtract(Duration(minutes: durationMinutes))
          .toIso8601String(),
      'end_time': DateTime.now().toIso8601String(),
      'actual_duration_minutes': durationMinutes,
    });
  }
}
