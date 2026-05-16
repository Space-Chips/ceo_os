import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, FontWeight, IconData;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ScreenTimeManagerScreen extends StatefulWidget {
  const ScreenTimeManagerScreen({super.key});

  @override
  State<ScreenTimeManagerScreen> createState() =>
      _ScreenTimeManagerScreenState();
}

class _ScreenTimeManagerScreenState extends State<ScreenTimeManagerScreen> {
  final FeatureRepository _featureRepository = FeatureRepository();
  final UserRepository _userRepository = UserRepository();

  List<Map<String, dynamic>> _logs = const [];
  UserRank? _rank;
  WinStreak? _streak;
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

      final logs = await _featureRepository.getScreenTimeLogs(days: 14);
      final rank = await _userRepository.getUserRank();
      final streak = await _userRepository.getWinStreak();

      if (!mounted) return;
      setState(() {
        _logs = logs;
        _rank = rank;
        _streak = streak;
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

  int _blockedTargets(FocusProvider focus) {
    if (focus.blockLists.isEmpty) return 0;
    final active = focus.blockLists.firstWhere(
      (list) => list.id == focus.activeBlockListId,
      orElse: () => focus.blockLists.first,
    );
    var count =
        active.blockedPackageNames.length + active.blockedCategories.length;
    if (active.adultBlocking) count += 1;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: _loading
            ? Center(
                child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
              )
            : Consumer<FocusProvider>(
                builder: (context, focus, _) {
                  final todayFromLogs = _todayMinutesFromLogs();
                  final todayMinutes = todayFromLogs > 0
                      ? todayFromLogs
                      : focus.screenTimeToday.round();
                  final avg7d = _averageDailyMinutes(days: 7);
                  final blockedTargets = _blockedTargets(focus);
                  final rankName =
                      (_rank?.rankName?.trim().isNotEmpty ?? false)
                      ? _rank!.rankName!.trim()
                      : 'Bronze';

                  return SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      children: [
                        _headerRow(),
                        const SizedBox(height: 10),
                        _focusEntryCard(),
                        const SizedBox(height: 12),
                        _statsClusterCard(
                          todayMinutes: todayMinutes,
                          avg7dMinutes: avg7d,
                          rankName: rankName,
                          streakValue: _streak?.currentStreak ?? 0,
                        ),
                        const SizedBox(height: 12),
                        _actionCard(
                          icon: CupertinoIcons.nosign,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Block Apps & Sites',
                          subtitle: '$blockedTargets blocked • apps, sites, pauses',
                          onTap: () => context.push('/screen-time'),
                        ),
                        const SizedBox(height: 8),
                        _actionCard(
                          icon: CupertinoIcons.rosette,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Leaderboard',
                          subtitle: 'Global rankings',
                          onTap: () => context.push('/leaderboard'),
                        ),
                        const SizedBox(height: 8),
                        _actionCard(
                          icon: CupertinoIcons.shield,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Blocking Preview',
                          subtitle: 'See how blocking works',
                          onTap: () => context.push('/focus'),
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
                Icon(CupertinoIcons.back, size: 20, color: AppColors.secondaryLabel),
                const SizedBox(width: 4),
                Text(
                  'Screen Time',
                  style: AppTypography.mono.copyWith(
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
                  'Home',
                  style: AppTypography.mono.copyWith(
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
    return GestureDetector(
      onTap: () => context.push('/focus'),
      child: _glowSurface(
        glowColor: AppColors.primaryOrange.withValues(alpha: 0.28),
        borderRadius: 28,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          borderRadius: 28,
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.62),
            width: 1.0,
          ),
          gradientColors: [
            AppColors.primaryOrange.withValues(alpha: 0.28),
            AppColors.backgroundLight.withValues(alpha: 0.9),
          ],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START SESSION',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Focus Mode',
                      style: AppTypography.mono.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.label,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deep work environment',
                      style: AppTypography.mono.copyWith(
                        fontSize: 15,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFB685).withValues(alpha: 0.98),
                      AppColors.primaryOrange.withValues(alpha: 0.95),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.33),
                      blurRadius: 26,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.bolt_fill,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsClusterCard({
    required int todayMinutes,
    required int avg7dMinutes,
    required String rankName,
    required int streakValue,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 24,
      border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.8), width: 0.7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statLargeTile(
                  label: 'TODAY',
                  value: '$todayMinutes',
                  unit: 'minutes',
                  accent: const Color(0xFF60A5FA),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statLargeTile(
                  label: '7-DAY',
                  value: '$avg7dMinutes',
                  unit: 'minutes',
                  accent: AppColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statSmallTile(
                  icon: CupertinoIcons.rosette,
                  iconColor: const Color(0xFFFACC15),
                  label: 'RANK',
                  value: rankName,
                  valueColor: const Color(0xFFFACC15),
                  onTap: () => context.push('/rank'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statSmallTile(
                  icon: CupertinoIcons.flame,
                  iconColor: AppColors.primaryOrange,
                  label: 'STREAK',
                  value: '$streakValue',
                  valueColor: AppColors.primaryOrange,
                  onTap: () => context.push('/win-streak'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statLargeTile({
    required String label,
    required String value,
    required String unit,
    required Color accent,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.backgroundLight.withValues(alpha: highlighted ? 0.82 : 0.64),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF2563EB).withValues(alpha: 0.92)
              : AppColors.glassBorder.withValues(alpha: 0.6),
          width: highlighted ? 1.35 : 0.7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.tertiaryLabel,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 54,
              color: accent,
              fontWeight: FontWeight.w900,
              height: 0.85,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unit,
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              color: AppColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statSmallTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.backgroundLight.withValues(alpha: 0.62),
          border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.56), width: 0.7),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.mono.copyWith(
                      fontSize: 9,
                      color: AppColors.tertiaryLabel,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono.copyWith(
                      fontSize: 30,
                      color: valueColor,
                      fontWeight: FontWeight.w900,
                      height: 0.85,
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

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        borderRadius: 20,
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.72), width: 0.7),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.backgroundLight.withValues(alpha: 0.7),
                border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.55), width: 0.7),
              ),
              child: Icon(icon, color: iconColor, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.mono.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.arrow_right, color: AppColors.tertiaryLabel, size: 18),
          ],
        ),
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
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
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
