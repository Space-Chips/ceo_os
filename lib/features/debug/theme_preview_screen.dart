import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_catalog.dart';

class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      onPressed: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.topBarControlBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.topBarControlBorder,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          size: 18,
                          color: AppColors.label,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Preview',
                            style: AppTypography.title1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.label,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Validate the 5-theme product language across real app surfaces.',
                            style: AppTypography.callout.copyWith(
                              fontSize: 13,
                              color: AppColors.secondaryLabel,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    _ThemeSelectorStrip(
                      currentId: themeProvider.currentPreset.id,
                      presets: themeProvider.presets,
                      onSelect: (presetId) =>
                          themeProvider.previewTheme(presetId),
                    ),
                    const SizedBox(height: 18),
                    _PreviewHero(),
                    const SizedBox(height: 18),
                    _PreviewButtonsAndControls(),
                    const SizedBox(height: 18),
                    _PreviewTextAndStates(),
                    const SizedBox(height: 18),
                    _PreviewSurfaces(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelectorStrip extends StatelessWidget {
  final String currentId;
  final List<AppThemePreset> presets;
  final ValueChanged<String> onSelect;

  const _ThemeSelectorStrip({
    required this.currentId,
    required this.presets,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      gradientColors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THEME SWITCHER',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 2,
              color: AppColors.secondaryLabel.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = presets[index];
                final selected = preset.id == currentId;
                return GestureDetector(
                  onTap: () => onSelect(preset.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected
                          ? AppColors.accentSurfaceSoft
                          : AppColors.topBarControlBackground,
                      border: Border.all(
                        color: selected
                            ? AppColors.selectionOutline
                            : AppColors.topBarControlBorder,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        preset.name,
                        style: AppTypography.callout.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.label
                              : AppColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewTopBar(),
        const SizedBox(height: 24),
        _PreviewDashboardCard(),
        const SizedBox(height: 18),
        _PreviewModuleGrid(),
      ],
    );
  }
}

class _PreviewTopBar extends StatelessWidget {
  const _PreviewTopBar();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      gradientColors: [AppColors.sectionBackground, AppColors.background],
      child: Row(
        children: [
          _CircleControl(
            child: Icon(
              CupertinoIcons.person_fill,
              size: 16,
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.accentSurfaceSoft,
                border: Border.all(color: AppColors.activeBorder, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.rankAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'STARTER',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.callout.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SquareControl(icon: CupertinoIcons.bolt_fill),
                  const SizedBox(width: 8),
                  _SquareControl(icon: CupertinoIcons.doc_text_fill),
                  const SizedBox(width: 8),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.topBarControlBackground,
                      border: Border.all(
                        color: AppColors.topBarControlBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.flame_fill,
                          size: 14,
                          color: AppColors.rankAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '7',
                          style: AppTypography.callout.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDashboardCard extends StatelessWidget {
  const _PreviewDashboardCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      level: GlassCardLevel.elevated,
      gradientColors: [
        AppColors.dashboardGradientStart,
        AppColors.dashboardGradientEnd,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: AppTypography.title1.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  'WAKE SCORE',
                  style: AppTypography.overline.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '84',
                  style: AppTypography.timer.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppColors.scoreValue,
                    shadows: [
                      Shadow(
                        color: AppColors.themeGlow.withValues(alpha: 0.12),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _MetricColumn(label: 'Tasks', value: '5')),
              Expanded(child: _MetricColumn(label: 'Habits', value: '2')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewModuleGrid extends StatelessWidget {
  const _PreviewModuleGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModulePreviewCard(
            title: 'To-Do',
            icon: CupertinoIcons.check_mark_circled,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _ModulePreviewCard(
            title: 'Screen Time',
            icon: CupertinoIcons.shield,
          ),
        ),
      ],
    );
  }
}

class _PreviewButtonsAndControls extends StatelessWidget {
  const _PreviewButtonsAndControls();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      gradientColors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTERACTION LAYER',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 2,
              color: AppColors.secondaryLabel.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LiquidButton(
                  label: 'PRIMARY ACTION',
                  onPressed: () {},
                  fullWidth: true,
                  height: 50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.topBarControlBackground,
                    border: Border.all(
                      color: AppColors.topBarControlBorder,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'SECONDARY',
                    style: AppTypography.callout.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.label,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TogglePreview(enabled: true)),
              const SizedBox(width: 12),
              Expanded(child: _TogglePreview(enabled: false)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.cardBackgroundAlt,
              border: Border.all(color: AppColors.borderStrong, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: AppColors.tertiaryLabel,
                ),
                const SizedBox(width: 10),
                Text(
                  'Input field preview',
                  style: AppTypography.callout.copyWith(
                    fontSize: 15,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ProgressPreview()),
              SizedBox(width: 12),
              Expanded(child: _FocusRingPreview()),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewTextAndStates extends StatefulWidget {
  @override
  State<_PreviewTextAndStates> createState() => _PreviewTextAndStatesState();
}

class _PreviewTextAndStatesState extends State<_PreviewTextAndStates> {
  bool _selected = true;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      gradientColors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEXT + STATES',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 2,
              color: AppColors.secondaryLabel.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Primary text hierarchy',
            style: AppTypography.title3.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Secondary text supports reading rhythm and product context.',
            style: AppTypography.callout.copyWith(
              fontSize: 14,
              color: AppColors.secondaryLabel,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tertiary metadata stays visible without adding noise.',
            style: AppTypography.footnote.copyWith(
              fontSize: 13,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = !_selected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _selected
                          ? AppColors.accentSurfaceSoft
                          : AppColors.cardBackgroundAlt,
                      border: Border.all(
                        color: _selected
                            ? AppColors.selectionOutline
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _selected ? 'Selected state' : 'Unselected state',
                      style: AppTypography.callout.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.label,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      color: AppColors.borderStrong,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Card border / divider',
                      style: AppTypography.caption1.copyWith(
                        fontSize: 11,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewSurfaces extends StatelessWidget {
  const _PreviewSurfaces();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      gradientColors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SURFACE STACK',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 2,
              color: AppColors.secondaryLabel.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SurfaceSwatch(
                  label: 'App Background',
                  color: AppColors.background,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SurfaceSwatch(
                  label: 'Section',
                  color: AppColors.sectionBackground,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SurfaceSwatch(
                  label: 'Card',
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption1.copyWith(
            fontSize: 11,
            color: AppColors.secondaryLabel.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.callout.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.label,
          ),
        ),
      ],
    );
  }
}

class _ModulePreviewCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ModulePreviewCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(14),
      gradientColors: [AppColors.cardRaised, AppColors.cardBase],
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.moduleIconBackground,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppColors.accentIcon,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.title3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TogglePreview extends StatelessWidget {
  final bool enabled;

  const _TogglePreview({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBackgroundAlt,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              enabled ? 'Toggle ON' : 'Toggle OFF',
              style: AppTypography.callout.copyWith(
                fontSize: 14,
                color: AppColors.label,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 24,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: enabled
                  ? AppColors.toggleOn
                  : CupertinoColors.white.withValues(alpha: 0.15),
            ),
            child: Align(
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPreview extends StatelessWidget {
  const _ProgressPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBackgroundAlt,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress bar',
            style: AppTypography.caption1.copyWith(
              fontSize: 11,
              color: AppColors.secondaryLabel,
            ),
          ),
          const Spacer(),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: CupertinoColors.white.withValues(alpha: 0.08),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.68,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.focusPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusRingPreview extends StatelessWidget {
  const _FocusRingPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBackgroundAlt,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(
              painter: _MiniRingPainter(
                progress: 0.72,
                color: AppColors.focusPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Focus ring',
              style: AppTypography.callout.copyWith(
                fontSize: 14,
                color: AppColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceSwatch extends StatelessWidget {
  final String label;
  final Color color;

  const _SurfaceSwatch({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color,
            border: Border.all(color: AppColors.borderStrong, width: 1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.caption1.copyWith(
            fontSize: 11,
            color: AppColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}

class _CircleControl extends StatelessWidget {
  final Widget child;

  const _CircleControl({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.topBarControlBackground,
        border: Border.all(color: AppColors.topBarControlBorder, width: 1),
      ),
      child: Center(child: child),
    );
  }
}

class _SquareControl extends StatelessWidget {
  final IconData icon;

  const _SquareControl({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.topBarControlBackground,
        border: Border.all(color: AppColors.topBarControlBorder, width: 1),
      ),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.accentIcon,
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _MiniRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
