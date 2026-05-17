import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';

class FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingAddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.focusPrimary, AppColors.focusSecondary],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.2),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 8),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.plus,
            color: AppColors.onAccent,
            size: 26,
          ),
        ),
      ),
    );
  }
}
