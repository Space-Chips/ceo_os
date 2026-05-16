import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  final UserRepository _repository = UserRepository();

  UserRank? _rank;
  WinStreak? _streak;
  int _daysInApp = 0;
  bool _loading = true;

  String _t(String key) => context.read<LanguageProvider>().t(key);

  static const List<_RankTierData> _tiers = [
    _RankTierData(
      name: 'CEO',
      requirements: ['500 day streak', '250h Focus', '250h CEO'],
      ring: [Color(0xFFFACC15), Color(0xFFFFFFFF), Color(0xFF111111)],
      glow: Color(0x66FACC15),
    ),
    _RankTierData(
      name: 'Batman',
      requirements: ['365 day streak', '200h Focus', '100h CEO'],
      ring: [Color(0xFF6B7280), Color(0xFF111827), Color(0xFF000000)],
      glow: Color(0x334B5563),
    ),
    _RankTierData(
      name: 'Diamond',
      requirements: ['180 day streak', '200h Focus'],
      ring: [Color(0xFF7DD3FC), Color(0xFF38BDF8), Color(0xFF0F172A)],
      glow: Color(0x3358C4FF),
    ),
    _RankTierData(
      name: 'Platinum',
      requirements: ['90 day streak', '60h Focus'],
      ring: [Color(0xFFE5E7EB), Color(0xFF9CA3AF), Color(0xFF0F172A)],
      glow: Color(0x33E5E7EB),
    ),
    _RankTierData(
      name: 'Gold',
      requirements: ['50 day streak'],
      ring: [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFF0F172A)],
      glow: Color(0x44FDE047),
    ),
    _RankTierData(
      name: 'Silver',
      requirements: ['15 days in app', '10 day streak'],
      ring: [Color(0xFFE5E7EB), Color(0xFF9CA3AF), Color(0xFF0F172A)],
      glow: Color(0x33E5E7EB),
    ),
    _RankTierData(
      name: 'Bronze',
      requirements: ['Starting rank'],
      ring: [Color(0xFFD4A574), Color(0xFFB87333), Color(0xFF0F172A)],
      glow: Color(0x44B87333),
    ),
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
    final createdAt = profile?.createdAt;
    final daysInApp = createdAt == null
        ? 0
        : DateTime.now().difference(createdAt).inDays + 1;

    if (!mounted) return;
    setState(() {
      _rank = rank;
      _streak = streak;
      _daysInApp = daysInApp;
      _loading = false;
    });
  }

  _RankTierData _currentTier() {
    final rankName = (_rank?.rankName ?? '').trim().toLowerCase();
    final byName = _tiers.where((tier) => tier.name.toLowerCase() == rankName);
    if (byName.isNotEmpty) return byName.first;

    final level = _rank?.rankLevel ?? 1;
    if (level >= 9) return _tiers[0];
    if (level == 8) return _tiers[1];
    if (level == 7) return _tiers[2];
    if (level == 6) return _tiers[3];
    if (level == 5) return _tiers[4];
    if (level == 4) return _tiers[5];
    return _tiers[6];
  }

  _RankTierData? _nextTier(_RankTierData current) {
    final idx = _tiers.indexWhere((tier) => tier.name == current.name);
    if (idx <= 0) return null;
    return _tiers[idx - 1];
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
    return _glowSurface(
      glowColor: tier.glow,
      borderRadius: 28,
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        borderRadius: 28,
        level: GlassCardLevel.elevated,
        showEdgeGlow: true,
        border: Border.all(
          color: tier.ring.first.withValues(alpha: 0.55),
          width: 0.8,
        ),
        gradientColors: [
          tier.ring[1].withValues(alpha: 0.14),
          AppColors.backgroundLight.withValues(alpha: 0.88),
        ],
        child: Column(
          children: [
            _tierBadge(tier, size: 120),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tier.name,
                  style: AppTypography.mono.copyWith(
                    fontSize: 74,
                    color: AppColors.label,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pathSection(_RankTierData current, _RankTierData? next) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      level: GlassCardLevel.standard,
      showEdgeGlow: true,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.74),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 20,
                color: const Color(0xFFFACC15),
              ),
              const SizedBox(width: 8),
              Text(
                next == null ? 'Top Rank Reached' : 'Path to ${next.name}',
                style: AppTypography.mono.copyWith(
                  fontSize: 22,
                  color: AppColors.label,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (next == null)
            Text(
              'You are currently at the highest tier.',
              style: AppTypography.mono.copyWith(
                fontSize: 15,
                color: AppColors.secondaryLabel,
              ),
            )
          else
            ...next.requirements.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.floatingGlassGradient.first.withValues(
                          alpha: 0.86,
                        ),
                        AppColors.floatingGlassGradient.last.withValues(
                          alpha: 0.76,
                        ),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.68),
                      width: 0.7,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.bolt,
                        size: 18,
                        color: const Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          req,
                          style: AppTypography.mono.copyWith(
                            fontSize: 15,
                            color: AppColors.secondaryLabel,
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

  Widget _statsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      level: GlassCardLevel.standard,
      showEdgeGlow: true,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.72),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR STATS',
            style: AppTypography.mono.copyWith(
              fontSize: 22,
              color: AppColors.label,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _statRow('Days in App', '$_daysInApp'),
          const SizedBox(height: 8),
          _statRow('Streak', '${_streak?.currentStreak ?? 0} days'),
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

  Widget _glowSurface({
    required Widget child,
    required Color glowColor,
    double borderRadius = 18,
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
          const Color(0xFF0B111D),
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
      ..color = const Color(0x88FFFFFF);
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
  final List<Color> ring;
  final Color glow;

  const _RankTierData({
    required this.name,
    required this.requirements,
    required this.ring,
    required this.glow,
  });
}
