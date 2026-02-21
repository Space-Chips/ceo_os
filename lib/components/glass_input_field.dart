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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: CupertinoTextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofocus: autofocus,
        maxLines: maxLines,
        placeholder: placeholder,
        placeholderStyle: AppTypography.body.copyWith(
          color: AppColors.quaternaryLabel,
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
        cursorWidth: 1.5,
      ),
    );
  }
}
