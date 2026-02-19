import 'package:flutter/cupertino.dart';
import '../../components/components.dart';
import '../theme/app_colors.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: borderRadius ?? 24,
        padding: padding,
        gradientColors: color != null ? [color!, color!] : null,
        border: showAccentStrip
            ? Border(
                left: BorderSide(
                  color: accentStripColor ?? AppColors.electricCyan,
                  width: 4,
                ),
                top: BorderSide(color: AppColors.glassBorder, width: 0.5),
                right: BorderSide(color: AppColors.glassBorder, width: 0.5),
                bottom: BorderSide(color: AppColors.glassBorder, width: 0.5),
              )
            : null,
        child: child,
      ),
    );
  }
}
