import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings_models.dart';
import '../services/supabase_service.dart';

class SettingsRepository {
  final SupabaseService _supabaseService;

  SettingsRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  Future<AppSettings?> getAppSettings() async {
    try {
      final response = await _client
          .from('app_settings')
          .select()
          .eq('created_by', _currentUserId)
          .maybeSingle();

      if (response == null) return null;
      return AppSettings.fromJson(response);
    } catch (e) {
      print('Error getting settings: $e');
      return null;
    }
  }

  Future<void> updateActiveApps(List<String> apps) async {
    // Check if settings exist, if so update, else insert
    final settings = await getAppSettings();
    if (settings != null) {
      await _client
          .from('app_settings')
          .update({'active_apps': apps})
          .eq('id', settings.id);
    } else {
      await _client.from('app_settings').insert({
        'created_by': _currentUserId,
        'active_apps': apps,
      });
    }
  }

  Future<List<BlockedApp>> getBlockedApps() async {
    try {
      final response = await _client
          .from('blocked_apps')
          .select()
          .eq('created_by', _currentUserId);

      return (response as List)
          .map((data) => BlockedApp.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting blocked apps: $e');
      return [];
    }
  }
}
