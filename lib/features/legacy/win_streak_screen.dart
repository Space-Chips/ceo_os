import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/focus_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/ambient_backdrop.dart';

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
    return "${completed ? _t('win_streak_completed") : _t('win_streak_stopped_early')} • ${duration}m';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: _loading
            ? Center(
                child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  children: [
                    _topBar(),
                    const SizedBox(height: 10),
                    _mainStreakCard(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: CupertinoIcons.rosette,
                            color: AppColors.warning,
                            value: '${_streak?.longestStreak ?? 0}',
                            label: _t('focus_record'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            icon: CupertinoIcons.arrow_up_right,
                            color: AppColors.success,
                            value: '$_successRate%',
                            label: _t('focus_success'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            icon: CupertinoIcons.check_mark_circled,
                            color: AppColors.info,
                            value: '${_streak?.totalCompletedSessions ?? 0}',
                            label: _t('focus_complete'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _winCardDecoration(radius: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('win_streak_recent_sessions'),
                            style: AppTypography.overline.copyWith(
                              fontSize: 18,
                              color: AppColors.label,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
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
                                  _t('win_streak_no_sessions_yet'),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.footnote.copyWith(
                                    fontSize: 13,
                                    color: AppColors.tertiaryLabel.withValues(
                                      alpha: 0.65,
                                    ),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._recentSessions.take(8).map(
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
                                    color: AppColors.backgroundLight.withValues(
                                      alpha: 0.66,
                                    ),
                                    border: Border.all(
                                      color: AppColors.glassBorder.withValues(
                                        alpha: 0.68,
                                      ),
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
                  _t('screen_time'),
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

  Widget _mainStreakCard() {
    final streak = _streak?.currentStreak ?? 0;
    final bestStreak = _streak?.longestStreak ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _winCardDecoration(radius: 24),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.flame,
            size: 36,
            color: AppColors.primaryOrange.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 12),
          Text(
            _t('win_streak_current_streak'),
            style: AppTypography.overline.copyWith(
              fontSize: 14,
              color: AppColors.secondaryLabel.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$streak',
            style: AppTypography.heroNumber.copyWith(
              fontSize: 96,
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
              height: 0.92,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: AppTypography.footnote.copyWith(
                fontSize: 13,
                color: AppColors.secondaryLabel.withValues(alpha: 0.7),
              ),
              children: [
                TextSpan(text: "${_t('win_streak_best_streak")}: '),
                TextSpan(
                  text:
                      "$bestStreak ${_t('win_streak_days_suffix")}',
                  style: AppTypography.footnote.copyWith(
                    fontSize: 13,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            streak == 0
                ? _t('win_streak_start_first_session')
                : _t('win_streak_keep_momentum'),
            style: AppTypography.footnote.copyWith(
              fontSize: 13,
              color: AppColors.secondaryLabel.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return _WinPressScale(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _winCardDecoration(radius: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.moduleIconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTypography.title2.copyWith(
                fontSize: 28,
                color: color,
                fontWeight: FontWeight.w700,
                height: 0.95,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption1.copyWith(
                fontSize: 12,
                color: AppColors.tertiaryLabel.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _winCardDecoration({double radius = 18}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cardBackgroundStrong, AppColors.cardBase],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.border,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.glassShadow.withValues(alpha: 0.3),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _WinPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _WinPressScale({required this.child, required this.onTap});

  @override
  State<_WinPressScale> createState() => _WinPressScaleState();
}

class _WinPressScaleState extends State<_WinPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 1.01 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
