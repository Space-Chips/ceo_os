import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// HIG-compliant card — grouped table view cell style.
/// Background: secondarySystemBackground, 10pt corner radius, subtle separator border.
class CeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool showAccentStrip;
  final Color? accentStripColor;
  final double? borderRadius;

  const CeoCard({
    super.key,
    this.borderRadius,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.showAccentStrip = false,
    this.accentStripColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.radiusGrouped;

    Widget card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            if (showAccentStrip)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: accentStripColor ?? AppColors.systemBlue,
                ),
              ),
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
