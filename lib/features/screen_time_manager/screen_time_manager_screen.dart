import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/settings_models.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/services/classic_blocking_coordinator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rank_art.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';

class ScreenTimeManagerScreen extends StatefulWidget {
  const ScreenTimeManagerScreen({super.key});

  @override
  State<ScreenTimeManagerScreen> createState() =>
      _ScreenTimeManagerScreenState();
}

class _ScreenTimeManagerScreenState extends State<ScreenTimeManagerScreen> {
  final FeatureRepository _featureRepository = FeatureRepository();
  final UserRepository _userRepository = UserRepository();
  final ClassicBlockingCoordinator _classicBlockingCoordinator =
      ClassicBlockingCoordinator();

  List<Map<String, dynamic>> _logs = const [];
  UserRank? _rank;
  WinStreak? _streak;
  int _classicBlockedTargets = 0;
  int _plannedPauseCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final focus = context.read<FocusProvider>();
      await focus.loadInitialData();
      await focus.refreshScreenTime();
      await _userRepository.refreshLeaderboardForMe();

      final results = await Future.wait<dynamic>([
        _featureRepository.getScreenTimeLogs(days: 14),
        _userRepository.getUserRank(),
        _userRepository.getWinStreak(),
        _featureRepository.getBlockedApps(),
        _featureRepository.getBlockedWebsites(),
      ]);
      final logs = results[0] as List<Map<String, dynamic>>;
      final rank = results[1] as UserRank?;
      final streak = results[2] as WinStreak?;
      final blockedApps = results[3] as List<BlockedApp>;
      final blockedSites = results[4] as List<BlockedWebsite>;
      final adultShieldEnabled = blockedSites.any(
        (site) =>
            (site.urlDomain ?? '').trim() ==
            FeatureRepository.adultContentShieldMarker,
      );
      final classicBlockedTargets =
          blockedApps.length +
          blockedSites
              .where(
                (site) =>
                    (site.urlDomain ?? '').trim() !=
                    FeatureRepository.adultContentShieldMarker,
              )
              .length +
          (adultShieldEnabled ? 1 : 0);
      final restPeriods = await _featureRepository.getRestPeriods();
      final now = DateTime.now();
      final plannedPauseCount = restPeriods
          .where((period) => _isScheduledRest(period, now))
          .length;
      await _classicBlockingCoordinator.syncNativeState(
        apps: blockedApps,
        websites: blockedSites
            .where(
              (site) =>
                  (site.urlDomain ?? '').trim() !=
                  FeatureRepository.adultContentShieldMarker,
            )
            .toList(growable: false),
        restPeriods: restPeriods,
      );

      if (!mounted) return;
      setState(() {
        _logs = logs;
        _rank = rank;
        _streak = streak;
        _classicBlockedTargets = classicBlockedTargets;
        _plannedPauseCount = plannedPauseCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int _todayMinutesFromLogs() {
    final todayKey = DateTime.now().toIso8601String().split('T').first;
    var seconds = 0;
    for (final log in _logs) {
      final date = (log['date'] ?? '').toString().split('T').first;
      if (date != todayKey) continue;
      seconds += (log['duration_seconds'] as num?)?.toInt() ?? 0;
    }
    return seconds ~/ 60;
  }

  int _averageDailyMinutes({int days = 7}) {
    if (_logs.isEmpty) return 0;
    final byDay = <String, int>{};

    for (final log in _logs) {
      final rawDate = (log['date'] ?? '').toString();
      if (rawDate.isEmpty) continue;
      final day = rawDate.split('T').first;
      byDay[day] =
          (byDay[day] ?? 0) + ((log['duration_seconds'] as num?)?.toInt() ?? 0);
    }

    if (byDay.isEmpty) return 0;
    final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final subset = sortedDays.take(days).toList();
    if (subset.isEmpty) return 0;

    final totalSeconds = subset.fold<int>(
      0,
      (sum, day) => sum + (byDay[day] ?? 0),
    );
    return (totalSeconds / 60 / subset.length).round();
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String _t(String key) => context.read<LanguageProvider>().t(key);

  int _blockedTargets(FocusProvider focus) {
    final configured =
        focus.configuredBlockedAppCount + focus.configuredBlockedWebsiteCount;
    return configured > 0 ? configured : _classicBlockedTargets;
  }

  bool _isScheduledRest(RestPeriod period, DateTime now) {
    final start = period.startTime;
    final end = period.endTime;
    if (!period.active || start == null || end == null) return false;
    if (!end.isAfter(start)) return false;
    return start.isAfter(now);
  }

  String _localizedRankName(String rawRankName) {
    final language = context.read<LanguageProvider>();
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

  BoxDecoration _moduleDecoration({
    double radius = 18,
    Color? borderColor,
    double borderWidth = 1,
    Color? overlay,
  }) {
    return BoxDecoration(
      color: overlay ?? AppColors.cardBase,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorder,
        width: borderWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LanguageProvider>().languageCode;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: _loading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.primaryOrange,
                ),
              )
            : Consumer<FocusProvider>(
                builder: (context, focus, _) {
                  final todayFromLogs = _todayMinutesFromLogs();
                  final todayMinutes = todayFromLogs > 0
                      ? todayFromLogs
                      : focus.screenTimeToday.round();
                  final avg7d = _averageDailyMinutes(days: 7);
                  final blockedTargets = _blockedTargets(focus);
                  final isAuthorized = focus.isAuthorized;
                  final rankName = (_rank?.rankName?.trim().isNotEmpty ?? false)
                      ? _rank!.rankName!.trim()
                      : 'Bronze';

                  return SafeArea(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(0, 64, 0, 24),
                            children: [
                              _focusEntryCard(),
                              const SizedBox(height: 14),
                              _statsClusterCard(
                                todayMinutes: todayMinutes,
                                avg7dMinutes: avg7d,
                                rankName: rankName,
                                streakValue: _streak?.currentStreak ?? 0,
                                blockedTargets: blockedTargets,
                                plannedPauseCount: _plannedPauseCount,
                                isAuthorized: isAuthorized,
                                privateRankLabel: rankName,
                              ),
                              const SizedBox(height: 14),
                              _actionCard(
                                icon: CupertinoIcons.person_2_fill,
                                iconColor: AppColors.secondaryLabel,
                                title: 'Offline Together',
                                subtitle: 'Shared no-phone sessions',
                                onTap: () => _showComingSoon(
                                  title: 'Offline Together',
                                  message:
                                      'Shared no-phone sessions will stay locked until Apple privacy and permission flows are production-ready.',
                                ),
                                locked: true,
                              ),
                              const SizedBox(height: 10),
                              _actionCard(
                                icon: CupertinoIcons.nosign,
                                iconColor: AppColors.secondaryLabel,
                                title: 'Block Apps And Sites',
                                subtitle:
                                    '$blockedTargets protected on this device',
                                onTap: () => context.push('/screen-time'),
                              ),
                              const SizedBox(height: 10),
                              _actionCard(
                                icon: CupertinoIcons.rosette,
                                iconColor: AppColors.secondaryLabel,
                                title: 'Friends & Leaderboard',
                                subtitle: 'Global rankings',
                                onTap: () => _showComingSoon(
                                  title: 'Friends & Leaderboard',
                                  message:
                                      'Social ranking will stay locked until friend privacy and consent flows are production-ready.',
                                ),
                                locked: true,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 18,
                                sigmaY: 18,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  10,
                                  20,
                                  10,
                                ),
                                child: _headerRow(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _headerRow() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            onPressed: () => context.go('/home'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  _isAndroid ? _t('focus_protection') : _t('screen_time'),
                  style: AppTypography.callout.copyWith(
                    fontSize: 16,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            minimumSize: Size.zero,
            onPressed: () => context.go('/home'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.house,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  _t('home'),
                  style: AppTypography.callout.copyWith(
                    fontSize: 16,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusEntryCard() {
    return _ScreenTimePressScale(
      onTap: () => context.push('/focus'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 40, 26, 44),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardBackgroundStrong.withValues(alpha: 0.98),
              AppColors.background.withValues(alpha: 0.82),
            ],
          ),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.40),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.42),
              blurRadius: 32,
              offset: const Offset(0, 14),
              spreadRadius: -10,
            ),
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _t('focus_mode'),
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label,
                  height: 1.02,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.backgroundLight.withValues(alpha: 0.46),
                    AppColors.surface.withValues(alpha: 0.18),
                  ],
                ),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.32),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glassShadow.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.bolt,
                color: AppColors.secondaryLabel,
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsClusterCard({
    required int todayMinutes,
    required int avg7dMinutes,
    required String rankName,
    required int streakValue,
    required int blockedTargets,
    required int plannedPauseCount,
    required bool isAuthorized,
    required String privateRankLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Expanded(
                child: _statMetricTile(
                  label: _t('today').toUpperCase(),
                  value: _durationLabel(todayMinutes),
                  subtitle: 'private on-device',
                  highlighted: true,
                  onTap: () => context.push('/screen-time?section=logs'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statMetricTile(
                  label: '7D AVG',
                  value: _durationLabel(avg7dMinutes),
                  subtitle: 'last 7 days',
                  onTap: () => context.push('/screen-time?section=logs'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statSmallTile(
                  icon: CupertinoIcons.lock_shield_fill,
                  iconColor: isAuthorized
                      ? AppColors.success
                      : AppColors.primaryOrange,
                  label: 'Access',
                  value: isAuthorized ? 'Approved' : 'Allow',
                  valueColor: isAuthorized
                      ? AppColors.success
                      : AppColors.primaryOrange,
                  onTap: () => context.push('/screen-time?section=access'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statSmallTile(
                  icon: CupertinoIcons.star_fill,
                  iconColor: AppColors.rankAccent,
                  label: 'Rank',
                  value: _localizedRankName(privateRankLabel),
                  valueColor: AppColors.rankAccent,
                  leading: RankArt(
                    rankName: privateRankLabel,
                    size: RankArtSize.xs,
                    dimension: 22,
                  ),
                  onTap: () => context.push('/rank'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  Widget _statMetricTile({
    required String label,
    required String value,
    required String subtitle,
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        border: Border.all(
          color: highlighted
              ? AppColors.glassBorder.withValues(alpha: 0.48)
              : AppColors.glassBorder.withValues(alpha: 0.38),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: AppTypography.timer.copyWith(
              fontSize: 30,
              color: AppColors.label,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.subhead.copyWith(
              fontSize: 11,
              color: AppColors.tertiaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return tile;
    return _ScreenTimePressScale(onTap: onTap, child: tile);
  }

  Widget _statSmallTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required VoidCallback onTap,
    Widget? leading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.backgroundLight.withValues(alpha: 0.42),
          border: Border.all(
            color: AppColors.glassBorder.withValues(alpha: 0.38),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                leading ?? Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.overline.copyWith(
                      fontSize: 11,
                      color: AppColors.tertiaryLabel,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppTypography.title3.copyWith(
                  fontSize: 24,
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool locked = false,
  }) {
    return _ScreenTimePressScale(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        borderRadius: 18,
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.38),
          width: 0.5,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.secondaryLabel.withValues(alpha: 0.55),
              ),
              child: Icon(
                icon,
                color: AppColors.background,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subhead.copyWith(
                      fontSize: 13,
                      color: AppColors.secondaryLabel,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              locked ? CupertinoIcons.lock : CupertinoIcons.arrow_right,
              color: AppColors.tertiaryLabel.withValues(alpha: 0.85),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showComingSoon({
    required String title,
    required String message,
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('$message\n\nCOMING SOON'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _glowSurface({
    required Widget child,
    required Color glowColor,
    double borderRadius = 20,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 32, spreadRadius: 2),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// Recovered class _ScreenTimePressScale @ 2026-03-09T18:44:16.804Z
class _ScreenTimePressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScreenTimePressScale({required this.child, required this.onTap});

  @override
  State<_ScreenTimePressScale> createState() => _ScreenTimePressScaleState();
}

class _ScreenTimePressScaleState extends State<_ScreenTimePressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
