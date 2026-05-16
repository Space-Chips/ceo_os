import 'package:flutter/cupertino.dart';
import '../core/theme/app_colors.dart';

class FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const FloatingAddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryOrange, AppColors.accentSecondary],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.glassHighlight.withValues(alpha: 0.34),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.plus,
          color: AppColors.onAccent,
          size: 32,
        ),
      ),
    );
  }
}
