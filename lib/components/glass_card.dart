import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Premium low-noise surface card.
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
  final Color? glowColor;
  final bool showTopHighlight;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 22,
    this.blur = 16,
    this.gradientColors,
    this.border,
    this.width,
    this.height,
    this.textured = false,
    this.level = GlassCardLevel.standard,
    this.showEdgeGlow = false,
    this.glowColor,
    this.showTopHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseGradient =
        gradientColors ?? [AppColors.cardBackgroundAlt, AppColors.cardBase];
    final shadowSpec = switch (level) {
      GlassCardLevel.subtle => (
        alpha: AppColors.isDark ? 0.12 : 0.08,
        blur: 12.0,
        offsetY: 6.0,
        spread: -8.0,
      ),
      GlassCardLevel.standard => (
        alpha: AppColors.isDark ? 0.2 : 0.11,
        blur: 16.0,
        offsetY: 7.0,
        spread: -10.0,
      ),
      GlassCardLevel.elevated => (
        alpha: AppColors.isDark ? 0.26 : 0.14,
        blur: 20.0,
        offsetY: 9.0,
        spread: -12.0,
      ),
    };

    final edgeColor = (glowColor ?? AppColors.themeGlow).withValues(
      alpha: showEdgeGlow ? (AppColors.isDark ? 0.16 : 0.1) : 0,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: shadowSpec.alpha),
            blurRadius: shadowSpec.blur,
            offset: Offset(0, shadowSpec.offsetY),
            spreadRadius: shadowSpec.spread,
          ),
          if (showEdgeGlow)
            BoxShadow(
              color: edgeColor,
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -14,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(color: AppColors.border, width: 0.9),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    AppColors.ambientTint.withValues(
                      alpha: AppColors.isDark ? 0.09 : 0.04,
                    ),
                    baseGradient.first,
                  ),
                  Color.alphaBlend(
                    AppColors.glassHighlightSoft.withValues(
                      alpha: AppColors.isDark ? 0.07 : 0.03,
                    ),
                    baseGradient.last,
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                if (showTopHighlight)
                  Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    child: IgnorePointer(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.glassHighlight.withValues(
                            alpha: 0.34,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (textured)
                  const Positioned.fill(
                    child: IgnorePointer(child: _SubtleGrain()),
                  ),
                Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtleGrain extends StatelessWidget {
  const _SubtleGrain();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.softLight,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.label.withValues(alpha: AppColors.isDark ? 0.07 : 0.04),
            AppColors.label.withValues(alpha: 0),
            AppColors.overlayScrim.withValues(
              alpha: AppColors.isDark ? 0.08 : 0.04,
            ),
          ],
          stops: [0, 0.5, 1],
        ).createShader(bounds);
      },
      child: Container(color: Colors.white),
    );
  }
}
