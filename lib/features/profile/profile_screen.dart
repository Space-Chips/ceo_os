import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/config/apple_review_compliance.dart';
import '../../core/models/premium_models.dart';
import '../../core/models/settings_models.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/ceo_mode_provider.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/settings_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_catalog.dart';
import '../../core/widgets/rank_art.dart';
import '../ceo_mode/blackout_preparation/blackout_preparation_flow_view.dart';
import '../ceo_mode/blackout_preparation/blackout_preparation_models.dart';

String _localizedRankDisplay(LanguageProvider language, String rawRankName) {
  switch (RankArt.canonicalKey(rawRankName)) {
    case 'awakened':
      return language.t('rank_awakened');
    case 'immortal':
      return language.t('rank_immortal');
    case 'diamond':
      return language.t('rank_diamond');
    case 'platinum':
      return language.t('rank_platinum');
    case 'gold':
      return language.t('rank_gold');
    case 'silver':
      return language.t('rank_silver');
    case 'bronze':
      return language.t('rank_bronze');
    case 'sleeping':
    default:
      return language.t('rank_asleep');
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _SelectionOption {
  final String id;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isPremium;
  final bool disabled;

  const _SelectionOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.isPremium = false,
    this.disabled = false,
  });
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Set<String> _availableLanguageCodes = {
    'en',
    'fr',
    'zh',
    'hi',
    'es',
  };
  static const List<_LanguageOption> _languages = [
    _LanguageOption(code: 'en', label: 'English', nativeLabel: 'English'),
    _LanguageOption(code: 'fr', label: 'French', nativeLabel: 'Français'),
    _LanguageOption(code: 'zh', label: 'Chinese', nativeLabel: '中文'),
    _LanguageOption(code: 'hi', label: 'Hindi', nativeLabel: 'हिन्दी'),
    _LanguageOption(code: 'es', label: 'Spanish', nativeLabel: 'Español'),
    _LanguageOption(code: 'ar', label: 'Arabic', nativeLabel: 'العربية'),
    _LanguageOption(
      code: 'id',
      label: 'Indonesian',
      nativeLabel: 'Bahasa Indonesia',
    ),
    _LanguageOption(code: 'ru', label: 'Russian', nativeLabel: 'Русский'),
    _LanguageOption(
      code: 'pt',
      label: 'Portuguese',
      nativeLabel: 'Português',
    ),
  ];

  final UserRepository _userRepository = UserRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final TextEditingController _nameCtrl = TextEditingController();

  Profile? _profile;
  AppSettings? _appSettings;
  UserRank? _rank;
  WinStreak? _streak;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isThemeSaving = false;
  final PremiumRepository _premiumRepository = PremiumRepository();
  bool _isSettingsSaving = false;

  String _t(String key) => context.read<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userRepository.getProfile();
      final settings = await _settingsRepository.getAppSettings();
      final rank = await _userRepository.getUserRank();
      final streak = await _userRepository.getWinStreak();
      _nameCtrl.text = profile?.fullName ?? '';
      if (mounted) {
        setState(() {
          _profile = profile;
          _appSettings = settings;
          _rank = rank;
          _streak = streak;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _userRepository.updateProfile(fullName: _nameCtrl.text.trim());
    await _load();
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showThemePicker() async {
    final themeProvider = context.read<ThemeProvider>();
    final runtime = await _premiumRepository.getRuntime();
    final premiumThemeIds = runtime.config.premiumThemes;
    final orderedPresets = [...themeProvider.presets]..sort((a, b) {
      final aPremium = premiumThemeIds.contains(a.id);
      final bPremium = premiumThemeIds.contains(b.id);
      if (aPremium == bPremium) {
        return themeProvider.presets.indexOf(a) -
            themeProvider.presets.indexOf(b);
      }
      return aPremium ? 1 : -1;
    });
    final selected = await _showSelectionSheet(
      title: _t('interface_appearance'),
      subtitle: _t('profile_theme_picker_subtitle'),
      options: [
        for (final preset in orderedPresets)
          _SelectionOption(
            id: preset.id,
            title: _themeDisplayName(preset),
            subtitle: _themeSubtitle(runtime, preset),
            selected: preset.id == themeProvider.currentPreset.id,
            isPremium: premiumThemeIds.contains(preset.id),
          ),
      ],
    );

    if (selected == null || selected == themeProvider.currentPreset.id) return;

    final themeCheck = await _premiumRepository.canUseTheme(selected);
    if (!themeCheck.allowed) {
      if (!mounted) return;
      await showPremiumGateDialog(context, themeCheck);
      return;
    }

    setState(() => _isThemeSaving = true);
    try {
      await themeProvider.saveThemeForCurrentUser(selected);
    } catch (_) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(_t('theme_sync_error'), style: AppTypography.mono),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _t('theme_sync_error_message'),
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _t('ok'),
                style: AppTypography.mono.copyWith(
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isThemeSaving = false);
      }
    }
  }

  String _themeSubtitle(PremiumRuntime runtime, AppThemePreset preset) {
    final isPremiumTheme = runtime.config.premiumThemes.contains(preset.id);
    if (!isPremiumTheme) {
      return preset.isDark ? _t('dark_theme') : _t('light_theme');
    }
    if (runtime.config.launchPremiumLabelsEnabled &&
        runtime.resolved.launchPremiumActive) {
      return _t('premium_unlocked_launch');
    }
    return _t('premium_theme');
  }

  String _themeDisplayName(AppThemePreset preset) {
    switch (preset.id) {
      case 'carbon_system':
        return _t('theme_carbon_system');
      case 'ember_protocol':
        return _t('theme_ember_protocol');
      case 'royal_violet':
        return _t('theme_royal_violet');
      case 'modern_desert':
        return _t('theme_modern_desert');
      case 'cloud_studio':
        return _t('theme_cloud_studio');
      default:
        return preset.name;
    }
  }

  void _showNotificationsInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('NOTIFICATION_CHANNELS', style: AppTypography.mono),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Notification channel controls will be available in a future update.',
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              color: AppColors.secondaryLabel,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: AppTypography.mono.copyWith(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();
    final languageCode = language.languageCode.toLowerCase();
    final notificationsEnabled = _appSettings?.notificationsEnabled ?? true;
    final habitEnabled = _appSettings?.habitNotificationsEnabled ?? true;
    final calendarEnabled = _appSettings?.calendarNotificationsEnabled ?? true;
    final focusEnabled = _appSettings?.focusNotificationsEnabled ?? true;
    final enabledChannels = [
      if (habitEnabled) 'H',
      if (calendarEnabled) 'C',
      if (focusEnabled) 'F',
    ].length;
    final showDebugTools = kDebugMode;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: NeoMonoText(
          language.t('profile'),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: Text(
            _isSaving ? language.t('saving') : language.t('save'),
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _isLoading
          ? Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    showEdgeGlow: false,
                    gradientColors: [
                      AppColors.cardBackgroundAlt,
                      AppColors.cardBase,
                    ],
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.t('display_name'),
                          style: AppTypography.overline.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: AppColors.secondaryLabel.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.inputBackground,
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: CupertinoTextField(
                            controller: _nameCtrl,
                            placeholder: language.t('your_name'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: null,
                            style: AppTypography.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.label,
                            ),
                            placeholderStyle: AppTypography.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryLabel.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _profile?.email ?? '-',
                          style: AppTypography.subhead.copyWith(
                            fontSize: 13,
                            color: AppColors.secondaryLabel.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    showEdgeGlow: false,
                    gradientColors: [
                      AppColors.cardBackgroundAlt,
                      AppColors.cardBase,
                    ],
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              _metric(
                                'RANK',
                                RankArt.displayName(_rank?.rankName ?? 'Asleep'),
                              ),
                              _metric('LEVEL', '${_rank?.rankLevel ?? 1}'),
                              _metric('POINTS', '${_rank?.totalRankPoints ?? 0}'),
                            ],
                          ),
                        ),
                        _divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              _metric(
                                language.t('streak'),
                                '${_streak?.currentStreak ?? 0}d',
                                valueColor: AppColors.warning,
                                valueSize: 20,
                                valueWeight: FontWeight.w700,
                              ),
                              _metric(
                                language.t('rank_best'),
                                '${_streak?.longestStreak ?? 0}d',
                                valueSize: 20,
                                valueWeight: FontWeight.w700,
                              ),
                              _metric(
                                language.t('focus_sessions'),
                                '${_streak?.totalCompletedSessions ?? 0}',
                                valueSize: 20,
                                valueWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader(language.t('focus_protocols')),
                  const SizedBox(height: 10),
                  _settingCard(
                    child: Column(
                      children: [
                        _settingRow(
                          label: language.t('focus_session_duration'),
                          trailing: Text(
                            '${focus.focusDurationMinutes}M',
                            style: AppTypography.callout.copyWith(
                              fontSize: 14,
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingRow(
                          label: language.t('focus_short_break'),
                          trailing: Text(
                            '${focus.shortBreakMinutes}M',
                            style: AppTypography.callout.copyWith(
                              fontSize: 14,
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingRow(
                          label: language.t('focus_auto_start_breaks'),
                          trailing: _adaptiveSwitch(
                            value: focus.autoStartBreaks,
                            onChanged: (_) => focus.toggleAutoStartBreaks(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingRow(
                          label: language.t('prepare_home_screen_blackout'),
                          onTap: () async {
                            final ceoModeProvider = context.read<CeoModeProvider>();
                            final outcome = await showBlackoutPreparationFlow(
                              context: context,
                              launchContext:
                                  BlackoutPreparationLaunchContext.settings,
                            );
                            if (!mounted || outcome == null) return;
                            await ceoModeProvider.persistPreparationOutcome(
                              outcome,
                            );
                          },
                          leadingIcon: CupertinoIcons.sparkles,
                          leadingColor: AppColors.primaryOrange,
                          trailing: _rowArrow(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader(language.t('system_preferences')),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      _settingRow(
                        label: language.t('interface_appearance'),
                        onTap: _isThemeSaving ? null : _showThemePicker,
                        trailing: _isThemeSaving
                            ? CupertinoActivityIndicator(color: AppColors.primaryOrange)
                            : _rowValueChevron(theme.currentPreset.name.toUpperCase()),
                      ),
                      const SizedBox(height: 12),
                      _settingRow(
                        label: language.t('language'),
                        onTap: _isSettingsSaving ? null : _showLanguagePicker,
                        trailing: _isSettingsSaving
                            ? CupertinoActivityIndicator(color: AppColors.primaryOrange)
                            : _rowValueChevron(_languageLabel(languageCode)),
                      ),
                      const SizedBox(height: 12),
                      _settingRow(
                        label: language.t('notification_channels'),
                        onTap: _isSettingsSaving ? null : _showNotificationChannels,
                        trailing: _rowValueChevron(
                          notificationsEnabled ? '$enabledChannels/3 ON' : 'OFF',
                          valueColor: notificationsEnabled
                              ? AppColors.secondaryLabel
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader(language.t('settings_legal')),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      _settingRow(
                        label: language.t('privacy_policy'),
                        onTap: _openPrivacyPolicy,
                        leadingIcon: CupertinoIcons.lock_shield,
                        trailing: _rowArrow(),
                      ),
                      const SizedBox(height: 12),
                      _settingRow(
                        label: language.t('permissions'),
                        onTap: _openPermissionsPolicy,
                        leadingIcon: CupertinoIcons.hand_raised,
                        trailing: _rowArrow(),
                      ),
                      const SizedBox(height: 12),
                      _settingRow(
                        label: language.t('terms_of_use'),
                        onTap: _openTermsOfUse,
                        leadingIcon: CupertinoIcons.doc_text,
                        trailing: _rowArrow(),
                      ),
                      const SizedBox(height: 12),
                      _settingRow(
                        label: language.t('contact_support'),
                        onTap: _openContactSupport,
                        leadingIcon: CupertinoIcons.chat_bubble_text,
                        trailing: Icon(
                          CupertinoIcons.doc_on_doc,
                          size: 16,
                          color: AppColors.tertiaryLabel.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _settingRow(
                        label: language.t('data_deletion'),
                        onTap: _openDataDeletionFlow,
                        leadingIcon: CupertinoIcons.delete,
                        leadingColor: AppColors.error,
                        trailing: Icon(
                          CupertinoIcons.delete,
                          size: 16,
                          color: AppColors.error,
                        ),
                        isDanger: true,
                      ),
                    ],
                  ),
                  if (showDebugTools) ...[
                    const SizedBox(height: 24),
                    _sectionHeader(language.t('debug')),
                    const SizedBox(height: 10),
                    CustomPaint(
                      painter: _DashedBorderPainter(
                        color: AppColors.borderStrong,
                        radius: 16,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.sectionBackground,
                        ),
                        child: Column(
                          children: [
                            _settingRow(
                              label: language.t('database_write_checks'),
                              onTap: () => context.push('/debug/database'),
                              leadingIcon: CupertinoIcons.lab_flask,
                              leadingColor: AppColors.tertiaryLabel,
                              trailing: Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: AppColors.tertiaryLabel.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            _divider(),
                            _settingRow(
                              label: language.t('theme_preview'),
                              onTap: () => context.push('/debug/themes'),
                              leadingIcon: CupertinoIcons.paintbrush,
                              leadingColor: AppColors.tertiaryLabel,
                              trailing: Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: AppColors.tertiaryLabel.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _sectionHeader(language.t('actions')),
                  const SizedBox(height: 10),
                  if (AppleReviewCompliance.allowSocialScreenTimeSurfaces) ...[
                    _actionButton(
                      label: language.t('open_leaderboard'),
                      onPressed: () => context.push('/leaderboard'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _actionButton(
                    label: language.t('open_rank'),
                    onPressed: () => context.push('/rank'),
                  ),
                  const SizedBox(height: 10),
                  _actionButton(
                    label: language.t('open_screen_manager'),
                    onPressed: () => context.push('/screen-time-manager'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      onPressed: () => auth.logout(),
                      child: NeoMonoText(
                        language.t('terminate_session'),
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _settingRow({
    required String label,
    required Widget trailing,
    VoidCallback? onTap,
    IconData? leadingIcon,
    Color? leadingColor,
    bool isDanger = false,
  }) {
    final row = Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.pillBackground,
        border: Border.all(color: AppColors.pillBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 16,
              color: leadingColor ??
                  AppColors.secondaryLabel.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 18,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AppTypography.callout.copyWith(
                    fontSize: 13,
                    color: isDanger ? AppColors.error : AppColors.label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap == null) return row;

    return _PressScale(
      pressedScale: 0.98,
      child: GestureDetector(
        onTap: onTap,
        child: row,
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: AppTypography.overline.copyWith(
        color: AppColors.secondaryLabel.withValues(alpha: 0.5),
        fontSize: 11,
        letterSpacing: 2,
      ),
    ),
  );

  Widget _divider() => Container(
    height: 1,
    color: AppColors.border,
  );

  Widget _metric(
    String label,
    String value, {
    Color? valueColor,
    double valueSize = 18,
    FontWeight valueWeight = FontWeight.w600,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 1.5,
              color: AppColors.secondaryLabel.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.title3.copyWith(
              fontSize: valueSize,
              fontWeight: valueWeight,
              color: valueColor ?? AppColors.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingCard({required Widget child}) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      borderRadius: 18,
      showEdgeGlow: false,
      gradientColors: [
        AppColors.cardBackgroundAlt,
        AppColors.cardBase,
      ],
      border: Border.all(
        color: AppColors.border,
        width: 1,
      ),
      child: child,
    );
  }

  Widget _rowArrow() => Icon(
    CupertinoIcons.chevron_right,
    size: 16,
    color: AppColors.tertiaryLabel.withValues(alpha: 0.4),
  );

  Widget _rowValueChevron(String value, {Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.caption1.copyWith(
            fontSize: 11,
            color: valueColor ?? AppColors.secondaryLabel,
          ),
        ),
        const SizedBox(width: 8),
        _rowArrow(),
      ],
    );
  }

  Widget _adaptiveSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: const Color(0xFF4C7DFF),
      inactiveTrackColor: CupertinoColors.white.withValues(alpha: 0.15),
      thumbColor: CupertinoColors.white,
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return _PressScale(
      pressedScale: 0.98,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.buttonGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadowSoft,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.callout.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onAccent,
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showSelectionSheet({
    required String title,
    required String subtitle,
    required List<_SelectionOption> options,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (popupContext) => _buildBottomSheetShell(
        context: popupContext,
        heightFactor: 0.62,
        title: title,
        subtitle: subtitle,
        onClose: () => Navigator.of(popupContext).pop(),
        child: Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final option = options[index];
              return _PressScale(
                pressedScale: 0.98,
                child: GestureDetector(
                  onTap: () => Navigator.of(popupContext).pop(option.id),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: option.selected
                          ? const Color(0xFF4C7DFF).withValues(alpha: 0.08)
                          : CupertinoColors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: option.selected
                            ? const Color(0xFF4C7DFF).withValues(alpha: 0.35)
                            : CupertinoColors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      option.title,
                                      style: AppTypography.callout.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.label,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (option.isPremium) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        color: AppColors.accentSurfaceSoft,
                                        border: Border.all(
                                          color: AppColors.activeBorder,
                                        ),
                                      ),
                                      child: Text(
                                        'PREMIUM',
                                        style: AppTypography.caption2.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.subtitle,
                                style: AppTypography.caption1.copyWith(
                                  fontSize: 11,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (option.selected)
                          Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            size: 18,
                            color: const Color(0xFF4C7DFF),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetShell({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onClose,
    required Widget child,
    double heightFactor = 0.62,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * heightFactor,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundElevated.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.borderStrong,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow,
              blurRadius: 28,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.title3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.subhead.copyWith(
                          fontSize: 12,
                          color: AppColors.secondaryLabel.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                _PressScale(
                  pressedScale: 0.94,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.topBarControlBackground,
                        border: Border.all(
                          color: AppColors.topBarControlBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _popupToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.pillBackground,
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.callout.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.label,
              ),
            ),
          ),
          _adaptiveSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const _PressScale({required this.child, required this.pressedScale});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in rect.computeMetrics()) {
      double distance = 0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _SettingsSection {
  final String title;
  final String body;

  const _SettingsSection(this.title, this.body);
}

class _LanguageOption {
  final String code;
  final String label;
  final String nativeLabel;

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });
}
