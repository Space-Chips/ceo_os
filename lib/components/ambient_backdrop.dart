import 'dart:math' as math;


import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';

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
                colors: [
                  AppColors.background,
                  AppColors.backgroundLight.withValues(alpha: 0.92),
                  AppColors.background.withValues(alpha: 0.98),
                ],
              ),
            ),
          ),
        ),
        const _AmbientBlob(
          top: -120,
          left: -80,
          size: 260,
          tone: _BlobTone.primary,
          opacity: 0.18,
        ),
        const _AmbientBlob(
          top: 120,
          right: -110,
          size: 290,
          tone: _BlobTone.secondary,
          opacity: 0.14,
        ),
        const _AmbientBlob(
          bottom: -140,
          left: 40,
          size: 320,
          tone: _BlobTone.primary,
          opacity: 0.1,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BackdropNoisePainter(strength: 0.018),
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
                    CupertinoColors.black.withValues(alpha: 0.06),
                    CupertinoColors.transparent,
                    CupertinoColors.black.withValues(alpha: 0.12),
                  ],
                  stops: const [0, 0.4, 1],
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
      seed = (1664525 * seed + 1013904223) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    final points = math.max(120, (size.width * size.height / 900).round());
    for (var i = 0; i < points; i++) {
      final x = next() * size.width;
      final y = next() * size.height;
      final w = 0.5 + (next() * 0.9);
      final h = 0.5 + (next() * 0.9);
      lightPaint.color = CupertinoColors.white.withValues(
        alpha: 0.002 + (next() * strength),
      );
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), lightPaint);
    }

    final darkPoints = math.max(80, points ~/ 2);
    for (var i = 0; i < darkPoints; i++) {
      final x = next() * size.width;
      final y = next() * size.height;
      final w = 0.5 + (next() * 0.8);
      final h = 0.5 + (next() * 0.8);
      darkPaint.color = CupertinoColors.black.withValues(
        alpha: 0.0015 + (next() * strength * 0.8),
      );
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), darkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropNoisePainter oldDelegate) {
    return oldDelegate.strength != strength;
  }
}

enum _BlobTone { primary, secondary }

class _AmbientBlob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final _BlobTone tone;
  final double opacity;

  const _AmbientBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.tone,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone == _BlobTone.primary
        ? AppColors.primaryOrange
        : AppColors.accentSecondary;
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: opacity),
                blurRadius: 120,
                spreadRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
