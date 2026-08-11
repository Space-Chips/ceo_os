import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'theme_catalog.dart';

/// Material + Cupertino themes derived from the active preset tone.
class AppTheme {
  AppTheme._();

  static CupertinoThemeData cupertinoForTone(AppThemeTone tone) {
    final isDark = tone == AppThemeTone.dark;
    return CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: Color.alphaBlend(
        AppColors.overlayScrim.withValues(alpha: isDark ? 0.32 : 0.16),
        AppColors.sectionBackground,
      ),
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accent,
        textStyle: AppTypography.body,
        navLargeTitleTextStyle: AppTypography.title1,
        navTitleTextStyle: AppTypography.headline,
        actionTextStyle: AppTypography.callout.copyWith(
          color: AppColors.accent,
        ),
      ),
    );
  }

  static ThemeData materialForTone(AppThemeTone tone) {
    final isDark = tone == AppThemeTone.dark;
    final baseScheme = isDark
        ? const ColorScheme.dark()
        : const ColorScheme.light();

    final colorScheme = baseScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.label,
      onPrimary: AppColors.onAccent,
      onSecondary: AppColors.onAccent,
      error: AppColors.error,
      onError: AppColors.white,
    );

    final outlineColor = AppColors.border;

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      primaryColor: AppColors.accent,
      textTheme: TextTheme(
        displayLarge: AppTypography.largeTitle,
        displayMedium: AppTypography.title1,
        headlineMedium: AppTypography.title2,
        titleLarge: AppTypography.title3,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.subhead,
        labelLarge: AppTypography.headline,
        labelMedium: AppTypography.footnote,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outlineColor, width: 0.9),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineColor, width: 0.9),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineColor, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.accent, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        labelStyle: AppTypography.callout.copyWith(
          color: AppColors.secondaryLabel,
        ),
        hintStyle: AppTypography.callout.copyWith(
          color: AppColors.tertiaryLabel,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.callout.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineColor,
        thickness: 0.9,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.border, width: 0.9),
        ),
      ),
    );
  }

  static CupertinoThemeData get cupertino =>
      cupertinoForTone(AppThemeTone.dark);
  static ThemeData get materialFallback => materialForTone(AppThemeTone.dark);
  static ThemeData get dark => materialFallback;
}
