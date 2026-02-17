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

  // ── Primary Cupertino Theme ──
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headline,
        iconTheme: const IconThemeData(color: AppColors.label, size: 22),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.secondarySystemBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
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

      // Divider
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
        labelStyle: AppTypography.footnote,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.tertiarySystemBackground,
        contentTextStyle: AppTypography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Legacy alias ──
  static ThemeData get dark => materialFallback;
}
