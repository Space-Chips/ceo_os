import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/settings_repository.dart';
import '../utils/app_logger.dart';
import 'language_overrides.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _defaultLanguage = 'en';
  static const String _localLanguageKey = 'language_preference_v1';
  static const String _cloudSyncPendingKey =
      'language_preference_cloud_pending_v1';
  static const Set<String> _supportedLanguageCodes = {
    'en',
    'fr',
    'zh',
    'hi',
    'es',
    'ar',
    'id',
    'ru',
    'pt',
  };

  final SupabaseClient _client = Supabase.instance.client;
  SettingsRepository _settingsRepository = SettingsRepository();
  StreamSubscription<AuthState>? _authSubscription;

  String _languageCode = _defaultLanguage;
  bool _cloudSyncPending = false;

  LanguageProvider({SettingsRepository? settingsRepository}) {
    if (settingsRepository != null) {
      _settingsRepository = settingsRepository;
    }
    _init();
  }

  String get languageCode => _languageCode;

  Future<void> _init() async {
    await _hydrateFromLocalPrefs();
    await _syncFromCloudRespectingLocalPreference();
    _authSubscription = _client.auth.onAuthStateChange.listen((event) async {
      if (event.session?.user == null) {
        await _hydrateFromLocalPrefs();
        return;
      }
      await _syncFromCloudRespectingLocalPreference();
    });
  }

  Future<void> loadFromSettings() async {
    if (_client.auth.currentUser == null) return;
    if (_cloudSyncPending) {
      await _syncLanguageToCloudBestEffort(_languageCode);
      return;
    }

    try {
      final settings = await _settingsRepository.getAppSettings();
      final code = settings?.languageCode.trim();
      if (code == null || code.isEmpty) return;
      final normalized = _normalize(code);
      _setLanguage(normalized, notify: true);
      await _persistToLocalPrefs(normalized, markPendingCloudSync: false);
    } catch (error) {
      AppLogger.warning(
        'Language load from cloud failed, keeping local language. $error',
      );
    }
  }

  Future<void> setLanguage(String code, {bool persistToCloud = true}) async {
    final normalized = _normalize(code);
    _setLanguage(normalized, notify: true);
    await _persistToLocalPrefs(
      normalized,
      markPendingCloudSync: persistToCloud && _client.auth.currentUser != null
          ? true
          : null,
    );
    if (!persistToCloud || _client.auth.currentUser == null) return;
    await _syncLanguageToCloudBestEffort(normalized);
  }

  Future<bool> syncLanguageToCloud({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (_client.auth.currentUser == null) return true;
    return _syncLanguageToCloudBestEffort(_languageCode, timeout: timeout);
  }

  String t(String key) {
    final raw = _resolveRawTranslation(key);
    final normalized = raw
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return _normalizeLegacyCase(normalized);
  }

  String _resolveRawTranslation(String key) {
    final localeOverride = kTranslationOverrides[_languageCode];
    if (localeOverride != null && localeOverride.containsKey(key)) {
      return localeOverride[key]!;
    }

    final localeTable = _translations[_languageCode];
    if (localeTable != null && localeTable.containsKey(key)) {
      return localeTable[key]!;
    }

    final defaultOverride = kTranslationOverrides[_defaultLanguage];
    if (defaultOverride != null && defaultOverride.containsKey(key)) {
      return defaultOverride[key]!;
    }

    final defaultTable = _translations[_defaultLanguage];
    if (defaultTable != null && defaultTable.containsKey(key)) {
      return defaultTable[key]!;
    }

    return key;
  }

  String _normalizeLegacyCase(String value) {
    final hasLowercase = RegExp(r'[a-zà-öø-ÿа-я]').hasMatch(value);
    final hasUppercase = RegExp(r'[A-ZÀ-ÖØ-ÞА-Я]').hasMatch(value);
    if (hasLowercase || !hasUppercase) return value;

    final words = value.split(' ');
    if (words.isEmpty) return value;
    final normalizedWords = <String>[];
    for (final word in words) {
      if (word.isEmpty) continue;
      if (word.contains('{') || word.contains('}')) {
        normalizedWords.add(word);
        continue;
      }
      final compact = word.replaceAll(RegExp(r'[^A-Za-zÀ-ÖØ-ÞА-Я0-9]'), '');
      if (compact.length <= 2 && RegExp(r'^[A-Z0-9]+$').hasMatch(compact)) {
        normalizedWords.add(word);
        continue;
      }
      final lower = word.toLowerCase();
      final lead = lower[0].toUpperCase();
      normalizedWords.add('$lead${lower.substring(1)}');
    }

    return normalizedWords.join(' ');
  }

  Future<void> _hydrateFromLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localLanguageKey);
    _cloudSyncPending = prefs.getBool(_cloudSyncPendingKey) ?? false;
    final normalized = _normalize(saved ?? _defaultLanguage);
    _setLanguage(normalized, notify: true);
  }

  Future<void> _persistToLocalPrefs(
    String code, {
    bool? markPendingCloudSync,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localLanguageKey, code);
    if (markPendingCloudSync != null) {
      _cloudSyncPending = markPendingCloudSync;
      await prefs.setBool(_cloudSyncPendingKey, markPendingCloudSync);
    }
  }

  String _normalize(String raw) {
    final c = raw.toLowerCase().trim();
    if (_supportedLanguageCodes.contains(c)) return c;
    return _defaultLanguage;
  }

  void _setLanguage(String code, {required bool notify}) {
    _languageCode = code;
    if (notify) notifyListeners();
  }

  Future<void> _syncFromCloudRespectingLocalPreference() async {
    if (_client.auth.currentUser == null) return;
    if (_cloudSyncPending) {
      await _syncLanguageToCloudBestEffort(_languageCode);
      return;
    }
    await loadFromSettings();
  }

  Future<bool> _syncLanguageToCloudBestEffort(
    String normalized, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      await _settingsRepository.updateLanguageCode(normalized).timeout(timeout);
      await _setCloudSyncPending(false);
      return true;
    } catch (error) {
      await _setCloudSyncPending(true);
      AppLogger.warning(
        'Language cloud sync failed, local preference kept. $error',
      );
      return false;
    }
  }

  Future<void> _setCloudSyncPending(bool value) async {
    _cloudSyncPending = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudSyncPendingKey, value);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

const Map<String, Map<String, String>> _translations = {
  'en': {
    'app_name': 'WakeApp',
    'profile': 'PROFILE',
    'save': 'SAVE',
    'saving': 'SAVING',
    'display_name': 'DISPLAY NAME',
    'focus_protocols': 'FOCUS PROTOCOLS',
    'system_preferences': 'SYSTEM PREFERENCES',
    'settings_legal': 'SETTINGS & LEGAL',
    'actions': 'ACTIONS',
    'interface_appearance': 'INTERFACE APPEARANCE',
    'language': 'LANGUAGE',
    'notification_channels': 'NOTIFICATION CHANNELS',
    'privacy_policy': 'PRIVACY POLICY',
    'permissions': 'PERMISSIONS',
    'terms_of_use': 'TERMS OF USE',
    'contact_support': 'CONTACT SUPPORT',
    'data_deletion': 'DATA DELETION',
    'terminate_session': 'TERMINATE SESSION',
    'open_leaderboard': 'OPEN LEADERBOARD',
    'open_rank': 'OPEN RANK',
    'open_screen_manager': 'OPEN SCREEN TIME MANAGER',
    'home': 'HOME',
    'navigation': 'NAVIGATION',
    'settings': 'SETTINGS',
    'app_modules': 'APP_MODULES',
    'notes': 'NOTES',
    'notes_new_note': 'NEW NOTE',
    'notes_last_edit': 'LAST EDIT',
    'notes_untitled': 'Untitled',
    'notes_search_placeholder': 'Search notes...',
    'notes_recent': 'RECENT',
    'notes_all_notes': 'All Notes',
    'notes_no_tag': 'No Tag',
    'notes_tag_placeholder': '#work/meeting',
    'notes_write_placeholder': 'Write your note...',
    'event_types_create_title': 'Create event type',
    'event_types_type_name': 'TYPE NAME',
    'event_types_name_placeholder': 'Work, sport, personal…',
    'event_types_color': 'COLOR',
    'event_types_create_button': '+ Create type',
    'event_types_empty_title': 'No event types yet.',
    'event_types_empty_subtitle': 'Create your first type to organize events.',
    'untitled': 'Untitled',
    'create': 'Create',
    'creating': 'Creating…',
    'rewards': 'REWARDS',
    'cancel': 'CANCEL',
    'welcome_back': 'Welcome back',
    'retry': 'RETRY',
    'start_focus': 'START_FOCUS',
    'quick_actions': 'QUICK_ACTIONS',
    'tasks': 'To-Do',
    'habits': 'HABITS',
    'calendar': 'Schedule',
    'focus': 'FOCUS',
    'dashboard': 'Control Center',
    'leaderboard': 'LEADERBOARD',
    'win_streak': 'WIN_STREAK',
    'screen_time': 'SCREEN_TIME',
    'manager': 'MANAGER',
    'rank': 'RANK',
    'event_types': 'EVENT_TYPES',
    'biannual': 'BIANNUAL',
    'leaderboard_global': 'GLOBAL',
    'leaderboard_friends': 'FRIENDS',
    'connect_friend': 'CONNECT_FRIEND',
    'invite_friends': 'INVITE_FRIENDS',
    'no_friends_connected': 'NO_FRIENDS_CONNECTED',
    'rank_title': 'RANK',
    'tier_map': 'TIER_MAP',
    'screen_time_manager': 'SCREEN_TIME_MANAGER',
    'primary_action': 'PRIMARY_ACTION',
    'focus_mode': 'Focus Mode',
    'start': 'START',
    'today': 'TODAY',
    'avg_7d': 'AVG_7D',
    'streak': 'STREAK',
    'performance_cluster': 'PERFORMANCE_CLUSTER',
    'recent_usage': 'RECENT_USAGE',
    'block_apps_sites': 'BLOCK_APPS_AND_SITES',
    'screen_time_logs': 'SCREEN_TIME_LOGS',
    'blocking_preview': 'BLOCKING_PREVIEW',
    'screen_time_tile_protected': 'PROTECTED',
    'screen_time_tile_targets': 'targets',
    'screen_time_tile_pauses': 'PAUSES',
    'screen_time_tile_scheduled': 'scheduled',
    'screen_time_tile_access': 'ACCESS',
    'screen_time_tile_approved': 'APPROVED',
    'screen_time_tile_allow': 'ALLOW',
    'screen_time_tile_iphone': 'IPHONE',
    'screen_time_tile_unavailable': 'UNAVAIL',
    'screen_time_tile_relaunch': 'RELAUNCH',
    'screen_time_tile_grant_access': 'grant access',
    'screen_time_tile_real_device_only': 'real device only',
    'screen_time_tile_ios16_required': 'iOS 16 required',
    'screen_time_tile_full_restart': 'full restart',
    'see_how_blocking_works': 'See how blocking works',
    'home_dashboard_load_failed': 'Control Center load failed',
    'home_dashboard_retry_hint': 'Tap to try loading Control Center again.',
    'no_active_modules':
        'No active modules. Enable modules from the grid button in the header.',
    'mission': 'MISSION',
    'mission_statement': 'Build high-leverage execution blocks today.',
    'focus_mode_active': 'Focus mode active',
    'ready_for_first_sprint': 'Ready for first sprint',
    'insights': 'INSIGHTS',
    'daily_control_center': 'DAILY CONTROL CENTER',
    'tap_open_dashboard_intelligence': 'Tap to open Control Center',
    'daily_indexes': 'Daily Indexes',
    'task_index': 'Task index',
    'habit_index': 'Habit index',
    'consistency': 'Consistency',
    'planning': 'Planning',
    'tap_manage_focus_mode': 'Tap to manage focus mode',
    'global_ranking_description':
        'Global ranking based on streak, level, and discipline index.',
    'friends_ranking_description':
        'Private friend ranking synced from your connection list.',
    'leaderboard_no_data':
        'No leaderboard data yet. Complete habits/tasks/focus to generate rankings.',
    'connect_friends_hint':
        'Connect friends by email to track their rank progression here.',
    'invite_peers_hint': 'Invite peers to compare streak and rank progression.',
    'manual_connection': 'MANUAL_CONNECTION',
    'syncing_friend_connections': 'SYNCING_FRIEND_CONNECTIONS',
    'friend': 'FRIEND',
    'you': 'YOU',
    'your_position': 'YOUR_POSITION',
    'top': 'Top',
    'please_try_again': 'Please try again in a moment.',
    'connect_friend_title': 'Connect Friend',
    'friend_email': 'Friend email',
    'display_name_optional': 'Display name (optional)',
    'invalid_email': 'INVALID_EMAIL',
    'provide_valid_email': 'Please provide a valid email address.',
    'connection_failed': 'CONNECTION_FAILED',
    'friend_connected': 'FRIEND_CONNECTED',
    'friend_connected_message':
        'Friend connection is now visible in your private ranking tab.',
    'remove_friend': 'Remove Friend',
    'remove_friend_confirm': 'Remove {friend} from this tab?',
    'delete_failed': 'DELETE_FAILED',
    'unable_remove_friend': 'Unable to remove this friend now.',
    'invite_ready': 'INVITE_READY',
    'invitation_copied': 'Invitation copied. Share it with your peers.',
    'ok': 'OK',
    'connect': 'Connect',
    'remove': 'Remove',
    'starter': 'Starter',
    'rank_level': 'LEVEL',
    'rank_points': 'POINTS',
    'rank_at_rank': 'AT_RANK',
    'rank_previous': 'PREVIOUS',
    'rank_best': 'BEST',
    'rank_screen': 'SCREEN',
    'rank_global_summary':
        'Global position #{position} of {total} • Top {top}%',
    'live': 'LIVE',
    'highest_tier': 'You are at the highest configured tier.',
    'next_tier': 'Next tier',
    'current': 'CURRENT',
    'unlocked': 'UNLOCKED',
    'locked': 'LOCKED',
    'primary_action_subtitle': 'Protected deep-work environment.',
    'block_list': 'BLOCK_LIST',
    'tap_configure_first_list': 'Tap to configure your first list',
    'targets_protected': '{count} targets protected',
    'targets_currently_protected': '{count} targets currently protected',
    'leaderboard_subtitle': 'Global rankings and friends progress',
    'screen_time_logs_subtitle': 'View detailed usage records',
    'no_screen_time_logs': 'No screen-time logs available yet.',
    'blocking_note':
        'NOTE: Full app/site blocking behavior is most reliable on physical iPhone devices.',
    'unknown': 'Unknown',
    'open_settings': 'Open Settings',
    'focus_start_timer_only': 'Start Timer Only',
    'focus_turn_on_android_access': 'Turn On Android Protection Access',
    'focus_turn_on_screen_time_access': 'Turn On Screen Time Access',
    'focus_blocking_not_active_yet': 'Blocking Not Active Yet',
    'focus_blocking_unavailable_here': 'Blocking Unavailable Here',
    'focus_notice_android_settings_off':
        'Focus Mode can block selected apps and supported websites on this Android device, but Accessibility or Usage Access is currently off. Re-enable protection in Android settings, or continue with a timer-only session.',
    'focus_notice_ios_settings_off':
        'Focus Mode can block apps and websites on this iPhone, but Screen Time / Family Controls access is currently off. You can re-enable it in iOS Settings, or continue with a timer-only session.',
    'focus_notice_android_timer_only':
        'Focus Mode can still start a timer right now, but blocked apps and supported websites will remain available until Android protection permissions are granted.',
    'focus_notice_ios_timer_only':
        'Focus Mode can still start a timer right now, but blocked apps and websites will remain available until Screen Time / Family Controls access is granted.',
    'focus_notice_android_runtime_unavailable':
        'This runtime does not currently expose Android protection services. You can still run the focus timer, but apps and websites will not be blocked here.',
    'focus_notice_ios_runtime_unavailable':
        'This runtime does not currently expose Apple Screen Time / Family Controls protection. You can still run the focus timer, but apps and websites will not be blocked.',
    'focus_warning_android_runtime_unavailable':
        'Android protection is unavailable on this runtime.\nThe focus timer still works, but apps and websites cannot be blocked here.',
    'focus_warning_ios_runtime_unavailable':
        'Apple Screen Time protection is unavailable on this runtime.\nThe focus timer still works, but apps and websites cannot be blocked here.',
    'focus_warning_android_access_off':
        'Android protection access is currently off.\nOpen Android settings to restore blocked apps and supported websites during Focus Mode.',
    'focus_warning_ios_access_off':
        'Screen Time / Family Controls access is currently off.\nOpen iOS Settings to restore blocked apps and websites during Focus Mode.',
    'focus_warning_android_not_enabled':
        'Android protection access is not enabled yet.\nGrant Accessibility and Usage Access to let Focus Mode block selected apps and supported websites on this device.',
    'focus_warning_ios_not_enabled':
        'Screen Time / Family Controls access is not enabled yet.\nGrant access to let Focus Mode block selected apps and websites on this device.',
    'focus_enable_protection': 'Enable protection',
    'focus_protection': 'Focus Protection',
    'focus_enter_zone': 'ENTER THE ZONE',
    'focus_select_duration': 'Select duration',
    'focus_min': 'min',
    'focus_custom_duration': 'Custom duration',
    'focus_warning': 'WARNING',
    'focus_warning_exit_resets_streak':
        'Early exit will RESET your Win Streak to ZERO',
    'focus_current_streak': 'Current Streak',
    'focus_begin_mode': 'BEGIN FOCUS MODE',
    'focus_plan': 'PLAN',
    'focus_no_targets_warning':
        'No restricted app/site found in Blocked apps & sites.\nFocus timer will run, but nothing can be blocked until you add targets there.',
    'focus_blocking_summary':
        'Focus will block {apps} app(s) and {websites} website(s) from Blocked apps & sites for the full session.',
    'focus_record': 'RECORD',
    'focus_success': 'SUCCESS',
    'focus_complete': 'COMPLETE',
    'focus_exit_window': 'EXIT WINDOW',
    'focus_deep_work': 'DEEP WORK',
    'focus_session': 'Focus Session',
    'focus_exit_request': 'Exit Request',
    'focus_request_exit': 'REQUEST EXIT (100s)',
    'focus_exit_ready_message':
        'You can now leave Focus Mode. This will break your streak.',
    'focus_hold_before_quit':
        'Hold for {countdown} before quitting. You can return anytime.',
    'focus_return_to_session': 'RETURN TO SESSION',
    'focus_quit_now_reset_streak': 'QUIT NOW (RESET STREAK)',
    'focus_quit_available_in': 'QUIT AVAILABLE IN {countdown}',
    'focus_return_home': 'RETURN TO HOME',
    'focus_skip': 'Skip',
    'focus_continue': 'Continue',
    'focus_understood': 'Understood',
    'focus_later': 'Later',
    'focus_active': 'FOCUS ACTIVE',
    'focus_plus_one_streak': '+1 WIN STREAK',
    'focus_blocking_active_until_end': 'Blocking active until the end',
    'focus_prep_intro_title': 'Prepare your Focus mode',
    'focus_prep_intro_body':
        'During a session, WakeApp blocks all apps in your block list, even those with remaining screen time.',
    'focus_prep_intro_goal': 'Goal: a clear start in under 15 seconds.',
    'focus_prep_demo_title': 'What happens during Focus',
    'focus_prep_demo_body':
        'Targeted apps become unavailable until the timer ends. The session stays active even if you leave WakeApp.',
    'focus_prep_checklist_title': 'Session rules',
    'focus_prep_checklist_body': 'You can now start with confidence.',
    'focus_prep_rule_blocking':
        'Apps in your block list are blocked during the session.',
    'focus_prep_rule_streak_daily_first':
        'The first completed session of the day adds +1 to your streak.',
    'focus_prep_rule_streak_once_per_day': 'Only one streak increase per day.',
    'focus_prep_rule_no_daily_session_required':
        'You do not need to run a session every day to keep your streak.',
    'focus_prep_rule_keep_streak_no_quit':
        'You keep your streak as long as you do not quit an active session.',
    'focus_prep_start_focus': 'Start Focus',
    'focus_skip_for_now': 'Skip for now',
    'profile_theme_picker_subtitle': 'Choose your color scheme and typography.',
    'theme_sync_error': 'THEME_SYNC_ERROR',
    'theme_sync_error_message':
        'Your appearance changed on this device, but we could not save it to your account right now. Please try again in a moment.',
    'dark_theme': 'Dark theme',
    'light_theme': 'Light theme',
    'premium_unlocked_launch': 'Premium, unlocked during launch',
    'premium_theme': 'Premium theme',
    'language_picker_subtitle': 'Choose your preferred language.',
    'save_failed': 'SAVE_FAILED',
    'language_save_failed': 'Unable to update language preference right now.',
    'notification_channels_subtitle':
        'Manage reminders and alert channels for the operating system.',
    'global_notifications': 'GLOBAL_NOTIFICATIONS',
    'habit_reminders': 'HABIT_REMINDERS',
    'calendar_alerts': 'CALENDAR_ALERTS',
    'focus_session_alerts': 'FOCUS_SESSION_ALERTS',
    'saving_channels': 'SAVING_CHANNELS',
    'save_channels': 'SAVE_CHANNELS',
    'notification_channels_save_failed':
        'Unable to save notification channels right now.',
    'last_updated_dec_2025': 'Last updated: December 2025',
    'support_contact': 'SUPPORT_CONTACT',
    'support_email_copied':
        'Support email copied: timofrmac@gmail.com. Include device, app version, and reproduction steps.',
    'data_deletion_type_delete_hint':
        'Type DELETE to permanently remove your account and associated cloud data. This action cannot be undone.',
    'type_delete': 'Type DELETE',
    'delete': 'Delete',
    'deletion_aborted': 'DELETION_ABORTED',
    'deletion_aborted_message': 'Confirmation token mismatch or flow canceled.',
    'account_data_deleted': 'ACCOUNT_DATA_DELETED',
    'account_data_deleted_message':
        'Your account and associated cloud data have been permanently deleted. You will now be signed out.',
    'deletion_failed': 'DELETION_FAILED',
    'deletion_failed_message':
        'We could not permanently delete your account right now. Please try again in a moment or contact support.',
    'on': 'ON',
    'off': 'OFF',
    'debug': 'DEBUG',
    'database_write_checks': 'DATABASE WRITE CHECKS',
    'theme_preview': 'THEME PREVIEW',
    'your_name': 'Your name',
    'asleep': 'Asleep',
    'focus_sessions': 'SESSIONS',
    'focus_session_duration': 'SESSION DURATION',
    'focus_short_break': 'SHORT BREAK',
    'focus_auto_start_breaks': 'AUTO START BREAKS',
    'prepare_home_screen_blackout': 'PREPARE HOME SCREEN FOR BLACKOUT',
    'habits_swipe_right_goals': 'Swipe right for Goals & Contract →',
    'habits_swipe_left_grid': '← Swipe left for Habits Grid',
    'habits_add_habit': '+ Habit',
    'habits_add_goal': '+ Goal',
    'no_habits': 'NO_HABITS',
    'habit': 'HABIT',
    'habits_week_score': 'WEEK SCORE',
    'habits_target_90': 'TARGET 90%',
    'untitled_goal': 'UNTITLED_GOAL',
    'habits_create_goal': 'Create Goal',
    'habits_goal_name_required': 'Goal name (required)',
    'habits_goal_precision_optional': 'Small precision (optional)',
    'habits_icon_optional': 'Icon (optional)',
    'habits_creating': 'Creating...',
    'habits_create': 'Create',
    'habits_delete_goal_title': 'Delete Goal?',
    'habits_delete_goal_message':
        '"{goal}" will be removed from your active goals.',
    'habits_confirm_goal_deletion_title': 'Confirm Goal Deletion',
    'habits_confirm_goal_deletion_message':
        'This will permanently remove "{goal}" and detach related habits.',
    'habits_delete_habit_title': 'Delete Habit?',
    'habits_delete_habit_message':
        '"{habit}" will be removed from your active habits.',
    'habits_confirm_habit_deletion_title': 'Confirm Habit Deletion',
    'habits_confirm_habit_deletion_message':
        'This will permanently remove "{habit}" from this goal.',
    'no_goals': 'NO_GOALS',
    'habits_create_goal_hint':
        'Create your first goal, then attach habits in the habit form.',
    'habits_no_attached_habits': 'No habits attached yet.',
    'habits_week_contract': 'WEEK CONTRACT',
    'habits_contract_committed': 'CONTRACT COMMITTED FOR THIS WEEK',
    'habits_reward': 'Reward',
    'habits_sanction': 'Sanction',
    'not_set': 'Not set',
    'habits_threshold_locked':
        'Threshold {threshold}% • Locked until next week',
    'habits_unlock_edit': 'UNLOCK_EDIT',
    'habits_reward_placeholder': 'Reward if successful',
    'habits_sanction_placeholder': 'Sanction if failed',
    'habits_threshold': 'THRESHOLD',
    'habits_locked_after_commitment':
        'Locked after commitment for the current week.',
    'habits_commit_contract': 'Commit Contract',
    'back': 'Back',
    'confirm_delete': 'Confirm Delete',
  },
  'fr': {
    'app_name': 'WakeApp',
    'profile': 'PROFIL',
    'save': 'ENREGISTRER',
    'saving': 'ENREGISTREMENT',
    'display_name': 'NOM AFFICHÉ',
    'focus_protocols': 'PROTOCOLES FOCUS',
    'system_preferences': 'PRÉFÉRENCES SYSTÈME',
    'settings_legal': 'PARAMÈTRES ET LÉGAL',
    'actions': 'ACTIONS',
    'interface_appearance': 'APPARENCE INTERFACE',
    'language': 'LANGUE',
    'notification_channels': 'CANAUX NOTIFICATION',
    'privacy_policy': 'POLITIQUE CONFIDENTIALITÉ',
    'permissions': 'AUTORISATIONS',
    'terms_of_use': 'CONDITIONS UTILISATION',
    'contact_support': 'CONTACT SUPPORT',
    'data_deletion': 'SUPPRESSION DONNÉES',
    'terminate_session': 'TERMINER SESSION',
    'open_leaderboard': 'OUVRIR CLASSEMENT',
    'open_rank': 'OUVRIR RANG',
    'open_screen_manager': 'OUVRIR GESTIONNAIRE ÉCRAN',
    'home': 'ACCUEIL',
    'navigation': 'NAVIGATION',
    'settings': 'PARAMÈTRES',
    'app_modules': 'MODULES_APP',
    'notes': 'NOTES',
    'notes_new_note': 'Nouvelle note',
    'notes_last_edit': 'Dernière modif',
    'notes_untitled': 'Sans titre',
    'notes_search_placeholder': 'Rechercher des notes…',
    'notes_recent': 'RÉCENT',
    'notes_all_notes': 'Toutes les notes',
    'notes_no_tag': 'Sans tag',
    'notes_tag_placeholder': '#travail/réunion',
    'notes_write_placeholder': 'Écris ta note…',
    'rewards': 'RÉCOMPENSES',
    'cancel': 'ANNULER',
    'welcome_back': 'Heureux de te revoir',
    'retry': 'RÉESSAYER',
    'start_focus': 'DÉMARRER_FOCUS',
    'quick_actions': 'ACTIONS_RAPIDES',
    'tasks': 'To-Do',
    'habits': 'HABITUDES',
    'calendar': 'Schedule',
    'focus': 'FOCUS',
    'dashboard': 'Control Center',
    'leaderboard': 'CLASSEMENT',
    'win_streak': 'SÉRIE',
    'screen_time': 'TEMPS_ÉCRAN',
    'manager': 'GESTIONNAIRE',
    'rank': 'RANG',
    'event_types': 'TYPES_ÉVÉNEMENTS',
    'event_types_create_title': "Créer un type d'événement",
    'event_types_type_name': 'NOM DU TYPE',
    'event_types_name_placeholder': 'Travail, sport, perso…',
    'event_types_color': 'COULEUR',
    'event_types_create_button': '+ Créer un type',
    'event_types_empty_title': "Aucun type pour l'instant.",
    'event_types_empty_subtitle':
        'Crée ton premier type pour organiser tes événements.',
    'untitled': 'Sans titre',
    'create': 'Créer',
    'creating': 'Création…',
    'biannual': 'SEMESTRIEL',
    'leaderboard_global': 'GLOBAL',
    'leaderboard_friends': 'AMIS',
    'connect_friend': 'CONNECTER_UN_AMI',
    'invite_friends': 'INVITER_DES_AMIS',
    'no_friends_connected': 'AUCUN_AMI_CONNECTÉ',
    'rank_title': 'RANG',
    'tier_map': 'CARTE_DES_NIVEAUX',
    'screen_time_manager': 'GESTIONNAIRE_TEMPS_ÉCRAN',
    'primary_action': 'ACTION_PRINCIPALE',
    'focus_mode': 'Focus Mode',
    'start': 'DÉMARRER',
    'today': 'AUJOURD_HUI',
    'avg_7d': 'MOY_7J',
    'streak': 'SÉRIE',
    'performance_cluster': 'CLUSTER_PERFORMANCE',
    'recent_usage': 'USAGE_RÉCENT',
    'block_apps_sites': 'Bloquer applis et sites',
    'screen_time_logs': 'JOURNAL_TEMPS_ÉCRAN',
    'blocking_preview': 'APERÇU_BLOCAGE',
    'see_how_blocking_works': 'Voir comment le blocage fonctionne',
    'home_dashboard_load_failed': 'Échec du chargement du Control Center',
    'home_dashboard_retry_hint': 'Touchez pour recharger le Control Center.',
    'no_active_modules':
        'Aucun module actif. Activez des modules depuis la grille en en-tête.',
    'mission': 'MISSION',
    'mission_statement':
        "Construis aujourd'hui des blocs d'exécution à fort levier.",
    'focus_mode_active': 'Mode focus actif',
    'ready_for_first_sprint': 'Prêt pour le premier sprint',
    'insights': 'INSIGHTS',
    'daily_control_center': 'CENTRE DE CONTRÔLE QUOTIDIEN',
    'tap_open_dashboard_intelligence': 'Touchez pour ouvrir le Control Center',
    'daily_indexes': 'Indices quotidiens',
    'task_index': 'Indice tâches',
    'habit_index': 'Indice habitudes',
    'consistency': 'Régularité',
    'planning': 'Planification',
    'tap_manage_focus_mode': 'Touchez pour gérer le mode focus',
    'global_ranking_description':
        'Classement global basé sur série, niveau et discipline.',
    'friends_ranking_description':
        'Classement privé des amis synchronisé depuis vos connexions.',
    'leaderboard_no_data':
        'Pas encore de données de classement. Complétez tâches/habitudes/focus.',
    'connect_friends_hint':
        'Connectez des amis par email pour suivre leur progression ici.',
    'invite_peers_hint':
        'Invitez des pairs pour comparer série et progression de rang.',
    'manual_connection': 'CONNEXION_MANUELLE',
    'syncing_friend_connections': 'SYNCHRO_CONNEXIONS_AMIS',
    'friend': 'AMI',
    'you': 'VOUS',
    'your_position': 'VOTRE_POSITION',
    'top': 'Top',
    'please_try_again': 'Veuillez réessayer dans un instant.',
    'connect_friend_title': 'Connecter un ami',
    'friend_email': "Email de l'ami",
    'display_name_optional': "Nom d'affichage (optionnel)",
    'invalid_email': 'EMAIL_INVALIDE',
    'provide_valid_email': 'Veuillez saisir une adresse email valide.',
    'connection_failed': 'ÉCHEC_CONNEXION',
    'friend_connected': 'AMI_CONNECTÉ',
    'friend_connected_message':
        'La connexion ami est visible dans votre onglet privé.',
    'remove_friend': "Retirer l'ami",
    'remove_friend_confirm': 'Retirer {friend} de cet onglet ?',
    'delete_failed': 'ÉCHEC_SUPPRESSION',
    'unable_remove_friend': "Impossible de retirer cet ami maintenant.",
    'invite_ready': 'INVITATION_PRÊTE',
    'invitation_copied': 'Invitation copiée. Partagez-la avec vos pairs.',
    'ok': 'OK',
    'connect': 'Connecter',
    'remove': 'Retirer',
    'starter': 'Starter',
    'rank_level': 'NIVEAU',
    'rank_points': 'POINTS',
    'rank_at_rank': 'AU_RANG',
    'rank_previous': 'PRÉCÉDENT',
    'rank_best': 'MEILLEUR',
    'rank_screen': 'ÉCRAN',
    'rank_global_summary':
        'Position globale #{position} sur {total} • Top {top}%',
    'live': 'LIVE',
    'highest_tier': 'Vous êtes au plus haut niveau configuré.',
    'next_tier': 'Prochain niveau',
    'current': 'ACTUEL',
    'unlocked': 'DÉBLOQUÉ',
    'locked': 'VERROUILLÉ',
    'primary_action_subtitle': 'Environnement de deep work protégé.',
    'block_list': 'LISTE_BLOCAGE',
    'tap_configure_first_list': 'Touchez pour configurer votre première liste',
    'targets_protected': '{count} cibles protégées',
    'targets_currently_protected': '{count} cibles actuellement protégées',
    'leaderboard_subtitle': 'Classements globaux et progression des amis',
    'screen_time_logs_subtitle': "Voir les enregistrements d'usage détaillés",
    'no_screen_time_logs': "Aucun journal de temps d'écran disponible.",
    'blocking_note':
        "NOTE: Le blocage complet app/site est plus fiable sur iPhone physique.",
    'unknown': 'Inconnu',
    'open_settings': 'Ouvrir les réglages',
    'focus_start_timer_only': 'Démarrer le minuteur seulement',
    'focus_turn_on_android_access': "Activer l'accès protection Android",
    'focus_turn_on_screen_time_access': "Activer l'accès Temps d'écran",
    'focus_blocking_not_active_yet': 'Blocage pas encore actif',
    'focus_blocking_unavailable_here': 'Blocage indisponible ici',
    'focus_notice_android_settings_off':
        "Le mode Focus peut bloquer les apps et sites ciblés sur cet appareil Android, mais l'accessibilité ou l'accès usage est désactivé. Réactivez la protection dans les réglages Android, ou continuez en mode minuteur.",
    'focus_notice_ios_settings_off':
        "Le mode Focus peut bloquer les apps et sites sur cet iPhone, mais l'accès Temps d'écran / Family Controls est désactivé. Vous pouvez le réactiver dans les réglages iOS, ou continuer en mode minuteur.",
    'focus_notice_android_timer_only':
        "Le mode Focus peut démarrer un minuteur maintenant, mais les apps et sites ciblés resteront disponibles tant que les permissions Android ne sont pas accordées.",
    'focus_notice_ios_timer_only':
        "Le mode Focus peut démarrer un minuteur maintenant, mais les apps et sites ciblés resteront disponibles tant que l'accès Temps d'écran / Family Controls n'est pas accordé.",
    'focus_notice_android_runtime_unavailable':
        "Ce runtime n'expose pas les services de protection Android. Le minuteur fonctionne, mais les apps et sites ne seront pas bloqués ici.",
    'focus_notice_ios_runtime_unavailable':
        "Ce runtime n'expose pas la protection Apple Temps d'écran / Family Controls. Le minuteur fonctionne, mais les apps et sites ne seront pas bloqués.",
    'focus_warning_android_runtime_unavailable':
        "La protection Android est indisponible sur ce runtime.\nLe minuteur Focus fonctionne, mais apps et sites ne peuvent pas être bloqués ici.",
    'focus_warning_ios_runtime_unavailable':
        "La protection Apple Temps d'écran est indisponible sur ce runtime.\nLe minuteur Focus fonctionne, mais apps et sites ne peuvent pas être bloqués ici.",
    'focus_warning_android_access_off':
        "L'accès protection Android est désactivé.\nOuvrez les réglages Android pour restaurer le blocage pendant le mode Focus.",
    'focus_warning_ios_access_off':
        "L'accès Temps d'écran / Family Controls est désactivé.\nOuvrez les réglages iOS pour restaurer le blocage pendant le mode Focus.",
    'focus_warning_android_not_enabled':
        "L'accès protection Android n'est pas encore activé.\nAccordez Accessibilité et Accès usage pour bloquer apps et sites ciblés.",
    'focus_warning_ios_not_enabled':
        "L'accès Temps d'écran / Family Controls n'est pas encore activé.\nAccordez l'accès pour bloquer apps et sites ciblés.",
    'focus_enable_protection': 'Activer la protection',
    'focus_protection': 'Protection Focus',
    'focus_enter_zone': 'ENTRER DANS LA ZONE',
    'focus_select_duration': 'Choisir la durée',
    'focus_min': 'min',
    'focus_custom_duration': 'Durée personnalisée',
    'focus_warning': 'ATTENTION',
    'focus_warning_exit_resets_streak':
        'Quitter trop tôt RÉINITIALISE ta streak à ZÉRO',
    'focus_current_streak': 'Streak actuelle',
    'focus_begin_mode': 'DÉMARRER LE MODE FOCUS',
    'focus_plan': 'PLANIFIER',
    'focus_no_targets_warning':
        "Aucune app/site restreinte trouvée dans Apps & sites bloqués.\nLe minuteur Focus tournera, mais rien ne sera bloqué tant que vous n'ajoutez pas des cibles.",
    'focus_blocking_summary':
        'Focus bloquera {apps} app(s) et {websites} site(s) depuis Apps & sites bloqués pendant toute la session.',
    'focus_record': 'RECORD',
    'focus_success': 'SUCCÈS',
    'focus_complete': 'COMPLÉTÉ',
    'focus_exit_window': 'FENÊTRE DE SORTIE',
    'focus_deep_work': 'DEEP WORK',
    'focus_session': 'Session Focus',
    'focus_exit_request': 'Demande de sortie',
    'focus_request_exit': 'DEMANDER SORTIE (100s)',
    'focus_exit_ready_message':
        'Vous pouvez maintenant quitter le mode Focus. Cela cassera votre streak.',
    'focus_hold_before_quit':
        'Maintenez {countdown} avant de quitter. Vous pouvez revenir à tout moment.',
    'focus_return_to_session': 'RETOUR À LA SESSION',
    'focus_quit_now_reset_streak': 'QUITTER MAINTENANT (RESET STREAK)',
    'focus_quit_available_in': 'QUITTER DISPONIBLE DANS {countdown}',
    'focus_return_home': "RETOUR À L'ACCUEIL",
    'focus_skip': 'Passer',
    'focus_continue': 'Continuer',
    'focus_understood': 'Compris',
    'focus_later': 'Plus tard',
    'focus_active': 'FOCUS ACTIF',
    'focus_plus_one_streak': '+1 WIN STREAK',
    'focus_blocking_active_until_end': "Blocage actif jusqu'à la fin",
    'focus_prep_intro_title': 'Prépare ton mode Focus',
    'focus_prep_intro_body':
        "Pendant une session, WakeApp bloque toutes les apps de ta liste, même celles avec du temps d'écran restant.",
    'focus_prep_intro_goal':
        'Objectif: un démarrage clair, en moins de 15 secondes.',
    'focus_prep_demo_title': 'Ce qui se passe pendant Focus',
    'focus_prep_demo_body':
        "Les apps ciblées deviennent indisponibles jusqu'à la fin du chrono. La session reste active même si tu quittes WakeApp.",
    'focus_prep_checklist_title': 'Règles de session',
    'focus_prep_checklist_body': 'Tu peux maintenant démarrer en confiance.',
    'focus_prep_rule_blocking':
        'Les apps de ta liste de blocage sont bloquées pendant la session.',
    'focus_prep_rule_streak_daily_first':
        'La première session complétée de la journée ajoute +1 à ta streak.',
    'focus_prep_rule_streak_once_per_day':
        'Une seule hausse de streak par jour.',
    'focus_prep_rule_no_daily_session_required':
        "Tu n'as pas besoin de faire une session chaque jour pour garder ta streak.",
    'focus_prep_rule_keep_streak_no_quit':
        'Tu gardes ta streak si tu ne quittes pas une session en cours.',
    'focus_prep_start_focus': 'Démarrer Focus',
    'focus_skip_for_now': "Passer pour l'instant",
    'profile_theme_picker_subtitle':
        'Choisis ton schéma de couleurs et ta typographie.',
    'theme_sync_error': 'ERREUR_SYNC_THÈME',
    'theme_sync_error_message':
        "L'apparence a changé sur cet appareil, mais nous n'avons pas pu la sauvegarder sur votre compte pour le moment. Réessayez dans un instant.",
    'dark_theme': 'Thème sombre',
    'light_theme': 'Thème clair',
    'premium_unlocked_launch': 'Premium déverrouillé pendant le lancement',
    'premium_theme': 'Thème premium',
    'language_picker_subtitle': 'Choisissez votre langue préférée.',
    'save_failed': 'ÉCHEC_SAUVEGARDE',
    'language_save_failed':
        "Impossible d'enregistrer la préférence de langue pour le moment.",
    'notification_channels_subtitle':
        'Gérez les rappels et canaux de notification du système.',
    'global_notifications': 'NOTIFICATIONS GLOBALES',
    'habit_reminders': 'RAPPELS HABITUDES',
    'calendar_alerts': 'ALERTES CALENDRIER',
    'focus_session_alerts': 'ALERTES SESSION FOCUS',
    'saving_channels': 'ENREGISTREMENT_CANAUX',
    'save_channels': 'ENREGISTRER_CANAUX',
    'notification_channels_save_failed':
        "Impossible d'enregistrer les canaux de notification pour le moment.",
    'last_updated_dec_2025': 'Dernière mise à jour: décembre 2025',
    'support_contact': 'CONTACT_SUPPORT',
    'support_email_copied':
        'Email support copié: timofrmac@gmail.com. Incluez appareil, version app et étapes.',
    'data_deletion_type_delete_hint':
        'Tapez DELETE pour supprimer définitivement votre compte et les données cloud associées. Cette action est irréversible.',
    'type_delete': 'Tapez DELETE',
    'delete': 'Supprimer',
    'deletion_aborted': 'SUPPRESSION_ANNULÉE',
    'deletion_aborted_message':
        'Token de confirmation invalide ou action annulée.',
    'account_data_deleted': 'DONNÉES_COMPTE_SUPPRIMÉES',
    'account_data_deleted_message':
        'Votre compte et vos données cloud associées ont été supprimés définitivement. Vous allez être déconnecté.',
    'deletion_failed': 'ÉCHEC_SUPPRESSION',
    'deletion_failed_message':
        "Nous n'avons pas pu supprimer votre compte pour le moment. Réessayez dans un instant ou contactez le support.",
    'on': 'ON',
    'off': 'OFF',
    'debug': 'DEBUG',
    'database_write_checks': "VÉRIFICATIONS ÉCRITURE BASE",
    'theme_preview': 'APERÇU THÈME',
    'your_name': 'Votre nom',
    'asleep': 'Endormi',
    'focus_sessions': 'SESSIONS',
    'focus_session_duration': 'DURÉE SESSION',
    'focus_short_break': 'PAUSE COURTE',
    'focus_auto_start_breaks': 'DÉMARRAGE AUTO PAUSES',
    'prepare_home_screen_blackout': "PRÉPARER L'ÉCRAN POUR BLACKOUT",
    'habits_swipe_right_goals': 'Glisse à droite pour Objectifs & Contrat →',
    'habits_swipe_left_grid': '← Glisse à gauche pour la grille Habitudes',
    'habits_add_habit': '+ Habitude',
    'habits_add_goal': '+ Objectif',
    'no_habits': 'AUCUNE_HABITUDE',
    'habit': 'HABITUDE',
    'habits_week_score': 'SCORE SEMAINE',
    'habits_target_90': 'OBJECTIF 90%',
    'untitled_goal': 'OBJECTIF_SANS_TITRE',
    'habits_create_goal': 'Créer un objectif',
    'habits_goal_name_required': "Nom de l'objectif (requis)",
    'habits_goal_precision_optional': 'Précision (optionnelle)',
    'habits_icon_optional': 'Icône (optionnelle)',
    'habits_creating': 'Création...',
    'habits_create': 'Créer',
    'habits_delete_goal_title': "Supprimer l'objectif ?",
    'habits_delete_goal_message':
        '« {goal} » sera retiré de vos objectifs actifs.',
    'habits_confirm_goal_deletion_title':
        "Confirmer la suppression de l'objectif",
    'habits_confirm_goal_deletion_message':
        'Cette action supprimera définitivement « {goal} » et détachera les habitudes liées.',
    'habits_delete_habit_title': "Supprimer l'habitude ?",
    'habits_delete_habit_message':
        '« {habit} » sera retirée de vos habitudes actives.',
    'habits_confirm_habit_deletion_title':
        "Confirmer la suppression de l'habitude",
    'habits_confirm_habit_deletion_message':
        'Cette action supprimera définitivement « {habit} » de cet objectif.',
    'no_goals': 'AUCUN_OBJECTIF',
    'habits_create_goal_hint':
        "Créez votre premier objectif, puis rattachez des habitudes dans le formulaire d'habitude.",
    'habits_no_attached_habits': "Aucune habitude rattachée pour l'instant.",
    'habits_week_contract': 'CONTRAT HEBDO',
    'habits_contract_committed': 'CONTRAT VALIDÉ POUR CETTE SEMAINE',
    'habits_reward': 'Récompense',
    'habits_sanction': 'Sanction',
    'not_set': 'Non défini',
    'habits_threshold_locked':
        "Seuil {threshold}% • Verrouillé jusqu'à la semaine prochaine",
    'habits_unlock_edit': 'DÉVERROUILLER_ÉDITION',
    'habits_reward_placeholder': 'Récompense en cas de réussite',
    'habits_sanction_placeholder': "Sanction en cas d'échec",
    'habits_threshold': 'SEUIL',
    'habits_locked_after_commitment':
        'Verrouillé après validation pour la semaine en cours.',
    'habits_commit_contract': 'Valider le contrat',
    'back': 'Retour',
    'confirm_delete': 'Confirmer suppression',
  },
  'es': {
    'profile': 'PERFIL',
    'save': 'GUARDAR',
    'saving': 'GUARDANDO',
    'display_name': 'NOMBRE MOSTRADO',
    'focus_protocols': 'PROTOCOLOS DE FOCUS',
    'system_preferences': 'PREFERENCIAS DEL SISTEMA',
    'settings_legal': 'AJUSTES Y LEGAL',
    'actions': 'ACCIONES',
    'interface_appearance': 'APARIENCIA DE INTERFAZ',
    'language': 'IDIOMA',
    'notification_channels': 'CANALES DE NOTIFICACIÓN',
    'privacy_policy': 'POLÍTICA DE PRIVACIDAD',
    'permissions': 'PERMISOS',
    'terms_of_use': 'TÉRMINOS DE USO',
    'contact_support': 'CONTACTAR SOPORTE',
    'data_deletion': 'ELIMINACIÓN DE DATOS',
    'terminate_session': 'CERRAR SESIÓN',
    'open_leaderboard': 'ABRIR CLASIFICACIÓN',
    'open_rank': 'ABRIR RANGO',
    'open_screen_manager': 'ABRIR GESTOR DE PANTALLA',
    'home': 'INICIO',
    'focus': 'FOCUS',
    'habits': 'HÁBITOS',
    'rank': 'RANGO',
    'streak': 'RACHA',
    'cancel': 'CANCELAR',
    'ok': 'OK',
    'on': 'ON',
    'off': 'OFF',
    'delete': 'Eliminar',
    'back': 'Atrás',
    'confirm_delete': 'Confirmar eliminación',
    'open_settings': 'Abrir ajustes',
    'focus_protection': 'Protección Focus',
    'focus_enter_zone': 'ENTRA EN LA ZONA',
    'focus_select_duration': 'Selecciona duración',
    'focus_min': 'min',
    'focus_custom_duration': 'Duración personalizada',
    'focus_warning': 'AVISO',
    'focus_warning_exit_resets_streak': 'Salir antes REINICIA tu racha a CERO',
    'focus_current_streak': 'Racha actual',
    'focus_begin_mode': 'INICIAR MODO FOCUS',
    'focus_plan': 'PLAN',
    'focus_record': 'RÉCORD',
    'focus_success': 'ÉXITO',
    'focus_complete': 'COMPLETADO',
    'focus_exit_window': 'VENTANA DE SALIDA',
    'focus_deep_work': 'TRABAJO PROFUNDO',
    'focus_session': 'Sesión Focus',
    'focus_exit_request': 'Solicitud de salida',
    'focus_request_exit': 'SOLICITAR SALIDA (100s)',
    'focus_return_to_session': 'VOLVER A LA SESIÓN',
    'focus_quit_now_reset_streak': 'SALIR AHORA (REINICIAR RACHA)',
    'focus_return_home': 'VOLVER AL INICIO',
    'focus_skip': 'Omitir',
    'focus_continue': 'Continuar',
    'focus_understood': 'Entendido',
    'focus_later': 'Más tarde',
    'focus_active': 'FOCUS ACTIVO',
    'focus_plus_one_streak': '+1 RACHA',
    'focus_blocking_active_until_end': 'Bloqueo activo hasta el final',
    'focus_prep_intro_title': 'Prepara tu modo Focus',
    'focus_prep_intro_body':
        'Durante una sesión, WakeApp bloquea todas las apps de tu lista, incluso las que todavía tenían tiempo de pantalla disponible.',
    'focus_prep_intro_goal': 'Objetivo: inicio claro en menos de 15 segundos.',
    'focus_prep_demo_title': 'Qué ocurre durante Focus',
    'focus_prep_demo_body':
        'Las apps objetivo no estarán disponibles hasta el final del temporizador. La sesión sigue activa aunque salgas de WakeApp.',
    'focus_prep_checklist_title': 'Reglas de sesión',
    'focus_prep_checklist_body': 'Ahora puedes empezar con confianza.',
    'focus_prep_rule_blocking':
        'Las apps de tu lista de bloqueo se bloquean durante la sesión.',
    'focus_prep_rule_streak_daily_first':
        'La primera sesión completada del día suma +1 a tu racha.',
    'focus_prep_rule_streak_once_per_day': 'Solo un aumento de racha por día.',
    'focus_prep_rule_no_daily_session_required':
        'No necesitas hacer una sesión cada día para mantener tu racha.',
    'focus_prep_rule_keep_streak_no_quit':
        'Mantienes tu racha si no abandonas una sesión activa.',
    'focus_prep_start_focus': 'Iniciar Focus',
    'focus_skip_for_now': 'Omitir por ahora',
    'profile_theme_picker_subtitle': 'Elige esquema de color y tipografía.',
    'dark_theme': 'Tema oscuro',
    'light_theme': 'Tema claro',
    'premium_theme': 'Tema premium',
    'premium_unlocked_launch': 'Premium desbloqueado durante el lanzamiento',
    'language_picker_subtitle': 'Elige tu idioma preferido.',
    'save_failed': 'GUARDADO_FALLIDO',
    'theme_sync_error': 'ERROR_SYNC_TEMA',
    'theme_sync_error_message':
        'El tema cambió en este dispositivo, pero no pudimos guardarlo en tu cuenta ahora.',
    'language_save_failed': 'No se pudo guardar el idioma ahora.',
    'notification_channels_subtitle':
        'Gestiona recordatorios y canales de alerta del sistema.',
    'global_notifications': 'NOTIFICACIONES GLOBALES',
    'habit_reminders': 'RECORDATORIOS DE HÁBITOS',
    'calendar_alerts': 'ALERTAS DE CALENDARIO',
    'focus_session_alerts': 'ALERTAS DE SESIÓN FOCUS',
    'saving_channels': 'GUARDANDO_CANALES',
    'save_channels': 'GUARDAR_CANALES',
    'notification_channels_save_failed':
        'No se pudieron guardar los canales de notificación.',
    'last_updated_dec_2025': 'Última actualización: diciembre 2025',
    'support_contact': 'CONTACTO_SOPORTE',
    'support_email_copied': 'Correo de soporte copiado: timofrmac@gmail.com.',
    'data_deletion_type_delete_hint':
        'Escribe DELETE para eliminar tu cuenta y datos de forma permanente.',
    'type_delete': 'Escribe DELETE',
    'deletion_aborted': 'ELIMINACIÓN_CANCELADA',
    'deletion_aborted_message': 'Confirmación inválida o acción cancelada.',
    'account_data_deleted': 'DATOS_ELIMINADOS',
    'account_data_deleted_message':
        'Tu cuenta y datos asociados fueron eliminados permanentemente.',
    'deletion_failed': 'ELIMINACIÓN_FALLIDA',
    'deletion_failed_message':
        'No pudimos eliminar tu cuenta ahora. Inténtalo de nuevo.',
    'debug': 'DEBUG',
    'database_write_checks': 'VERIFICACIONES DE ESCRITURA DB',
    'theme_preview': 'VISTA PREVIA DE TEMA',
    'your_name': 'Tu nombre',
    'asleep': 'Dormido',
    'focus_sessions': 'SESIONES',
    'focus_session_duration': 'DURACIÓN DE SESIÓN',
    'focus_short_break': 'DESCANSO CORTO',
    'focus_auto_start_breaks': 'INICIO AUTOMÁTICO DE DESCANSOS',
    'prepare_home_screen_blackout': 'PREPARAR PANTALLA PARA BLACKOUT',
    'habits_swipe_right_goals': 'Desliza a la derecha para Metas y Contrato →',
    'habits_swipe_left_grid': '← Desliza a la izquierda para la cuadrícula',
    'habits_add_habit': '+ Hábito',
    'habits_add_goal': '+ Meta',
    'no_habits': 'SIN_HÁBITOS',
    'habit': 'HÁBITO',
    'habits_week_score': 'PUNTAJE SEMANAL',
    'habits_target_90': 'OBJETIVO 90%',
    'untitled_goal': 'META_SIN_TÍTULO',
    'habits_create_goal': 'Crear meta',
    'habits_goal_name_required': 'Nombre de la meta (obligatorio)',
    'habits_goal_precision_optional': 'Precisión (opcional)',
    'habits_icon_optional': 'Icono (opcional)',
    'habits_creating': 'Creando...',
    'habits_create': 'Crear',
    'habits_delete_goal_title': '¿Eliminar meta?',
    'habits_confirm_goal_deletion_title': 'Confirmar eliminación de meta',
    'habits_delete_habit_title': '¿Eliminar hábito?',
    'habits_confirm_habit_deletion_title': 'Confirmar eliminación de hábito',
    'no_goals': 'SIN_METAS',
    'habits_create_goal_hint': 'Crea tu primera meta y vincula hábitos.',
    'habits_no_attached_habits': 'Aún no hay hábitos vinculados.',
    'habits_week_contract': 'CONTRATO SEMANAL',
    'habits_contract_committed': 'CONTRATO CONFIRMADO ESTA SEMANA',
    'habits_reward': 'Recompensa',
    'habits_sanction': 'Sanción',
    'not_set': 'No definido',
    'habits_unlock_edit': 'DESBLOQUEAR_EDICIÓN',
    'habits_reward_placeholder': 'Recompensa si cumples',
    'habits_sanction_placeholder': 'Sanción si fallas',
    'habits_threshold': 'UMBRAL',
    'habits_commit_contract': 'Confirmar contrato',
  },
  'pt': {
    'profile': 'PERFIL',
    'save': 'SALVAR',
    'saving': 'SALVANDO',
    'language': 'IDIOMA',
    'home': 'INÍCIO',
    'focus': 'FOCUS',
    'habits': 'HÁBITOS',
    'interface_appearance': 'APARÊNCIA DA INTERFACE',
    'notification_channels': 'CANAIS DE NOTIFICAÇÃO',
    'contact_support': 'CONTATAR SUPORTE',
    'data_deletion': 'EXCLUSÃO DE DADOS',
    'open_settings': 'Abrir Ajustes',
    'cancel': 'Cancelar',
    'ok': 'OK',
    'delete': 'Excluir',
    'back': 'Voltar',
    'confirm_delete': 'Confirmar exclusão',
    'focus_begin_mode': 'INICIAR MODO FOCUS',
    'focus_plan': 'PLANO',
    'focus_current_streak': 'Sequência atual',
    'focus_warning': 'AVISO',
    'focus_skip': 'Pular',
    'focus_continue': 'Continuar',
    'focus_understood': 'Entendi',
    'focus_later': 'Mais tarde',
    'focus_prep_intro_title': 'Prepare seu modo Focus',
    'focus_prep_intro_body':
        'Durante uma sessão, a WakeApp bloqueia todos os apps da sua lista, inclusive os que ainda tinham tempo de ecrã.',
    'focus_prep_intro_goal':
        'Objetivo: começar com clareza em menos de 15 segundos.',
    'focus_prep_demo_title': 'O que acontece durante o Focus',
    'focus_prep_demo_body':
        'Os apps-alvo ficam indisponíveis até o fim do cronômetro. A sessão continua ativa mesmo fora da WakeApp.',
    'focus_prep_checklist_title': 'Regras da sessão',
    'focus_prep_checklist_body': 'Agora você pode começar com confiança.',
    'focus_prep_rule_blocking':
        'Os apps da sua lista de bloqueio ficam bloqueados durante a sessão.',
    'focus_prep_rule_streak_daily_first':
        'A primeira sessão concluída do dia adiciona +1 à sua sequência.',
    'focus_prep_rule_streak_once_per_day':
        'A sequência só pode aumentar uma vez por dia.',
    'focus_prep_start_focus': 'Iniciar Focus',
    'focus_prep_rule_no_daily_session_required':
        'Você não precisa fazer uma sessão todos os dias para manter sua sequência.',
    'focus_prep_rule_keep_streak_no_quit':
        'Você mantém sua sequência enquanto não sair de uma sessão ativa.',
    'habits_add_habit': '+ Hábito',
    'habits_add_goal': '+ Meta',
    'no_habits': 'SEM_HÁBITOS',
    'no_goals': 'SEM_METAS',
    'habits_week_contract': 'CONTRATO SEMANAL',
    'habits_commit_contract': 'Confirmar contrato',
    'your_name': 'Seu nome',
    'save_failed': 'FALHA_AO_SALVAR',
  },
  'ru': {
    'profile': 'ПРОФИЛЬ',
    'save': 'СОХРАНИТЬ',
    'saving': 'СОХРАНЕНИЕ',
    'language': 'ЯЗЫК',
    'home': 'ГЛАВНАЯ',
    'focus': 'ФОКУС',
    'habits': 'ПРИВЫЧКИ',
    'interface_appearance': 'ОФОРМЛЕНИЕ',
    'notification_channels': 'КАНАЛЫ УВЕДОМЛЕНИЙ',
    'contact_support': 'СВЯЗАТЬСЯ С ПОДДЕРЖКОЙ',
    'data_deletion': 'УДАЛЕНИЕ ДАННЫХ',
    'open_settings': 'Открыть настройки',
    'cancel': 'Отмена',
    'ok': 'OK',
    'delete': 'Удалить',
    'back': 'Назад',
    'confirm_delete': 'Подтвердить удаление',
    'focus_begin_mode': 'НАЧАТЬ РЕЖИМ ФОКУСА',
    'focus_plan': 'ПЛАН',
    'focus_current_streak': 'Текущая серия',
    'focus_warning': 'ВНИМАНИЕ',
    'focus_skip': 'Пропустить',
    'focus_continue': 'Продолжить',
    'focus_understood': 'Понятно',
    'focus_later': 'Позже',
    'focus_prep_intro_title': 'Подготовь режим Focus',
    'focus_prep_intro_body':
        'Во время сессии WakeApp блокирует все приложения из списка блокировки, даже те, где оставалось экранное время.',
    'focus_prep_intro_goal': 'Цель: чёткий старт менее чем за 15 секунд.',
    'focus_prep_demo_title': 'Что происходит во время Focus',
    'focus_prep_demo_body':
        'Целевые приложения недоступны до окончания таймера. Сессия остаётся активной, даже если вы вышли из WakeApp.',
    'focus_prep_checklist_title': 'Правила сессии',
    'focus_prep_checklist_body': 'Теперь можно начинать уверенно.',
    'focus_prep_rule_blocking':
        'Приложения из списка блокировки блокируются на время сессии.',
    'focus_prep_rule_streak_daily_first':
        'Первая завершённая сессия дня добавляет +1 к серии.',
    'focus_prep_rule_streak_once_per_day':
        'Серия может увеличиться только один раз в день.',
    'focus_prep_start_focus': 'Запустить Focus',
    'focus_prep_rule_no_daily_session_required':
        'Не нужно проводить сессию каждый день, чтобы сохранить серию.',
    'focus_prep_rule_keep_streak_no_quit':
        'Серия сохраняется, пока вы не выходите из активной сессии.',
    'habits_add_habit': '+ Привычка',
    'habits_add_goal': '+ Цель',
    'no_habits': 'НЕТ_ПРИВЫЧЕК',
    'no_goals': 'НЕТ_ЦЕЛЕЙ',
    'habits_week_contract': 'НЕДЕЛЬНЫЙ КОНТРАКТ',
    'habits_commit_contract': 'Подтвердить контракт',
    'your_name': 'Ваше имя',
    'save_failed': 'ОШИБКА_СОХРАНЕНИЯ',
  },
  'ar': {
    'profile': 'الملف الشخصي',
    'save': 'حفظ',
    'saving': 'جارٍ الحفظ',
    'language': 'اللغة',
    'home': 'الرئيسية',
    'focus': 'التركيز',
    'habits': 'العادات',
    'interface_appearance': 'مظهر الواجهة',
    'notification_channels': 'قنوات الإشعارات',
    'contact_support': 'الاتصال بالدعم',
    'data_deletion': 'حذف البيانات',
    'open_settings': 'فتح الإعدادات',
    'cancel': 'إلغاء',
    'ok': 'حسناً',
    'delete': 'حذف',
    'back': 'رجوع',
    'confirm_delete': 'تأكيد الحذف',
    'focus_begin_mode': 'ابدأ وضع التركيز',
    'focus_plan': 'خطة',
    'focus_current_streak': 'السلسلة الحالية',
    'focus_warning': 'تحذير',
    'focus_skip': 'تخطي',
    'focus_continue': 'متابعة',
    'focus_understood': 'مفهوم',
    'focus_later': 'لاحقاً',
    'focus_prep_intro_title': 'حضّر وضع التركيز',
    'focus_prep_intro_body':
        'أثناء الجلسة، يقوم WakeApp بحظر كل التطبيقات في قائمة الحظر، حتى التطبيقات التي ما زال لديها وقت شاشة متبقٍ.',
    'focus_prep_intro_goal': 'الهدف: بداية واضحة خلال أقل من 15 ثانية.',
    'focus_prep_demo_title': 'ماذا يحدث أثناء التركيز',
    'focus_prep_demo_body':
        'تصبح التطبيقات المستهدفة غير متاحة حتى ينتهي المؤقت. وتبقى الجلسة نشطة حتى لو غادرت WakeApp.',
    'focus_prep_checklist_title': 'قواعد الجلسة',
    'focus_prep_checklist_body': 'الآن يمكنك البدء بثقة.',
    'focus_prep_rule_blocking':
        'يتم حظر التطبيقات الموجودة في قائمة الحظر أثناء الجلسة.',
    'focus_prep_rule_streak_daily_first':
        'أول جلسة مكتملة في اليوم تضيف +1 إلى السلسلة.',
    'focus_prep_rule_streak_once_per_day':
        'لا يمكن أن تزيد السلسلة أكثر من مرة واحدة في اليوم.',
    'focus_prep_start_focus': 'ابدأ التركيز',
    'focus_prep_rule_no_daily_session_required':
        'لست بحاجة إلى جلسة كل يوم للحفاظ على السلسلة.',
    'focus_prep_rule_keep_streak_no_quit':
        'تحافظ على السلسلة ما دمت لا تنهي جلسة نشطة قبل وقتها.',
    'habits_add_habit': '+ عادة',
    'habits_add_goal': '+ هدف',
    'no_habits': 'لا_عادات',
    'no_goals': 'لا_أهداف',
    'habits_week_contract': 'عقد الأسبوع',
    'habits_commit_contract': 'تأكيد العقد',
    'your_name': 'اسمك',
    'save_failed': 'فشل_الحفظ',
  },
  'id': {
    'profile': 'PROFIL',
    'save': 'SIMPAN',
    'saving': 'MENYIMPAN',
    'language': 'BAHASA',
    'home': 'BERANDA',
    'focus': 'FOKUS',
    'habits': 'KEBIASAAN',
    'interface_appearance': 'TAMPILAN ANTARMUKA',
    'notification_channels': 'KANAL NOTIFIKASI',
    'contact_support': 'HUBUNGI DUKUNGAN',
    'data_deletion': 'HAPUS DATA',
    'open_settings': 'Buka Pengaturan',
    'cancel': 'Batal',
    'ok': 'OK',
    'delete': 'Hapus',
    'back': 'Kembali',
    'confirm_delete': 'Konfirmasi hapus',
    'focus_begin_mode': 'MULAI MODE FOKUS',
    'focus_plan': 'Rencana',
    'focus_current_streak': 'Streak saat ini',
    'focus_warning': 'PERINGATAN',
    'focus_skip': 'Lewati',
    'focus_continue': 'Lanjut',
    'focus_understood': 'Mengerti',
    'focus_later': 'Nanti',
    'focus_prep_intro_title': 'Siapkan mode Fokus',
    'focus_prep_intro_body':
        'Selama sesi, WakeApp memblokir semua aplikasi di daftar blokir kamu, termasuk aplikasi yang masih punya sisa waktu layar.',
    'focus_prep_intro_goal':
        'Tujuan: mulai dengan jelas dalam kurang dari 15 detik.',
    'focus_prep_demo_title': 'Apa yang terjadi saat Focus',
    'focus_prep_demo_body':
        'Aplikasi target menjadi tidak tersedia sampai timer selesai. Sesi tetap aktif meski kamu keluar dari WakeApp.',
    'focus_prep_checklist_title': 'Aturan sesi',
    'focus_prep_checklist_body': 'Sekarang kamu bisa mulai dengan yakin.',
    'focus_prep_rule_blocking':
        'Aplikasi di daftar blokir kamu diblokir selama sesi.',
    'focus_prep_rule_streak_daily_first':
        'Sesi pertama yang selesai hari ini menambah +1 streak.',
    'focus_prep_rule_streak_once_per_day':
        'Streak hanya bisa bertambah sekali per hari.',
    'focus_prep_start_focus': 'Mulai Fokus',
    'focus_prep_rule_no_daily_session_required':
        'Kamu tidak harus menjalankan sesi setiap hari untuk menjaga streak.',
    'focus_prep_rule_keep_streak_no_quit':
        'Streak tetap terjaga selama kamu tidak keluar dari sesi aktif.',
    'habits_add_habit': '+ Kebiasaan',
    'habits_add_goal': '+ Tujuan',
    'no_habits': 'TIDAK_ADA_KEBIASAAN',
    'no_goals': 'TIDAK_ADA_TUJUAN',
    'habits_week_contract': 'KONTRAK MINGGUAN',
    'habits_commit_contract': 'Komit kontrak',
    'your_name': 'Nama Anda',
    'save_failed': 'GAGAL_SIMPAN',
  },
  'hi': {
    'profile': 'प्रोफ़ाइल',
    'save': 'सेव करें',
    'saving': 'सेव हो रहा है',
    'language': 'भाषा',
    'home': 'होम',
    'focus': 'फोकस',
    'habits': 'आदतें',
    'interface_appearance': 'इंटरफ़ेस रूप',
    'notification_channels': 'नोटिफिकेशन चैनल',
    'contact_support': 'सपोर्ट संपर्क',
    'data_deletion': 'डेटा हटाना',
    'open_settings': 'सेटिंग्स खोलें',
    'cancel': 'रद्द करें',
    'ok': 'ठीक है',
    'delete': 'हटाएँ',
    'back': 'वापस',
    'confirm_delete': 'हटाना पुष्टि करें',
    'focus_begin_mode': 'फोकस मोड शुरू करें',
    'focus_plan': 'योजना',
    'focus_current_streak': 'मौजूदा स्ट्रीक',
    'focus_warning': 'चेतावनी',
    'focus_skip': 'स्किप करें',
    'focus_continue': 'जारी रखें',
    'focus_understood': 'समझ गया',
    'focus_later': 'बाद में',
    'focus_prep_intro_title': 'फोकस मोड तैयार करें',
    'focus_prep_intro_body':
        'सत्र के दौरान WakeApp आपकी ब्लॉक सूची की सभी ऐप्स को ब्लॉक करता है, उन ऐप्स को भी जिनमें स्क्रीन टाइम बचा हो।',
    'focus_prep_intro_goal': 'लक्ष्य: 15 सेकंड से कम समय में स्पष्ट शुरुआत।',
    'focus_prep_demo_title': 'Focus के दौरान क्या होता है',
    'focus_prep_demo_body':
        'टार्गेट ऐप्स टाइमर खत्म होने तक उपलब्ध नहीं रहते। WakeApp से बाहर जाने पर भी सत्र सक्रिय रहता है।',
    'focus_prep_checklist_title': 'सेशन नियम',
    'focus_prep_checklist_body': 'अब आप भरोसे के साथ शुरू कर सकते हैं।',
    'focus_prep_rule_blocking':
        'आपकी ब्लॉक सूची की ऐप्स सत्र के दौरान ब्लॉक रहती हैं।',
    'focus_prep_rule_streak_daily_first':
        'दिन की पहली पूरी हुई सत्र से स्ट्रीक में +1 जुड़ता है।',
    'focus_prep_rule_streak_once_per_day':
        'एक दिन में स्ट्रीक केवल एक बार बढ़ सकती है।',
    'focus_prep_start_focus': 'फोकस शुरू करें',
    'focus_prep_rule_no_daily_session_required':
        'स्ट्रीक बनाए रखने के लिए हर दिन सत्र करना ज़रूरी नहीं है।',
    'focus_prep_rule_keep_streak_no_quit':
        'जब तक आप सक्रिय सत्र बीच में नहीं छोड़ते, आपकी स्ट्रीक बनी रहती है।',
    'habits_add_habit': '+ आदत',
    'habits_add_goal': '+ लक्ष्य',
    'no_habits': 'कोई_आदत_नहीं',
    'no_goals': 'कोई_लक्ष्य_नहीं',
    'habits_week_contract': 'साप्ताहिक अनुबंध',
    'habits_commit_contract': 'अनुबंध पुष्टि',
    'your_name': 'आपका नाम',
    'save_failed': 'सेव_विफल',
  },
  'zh': {
    'app_name': '觉醒应用',
    'profile': '个人资料',
    'save': '保存',
    'saving': '正在保存',
    'language': '语言',
    'home': '主页',
    'focus': '专注',
    'habits': '习惯',
    'interface_appearance': '界面外观',
    'notification_channels': '通知渠道',
    'contact_support': '联系支持',
    'data_deletion': '删除数据',
    'open_settings': '打开设置',
    'cancel': '取消',
    'ok': '确定',
    'delete': '删除',
    'back': '返回',
    'confirm_delete': '确认删除',
    'focus_begin_mode': '开始专注模式',
    'focus_plan': '计划',
    'focus_current_streak': '当前连胜',
    'focus_warning': '警告',
    'focus_skip': '跳过',
    'focus_continue': '继续',
    'focus_understood': '明白了',
    'focus_later': '稍后',
    'focus_prep_intro_title': '准备你的专注模式',
    'focus_prep_intro_body': '在专注会话期间，WakeApp 会屏蔽你拉黑列表中的所有应用，包括仍有剩余屏幕时间的应用。',
    'focus_prep_intro_goal': '目标：在 15 秒内清晰进入状态。',
    'focus_prep_demo_title': '专注期间会发生什么',
    'focus_prep_demo_body': '目标应用会在计时结束前保持不可用。即使离开 WakeApp，会话也会继续进行。',
    'focus_prep_checklist_title': '会话规则',
    'focus_prep_checklist_body': '现在你可以放心开始。',
    'focus_prep_rule_blocking': '拉黑列表中的应用会在会话期间被屏蔽。',
    'focus_prep_rule_streak_daily_first': '当天第一场完成的会话会让连胜 +1。',
    'focus_prep_rule_streak_once_per_day': '连胜每天最多只会增加一次。',
    'focus_prep_start_focus': '开始专注',
    'focus_prep_rule_no_daily_session_required': '你不需要每天都做会话来保持连胜。',
    'focus_prep_rule_keep_streak_no_quit': '只要不提前退出进行中的会话，你就能保住连胜。',
    'habits_add_habit': '+ 习惯',
    'habits_add_goal': '+ 目标',
    'no_habits': '没有_习惯',
    'no_goals': '没有_目标',
    'habits_week_contract': '每周契约',
    'habits_commit_contract': '确认契约',
    'your_name': '你的名字',
    'save_failed': '保存失败',
  },
};
