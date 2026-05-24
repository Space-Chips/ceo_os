import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class LiquidButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final TextStyle? labelStyle;
  final bool fullWidth;
  final List<Color>? gradient;
  final double height;
  final double borderRadius;

  const LiquidButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.labelStyle,
    this.fullWidth = false,
    this.gradient,
    this.height = 52,
    this.borderRadius = 16,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool get _pressed => _controller.value > 0.01;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;
    final colors =
        widget.gradient ?? [AppColors.focusPrimary, AppColors.focusSecondary];
    final textStyle =
        widget.labelStyle ??
        AppTypography.callout.copyWith(fontWeight: FontWeight.w600);
    final radius = BorderRadius.circular(widget.borderRadius);

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _controller.forward(),
      onTapUp: disabled ? null : (_) => _controller.reverse(),
      onTapCancel: disabled ? null : () => _controller.reverse(),
      onTap: disabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: disabled ? 0.55 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: widget.fullWidth ? double.infinity : null,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow.withValues(alpha: 0.28),
                  blurRadius: _pressed ? 9 : 15,
                  offset: Offset(0, _pressed ? 3 : 8),
                  spreadRadius: -8,
                ),
                if (!disabled)
                  BoxShadow(
                    color: colors.first.withValues(
                      alpha: _pressed ? 0.16 : 0.24,
                    ),
                    blurRadius: _pressed ? 12 : 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -12,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppColors.isDark ? 8 : 4,
                  sigmaY: AppColors.isDark ? 8 : 4,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: disabled
                          ? [AppColors.cardBackgroundAlt, AppColors.surface]
                          : colors,
                    ),
                    borderRadius: radius,
                    border: Border.all(
                      color: disabled
                          ? AppColors.border
                          : AppColors.selectionOutline.withValues(alpha: 0.52),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 8,
                        right: 8,
                        child: IgnorePointer(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: AppColors.white.withValues(alpha: 0.24),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: widget.isLoading
                            ? CupertinoActivityIndicator(
                                color: AppColors.onAccent,
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(
                                      widget.icon,
                                      color: disabled
                                          ? AppColors.secondaryLabel
                                          : AppColors.onAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    widget.label,
                                    style: textStyle.copyWith(
                                      color: disabled
                                          ? AppColors.secondaryLabel
                                          : AppColors.onAccent,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
