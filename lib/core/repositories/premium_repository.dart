import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/tester_config.dart';
import '../models/premium_models.dart';
import '../services/supabase_service.dart';

class PremiumRepository {
  final SupabaseService _supabaseService;

  PremiumRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  static const String _clientGraceUntilKey = 'premium_client_grace_until_v1';
  static const Duration _clientGraceDuration = Duration(hours: 24);
  static const Duration _billingPollInterval = Duration(seconds: 2);
  static const Duration _billingPollTimeout = Duration(seconds: 30);
  static const String _runtimeCacheKey = 'premium_runtime_cache_v1';
  static const String _runtimeCacheAtKey = 'premium_runtime_cache_at_v1';
  static const Duration _runtimeCacheValidity = Duration(hours: 24);

  SupabaseClient get _client => _supabaseService.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<PremiumConfig> getConfig() async {
    final premium = await _readConfig('premium');
    final global = await _readConfig('global');
    final merged = <String, dynamic>{...global, ...premium};
    return _configFromJson(merged);
  }

  Future<PremiumRuntime> getRuntime() async {
    try {
      final fresh = await _fetchRuntime();
      await _cacheRuntime(fresh);
      return fresh;
    } catch (_) {
      // Network/Supabase failure — fall back to cached runtime if recent.
      final cached = await _readCachedRuntime();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<PremiumRuntime> _fetchRuntime() async {
    final config = await getConfig();
    final billing = await _getBillingSubscription();
    final entitlements = await _syncAndGetEntitlements();
    final clientGraceActive = await _isClientGraceActive();

    final subscriptionStatus = _stringValue(billing?['status']) ?? 'free';
    final normalizedStatus = subscriptionStatus.toLowerCase().trim();
    final hasPaidSubscription = const {
      'active',
      'trialing',
    }.contains(normalizedStatus);
    final isTrialing = normalizedStatus == 'trialing';
    final overrideActive = _isOverrideActive(entitlements);
    final grandfathered = _boolValue(entitlements?['is_grandfathered']);
    final themeBundle = _boolValue(entitlements?['theme_bundle_granted']);
    final earlyLaunch = _boolValue(entitlements?['early_launch_user']);
    final launchMode = _boolValue(
      {'value': config.paywallEnabled == false}['value'],
    );

    final isPremiumUser =
        TesterConfig.devForcePremium ||
        hasPaidSubscription ||
        clientGraceActive ||
        overrideActive ||
        grandfathered ||
        (!config.paywallEnabled && (earlyLaunch || themeBundle || launchMode));

    return PremiumRuntime(
      config: config,
      subscriptionStatus: subscriptionStatus,
      resolved: PremiumResolvedAccess(
        isPremiumUser: isPremiumUser,
        clientGraceActive: clientGraceActive,
        hasPaidSubscription: hasPaidSubscription,
        isTrialing: isTrialing,
      ),
    );
  }

  Future<PremiumCheckResult> canAccessAdvancedCalendar() async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess) return const PremiumCheckResult.allowed();
    return const PremiumCheckResult.blocked(reason: 'calendar_advanced');
  }

  Future<PremiumCheckResult> canUseTheme(String presetId) async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess) return const PremiumCheckResult.allowed();
    if (!runtime.config.premiumThemes.contains(presetId)) {
      return const PremiumCheckResult.allowed();
    }
    return const PremiumCheckResult.blocked(reason: 'theme');
  }

  Future<PremiumCheckResult> canCreateTask([int currentCount = 0]) async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess || runtime.resolved.canCreateUnlimitedTasks) {
      return const PremiumCheckResult.allowed();
    }
    final activeCount = currentCount > 0
        ? currentCount
        : await _countRows(
            table: 'pareto_tasks',
            filters: (query) => query.eq('completed', false),
          );
    if (activeCount >= runtime.config.tasksFreeLimit) {
      return PremiumCheckResult.blocked(
        reason: 'tasks',
        limit: runtime.config.tasksFreeLimit,
        current: activeCount,
      );
    }
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canCreateHabit([int currentCount = 0]) async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess || runtime.resolved.canCreateUnlimitedHabits) {
      return const PremiumCheckResult.allowed();
    }
    final activeCount = currentCount > 0
        ? currentCount
        : await _countRows(
            table: 'habits',
            filters: (query) => query.eq('archived', false),
          );
    if (activeCount >= runtime.config.habitsFreeLimit) {
      return PremiumCheckResult.blocked(
        reason: 'habits',
        limit: runtime.config.habitsFreeLimit,
        current: activeCount,
      );
    }
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canCreateNote([int currentCount = 0]) async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess) return const PremiumCheckResult.allowed();
    final activeCount = currentCount > 0
        ? currentCount
        : await _countRows(table: 'notes');
    if (activeCount >= runtime.config.notesFreeLimit) {
      return PremiumCheckResult.blocked(
        reason: 'notes',
        limit: runtime.config.notesFreeLimit,
        current: activeCount,
      );
    }
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canAccessReports() async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess) return const PremiumCheckResult.allowed();
    return const PremiumCheckResult.blocked(reason: 'reports');
  }

  Future<PremiumCheckResult> canAccessScreenTimeManager() async {
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canAccessLeaderboard() async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess) return const PremiumCheckResult.allowed();
    return const PremiumCheckResult.blocked(reason: 'leaderboard');
  }

  Future<PremiumCheckResult> canConfigureHomeWidgets() async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess) return const PremiumCheckResult.allowed();
    return const PremiumCheckResult.blocked(reason: 'home_widgets');
  }

  Future<PremiumCheckResult> canStartFocusSession(int minutes) async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess || runtime.resolved.canUseExtendedFocus) {
      return const PremiumCheckResult.allowed();
    }
    if (minutes > runtime.config.focusFreeMinutesLimit) {
      return PremiumCheckResult.blocked(
        reason: 'focus',
        limit: runtime.config.focusFreeMinutesLimit,
        current: minutes,
      );
    }
    final countToday = await _countRows(
      table: 'focus_sessions',
      filters: (query) => query.gte('start_time', _dayStartIso(DateTime.now())),
    );
    if (countToday >= runtime.config.focusFreeDailyLimit) {
      return PremiumCheckResult.blocked(
        reason: 'focus_daily',
        limit: runtime.config.focusFreeDailyLimit,
        current: countToday,
      );
    }
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canStartCeoSession(int minutes) async {
    final runtime = await getRuntime();
    final hasPremiumAccess = _hasOpenAccess(runtime);
    if (hasPremiumAccess || runtime.resolved.canUseExtendedCeoMode) {
      return const PremiumCheckResult.allowed();
    }
    final ceoMinutesLimit = runtime.config.ceoModeFreeMinutesLimit;
    if (ceoMinutesLimit > 0 && minutes > ceoMinutesLimit) {
      return PremiumCheckResult.blocked(
        reason: 'ceo_mode',
        limit: ceoMinutesLimit,
        current: minutes,
      );
    }
    final weekStart = _weekStart(DateTime.now());
    final countThisWeek = await _countRows(
      table: 'ceo_mode_sessions',
      filters: (query) => query.gte('started_at', weekStart.toIso8601String()),
    );
    if (countThisWeek >= runtime.config.ceoModeFreeWeeklyLimit) {
      return PremiumCheckResult.blocked(
        reason: 'ceo_mode_weekly',
        limit: runtime.config.ceoModeFreeWeeklyLimit,
        current: countThisWeek,
      );
    }
    return const PremiumCheckResult.allowed();
  }

  Future<void> activateClientGraceWindow() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(_clientGraceDuration);
    await prefs.setString(_clientGraceUntilKey, until.toIso8601String());
  }

  Future<bool> waitForBillingActivation() async {
    final deadline = DateTime.now().add(_billingPollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final runtime = await getRuntime();
      if (runtime.resolved.hasPaidSubscription) {
        return true;
      }
      await Future<void>.delayed(_billingPollInterval);
    }
    return false;
  }

  bool _hasOpenAccess(PremiumRuntime runtime) {
    return !runtime.config.paywallEnabled || runtime.resolved.isPremiumUser;
  }

  Future<Map<String, dynamic>> _readConfig(String key) async {
    try {
      final row = await _client
          .from('app_configs')
          .select('config_value')
          .eq('config_key', key)
          .maybeSingle();
      final value = row?['config_value'];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {
      // Remote config is best effort; defaults keep the app usable offline.
    }
    return const <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> _getBillingSubscription() async {
    final uid = _currentUserId;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('billing_subscriptions')
          .select()
          .eq('created_by', uid)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _syncAndGetEntitlements() async {
    final uid = _currentUserId;
    if (uid == null) return null;
    try {
      final synced = await _client.rpc('sync_launch_entitlements');
      if (synced is Map<String, dynamic>) return synced;
      if (synced is Map) return Map<String, dynamic>.from(synced);
    } catch (_) {
      // Fallback to direct read when the RPC is unavailable on older schemas.
    }
    try {
      final row = await _client
          .from('user_entitlements')
          .select()
          .eq('created_by', uid)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<int> _countRows({
    required String table,
    dynamic Function(dynamic query)? filters,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return 0;
    try {
      var query = _client.from(table).select('id').eq('created_by', uid);
      if (filters != null) query = filters(query);
      final rows = await query;
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _isClientGraceActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_clientGraceUntilKey);
      final until = raw == null ? null : DateTime.tryParse(raw);
      if (until == null) return false;
      if (until.isAfter(DateTime.now())) return true;
      await prefs.remove(_clientGraceUntilKey);
    } catch (_) {
      return false;
    }
    return false;
  }

  bool _isOverrideActive(Map<String, dynamic>? entitlements) {
    if (!_boolValue(entitlements?['premium_override'])) return false;
    final expiresAt = _dateValue(entitlements?['premium_override_expires_at']);
    return expiresAt == null || expiresAt.isAfter(DateTime.now());
  }

  PremiumConfig _configFromJson(Map<String, dynamic> json) {
    return PremiumConfig(
      paywallEnabled: _boolValue(json['paywall_enabled']),
      habitsFreeLimit: _intValue(json['habits_free_limit'], fallback: 3),
      tasksFreeLimit: _intValue(json['tasks_free_limit'], fallback: 5),
      notesFreeLimit: _intValue(json['notes_free_limit'], fallback: 50),
      focusFreeDailyLimit: _intValue(
        json['focus_free_daily_limit'],
        fallback: 1,
      ),
      focusFreeMinutesLimit: _intValue(
        json['focus_free_max_duration_minutes'] ??
            json['focus_free_minutes_limit'],
        fallback: 60,
      ),
      ceoModeFreeWeeklyLimit: _intValue(
        json['ceo_free_weekly_limit'],
        fallback: 1,
      ),
      // 0 acts as a sentinel: "no per-session duration limit"
      // (enforced via `limit > 0` guard in canStartCeoSession).
      ceoModeFreeMinutesLimit: _intValue(
        json['ceo_free_max_duration_minutes'] ??
            json['ceo_mode_free_minutes_limit'],
        fallback: 0,
      ),
      revenuecatEntitlementId:
          _stringValue(json['revenuecat_entitlement_id']) ?? 'premium',
      revenuecatOfferingId: _stringValue(json['revenuecat_offering_id']),
      revenuecatIosApiKey: _stringValue(json['revenuecat_ios_api_key']),
      revenuecatAndroidApiKey: _stringValue(json['revenuecat_android_api_key']),
      premiumThemes: _stringSetValue(json['premium_themes']),
      launchPremiumLabelsEnabled: _boolValue(
        json['launch_premium_labels_enabled'],
      ),
    );
  }

  Set<String> _stringSetValue(Object? raw) {
    if (raw is Iterable) {
      return raw.map((value) => value.toString()).toSet();
    }
    return const <String>{};
  }

  bool _boolValue(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  int _intValue(Object? raw, {required int fallback}) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    return fallback;
  }

  String? _stringValue(Object? raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  DateTime? _dateValue(Object? raw) {
    final value = _stringValue(raw);
    return value == null ? null : DateTime.tryParse(value);
  }

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _dayStartIso(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.toIso8601String();
  }

  // ── Offline runtime cache ──
  // Persists the last resolved PremiumRuntime in SharedPreferences so that
  // when the device is offline (or Supabase is unreachable) gating decisions
  // can still be made from the most recent known state for up to 24 h.

  String _cacheScopedKey(String base) {
    final uid = _currentUserId ?? 'guest';
    return '$base::$uid';
  }

  Future<void> _cacheRuntime(PremiumRuntime runtime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _cacheScopedKey(_runtimeCacheKey),
        runtime.resolved.isPremiumUser,
      );
      await prefs.setInt(
        _cacheScopedKey(_runtimeCacheAtKey),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<PremiumRuntime?> _readCachedRuntime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAt = prefs.getInt(_cacheScopedKey(_runtimeCacheAtKey));
      if (cachedAt == null) return null;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cachedAt),
      );
      if (age > _runtimeCacheValidity) return null;
      final isPremium =
          prefs.getBool(_cacheScopedKey(_runtimeCacheKey)) ?? false;
      // Build a minimal PremiumConfig with defaults — gating mostly reads
      // `resolved.isPremiumUser`, so default config is acceptable offline.
      const config = PremiumConfig(paywallEnabled: true);
      return PremiumRuntime(
        config: config,
        subscriptionStatus: isPremium ? 'cached' : 'free',
        resolved: PremiumResolvedAccess(
          isPremiumUser: isPremium,
          clientGraceActive: false,
          hasPaidSubscription: isPremium,
          isTrialing: false,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
