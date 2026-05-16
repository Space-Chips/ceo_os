import 'dart:ui';
import 'package:flutter/cupertino.dart';
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
    final radius = BorderRadius.circular(30);
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.floatingGlassGradient,
                    ),
                    borderRadius: radius,
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.85),
                      width: 0.65,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.glassShadow.withValues(alpha: 0.26),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: -10,
                      ),
                    ],
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
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.floatingGlassGradient.first,
                      AppColors.floatingGlassGradient.last,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.glassBorder.withValues(alpha: 0.85),
                    width: 0.65,
                  ),
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
            color: isSelected ? AppColors.primaryOrange : AppColors.secondaryLabel,
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
