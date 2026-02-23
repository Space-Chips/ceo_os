import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class FloatingNavBarItem {
  final IconData icon;
  final String label;

  const FloatingNavBarItem({
    required this.icon,
    required this.label,
  });
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
    return Positioned(
      bottom: 24, // Adjust distance from bottom
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nav Tabs Pill
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A).withOpacity(0.85), // Dark pill color matching mockup
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: AppColors.glassBorder.withOpacity(0.1), width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () => onItemSelected(index),
                        behavior: HitTestBehavior.opaque,
                        child: _NavBarTab(
                          item: item,
                          isSelected: isSelected,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Action Button Circle
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A).withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.glassBorder.withOpacity(0.1), width: 0.5),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onActionPressed,
                  child: Icon(
                    actionIcon,
                    color: AppColors.label,
                    size: 24,
                  ),
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

  const _NavBarTab({
    required this.item,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            color: isSelected ? AppColors.primaryOrange : const Color(0xFFB0B0B0), // Lighter grey for unselected
            size: 24,
          ),
          if (isSelected) ...[
             const SizedBox(height: 2),
             Text(
               item.label,
               style: AppTypography.caption2.copyWith(
                 color: AppColors.primaryOrange,
                 fontWeight: FontWeight.w600,
                 fontSize: 10,
               ),
             ),
          ]
        ],
      ),
    );
  }
}
