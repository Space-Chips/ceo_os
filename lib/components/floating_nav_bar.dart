import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class FloatingNavBarItem {
  final IconData icon;
  final String label;

  const FloatingNavBarItem({required this.icon, required this.label});
}

class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final IconData actionIcon;
  final VoidCallback onActionPressed;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.actionIcon,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);

    return Positioned(
      bottom: 14,
      left: 14,
      right: 14,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.floatingGlassGradient,
                    ),
                    borderRadius: radius,
                    border: Border.all(color: AppColors.border, width: 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.glassShadow.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () => onItemSelected(index),
                        behavior: HitTestBehavior.opaque,
                        child: _NavBarTab(item: item, isSelected: isSelected),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.floatingGlassGradient),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.9),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onActionPressed,
                  child: Icon(actionIcon, color: AppColors.label, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarTab extends StatelessWidget {
  final FloatingNavBarItem item;
  final bool isSelected;

  const _NavBarTab({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? AppColors.accentSoft.withValues(alpha: 0.18) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: isSelected ? AppColors.accent : AppColors.secondaryLabel,
            size: 20,
          ),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Text(
              item.label,
              style: AppTypography.caption1.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
