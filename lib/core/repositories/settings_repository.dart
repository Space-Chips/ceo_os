import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/onboarding_models.dart';
import '../models/settings_models.dart';
import '../services/supabase_service.dart';
import '../utils/app_logger.dart';

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
      AppLogger.error('Error getting settings.', e);
      return null;
    }
  }

  Future<void> _upsertSettingsFields(Map<String, dynamic> fields) async {
    await _client.from('app_settings').upsert({
      'created_by': _currentUserId,
      ...fields,
    }, onConflict: 'created_by');
  }

  Future<void> updateActiveApps(List<String> apps) async {
    await _upsertSettingsFields({'active_apps': apps});
  }

  Future<void> updateThemePreset(String presetId) async {
    await _upsertSettingsFields({
      'theme_preset': presetId,
      'theme_updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateLanguageCode(String languageCode) async {
    await _upsertSettingsFields({
      'language_code': languageCode.trim().toLowerCase(),
    });
  }

  Future<void> updateNotificationChannels({
    required bool notificationsEnabled,
    required bool habitNotificationsEnabled,
    required bool calendarNotificationsEnabled,
    required bool focusNotificationsEnabled,
  }) async {
    await _upsertSettingsFields({
      'notifications_enabled': notificationsEnabled,
      'habit_notifications_enabled': habitNotificationsEnabled,
      'calendar_notifications_enabled': calendarNotificationsEnabled,
      'focus_notifications_enabled': focusNotificationsEnabled,
    });
  }

  Future<void> saveOnboardingSetup(OnboardingSetupData setup) async {
    await _upsertSettingsFields({
      'theme_preset': setup.themePresetId,
      'onboarding_goal': setup.goal,
      'onboarding_discipline': setup.discipline,
      'onboarding_focus_challenge': setup.focusChallenge,
      'theme_updated_at': DateTime.now().toIso8601String(),
    });
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
      AppLogger.error('Error getting blocked apps.', e);
      return [];
    }
  }

  Future<void> deleteMyAccountData() async {
    try {
      await _client.functions.invoke('delete-account');
      return;
    } on FunctionException {
      rethrow;
    }
  }
}
