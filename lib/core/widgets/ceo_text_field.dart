import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// HIG-compliant text field using CupertinoTextField.
class CeoTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool autofocus;

  const CeoTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.footnote.copyWith(
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: autofocus,
          onChanged: onChanged,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.tertiarySystemBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          style: AppTypography.body,
          placeholderStyle: AppTypography.body.copyWith(
            color: AppColors.tertiaryLabel,
          ),
          cursorColor: AppColors.systemBlue,
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: prefixIcon,
                )
              : null,
          suffix: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
        ),
      ],
    );
  }
}
