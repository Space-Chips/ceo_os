import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// HIG-compliant card — no border in dark mode, color differentiation only.
class CeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool showAccentStrip;
  final Color? accentStripColor;

  const CeoCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
    this.showAccentStrip = false,
    this.accentStripColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.radiusMd; // 10pt (HIG)

    Widget card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface, // #1C1C1E
        borderRadius: BorderRadius.circular(radius),
        // No border in dark mode — HIG uses color differentiation
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Accent strip
            if (showAccentStrip)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: accentStripColor ?? AppColors.accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            // Content
            Padding(padding: padding ?? AppSpacing.paddingCard, child: child),
          ],
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
