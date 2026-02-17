import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum CeoButtonVariant { primary, secondary, ghost, danger }

/// Premium button with press animation and icon support.
class CeoButton extends StatefulWidget {
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
  State<CeoButton> createState() => _CeoButtonState();
}

class _CeoButtonState extends State<CeoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.variant) {
      case CeoButtonVariant.primary:
        return AppColors.accent;
      case CeoButtonVariant.secondary:
        return AppColors.surfaceLight;
      case CeoButtonVariant.ghost:
        return Colors.transparent;
      case CeoButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color get _foregroundColor {
    switch (widget.variant) {
      case CeoButtonVariant.primary:
      case CeoButtonVariant.danger:
        return Colors.white;
      case CeoButtonVariant.secondary:
        return AppColors.textPrimary;
      case CeoButtonVariant.ghost:
        return AppColors.accent;
    }
  }

  BorderSide get _border {
    switch (widget.variant) {
      case CeoButtonVariant.secondary:
        return const BorderSide(color: AppColors.border);
      case CeoButtonVariant.ghost:
        return BorderSide.none;
      default:
        return BorderSide.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _controller.forward(),
        onTapUp: isDisabled
            ? null
            : (_) {
                _controller.reverse();
                widget.onPressed?.call();
              },
        onTapCancel: isDisabled ? null : () => _controller.reverse(),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.fromBorderSide(_border),
            ),
            child: Row(
              mainAxisSize:
                  widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _foregroundColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: _foregroundColor),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  widget.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: _foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
