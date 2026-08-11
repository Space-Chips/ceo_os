import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';

/// Calm matte backdrop shared by all major screens.
class AmbientBackdrop extends StatelessWidget {
  final Widget child;

  const AmbientBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.backdropGradient,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -0.6),
                end: const Alignment(1, 1),
                colors: [
                  AppColors.accentSoft.withValues(alpha: AppColors.isDark ? 0.09 : 0.05),
                  CupertinoColors.transparent,
                  AppColors.backgroundElevated.withValues(
                    alpha: AppColors.isDark ? 0.22 : 0.08,
                  ),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: -170,
          right: -140,
          child: _SoftAura(
            size: 320,
            color: AppColors.accent.withValues(alpha: AppColors.isDark ? 0.1 : 0.08),
          ),
        ),
        Positioned(
          bottom: -190,
          left: -120,
          child: _SoftAura(
            size: 280,
            color: AppColors.chartB.withValues(alpha: AppColors.isDark ? 0.08 : 0.05),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BackdropNoisePainter(
                strength: AppColors.isDark ? 0.013 : 0.005,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withValues(alpha: AppColors.isDark ? 0.18 : 0.03),
                    CupertinoColors.transparent,
                    AppColors.black.withValues(alpha: AppColors.isDark ? 0.36 : 0.08),
                  ],
                  stops: const [0, 0.44, 1],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SoftAura extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftAura({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 120,
              spreadRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropNoisePainter extends CustomPainter {
  final double strength;

  const _BackdropNoisePainter({required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..style = PaintingStyle.fill;
    final darkPaint = Paint()..style = PaintingStyle.fill;

    var seed =
        (size.width.floor() * 73856093) ^
        (size.height.floor() * 19349663) ^
        0x9E3779B9;

    double next() {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      return seed / 0xFFFFFFFF;
    }

    const step = 6.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final n = next();
        if (n < 0.1) {
          final alpha = strength * (0.3 + next() * 0.7);
          lightPaint.color = AppColors.white.withValues(alpha: alpha);
          canvas.drawRect(Rect.fromLTWH(x, y, 1.1, 1.1), lightPaint);
        } else if (n > 0.9) {
          final alpha = strength * (0.25 + next() * 0.65);
          darkPaint.color = AppColors.black.withValues(alpha: alpha);
          canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), darkPaint);
        }
      }
    }

    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.white.withValues(alpha: strength * 0.6);
    final lines = math.max(10, (size.height / 120).round());
    for (var i = 0; i < lines; i++) {
      final y = (i + 1) * size.height / (lines + 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropNoisePainter oldDelegate) {
    return oldDelegate.strength != strength;
  }
}
