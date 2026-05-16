import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';

/// Opaque premium surface card.
///
/// This intentionally avoids BackdropFilter/Glass materials because some iOS
/// compositor paths can wash out colors and make theme surfaces appear white.
class PremiumSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const PremiumSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.isDark
        ? AppColors.cardBackgroundAlt
        : AppColors.cardBackgroundAlt;
    final surface2 =
        AppColors.isDark ? AppColors.cardBackgroundStrong : AppColors.cardBase;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surface, surface2],
        ),
        border: Border.all(color: AppColors.borderStrong, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(
              alpha: AppColors.isDark ? 0.24 : 0.12,
            ),
            blurRadius: 18,
            offset: const Offset(0, 9),
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
