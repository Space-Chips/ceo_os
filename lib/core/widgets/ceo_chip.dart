import 'package:flutter/cupertino.dart';
import '../../components/components.dart';
import '../theme/app_colors.dart';

class CeoChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;

  const CeoChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.electricCyan;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        blur: 10,
        border: Border.all(
          color: isSelected ? chipColor : AppColors.glassBorder,
          width: isSelected ? 1.5 : 0.5,
        ),
        gradientColors: isSelected
            ? [chipColor.withOpacity(0.2), chipColor.withOpacity(0.05)]
            : [AppColors.glassBase, AppColors.glassBase],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? chipColor : AppColors.secondaryLabel,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? chipColor : AppColors.label,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
