import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular progress ring with gradient stroke.
class CeoProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final List<Color>? gradientColors;
  final Widget? child;

  const CeoProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 6,
    this.color,
    this.trackColor,
    this.gradientColors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              color: color ?? AppColors.accent,
              trackColor: trackColor ?? AppColors.surfaceLight,
              gradientColors: gradientColors ?? AppColors.accentGradient,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final List<Color> gradientColors;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc with gradient
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;
      final gradient = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi,
        colors: gradientColors,
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);

      // Glow effect at the tip
      if (progress > 0.01) {
        final tipAngle = -pi / 2 + sweepAngle;
        final tipX = center.dx + radius * cos(tipAngle);
        final tipY = center.dy + radius * sin(tipAngle);
        final glowPaint = Paint()
          ..color = gradientColors.last.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(
          Offset(tipX, tipY),
          strokeWidth / 2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}
