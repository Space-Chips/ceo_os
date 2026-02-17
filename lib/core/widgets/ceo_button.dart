import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum CeoButtonVariant { primary, secondary, ghost, danger }

/// HIG-compliant button using CupertinoButton under the hood.
/// 44pt minimum touch target, press-down animation built-in.
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
    final isDisabled = onPressed == null || isLoading;

    Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const CupertinoActivityIndicator(radius: 9),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: _foregroundColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTypography.headline.copyWith(
            color: _foregroundColor,
            fontSize: 15,
          ),
        ),
      ],
    );

    Widget button;
    switch (variant) {
      case CeoButtonVariant.primary:
        button = CupertinoButton.filled(
          onPressed: isDisabled ? null : onPressed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: content,
        );
      case CeoButtonVariant.danger:
        button = CupertinoButton(
          onPressed: isDisabled ? null : onPressed,
          color: AppColors.systemRed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: content,
        );
      case CeoButtonVariant.secondary:
        button = CupertinoButton(
          onPressed: isDisabled ? null : onPressed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          color: AppColors.tertiarySystemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: content,
        );
      case CeoButtonVariant.ghost:
        button = CupertinoButton(
          onPressed: isDisabled ? null : onPressed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: content,
        );
    }

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color get _foregroundColor {
    switch (variant) {
      case CeoButtonVariant.primary:
      case CeoButtonVariant.danger:
        return CupertinoColors.white;
      case CeoButtonVariant.secondary:
        return AppColors.label;
      case CeoButtonVariant.ghost:
        return AppColors.systemBlue;
    }
  }
}
