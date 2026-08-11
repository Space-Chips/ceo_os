import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class GlassInputField extends StatelessWidget {
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final bool autofocus;
  final int? maxLines;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final TextStyle? textStyle;
  final TextStyle? placeholderStyle;

  const GlassInputField({
    super.key,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.autofocus = false,
    this.maxLines = 1,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autofillHints,
    this.contentPadding,
    this.borderRadius = 16,
    this.textStyle,
    this.placeholderStyle,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.isDark ? 10 : 5,
          sigmaY: AppColors.isDark ? 10 : 5,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.inputGlassGradient,
            ),
            borderRadius: radius,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.88),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -10,
              ),
            ],
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
                      color: AppColors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
              CupertinoTextField(
                controller: controller,
                onChanged: onChanged,
                obscureText: obscureText,
                keyboardType: keyboardType,
                autofocus: autofocus,
                maxLines: maxLines,
                autocorrect: autocorrect,
                textCapitalization: textCapitalization,
                textInputAction: textInputAction,
                autofillHints: autofillHints,
                placeholder: placeholder,
                placeholderStyle: AppTypography.callout.copyWith(
                  color: AppColors.tertiaryLabel,
                ),
                style: AppTypography.callout.copyWith(color: AppColors.label),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: null,
                prefix: prefix != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: prefix,
                      )
                    : null,
                suffix: suffix != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: suffix,
                      )
                    : null,
                cursorColor: AppColors.accent,
                cursorWidth: 1.4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
