import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum GlassCardLevel { subtle, standard, elevated }

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final List<Color>? gradientColors;
  final Border? border;
  final double? width;
  final double? height;
  final bool textured;
  final GlassCardLevel level;
  final bool showEdgeGlow;
  final bool showTopHighlight;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 28,
    this.blur = 30,
    this.gradientColors,
    this.border,
    this.width,
    this.height,
    this.textured = true,
    this.level = GlassCardLevel.standard,
    this.showEdgeGlow = false,
    this.showTopHighlight = true,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final shadowStrength = switch (level) {
      GlassCardLevel.subtle => 0.6,
      GlassCardLevel.standard => 1.0,
      GlassCardLevel.elevated => 1.35,
    };
    final effectiveGlow = (glowColor ?? AppColors.edgeGlow).withValues(
      alpha: showEdgeGlow
          ? (AppColors.isDark ? 0.26 : 0.16)
          : (AppColors.isDark ? 0.07 : 0.045),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(
              alpha: 0.46 * shadowStrength,
            ),
            blurRadius: 36 * shadowStrength,
            offset: Offset(0, 16 * shadowStrength),
            spreadRadius: -12,
          ),
          BoxShadow(
            color: effectiveGlow,
            blurRadius: 48 * shadowStrength,
            offset: const Offset(0, 8),
            spreadRadius: -18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            children: [
              Container(
                padding: padding ?? const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border:
                      border ??
                      Border.all(color: AppColors.glassBorder, width: 0.7),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        gradientColors ??
                        [
                          AppColors.floatingGlassGradient.first,
                          AppColors.floatingGlassGradient.last,
                        ],
                  ),
                ),
                child: child,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: RadialGradient(
                        center: const Alignment(-0.65, -0.95),
                        radius: 1.08,
                        colors: [
                          AppColors.glassHighlight.withValues(alpha: 0.24),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.glassHighlightSoft.withValues(alpha: 0.17),
                          Colors.transparent,
                          AppColors.glassShadowSoft.withValues(alpha: 0.2),
                        ],
                        stops: const [0, 0.35, 1],
                      ),
                    ),
                  ),
                ),
              ),
              if (textured)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _NoiseTexturePainter(strength: 0.028),
                    ),
                  ),
                ),
              Positioned(
                left: 2,
                right: 2,
                top: 2,
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.glassHighlight.withValues(alpha: 0.32),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoiseTexturePainter extends CustomPainter {
  final double strength;

  const _NoiseTexturePainter({required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..style = PaintingStyle.fill;
    final darkPaint = Paint()..style = PaintingStyle.fill;

    var seed =
        (size.width.floor() * 73856093) ^
        (size.height.floor() * 19349663) ^
        0x9E3779B9;

    double next() {
      seed = (1664525 * seed + 1013904223) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    final points = math.max(40, (size.width * size.height / 1200).round());
    for (var i = 0; i < points; i++) {
      final x = next() * size.width;
      final y = next() * size.height;
      final w = 0.7 + (next() * 1.1);
      final h = 0.7 + (next() * 1.1);
      whitePaint.color = AppColors.glassHighlightSoft.withValues(
        alpha: 0.003 + (next() * strength),
      );
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), whitePaint);
    }

    final darkPoints = math.max(20, points ~/ 2);
    for (var i = 0; i < darkPoints; i++) {
      final x = next() * size.width;
      final y = next() * size.height;
      final w = 0.6 + (next() * 0.8);
      final h = 0.6 + (next() * 0.8);
      darkPaint.color = AppColors.glassShadowSoft.withValues(
        alpha: 0.003 + (next() * strength * 0.7),
      );
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), darkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoiseTexturePainter oldDelegate) {
    return oldDelegate.strength != strength;
  }
}
