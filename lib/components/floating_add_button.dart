import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
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
          color: AppColors.primaryOrange,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Icon(
          CupertinoIcons.plus,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
