import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────
// Platform detection helper
// ─────────────────────────────────────────────────────────────────────

bool get isApplePlatform {
  try {
    return Platform.isIOS || Platform.isMacOS;
  } catch (_) {
    return false; // web fallback
  }
}

// ─────────────────────────────────────────────────────────────────────
// AdaptiveNavBar
// ─────────────────────────────────────────────────────────────────────

class AdaptiveNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool largeTitle;

  const AdaptiveNavBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.largeTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoNavigationBar(
        middle: largeTitle ? null : Text(title),
        leading: leading,
        trailing: trailing,
        backgroundColor: CupertinoColors.systemBackground.darkColor.withValues(
          alpha: 0.85,
        ),
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      );
    }

    return AppBar(
      title: Text(title, style: AppTypography.headingSmall),
      leading: leading,
      actions: trailing != null ? [trailing!] : null,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// AdaptiveButton
// ─────────────────────────────────────────────────────────────────────

class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;
  final bool expand;

  const AdaptiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.filled = true,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      final button = filled
          ? CupertinoButton.filled(
              onPressed: onPressed,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              child: _content(Colors.white),
            )
          : CupertinoButton(
              onPressed: onPressed,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              child: _content(AppColors.accent),
            );
      return expand ? SizedBox(width: double.infinity, child: button) : button;
    }

    // Android: custom styled button
    final button = GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onPressed == null ? 0.5 : 1.0,
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: filled ? null : Border.all(color: AppColors.border),
          ),
          child: _content(filled ? Colors.white : AppColors.accent),
        ),
      ),
    );
    return button;
  }

  Widget _content(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// AdaptiveTextField
// ─────────────────────────────────────────────────────────────────────

class AdaptiveTextField extends StatelessWidget {
  final String? placeholder;
  final String? label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;

  const AdaptiveTextField({
    super.key,
    this.placeholder,
    this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            keyboardType: keyboardType,
            prefix: prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: prefix,
                  )
                : null,
            onChanged: onChanged,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight, // tertiarySystemBackground
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd), // 10pt
            ),
            style: AppTypography.bodyLarge, // 17pt Body
            placeholderStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      );
    }

    // Android Material field
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTypography.bodyLarge, // 17pt Body
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: prefix,
            filled: true,
            fillColor: AppColors.surfaceLight, // tertiarySystemBackground
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd), // 10pt
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// AdaptiveSwitch
// ─────────────────────────────────────────────────────────────────────

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.accent,
      );
    }

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.accent,
      activeTrackColor: AppColors.accentMuted,
      inactiveTrackColor: AppColors.surfaceLight,
      inactiveThumbColor: AppColors.textTertiary,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// AdaptiveSlider
// ─────────────────────────────────────────────────────────────────────

class AdaptiveSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  const AdaptiveSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        activeColor: AppColors.accent,
      );
    }

    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// AdaptiveCheckbox
// ─────────────────────────────────────────────────────────────────────

class AdaptiveCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AdaptiveCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.accent;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: isApplePlatform ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isApplePlatform ? BorderRadius.circular(6) : null,
          color: value ? color : Colors.transparent,
          border: Border.all(
            color: value ? color : AppColors.textTertiary,
            width: 2,
          ),
        ),
        child: value
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// AdaptiveTabBar (Bottom Navigation)
// ─────────────────────────────────────────────────────────────────────

class AdaptiveTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdaptiveTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.checkmark_circle),
      activeIcon: Icon(CupertinoIcons.checkmark_circle_fill),
      label: 'Tasks',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.flame),
      activeIcon: Icon(CupertinoIcons.flame_fill),
      label: 'Habits',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.shield),
      activeIcon: Icon(CupertinoIcons.shield_fill),
      label: 'Focus',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.gear),
      activeIcon: Icon(CupertinoIcons.gear_solid),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: _items,
        activeColor: AppColors.accent,
        inactiveColor: AppColors.textTertiary,
        backgroundColor: AppColors.background.withValues(alpha: 0.85),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      );
    }

    // Android: custom blurred bottom nav
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.85),
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) {
                  final item = _items[index];
                  final isActive = index == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconTheme(
                            data: IconThemeData(
                              size: 22,
                              color: isActive
                                  ? AppColors.accent
                                  : AppColors.textTertiary,
                            ),
                            child: isActive ? item.activeIcon : item.icon,
                          ),
                          if (isActive) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              item.label!,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
