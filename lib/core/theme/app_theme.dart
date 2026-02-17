import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// CEO OS Theme — Cupertino-first, dark only.
/// Primary theme is CupertinoThemeData; Material ThemeData provided for
/// fallback compatibility (charts, bottom sheets, etc.).
class AppTheme {
  AppTheme._();

  // ── Primary Cupertino Theme (iOS) ──
  static CupertinoThemeData get cupertino {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.systemBlue,
      scaffoldBackgroundColor: AppColors.systemBackground,
      barBackgroundColor: Color(0xF0000000), // Translucent black for bars
      textTheme: CupertinoTextThemeData(primaryColor: AppColors.systemBlue),
    );
  }

  // ── Material Fallback Theme (for fl_chart, showModalBottomSheet, etc.) ──
  static ThemeData get materialFallback {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.systemBackground,
      primaryColor: AppColors.systemBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.systemBlue,
        secondary: AppColors.systemBlue,
        surface: AppColors.secondarySystemBackground,
        error: AppColors.systemRed,
      ),

      // AppBar (rarely used, but just in case)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
        ),
        iconTheme: IconThemeData(color: AppColors.label, size: 22),
      ),

      // Card — no border in dark mode (HIG: color differentiation only)
      cardTheme: CardThemeData(
        color: AppColors.secondarySystemBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.systemBackground,
        selectedItemColor: AppColors.systemBlue,
        unselectedItemColor: AppColors.tertiaryLabel,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.systemBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 50), // HIG large button height
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // HIG large button radius
          ),
        ),
      ),

      // Input — HIG text field specs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tertiarySystemBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.systemBlue, width: 1.5),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.systemBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Divider — HIG separator
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: 0.5,
        space: 0,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.tertiarySystemBackground,
        selectedColor: AppColors.accentMuted,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.secondarySystemBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.tertiarySystemBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Legacy aliases ──
  static ThemeData get dark => materialFallback;
}
