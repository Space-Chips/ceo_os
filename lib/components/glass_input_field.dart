import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

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
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.isDark ? 12 : 8,
          sigmaY: AppColors.isDark ? 12 : 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.inputGlassGradient,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder, width: 0.76),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassHighlightSoft.withValues(
                  alpha: AppColors.isDark ? 0.08 : 0.05,
                ),
                blurRadius: 12,
                offset: const Offset(0, -3),
                spreadRadius: -10,
              ),
              BoxShadow(
                color: AppColors.glassShadow.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 9),
                spreadRadius: -9,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: const Alignment(-0.9, -1),
                        end: const Alignment(1, 1),
                        colors: [
                          AppColors.glassHighlight.withValues(alpha: 0.13),
                          Colors.transparent,
                          AppColors.glassShadowSoft.withValues(alpha: 0.12),
                        ],
                        stops: const [0, 0.48, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 1,
                left: 8,
                right: 8,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.glassHighlight.withValues(alpha: 0.38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 1.4,
                right: 1.4,
                bottom: 1.4,
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.glassShadowSoft.withValues(alpha: 0.32),
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
                placeholderStyle: AppTypography.body.copyWith(
                  color: AppColors.tertiaryLabel.withValues(alpha: 0.92),
                ),
                style: AppTypography.body.copyWith(color: AppColors.label),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: null,
                prefix: prefix != null
                    ? Padding(padding: const EdgeInsets.only(left: 18), child: prefix)
                    : null,
                suffix: suffix != null
                    ? Padding(padding: const EdgeInsets.only(right: 18), child: suffix)
                    : null,
                cursorColor: AppColors.primaryOrange,
                cursorWidth: 1.6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
