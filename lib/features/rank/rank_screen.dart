import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/focus_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rank_art.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  final UserRepository _repository = UserRepository();
  final FocusRepository _focusRepository = FocusRepository();

  UserRank? _rank;
  WinStreak? _streak;
  int _daysInApp = 0;
  int _focusSessionsCompleted = 0;
  bool _loading = true;

  String _t(String key) => context.read<LanguageProvider>().t(key);

  List<_RankTierData> get _tiers => [
    _RankTierData(
      name: 'Awakened',
      requirements: ['500 day streak', '250h Focus', '250h CEO'],
    ),
    _RankTierData(
      name: 'Immortal',
      requirements: ['365 day streak', '200h Focus', '100h CEO'],
    ),
    _RankTierData(
      name: 'Diamond',
      requirements: ['180 day streak', '200h Focus'],
    ),
    _RankTierData(
      name: 'Platinum',
      requirements: ['90 day streak', '60h Focus'],
    ),
    _RankTierData(name: 'Gold', requirements: ['50 day streak']),
    _RankTierData(
      name: 'Silver',
      requirements: ['15 days in app', '10 day streak'],
    ),
    _RankTierData(name: 'Bronze', requirements: ['Starting rank']),
    _RankTierData(name: 'Sleeping', requirements: ['Start your first streak']),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    await _repository.refreshLeaderboardForMe();
    final rank = await _repository.getUserRank();
    final streak = await _repository.getWinStreak();
    final profile = await _repository.getProfile();
    final focusSessionsCompleted = await _focusRepository
        .getCompletedSessionCount();
    final createdAt = profile?.createdAt;
    final daysInApp = createdAt == null
        ? 0
        : DateTime.now().difference(createdAt).inDays + 1;

    if (!mounted) return;
    setState(() {
      _rank = rank;
      _streak = streak;
      _daysInApp = daysInApp;
      _focusSessionsCompleted = focusSessionsCompleted;
      _loading = false;
    });
  }

  _RankTierData _currentTier() {
    final serverTier = _serverTier();
    final localTier = _localFallbackTier();
    final serverIndex = _tiers.indexWhere(
      (tier) => tier.name == serverTier.name,
    );
    final localIndex = _tiers.indexWhere((tier) => tier.name == localTier.name);
    return localIndex < serverIndex ? localTier : serverTier;
  }

  _RankTierData _serverTier() {
    final rankName = RankArt.displayName(_rank?.rankName ?? '').toLowerCase();
    final byName = _tiers.where((tier) => tier.name.toLowerCase() == rankName);
    if (byName.isNotEmpty) return byName.first;

    final level = _rank?.rankLevel ?? 0;
    if (level >= 7) return _tiers[0];
    if (level == 6) return _tiers[1];
    if (level == 5) return _tiers[2];
    if (level == 4) return _tiers[3];
    if (level == 3) return _tiers[4];
    if (level == 2) return _tiers[5];
    if (level == 1) return _tiers[6];
    return _tiers[7];
  }

  _RankTierData _localFallbackTier() {
    if (_daysInApp >= 7 && _focusSessionsCompleted >= 1) {
      return _tiers[6];
    }
    return _tiers[7];
  }

  bool _serverRankIsBehind(_RankTierData current) {
    final serverTier = _serverTier();
    final currentIndex = _tiers.indexWhere((tier) => tier.name == current.name);
    final serverIndex = _tiers.indexWhere(
      (tier) => tier.name == serverTier.name,
    );
    return currentIndex < serverIndex;
  }

  _RankTierData? _nextTier(_RankTierData current) {
    final idx = _tiers.indexWhere((tier) => tier.name == current.name);
    if (idx <= 0) return null;
    return _tiers[idx - 1];
  }

  double _nextRankProgressPercent(_RankTierData? next) {
    if (next == null) return 100;

    final progress = <double>[];
    for (final requirement in next.requirements) {
      final normalized = requirement.toLowerCase().trim();
      if (normalized.contains('day streak')) {
        final target = int.tryParse(
          RegExp(r'(\d+)').firstMatch(normalized)?.group(1) ?? '',
        );
        if (target != null && target > 0) {
          progress.add(
            ((_streak?.currentStreak ?? 0) / target).clamp(0, 1).toDouble(),
          );
          continue;
        }
      }
      if (normalized.contains('days in app')) {
        final target = int.tryParse(
          RegExp(r'(\d+)').firstMatch(normalized)?.group(1) ?? '',
        );
        if (target != null && target > 0) {
          progress.add((_daysInApp / target).clamp(0, 1).toDouble());
          continue;
        }
      }
    }

    if (progress.isNotEmpty) {
      return (progress.reduce((a, b) => a + b) / progress.length) * 100;
    }

    final rankPoints = (_rank?.totalRankPoints ?? 0).toDouble();
    if (rankPoints <= 0) return 0;
    return (rankPoints % 100).clamp(0, 100).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    final current = _currentTier();
    final next = _nextTier(current);

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
                    _currentRankHero(current),
                    const SizedBox(height: 14),
                    _pathSection(current, next),
                    const SizedBox(height: 14),
                    _statsSection(),
                    const SizedBox(height: 14),
                    Text(
                      _t('rank_ladder'),
                      style: AppTypography.mono.copyWith(
                        fontSize: 24,
                        color: AppColors.label,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._tiers.map((tier) => _tierCard(tier, current)),
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
                  _t('back'),
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

  Widget _currentRankHero(_RankTierData tier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              AppColors.accentSurfaceSoft.withValues(alpha: 0.8),
              AppColors.cardBackgroundAlt,
            ),
            AppColors.cardBase,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.activeBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _rankIconContainer(tier, iconSize: 120),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _localizedTierName(tier.name),
                style: AppTypography.largeTitle.copyWith(
                  fontSize: 52,
                  color: AppColors.label,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pathSection(_RankTierData current, _RankTierData? next) {
    final progressPercent = _nextRankProgressPercent(next);
    final serverBehind = _serverRankIsBehind(current);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _rankCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 20,
                color: AppColors.rankAccent,
              ),
              const SizedBox(width: 8),
              Text(
                next == null
                    ? _t('rank_top_reached')
                    : _t(
                        'rank_path_to',
                      ).replaceAll('{rank}', _localizedTierName(next.name)),
                style: AppTypography.callout.copyWith(
                  fontSize: 16,
                  color: AppColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (next != null) ...[
            Row(
              children: [
                Text(
                  _t('rank_progress'),
                  style: AppTypography.caption1.copyWith(
                    fontSize: 12,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progressPercent.round()}%',
                  style: AppTypography.footnote.copyWith(
                    fontSize: 13,
                    color: AppColors.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                width: double.infinity,
                color: AppColors.border,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: (progressPercent / 100).clamp(0, 1),
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.rankAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (next == null)
            Text(
              _t('rank_highest_tier'),
              style: AppTypography.footnote.copyWith(
                fontSize: 13,
                color: AppColors.secondaryLabel.withValues(alpha: 0.7),
              ),
            )
          else if (serverBehind) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.rankAccent.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.rankAccent.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Text(
                _t('rank_requirements_completed_sync_pending'),
                style: AppTypography.footnote.copyWith(
                  fontSize: 12,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.88),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else
            ...next.requirements.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.bolt,
                        size: 18,
                        color: AppColors.rankAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          req,
                          style: AppTypography.callout.copyWith(
                            fontSize: 14,
                            color: AppColors.secondaryLabel.withValues(
                              alpha: 0.85,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _localizedTierName(String rawRankName) {
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

  BoxDecoration _rankCardDecoration({required double radius}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.cardBackgroundStrong, AppColors.cardBase],
      ),
      border: Border.all(color: AppColors.glassBorder, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.24),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -14,
        ),
      ],
    );
  }

  Widget _rankIconContainer(_RankTierData tier, {required double iconSize}) {
    return _tierBadge(tier, size: iconSize);
  }

  Widget _statsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _rankCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('rank_your_stats'),
            style: AppTypography.overline.copyWith(
              fontSize: 14,
              letterSpacing: 2,
              color: AppColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _statRow(_t('rank_days_in_app'), '$_daysInApp'),
          const SizedBox(height: 10),
          _statRow(
            _t('rank_streak'),
            _t(
              'rank_days_value',
            ).replaceAll('{count}', '${_streak?.currentStreak ?? 0}'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.floatingGlassGradient.first.withValues(alpha: 0.84),
            AppColors.floatingGlassGradient.last.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.mono.copyWith(
                fontSize: 16,
                color: AppColors.secondaryLabel,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 17,
              color: label == 'Streak'
                  ? const Color(0xFFFF9D43)
                  : AppColors.label,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard(_RankTierData tier, _RankTierData current) {
    final currentIndex = _tiers.indexWhere((t) => t.name == current.name);
    final thisIndex = _tiers.indexWhere((t) => t.name == tier.name);
    final isCurrent = thisIndex == currentIndex;
    final unlocked = thisIndex >= currentIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        borderRadius: 16,
        level: isCurrent ? GlassCardLevel.elevated : GlassCardLevel.standard,
        showEdgeGlow: isCurrent,
        border: Border.all(
          color: isCurrent
              ? tier.ring.first.withValues(alpha: 0.72)
              : AppColors.glassBorder.withValues(alpha: 0.7),
          width: isCurrent ? 0.95 : 0.7,
        ),
        gradientColors: isCurrent
            ? [
                tier.ring.first.withValues(alpha: 0.18),
                AppColors.backgroundLight.withValues(alpha: 0.9),
              ]
            : null,
        child: Row(
          children: [
            _tierBadge(tier, size: 68),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.name,
                    style: AppTypography.mono.copyWith(
                      fontSize: 20,
                      color: AppColors.label,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.requirements.join(' + '),
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(
                CupertinoIcons.rosette,
                color: const Color(0xFFFACC15),
                size: 24,
              )
            else
              Text(
                unlocked ? 'Unlocked' : 'Locked',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: unlocked ? AppColors.success : AppColors.tertiaryLabel,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tierBadge(_RankTierData tier, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tier.ring[0], tier.ring[1], tier.ring[2]],
        ),
        boxShadow: [
          BoxShadow(color: tier.glow, blurRadius: size * 0.35, spreadRadius: 1),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.2),
            color: const Color(0xFF060B15),
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _RankPressScale({required this.child, required this.onTap});

  @override
  State<_RankPressScale> createState() => _RankPressScaleState();
}

class _RankPressScaleState extends State<_RankPressScale> {
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

class _FacetPainter extends CustomPainter {
  final Color lineColor;
  final Color secondaryColor;
  final int density;

  _FacetPainter({
    required this.lineColor,
    required this.secondaryColor,
    required this.density,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = lineColor.withValues(alpha: 0.42);
    final secPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = secondaryColor.withValues(alpha: 0.32);

    final w = size.width;
    final h = size.height;
    final step = w / density;
    for (var i = 0; i < density; i++) {
      final x = step * i;
      canvas.drawLine(Offset(x, 0), Offset(w - x * 0.25, h), linePaint);
    }
    for (var j = 0; j < density ~/ 2; j++) {
      final y = (h / (density ~/ 2)) * j;
      canvas.drawLine(Offset(0, y), Offset(w, h - y * 0.2), secPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FacetPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.density != density;
  }
}

class _IrisPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final Color shadow;

  _IrisPainter({
    required this.primary,
    required this.secondary,
    required this.shadow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.47;
    final pupil = size.width * 0.19;

    final base = Paint()
      ..shader = RadialGradient(
        colors: [
          shadow.withValues(alpha: 0.95),
          primary.withValues(alpha: 0.78),
          secondary.withValues(alpha: 0.76),
          AppColors.cardBackgroundStrong,
        ],
        stops: const [0.0, 0.42, 0.76, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, base);

    final rays = 240;
    for (var i = 0; i < rays; i++) {
      final t = i / rays;
      final angle = t * math.pi * 2;
      final inner = pupil + 1 + (math.sin(i * 0.91) + 1) * 4.0;
      final outer = r - (math.cos(i * 1.27) + 1) * 3.8;
      final p1 = Offset(
        c.dx + math.cos(angle) * inner,
        c.dy + math.sin(angle) * inner,
      );
      final p2 = Offset(
        c.dx + math.cos(angle) * outer,
        c.dy + math.sin(angle) * outer,
      );
      final rayPaint = Paint()
        ..strokeWidth = 1.05
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(
          primary,
          secondary,
          (math.sin(i * 0.33) + 1) / 2,
        )!.withValues(alpha: 0.58);
      canvas.drawLine(p1, p2, rayPaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.label.withValues(alpha: 0.5);
    canvas.drawCircle(c, r * 0.98, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _IrisPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.shadow != shadow;
  }
}

class _RankTierData {
  final String name;
  final List<String> requirements;

  const _RankTierData({required this.name, required this.requirements});

  List<Color> get ring {
    switch (RankArt.canonicalKey(name)) {
      case 'awakened':
        return const [Color(0xFFE9D5FF), Color(0xFF8B5CF6), Color(0xFF22D3EE)];
      case 'immortal':
        return const [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)];
      case 'diamond':
        return const [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF2563EB)];
      case 'platinum':
        return const [Color(0xFFE5E7EB), Color(0xFF94A3B8), Color(0xFF475569)];
      case 'gold':
        return const [Color(0xFFFEF3C7), Color(0xFFFACC15), Color(0xFFB45309)];
      case 'silver':
        return const [Color(0xFFF8FAFC), Color(0xFFCBD5E1), Color(0xFF64748B)];
      case 'bronze':
        return const [Color(0xFFFED7AA), Color(0xFFFB923C), Color(0xFF92400E)];
      case 'sleeping':
      default:
        return const [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF020617)];
    }
  }

  Color get glow => ring[1].withValues(alpha: 0.32);
}
