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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.focusPrimary, AppColors.focusSecondary],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Center(
          child: Icon(CupertinoIcons.plus, color: AppColors.onAccent, size: 25),
        ),
      ),
    );
  }
}
