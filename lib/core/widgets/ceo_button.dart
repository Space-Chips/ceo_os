import 'package:flutter/cupertino.dart';
import '../../components/components.dart';
import '../theme/app_colors.dart';

enum CeoButtonVariant { primary, secondary, ghost, danger }

class CeoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CeoButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const CeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CeoButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Color>? gradient;
    if (variant == CeoButtonVariant.danger) {
      gradient = [AppColors.error, AppColors.error];
    } else if (variant == CeoButtonVariant.secondary) {
      gradient = [AppColors.glassBase, AppColors.glassBase];
    } else if (variant == CeoButtonVariant.ghost) {
      // For ghost buttons, we might want a different implementation,
      // but for consistency we use LiquidButton with clear gradient if needed
      return CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        child: Text(label, style: TextStyle(color: AppColors.electricCyan)),
      );
    }

    return LiquidButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      fullWidth: expand,
      gradient: gradient,
    );
  }
}
