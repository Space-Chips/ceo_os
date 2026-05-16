import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/focus_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class WinStreakScreen extends StatefulWidget {
  const WinStreakScreen({super.key});

  @override
  State<WinStreakScreen> createState() => _WinStreakScreenState();
}

class _WinStreakScreenState extends State<WinStreakScreen> {
  final FeatureRepository _featureRepo = FeatureRepository();
  final FocusRepository _focusRepo = FocusRepository();

  WinStreak? _streak;
  List<Map<String, dynamic>> _recentSessions = const [];
  bool _loading = true;

  String _t(String key) => context.read<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final streak = await _featureRepo.getWinStreak();
    final sessions = await _focusRepo.getRecentSessions();
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _recentSessions = sessions;
      _loading = false;
    });
  }

  int get _successRate {
    final completed = _streak?.totalCompletedSessions ?? 0;
    final failed = _streak?.totalFailedSessions ?? 0;
    if (completed + failed == 0) return 0;
    return ((completed / (completed + failed)) * 100).round();
  }

  String _sessionLine(Map<String, dynamic> row) {
    final duration = (row['duration_minutes'] as num?)?.toInt() ?? 0;
    final completed = row['completed'] == true;
    return '${completed ? 'Completed' : 'Stopped early'} • ${duration}m';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: _loading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.primaryOrange,
                ),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  children: [
                    _topBar(),
                    const SizedBox(height: 10),
                    _mainStreakCard(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: CupertinoIcons.rosette,
                            color: const Color(0xFFFACC15),
                            value: '${_streak?.longestStreak ?? 0}',
                            label: 'RECORD',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            icon: CupertinoIcons.arrow_up_right,
                            color: const Color(0xFF6EE7B7),
                            value: '$_successRate%',
                            label: 'SUCCESS',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            icon: CupertinoIcons.check_mark_circled,
                            color: const Color(0xFFA78BFA),
                            value: '${_streak?.totalCompletedSessions ?? 0}',
                            label: 'COMPLETE',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 22,
                      border: Border.all(
                        color: AppColors.glassBorder.withValues(alpha: 0.76),
                        width: 0.7,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECENT SESSIONS',
                            style: AppTypography.mono.copyWith(
                              fontSize: 18,
                              color: AppColors.label,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_recentSessions.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 12,
                              ),
                              child: Center(
                                child: Text(
                                  'No sessions yet. Start your first focus session!',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 14,
                                    color: AppColors.tertiaryLabel,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._recentSessions
                                .take(8)
                                .map(
                                  (row) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.backgroundLight
                                            .withValues(alpha: 0.66),
                                        border: Border.all(
                                          color: AppColors.glassBorder
                                              .withValues(alpha: 0.68),
                                          width: 0.7,
                                        ),
                                      ),
                                      child: Text(
                                        _sessionLine(row),
                                        style: AppTypography.mono.copyWith(
                                          fontSize: 13,
                                          color: AppColors.secondaryLabel,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            minimumSize: Size.zero,
            onPressed: () => context.go('/screen-time-manager'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  'Screen Time',
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
            padding: const EdgeInsets.symmetric(horizontal: 2),
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

  Widget _mainStreakCard() {
    final streak = _streak?.currentStreak ?? 0;
    return _glowSurface(
      glowColor: AppColors.primaryOrange.withValues(alpha: 0.34),
      borderRadius: 38,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        borderRadius: 38,
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.62),
          width: 1.1,
        ),
        gradientColors: [
          AppColors.primaryOrange.withValues(alpha: 0.18),
          AppColors.backgroundLight.withValues(alpha: 0.92),
        ],
        child: Column(
          children: [
            Icon(
              CupertinoIcons.flame_fill,
              size: 98,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 8),
            Text(
              'CURRENT STREAK',
              style: AppTypography.mono.copyWith(
                fontSize: 18,
                color: AppColors.primaryOrange.withValues(alpha: 0.86),
                fontWeight: FontWeight.w900,
                letterSpacing: 4.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$streak',
              style: AppTypography.mono.copyWith(
                fontSize: 200,
                color: const Color(0xFFFF9445),
                fontWeight: FontWeight.w900,
                height: 0.82,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              streak == 0 ? 'Start your first session' : 'Keep the momentum',
              style: AppTypography.mono.copyWith(
                fontSize: 16,
                color: AppColors.secondaryLabel,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      borderRadius: 24,
      border: Border.all(color: color.withValues(alpha: 0.52), width: 0.9),
      gradientColors: [
        color.withValues(alpha: 0.1),
        AppColors.backgroundLight.withValues(alpha: 0.86),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 68,
              color: color,
              fontWeight: FontWeight.w900,
              height: 0.82,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.tertiaryLabel,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
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
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 30, spreadRadius: 1),
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
