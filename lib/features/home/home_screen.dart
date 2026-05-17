import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/components.dart';
import '../../core/config/apple_review_compliance.dart';
import '../../core/models/insights_models.dart';
import '../../core/providers/ceo_mode_provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/insights_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/services/performance_score_service.dart';
import '../../core/services/stats_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rank_art.dart';
import '../screen_time_setup/screen_time_setup_controller.dart';
import '../setup/setup_flow_controller.dart';
import '../control_center_setup/control_center_setup_models.dart';
import '../control_center_setup/control_center_setup_store.dart';
import '../calendar/add_event_sheet.dart';
import '../habits/habit_gallery_sheet.dart';
import '../tasks/add_task_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ShortcutCard extends StatelessWidget {
  final _ShortcutCardData data;
  final bool compact;

  const _ShortcutCard({required this.data, required this.compact});

  Color _shortcutGlow(String shortcutId) {
    switch (shortcutId) {
      case 'rank':
        return AppColors.warning.withValues(alpha: 0.2);
      case 'leaderboard':
        return AppColors.chartC.withValues(alpha: 0.2);
      case 'focus':
        return AppColors.focusPrimary.withValues(alpha: 0.2);
      case 'family_time':
        return AppColors.chartB.withValues(alpha: 0.2);
      case 'block_apps':
        return AppColors.chartD.withValues(alpha: 0.2);
      case 'streak':
        return AppColors.warning.withValues(alpha: 0.2);
      case 'notes':
        return AppColors.accent.withValues(alpha: 0.2);
      default:
        return AppColors.edgeGlowSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _shortcutGlow(data.shortcutId);
    return _InteractiveLift(
      onTap: data.onTap,
      borderRadius: 24,
      hoverScale: 1.017,
      pressedScale: 1.028,
      glowColor: glowColor,
      child: GlassCard(
        padding: EdgeInsets.all(compact ? 12 : 14),
        borderRadius: 24,
        level: GlassCardLevel.standard,
        showEdgeGlow: false,
        gradientColors: [AppColors.cardBackgroundStrong, AppColors.cardBase],
        border: Border.all(color: AppColors.borderStrong, width: 1),
        child: SizedBox(
          height: compact ? null : 126,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 56 : 62,
                height: compact ? 56 : 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cardBackgroundStrong,
                      AppColors.cardBackgroundAlt,
                    ],
                  ),
                  border: Border.all(color: AppColors.border, width: 0.9),
                ),
                child: Icon(
                  data.icon,
                  color: data.active
                      ? AppColors.accentIcon
                      : AppColors.secondaryLabel,
                  size: compact ? 24 : 27,
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title3.copyWith(
                  fontSize: compact ? 18 : 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoModulesMessageCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _NoModulesMessageCard({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.64),
        width: 0.65,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.footnote.copyWith(
                fontSize: 12,
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _MenuPressable(
            onTap: onDismiss,
            pressedScale: 0.94,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceMuted.withValues(alpha: 0.72),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.xmark,
                size: 12,
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final InsightsRepository _insightsRepository = InsightsRepository();
  final UserRepository _userRepository = UserRepository();
  final FeatureRepository _featureRepository = FeatureRepository();
  final StatsEngine _statsEngine = StatsEngine();

  static const Set<String> _defaultActiveApps = {
    'Pareto',
    'Habits',
    'Calendar',
    'ScreenTimeManager',
  };
  static const Set<String> _validPrimaryApps = {
    'Pareto',
    'Habits',
    'Calendar',
    'ScreenTimeManager',
  };
  static const Set<String> _defaultEnabledShortcuts = {};
  static const List<String> _shortcutOrder = [
    'rank',
    'leaderboard',
    'focus',
    'family_time',
    'block_apps',
    'streak',
    'notes',
  ];
  static const Set<String> _socialShortcutIds = {'leaderboard', 'family_time'};

  Future<DashboardSnapshot>? _snapshotFuture;
  String? _settingsId;
  Set<String> _activeApps = {..._defaultActiveApps};
  Set<String> _enabledShortcuts = {..._defaultEnabledShortcuts};
  bool _hideNoModulesMessage = false;
  int _winStreak = 0;
  String? _lastDataSignature;

  bool get _showAdvancedStats => AppleReviewCompliance.allowAdvancedStats;
  bool get _showSocialScreenTimeSurfaces =>
      AppleReviewCompliance.allowSocialScreenTimeSurfaces;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _insightsRepository.getDashboardSnapshot();
    unawaited(_statsEngine.recordDashboardOpened());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrap();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final habitProvider = context.read<HabitProvider>();
    final taskProvider = context.read<TaskProvider>();

    if (!identical(_habitProvider, habitProvider)) {
      _habitProvider?.removeListener(_handleSourceDataChanged);
      _habitProvider = habitProvider;
      _habitProvider?.addListener(_handleSourceDataChanged);
    }

    if (!identical(_taskProvider, taskProvider)) {
      _taskProvider?.removeListener(_handleSourceDataChanged);
      _taskProvider = taskProvider;
      _taskProvider?.addListener(_handleSourceDataChanged);
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _habitProvider?.removeListener(_handleSourceDataChanged);
    _taskProvider?.removeListener(_handleSourceDataChanged);
    super.dispose();
  }

  Future<void> _loadWinStreak() async {
    final streak = await _userRepository.getWinStreak();
    if (!mounted) return;
    setState(() {
      _winStreak = streak?.currentStreak ?? 0;
    });
  }

  Future<void> _onToggleShortcut(_ModuleToggleOption option, bool value) async {
    setState(() {
      if (value) {
        _shortcuts.add(option.moduleId);
      } else {
        _shortcuts.remove(option.moduleId);
      }
      _saving.add(option.moduleId);
    });

    await widget.onToggleShortcut(option.moduleId, value);
    if (!mounted) return;
    setState(() {
      _saving.remove(option.moduleId);
    });
  }

  String _prefsKey(String suffix) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'home::$userId::$suffix';
  }

  List<String> _normalizeControlCenterSlots(List<String> raw) {
    final trimmed = raw
        .take(4)
        .map((id) => id.trim())
        .toList(growable: true);
    while (trimmed.length < 4) {
      trimmed.add('');
    }
    return trimmed;
  }

  Future<void> _loadHomePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final shortcuts =
        prefs.getStringList(_prefsKey('enabled_shortcuts_v2'))?.toSet();
    var hideNoModules =
        prefs.getBool(_prefsKey('hide_no_modules_message_v1')) ?? false;
    final normalizedShortcuts = _normalizeEnabledShortcuts(
      shortcuts ?? _defaultEnabledShortcuts,
      _activeApps,
    );

    if ((_activeApps.length + normalizedShortcuts.length) > 0 && hideNoModules) {
      hideNoModules = false;
      await prefs.setBool(_prefsKey('hide_no_modules_message_v1'), false);
    }
    await prefs.setStringList(
      _prefsKey('enabled_shortcuts_v2'),
      normalizedShortcuts.toList(growable: false),
    );

    if (!mounted) return;
    setState(() {
      _enabledShortcuts = normalizedShortcuts;
      _hideNoModulesMessage = hideNoModules;
    });
  }

  Future<void> _loadControlCenterConfiguration() async {
    final store = await ControlCenterSetupStore.create();
    final config = await store.load();
    final parsed = config.toState();
    if (!mounted) return;
    setState(() {
      _controlCenterConfiguration = config;
      _enabledDashboardWidgets = parsed.enabledDashboardWidgets;
    });
  }

  void _openScreenTimeEntry() {
    final controller = context.read<ScreenTimeSetupController>();
    unawaited(controller.initialize().then((_) async {
      await controller.refreshAndSync();
      if (!mounted) return;
      if (controller.isSetupRequired || !controller.isSetupComplete) {
        context.push('/screen-time-setup');
      } else {
        context.push('/screen-time-manager');
      }
    }));
  }

  int _shortcutCapacityFor(Set<String> activeApps) => 4 - activeApps.length;

  Set<String> _normalizeEnabledShortcuts(
    Set<String> shortcuts,
    Set<String> activeApps,
  ) {
    final capacity = _shortcutCapacityFor(activeApps).clamp(0, 4);
    final ordered = _shortcutOrder
        .where(
          (shortcutId) =>
              shortcuts.contains(shortcutId) &&
              (_showSocialScreenTimeSurfaces ||
                  !_socialShortcutIds.contains(shortcutId)),
        )
        .take(capacity)
        .toSet();
    return ordered;
  }

  Future<void> _bootstrap() async {
    if (!mounted || _isBootstrapping) return;
    _isBootstrapping = true;
    try {
      try {
        await _loadBaseData();
      } catch (_) {}

      if (!mounted) return;

      unawaited(context.read<ScreenTimeSetupController>().initialize());
      await _hydrateUser();
      if (!mounted) return;

      await Future.wait<void>([_loadActiveApps(), _loadWinStreak()]);
      if (!mounted) return;

      await _loadHomePreferences();
      if (!mounted) return;

      await _loadControlCenterConfiguration();
      if (!mounted) return;

      if (!_controlCenterConfiguration.setupCompleted &&
          !_didRouteToControlCenterSetup) {
        _didRouteToControlCenterSetup = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/control-center-setup');
        });
      }

      setState(() {
        _pendingYesterdayValidationFuture = _hasPendingYesterdayHabits();
      });

      // Show the onboarding premium prompt once per account, after bootstrap.
      // Skip fresh signups that will route to control-center setup (handled above).
      if (!(auth.wasJustSignedUp && isRecentAccount)) {
        unawaited(PremiumOnboardingPromptService.maybeShow(context));
      }
    } finally {
      _isBootstrapping = false;
    }
  }

  Future<void> _loadBaseData() async {
    final taskProvider = context.read<TaskProvider>();
    final habitProvider = context.read<HabitProvider>();
    await Future.wait<void>([
      taskProvider.loadTasks(),
      taskProvider.loadEvents(),
      habitProvider.loadData(),
    ]);
  }

  Future<void> _hydrateUser() async {
    final existing = await _userRepository.getProfile();
    if (existing == null) {
      await _userRepository.upsertProfile();
    }
  }

  Future<void> _loadActiveApps() async {
    final settings = await _featureRepository.getAppSettings();
    if (!mounted) return;

    final configured = settings?.activeApps;
    final normalized = configured?.where(_validPrimaryApps.contains).toSet();
    setState(() {
      _settingsId = settings?.id;
      if (configured != null) {
        if (normalized != null && normalized.isNotEmpty) {
          _activeApps = normalized;
        } else if (configured.isNotEmpty) {
          _activeApps = {..._defaultActiveApps};
        } else {
          _activeApps = <String>{};
        }
      }
    });
  }

  void _reloadSnapshot() {
    setState(() {
      _snapshotFuture = _insightsRepository.getDashboardSnapshot();
    });
  }

  Future<bool> _togglePrimaryModule(String moduleId, bool enabled) async {
    final previous = Set<String>.from(_activeApps);
    final previousShortcuts = Set<String>.from(_enabledShortcuts);
    final next = Set<String>.from(_activeApps);

    if (enabled) {
      next.add(moduleId);
    } else {
      next.remove(moduleId);
    }
    final normalizedShortcuts = _normalizeEnabledShortcuts(
      _enabledShortcuts,
      next,
    );

    setState(() {
      _activeApps = next;
      _enabledShortcuts = normalizedShortcuts;
    });
    await _handleNoModulesStateTransition(
      previousApps: previous,
      previousShortcuts: previousShortcuts,
      nextApps: next,
      nextShortcuts: normalizedShortcuts,
    );

    try {
      final id = await _featureRepository.saveActiveAppsFast(
        next.toList(),
        settingsId: _settingsId,
      );
      _settingsId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey('enabled_shortcuts_v2'),
        normalizedShortcuts.toList(growable: false),
      );
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _activeApps = previous;
          _enabledShortcuts = previousShortcuts;
        });
      }
      return false;
    }
  }

  Future<void> _handleNoModulesStateTransition({
    required Set<String> previousApps,
    required Set<String> previousShortcuts,
    required Set<String> nextApps,
    required Set<String> nextShortcuts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hadVisibleItems = previousApps.length + previousShortcuts.length > 0;
    final hasVisibleItems = nextApps.length + nextShortcuts.length > 0;

    if (hasVisibleItems) {
      if (_hideNoModulesMessage) {
        if (mounted) {
          setState(() => _hideNoModulesMessage = false);
        }
        await prefs.setBool(_prefsKey('hide_no_modules_message_v1'), false);
      }
      return;
    }

    if (hadVisibleItems && !hasVisibleItems) {
      if (mounted) {
        setState(() => _hideNoModulesMessage = false);
      }
      await prefs.setBool(_prefsKey('hide_no_modules_message_v1'), false);
    }
  }

  Future<void> _toggleShortcut(String shortcutId, bool enabled) async {
    final previous = Set<String>.from(_enabledShortcuts);
    final next = Set<String>.from(_enabledShortcuts);
    if (enabled) {
      final capacity = _shortcutCapacityFor(_activeApps);
      if (_enabledShortcuts.length >= capacity) {
        return;
      }
      next.add(shortcutId);
    } else {
      next.remove(shortcutId);
    }

    setState(() => _enabledShortcuts = next);

    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setStringList(
        _prefsKey('enabled_shortcuts_v2'),
        next.toList(growable: false),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _enabledShortcuts = previous);
    }
  }

  Future<void> _dismissNoModulesMessage() async {
    setState(() => _hideNoModulesMessage = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey('hide_no_modules_message_v1'), true);
  }

  void _openQuickAddTask() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddTaskSheet(),
    );
  }

  void _openQuickAddHabit() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const HabitGallerySheet(),
    );
  }

  void _openQuickAddEvent() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddEventSheet(),
    );
  }

  void _openSecondaryMenu() {
    final hostContext = context;
    showGeneralDialog<void>(
      context: hostContext,
      barrierDismissible: true,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      barrierLabel: context.read<LanguageProvider>().t('secondary_menu'),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (sheetContext, _, __) {
        return Align(
          alignment: Alignment.centerLeft,
          child: _SecondaryMenuSheet(
            initialActiveApps: _activeApps,
            initialEnabledShortcuts: _enabledShortcuts,
            onToggleModule: _togglePrimaryModule,
            onToggleShortcut: _toggleShortcut,
            onCustomizeControlCenter: () {
              Navigator.of(sheetContext).pop();
              unawaited(_openControlCenterCustomizer());
            },
            onOpenProfileAndSettings: () {
              Navigator.of(sheetContext).pop();
              unawaited(_pushAndRefresh('/profile'));
            },
            onOpenAdvancedStats: () {
              Navigator.of(sheetContext).pop();
              unawaited(_pushAndRefresh('/stats'));
            },
            showAdvancedStats: _showAdvancedStats,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final ceoProvider = context.watch<CeoModeProvider>();
    final language = context.watch<LanguageProvider>();

    final pendingTasks = taskProvider.tasks.where((t) => !t.completed).length;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: FutureBuilder<DashboardSnapshot>(
            future: _snapshotFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final rankName =
                  (data?.rankName.trim().isNotEmpty ?? false)
                  ? data!.rankName
                  : 'Bronze';
              final habitsCount = data?.totalHabits ?? habitProvider.habits.length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                children: [
                  _TopShortcutsBar(
                    rankName: rankName,
                    winStreak: _winStreak,
                    onOpenMenu: _openSecondaryMenu,
                    onOpenRank: () => context.push('/rank'),
                    onOpenFocus: () => context.push('/focus'),
                    onOpenNotes: () => context.push('/notes'),
                    onOpenStreak: () => context.push('/win-streak'),
                  ),
                  const SizedBox(height: 8),
                  _DashboardMainCard(
                    userLabel: _userLabel,
                    habitsCount: habitsCount,
                    onOpenDashboard: () => context.push('/dashboard'),
                  ),
                  const SizedBox(height: 16),
                  if (visibleCards.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 18,
                      border: Border.all(
                        color: AppColors.glassBorder.withValues(alpha: 0.64),
                        width: 0.65,
                      ),
                      child: Text(
                        'No mini-app enabled. Use profile menu to activate at least one.',
                        style: AppTypography.footnote.copyWith(
                          fontSize: 12,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    )
                  else
                    _PrimaryAppsGrid(cards: visibleCards),
                  if (_enabledDashboardWidgets.contains(
                    DashboardWidget.blackoutButton,
                  )) ...[
                    const SizedBox(height: 16),
                    _CeoModeCard(
                      statusLabel: ceoProvider.homeCardLabel,
                      title: language.t('blackout_mode'),
                      maxFocusLabel: language.t('max_focus'),
                      sessionPrefix: language.t('session_prefix'),
                      exitPrefix: language.t('exit_prefix'),
                      onOpenCeoMode: () => context.push('/ceo-mode'),
                    ),
                  ],
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _reloadSnapshot,
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.28),
                          width: 0.6,
                        ),
                        child: Text(
                          "${language.t('home_dashboard_load_failed")}. ${language.t('home_dashboard_retry_hint')}',
                          style: AppTypography.caption1.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModuleControlRow extends StatelessWidget {
  final _ModuleToggleOption option;
  final bool enabled;
  final bool saving;
  final bool locked;
  final ValueChanged<bool> onChanged;

  const _ModuleControlRow({
    required this.option,
    required this.enabled,
    required this.saving,
    this.locked = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return _MenuPressable(
      pressedScale: 0.98,
      onTap: saving || locked ? null : () => onChanged(!enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled
              ? const Color(0xFF4C7DFF).withValues(alpha: 0.06)
              : CupertinoColors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: enabled
                ? const Color(0xFF4C7DFF).withValues(alpha: 0.35)
                : CupertinoColors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x08000000),
              blurRadius: 14,
              offset: Offset(0, 6),
              spreadRadius: -10,
            ),
            if (enabled)
              BoxShadow(
                color: const Color(0xFF4C7DFF).withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: -4,
              ),
          ],
        ),
        child: Opacity(
          opacity: locked ? 0.42 : 1,
          child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardBackgroundAlt,
                    AppColors.cardBackgroundStrong,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                option.icon,
                size: 18,
                color: enabled ? const Color(0xFF4C7DFF) : AppColors.tertiaryLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language.t(option.titleKey),
                style: AppTypography.callout.copyWith(
                  fontSize: 14,
                  color: AppColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (saving)
              const CupertinoActivityIndicator()
            else
              TweenAnimationBuilder<double>(
                key: ValueKey('${option.moduleId}-$enabled'),
                tween: Tween<double>(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: CupertinoSwitch(
                  value: enabled,
                  onChanged: onChanged,
                  activeTrackColor: const Color(0xFF4C7DFF),
                  inactiveTrackColor: CupertinoColors.white.withValues(
                    alpha: 0.15,
                  ),
                  thumbColor: CupertinoColors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const _MenuPressable({
    required this.child,
    required this.onTap,
    required this.pressedScale,
  });

  @override
  State<_MenuPressable> createState() => _MenuPressableState();
}

class _MenuPressableState extends State<_MenuPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _InteractiveLift extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double hoverScale;
  final double pressedScale;
  final Color glowColor;
  final Color? longPressGlowColor;

  const _InteractiveLift({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    required this.glowColor,
    this.hoverScale = 1.012,
    this.pressedScale = 1.022,
    this.longPressGlowColor,
  });

  @override
  State<_InteractiveLift> createState() => _InteractiveLiftState();
}

class _InteractiveLiftState extends State<_InteractiveLift> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isLongPressed = false;

  bool get _interactive => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed
        ? widget.pressedScale
        : (_isHovered ? widget.hoverScale : 1.0);
    final lift = _isPressed ? -1.0 : (_isHovered ? -2.0 : 0.0);
    final glow = _isLongPressed
        ? (widget.longPressGlowColor ?? widget.glowColor)
        : widget.glowColor;

    return MouseRegion(
      cursor: _interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: _interactive ? (_) => setState(() => _isHovered = true) : null,
      onExit: _interactive
          ? (_) {
              if (!mounted) return;
              setState(() {
                _isHovered = false;
                _isPressed = false;
                _isLongPressed = false;
              });
            }
          : null,
      child: GestureDetector(
        onTap: _interactive ? widget.onTap : null,
        onTapDown: _interactive
            ? (_) => setState(() {
                _isPressed = true;
              })
            : null,
        onTapUp: _interactive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: _interactive
            ? () => setState(() => _isPressed = false)
            : null,
        onLongPressStart: _interactive && widget.longPressGlowColor != null
            ? (_) => setState(() => _isLongPressed = true)
            : null,
        onLongPressEnd: _interactive && widget.longPressGlowColor != null
            ? (_) => setState(() => _isLongPressed = false)
            : null,
        behavior: HitTestBehavior.translucent,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, lift, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(
                    alpha: _isLongPressed
                        ? 0.2
                        : (_isPressed ? 0.2 : (_isHovered ? 0.14 : 0.06)),
                  ),
                  blurRadius: _isLongPressed
                      ? 20
                      : (_isPressed ? 24 : (_isHovered ? 18 : 8)),
                  offset: Offset(
                    0,
                    _isLongPressed ? 6 : (_isPressed ? 6 : (_isHovered ? 8 : 4)),
                  ),
                  spreadRadius: _isLongPressed
                      ? -8
                      : (_isPressed ? -10 : (_isHovered ? -12 : -16)),
                ),
                BoxShadow(
                  color: AppColors.glassShadow.withValues(
                    alpha: _isPressed ? 0.18 : (_isHovered ? 0.24 : 0.14),
                  ),
                  blurRadius: _isPressed ? 12 : (_isHovered ? 14 : 10),
                  offset: Offset(0, _isPressed ? 5 : (_isHovered ? 8 : 4)),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TopMenuBar extends StatelessWidget {
  final VoidCallback onOpenMenu;

  const _TopMenuBar({
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InteractiveLift(
          onTap: onOpenMenu,
          borderRadius: 24,
          glowColor: AppColors.edgeGlow,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(color: AppColors.borderStrong, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: AppColors.secondaryLabel,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        _ShortcutPill(
          label: rankName,
          icon: CupertinoIcons.star_fill,
          iconColor: AppColors.warning,
          labelColor: AppColors.warning,
          onTap: onOpenRank,
        ),
        const SizedBox(width: 8),
        _ShortcutCircle(
          icon: CupertinoIcons.bolt_fill,
          gradient: [
            const Color(0xFFFF934D),
            AppColors.primaryOrange,
          ],
          onTap: onOpenFocus,
        ),
        const SizedBox(width: 8),
        _ShortcutCircle(
          icon: CupertinoIcons.doc_text_fill,
          gradient: const [
            Color(0xFFA26BFF),
            Color(0xFF7F50F2),
          ],
          onTap: onOpenNotes,
        ),
        const SizedBox(width: 8),
        _StreakPill(streak: winStreak, onTap: onOpenStreak),
      ],
    );
  }
}

class _ShortcutPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _ShortcutPill({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _InteractiveLift(
      onTap: onTap,
      borderRadius: 18,
      glowColor: labelColor.withValues(alpha: 0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.floatingGlassGradient,
          ),
          border: Border.all(color: AppColors.border, width: 0.9),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 6),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 1,
              left: 8,
              right: 8,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.glassHighlight.withValues(alpha: 0.22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTypography.footnote.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      language.t('shortcuts'),
                      style: AppTypography.overline.copyWith(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _shortcutOptions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final option = _shortcutOptions[index];
                          final enabled = _shortcuts.contains(option.moduleId);
                          final saving = _saving.contains(option.moduleId);
                          final canEnable =
                              enabled || _shortcuts.length < shortcutCapacity;
                          return _ModuleControlRow(
                            option: option,
                            enabled: enabled,
                            saving: saving,
                            locked: !canEnable,
                            onChanged: (value) =>
                                _onToggleShortcut(option, value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ShortcutCircle extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ShortcutCircle({
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _InteractiveLift(
      onTap: onTap,
      borderRadius: 24,
      glowColor: gradient.last.withValues(alpha: 0.32),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(color: AppColors.borderStrong, width: 1),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 8),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 1,
              left: 7,
              right: 7,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.glassHighlight.withValues(alpha: 0.24),
                ),
              ),
            ),
            Center(child: Icon(icon, color: AppColors.onAccent, size: 20)),
          ],
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;

  const _StreakPill({required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _InteractiveLift(
      onTap: onTap,
      borderRadius: 18,
      glowColor: AppColors.warning.withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.floatingGlassGradient,
          ),
          border: Border.all(color: AppColors.border, width: 0.9),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 6),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥', style: AppTypography.callout.copyWith(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              '$streak',
              style: AppTypography.footnote.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMainCard extends StatelessWidget {
  final int wakeScore;
  final int tasksCount;
  final int habitsCount;
  final VoidCallback onOpenDashboard;

  const _DashboardMainCard({
    required this.wakeScore,
    required this.tasksCount,
    required this.habitsCount,
    required this.onOpenDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return _InteractiveLift(
      onTap: onOpenDashboard,
      borderRadius: 30,
      hoverScale: 1.018,
      pressedScale: 1.028,
      glowColor: AppColors.edgeGlow,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 30,
        level: GlassCardLevel.elevated,
        showEdgeGlow: false,
        gradientColors: [
          AppColors.cardRaised,
          AppColors.cardBase,
        ],
        border: Border.all(color: AppColors.borderStrong, width: 1),
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceMuted,
                      AppColors.surface,
                    ],
                  ),
                  border: Border.all(color: AppColors.border, width: 0.9),
                ),
                child: Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  color: AppColors.accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title1.copyWith(fontSize: 48 / 2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your daily control center',
                      style: AppTypography.callout.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.accentSoft.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.65),
                    width: 1.1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$habitsCount',
                      style: AppTypography.timer.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'HABITS',
                      style: AppTypography.overline.copyWith(
                        fontSize: 9,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryAppCardData {
  final String moduleId;
  final String title;
  final IconData icon;
  final bool active;
  final bool isPlaceholder;
  final int? badgeValue;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;

  const _PrimaryAppCardData({
    required this.moduleId,
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
    this.isPlaceholder = false,
    this.badgeValue,
    this.onQuickAdd,
  });
}

class _PrimaryAppsGrid extends StatelessWidget {
  final List<_PrimaryAppCardData> cards;

  const _PrimaryAppsGrid({required this.cards});

  Widget _squareCard(_PrimaryAppCardData data) {
    return AspectRatio(aspectRatio: 1, child: _PrimaryAppCard(data: data, compact: true));
  }

  @override
  Widget build(BuildContext context) {
    if (cards.length == 1) {
      return _PrimaryAppCard(data: cards.first, compact: false);
    }

    if (cards.length == 2) {
      return Row(
        children: [
          Expanded(child: _squareCard(cards[0])),
          const SizedBox(width: 14),
          Expanded(child: _squareCard(cards[1])),
        ],
      );
    }

    final byId = <String, _PrimaryAppCardData>{
      for (final card in cards) card.moduleId: card,
    };
    final rowA = [byId['Pareto'], byId['Habits']];
    final rowB = [byId['Calendar'], byId['ScreenTimeManager']];

    Widget buildRow(List<_PrimaryAppCardData?> row) {
      final enabled = row.whereType<_PrimaryAppCardData>().toList();
      if (enabled.isEmpty) return const SizedBox.shrink();
      if (enabled.length == 1) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.44,
            child: AspectRatio(aspectRatio: 1, child: _PrimaryAppCard(data: enabled.first, compact: true)),
          ),
        );
      }
      return Row(
        children: [
          Expanded(child: _squareCard(enabled[0])),
          const SizedBox(width: 14),
          Expanded(child: _squareCard(enabled[1])),
        ],
      );
    }

    return Column(
      children: [
        buildRow(rowA),
        if (rowA.whereType<_PrimaryAppCardData>().isNotEmpty &&
            rowB.whereType<_PrimaryAppCardData>().isNotEmpty)
          const SizedBox(height: 14),
        buildRow(rowB),
      ],
    );
  }
}

class _PrimaryAppCard extends StatelessWidget {
  final _PrimaryAppCardData data;
  final bool compact;

  const _PrimaryAppCard({required this.data, required this.compact});

  Color _moduleGlow(String moduleId) {
    switch (moduleId) {
      case 'module_todo':
      case 'Pareto':
        return AppColors.chartA.withValues(alpha: 0.22);
      case 'module_habits':
      case 'Habits':
        return AppColors.chartB.withValues(alpha: 0.2);
      case 'module_schedule':
      case 'Calendar':
        return AppColors.chartC.withValues(alpha: 0.2);
      case 'module_screen_time':
      case 'ScreenTimeManager':
        return AppColors.chartD.withValues(alpha: 0.22);
      case 'shortcut_blackout':
        return AppColors.edgeGlowSoft.withValues(alpha: 0.22);
      case 'shortcut_quick_focus':
        return AppColors.focusPrimary.withValues(alpha: 0.18);
      case 'shortcut_controlled_pause':
        return AppColors.edgeGlowSoft.withValues(alpha: 0.16);
      case 'shortcut_block_now':
        return AppColors.chartD.withValues(alpha: 0.18);
      case 'shortcut_add_rule':
        return AppColors.chartC.withValues(alpha: 0.16);
      case 'shortcut_stats':
        return AppColors.warning.withValues(alpha: 0.14);
      case 'rank':
        return AppColors.warning.withValues(alpha: 0.18);
      case 'leaderboard':
        return AppColors.chartC.withValues(alpha: 0.18);
      case 'focus':
        return AppColors.focusPrimary.withValues(alpha: 0.18);
      case 'family_time':
        return AppColors.chartB.withValues(alpha: 0.18);
      case 'block_apps':
        return AppColors.chartD.withValues(alpha: 0.18);
      case 'streak':
        return AppColors.warning.withValues(alpha: 0.18);
      case 'notes':
        return AppColors.accent.withValues(alpha: 0.18);
      default:
        return AppColors.edgeGlowSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _moduleGlow(data.moduleId);
    if (data.isPlaceholder) {
      final placeholder = GlassCard(
        padding: EdgeInsets.all(compact ? 12 : 14),
        borderRadius: 24,
        level: GlassCardLevel.subtle,
        showEdgeGlow: false,
        glowColor: glowColor,
        gradientColors: [AppColors.cardBackgroundStrong, AppColors.cardBase],
        border: Border.all(color: AppColors.border, width: 0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.plus,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.8),
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ajouter',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.tertiaryLabel.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

      return _InteractiveLift(
        onTap: data.onTap,
        borderRadius: 24,
        hoverScale: 1.017,
        pressedScale: 1.028,
        glowColor: glowColor,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.16),
                        blurRadius: 18,
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            placeholder,
          ],
        ),
      );
    }

    final base = GlassCard(
      padding: EdgeInsets.all(compact ? 12 : 14),
      borderRadius: 24,
      level: data.active ? GlassCardLevel.elevated : GlassCardLevel.subtle,
      showEdgeGlow: false,
      glowColor: glowColor,
      gradientColors: [
        AppColors.cardRaised,
        AppColors.cardBase,
      ],
      border: Border.all(
        color: data.active ? AppColors.borderStrong : AppColors.border,
        width: data.active ? 1 : 0.9,
      ),
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 58 : 66,
                  height: compact ? 58 : 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.backgroundLight.withValues(alpha: 0.92),
                        AppColors.background.withValues(alpha: 0.9),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.65),
                      width: 0.92,
                    ),
                  ),
                  child: Icon(data.icon, color: AppColors.accentSecondary, size: 30),
                ),
                const Spacer(),
                if (data.onQuickAdd != null)
                  GestureDetector(
                    onTap: data.active ? data.onQuickAdd : null,
                    child: Opacity(
                      opacity: data.active ? 1 : 0.35,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.backgroundLight.withValues(alpha: 0.78),
                          border: Border.all(
                            color: AppColors.glassBorder.withValues(alpha: 0.6),
                            width: 0.82,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.add,
                          size: 17,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: data.active ? AppColors.label : AppColors.tertiaryLabel,
                    ),
                  ),
                ),
                if (data.badgeValue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.accentSecondary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.accentSecondary.withValues(alpha: 0.35),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${data.badgeValue}',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.accentSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              data.active ? 'ACTIVE' : 'DISABLED',
              style: AppTypography.mono.copyWith(
                fontSize: 8,
                color: data.active ? AppColors.tertiaryLabel : AppColors.error,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    if (!data.active) {
      return GestureDetector(
        onTap: () {},
        child: Opacity(opacity: 0.58, child: base),
      );
    }

    return GestureDetector(onTap: data.onTap, child: base);
  }
}

class _CeoModeCard extends StatelessWidget {
  final String statusLabel;
  final VoidCallback onOpenCeoMode;

  const _CeoModeCard({
    required this.statusLabel,
    required this.onOpenCeoMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenCeoMode,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 1.4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundLight.withValues(alpha: 0.45),
              AppColors.background.withValues(alpha: 0.72),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.95),
                  width: 2.05,
                ),
              ),
              child: Center(
                child: Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondaryLabel.withValues(alpha: 0.6),
                      width: 1.65,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Blackout Mode',
                style: AppTypography.mono.copyWith(
                  fontSize: 36 / 2,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onOpenCeoMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderStrong,
                    width: 1,
                  ),
                  color: AppColors.surface.withValues(alpha: 0.58),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.overline.copyWith(
                    fontSize: 11,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryMenuSheet extends StatefulWidget {
  final Set<String> initialActiveApps;
  final Set<String> initialEnabledShortcuts;
  final Future<bool> Function(String moduleId, bool enabled) onToggleModule;
  final Future<void> Function(String shortcutId, bool enabled) onToggleShortcut;
  final VoidCallback onCustomizeControlCenter;
  final VoidCallback onOpenProfileAndSettings;
  final VoidCallback onOpenAdvancedStats;
  final bool showAdvancedStats;

  const _SecondaryMenuSheet({
    required this.initialActiveApps,
    required this.initialEnabledShortcuts,
    required this.onToggleModule,
    required this.onToggleShortcut,
    required this.onCustomizeControlCenter,
    required this.onOpenProfileAndSettings,
    required this.onOpenAdvancedStats,
    required this.showAdvancedStats,
  });

  @override
  State<_SecondaryMenuSheet> createState() => _SecondaryMenuSheetState();
}

class _SecondaryMenuSheetState extends State<_SecondaryMenuSheet> {
  static const Set<String> _validPrimaryApps = {
    'Pareto',
    'Habits',
    'Calendar',
    'ScreenTimeManager',
  };
  late Set<String> _active;
  late Set<String> _shortcuts;
  final Set<String> _saving = <String>{};

  static const List<_ModuleToggleOption> _moduleOptions = [
    _ModuleToggleOption(
      moduleId: 'Pareto',
      titleKey: 'tasks',
      icon: CupertinoIcons.check_mark_circled,
    ),
    _ModuleToggleOption(
      moduleId: 'Habits',
      titleKey: 'habits',
      icon: CupertinoIcons.checkmark_circle,
    ),
    _ModuleToggleOption(
      moduleId: 'Calendar',
      titleKey: 'calendar',
      icon: CupertinoIcons.calendar,
    ),
    _ModuleToggleOption(
      moduleId: 'ScreenTimeManager',
      titleKey: 'screen_time_manager',
      icon: CupertinoIcons.shield,
    ),
  ];
  static const List<_ModuleToggleOption> _shortcutOptions = [
    _ModuleToggleOption(
      moduleId: 'rank',
      titleKey: 'rank',
      icon: CupertinoIcons.star_fill,
    ),
    _ModuleToggleOption(
      moduleId: 'focus',
      titleKey: 'focus_mode',
      icon: CupertinoIcons.bolt_fill,
    ),
    _ModuleToggleOption(
      moduleId: 'block_apps',
      titleKey: 'block_apps_sites',
      icon: CupertinoIcons.shield_fill,
    ),
    _ModuleToggleOption(
      moduleId: 'streak',
      titleKey: 'streak',
      icon: CupertinoIcons.flame_fill,
    ),
    _ModuleToggleOption(
      moduleId: 'notes',
      titleKey: 'notes',
      icon: CupertinoIcons.doc_text_fill,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _active = widget.initialActiveApps.where(_validPrimaryApps.contains).toSet();
    _shortcuts = Set<String>.from(widget.initialEnabledShortcuts);
  }

  Future<void> _onToggle(_ModuleToggleOption option, bool value) async {
    final previous = Set<String>.from(_active);
    setState(() {
      if (value) {
        _active.add(option.moduleId);
      } else {
        _active.remove(option.moduleId);
      }
      _saving.add(option.moduleId);
    });

    final success = await widget.onToggleModule(option.moduleId, value);
    if (!mounted) return;

    setState(() {
      if (!success) {
        _active = previous;
      }
      _saving.remove(option.moduleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final screen = MediaQuery.of(context).size;
    final panelWidth = (screen.width * 0.84).clamp(280.0, 360.0);
    return SizedBox(
      width: panelWidth,
      height: screen.height,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.97),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(20),
          ),
          border: Border(
            right: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Menu',
                    style: AppTypography.title2.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.label,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: AppColors.backgroundLight.withValues(alpha: 0.72),
                        border: Border.all(
                          color: AppColors.glassBorder.withValues(alpha: 0.72),
                          width: 0.6,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Settings, advanced stats, and mini-app visibility',
                style: AppTypography.caption1.copyWith(
                  fontSize: 11,
                  color: AppColors.tertiaryLabel,
                ),
              ),
              const SizedBox(height: 16),
              _SheetActionButton(
                label: language.t('profile_settings'),
                icon: CupertinoIcons.person_fill,
                onTap: widget.onOpenProfileAndSettings,
              ),
              const SizedBox(height: 8),
              _SheetActionButton(
                label: language.t('advanced_stats'),
                icon: CupertinoIcons.chart_bar_alt_fill,
                onTap: widget.onOpenAdvancedStats,
              ),
              const SizedBox(height: 16),
              Text(
                'Home modules',
                style: AppTypography.overline.copyWith(
                  fontSize: 11,
                  color: AppColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _moduleOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = _moduleOptions[index];
                    final enabled = _active.contains(option.moduleId);
                    final saving = _saving.contains(option.moduleId);
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      borderRadius: 14,
                      border: Border.all(
                        color: enabled
                            ? AppColors.accent.withValues(alpha: 0.44)
                            : AppColors.border,
                        width: 0.9,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option.icon,
                            size: 18,
                            color: enabled
                                ? AppColors.accent
                                : AppColors.tertiaryLabel,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option.title,
                              style: AppTypography.callout.copyWith(
                                fontSize: 13,
                                color: AppColors.label,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (saving)
                            CupertinoActivityIndicator(
                              color: AppColors.accent,
                            )
                          else
                            CupertinoSwitch(
                              value: enabled,
                              onChanged: (value) => _onToggle(option, value),
                              activeTrackColor: AppColors.accent,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 14,
        border: Border.all(
          color: AppColors.border,
          width: 0.9,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accentSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.callout.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.label,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleToggleOption {
  final String moduleId;
  final String titleKey;
  final IconData icon;

  const _ModuleToggleOption({
    required this.moduleId,
    required this.titleKey,
    required this.icon,
  });
}
