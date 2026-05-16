import 'dart:async';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_models.dart';
import '../repositories/settings_repository.dart';
import '../services/focus_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_catalog.dart';
import '../theme/theme_runtime.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();

  factory ThemeProvider({SettingsRepository? settingsRepository}) {
    if (settingsRepository != null) {
      _instance._settingsRepository = settingsRepository;
    }
    return _instance;
  }

  ThemeProvider._internal() {
    _init();
  }

  SettingsRepository _settingsRepository = SettingsRepository();
  final FocusService _focusService = FocusService();
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;
  static const _pendingOnboardingKey = 'pending_onboarding_setup_v1';
  static const _themeCacheKey = 'theme_preset_cache_v1';

  AppThemePreset _currentPreset = ThemeCatalog.resolveById(
    ThemeCatalog.defaultPresetId,
  );
  OnboardingSetupData? _pendingOnboardingSetup;
  String _onboardingCurrentThemeId = ThemeCatalog.defaultPresetId;

  AppThemePreset get currentPreset => _currentPreset;
  AppColorPalette get currentColors => _currentPreset.colors;
  AppTypographyProfile get currentTypography => _currentPreset.typography;
  ThemeMode get themeMode =>
      _currentPreset.isDark ? ThemeMode.dark : ThemeMode.light;
  List<AppThemePreset> get presets => ThemeCatalog.presets;
  String get onboardingCurrentThemeId => _onboardingCurrentThemeId;

  String _normalizedPresetId(String presetId) {
    return ThemeCatalog.resolveById(presetId).id;
  }

  void _init() {
    unawaited(_hydratePendingOnboardingFromPrefs());
    final user = _client.auth.currentUser;
    if (user != null) {
      unawaited(loadThemeFromSupabase());
    }
    _authSubscription = _client.auth.onAuthStateChange.listen((event) async {
      if (event.session?.user == null) {
        await _hydratePendingOnboardingFromPrefs();
        final pendingTheme = _pendingOnboardingSetup?.themePresetId;
        final fallback = pendingTheme ?? ThemeCatalog.defaultPresetId;
        _setPreset(fallback, notify: true);
        _onboardingCurrentThemeId = fallback;
        return;
      }
      try {
        await loadThemeFromSupabase();
        await _hydratePendingOnboardingFromPrefs();
        if (_pendingOnboardingSetup != null) {
          await persistPendingOnboardingSetup();
        }
      } catch (_) {
        // Keep current runtime theme if sync fails and retry on next app event.
      }
    });
  }

  Future<void> loadThemeFromSupabase() async {
    if (_client.auth.currentUser == null) {
      _setPreset(ThemeCatalog.defaultPresetId, notify: true);
      _onboardingCurrentThemeId = ThemeCatalog.defaultPresetId;
      return;
    }
    var presetId = ThemeCatalog.defaultPresetId;
    try {
      final settings = await _settingsRepository.getAppSettings();
      presetId = _normalizedPresetId(
        settings?.themePreset ?? ThemeCatalog.defaultPresetId,
      );
    } catch (_) {
      presetId = ThemeCatalog.defaultPresetId;
    }
    _onboardingCurrentThemeId = presetId;
    _setPreset(presetId, notify: true);
  }

  void previewTheme(String presetId) {
    _setPreset(_normalizedPresetId(presetId), notify: true);
  }

  void selectThemeForOnboarding(String presetId) {
    final normalized = _normalizedPresetId(presetId);
    _onboardingCurrentThemeId = normalized;
    previewTheme(normalized);
  }

  Future<void> saveThemeForCurrentUser(String presetId) async {
    final normalized = _normalizedPresetId(presetId);
    final previousPresetId = _currentPreset.id;
    _setPreset(normalized, notify: true);
    _onboardingCurrentThemeId = normalized;
    if (_client.auth.currentUser == null) return;
    try {
      await _settingsRepository.updateThemePreset(normalized);
    } catch (_) {
      _setPreset(previousPresetId, notify: true);
      _onboardingCurrentThemeId = previousPresetId;
      rethrow;
    }
  }

  void setPendingOnboardingSetup(OnboardingSetupData setup) {
    final normalizedThemeId = _normalizedPresetId(setup.themePresetId);
    final normalizedSetup = OnboardingSetupData(
      goal: setup.goal,
      discipline: setup.discipline,
      focusChallenge: setup.focusChallenge,
      themePresetId: normalizedThemeId,
    );

    _pendingOnboardingSetup = normalizedSetup;
    _onboardingCurrentThemeId = normalizedThemeId;
    previewTheme(normalizedThemeId);
    unawaited(_persistPendingOnboardingToPrefs(normalizedSetup));
  }

  Future<void> persistPendingOnboardingSetup() async {
    final setup = _pendingOnboardingSetup;
    if (setup == null) return;
    if (_client.auth.currentUser == null) return;
    final normalizedThemeId = _normalizedPresetId(setup.themePresetId);
    final normalizedSetup = OnboardingSetupData(
      goal: setup.goal,
      discipline: setup.discipline,
      focusChallenge: setup.focusChallenge,
      themePresetId: normalizedThemeId,
    );

    await _settingsRepository.saveOnboardingSetup(normalizedSetup);
    _setPreset(normalizedThemeId, notify: true);
    _onboardingCurrentThemeId = normalizedThemeId;
    _pendingOnboardingSetup = null;
    await _clearPendingOnboardingPrefs();
  }

  void _setPreset(String presetId, {required bool notify}) {
    _currentPreset = ThemeCatalog.resolveById(presetId);
    ThemeRuntime.setPreset(_currentPreset);
    unawaited(_persistThemeCache(_currentPreset.id));
    _syncScreenTimeTheme();
    if (notify) {
      notifyListeners();
    }
  }

  static Future<void> bootstrapRuntimeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_themeCacheKey);
      if (cached == null || cached.isEmpty) return;
      ThemeRuntime.setPreset(ThemeCatalog.resolveById(cached));
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> _persistThemeCache(String presetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeCacheKey, presetId);
    } catch (_) {
      // Best effort only.
    }
  }

  void _syncScreenTimeTheme() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final tokens = <String, String>{
      'card_bg': _hexColor(AppColors.cardBackgroundStrong),
      'card_border': _hexColor(AppColors.border),
      'title': _hexColor(AppColors.secondaryLabel),
      'value': _hexColor(AppColors.label),
      'subtitle': _hexColor(AppColors.tertiaryLabel),
      'version': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    unawaited(_focusService.syncScreenTimeTheme(tokens));
  }

  String _hexColor(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return '#$value';
  }

  Future<void> _hydratePendingOnboardingFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingOnboardingKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final payload = jsonDecode(raw);
      if (payload is! Map<String, dynamic>) return;
      final themeId = _normalizedPresetId(
        payload['themePresetId'] as String? ?? ThemeCatalog.defaultPresetId,
      );
      _pendingOnboardingSetup = OnboardingSetupData(
        goal: payload['goal'] as String? ?? 'Execution',
        discipline: payload['discipline'] as String? ?? 'Intermediate',
        focusChallenge: payload['focusChallenge'] as String? ?? 'Distractions',
        themePresetId: themeId,
      );
      _onboardingCurrentThemeId = themeId;
      if (_client.auth.currentUser == null) {
        _setPreset(themeId, notify: true);
      }
    } catch (_) {
      // Ignore invalid local payloads.
    }
  }

  Future<void> _persistPendingOnboardingToPrefs(
    OnboardingSetupData setup,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'goal': setup.goal,
      'discipline': setup.discipline,
      'focusChallenge': setup.focusChallenge,
      'themePresetId': setup.themePresetId,
    });
    await prefs.setString(_pendingOnboardingKey, payload);
  }

  Future<void> _clearPendingOnboardingPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOnboardingKey);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
