import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'theme_catalog.dart';

/// App theme builders powered by the active preset.
class AppTheme {
  AppTheme._();

  static CupertinoThemeData cupertinoForTone(AppThemeTone tone) {
    final isDark = tone == AppThemeTone.dark;
    return CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: AppColors.primaryOrange,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: AppColors.background.withValues(
        alpha: isDark ? 0.72 : 0.86,
      ),
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primaryOrange,
        textStyle: AppTypography.body,
        navLargeTitleTextStyle: AppTypography.title1,
        navTitleTextStyle: AppTypography.headline,
        actionTextStyle: AppTypography.headline.copyWith(
          color: AppColors.primaryOrange,
        ),
      ),
    );
  }

  static ThemeData materialForTone(AppThemeTone tone) {
    final isDark = tone == AppThemeTone.dark;
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryOrange,
      fontFamily: '.SF Pro Text',
      canvasColor: AppColors.background,
      useMaterial3: true,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light())
          .copyWith(
            primary: AppColors.primaryOrange,
            secondary: AppColors.primaryOrange,
            surface: AppColors.elevatedBackground,
            onSurface: AppColors.label,
            onPrimary: AppColors.onAccent,
            onSecondary: AppColors.onAccent,
            error: AppColors.error,
            onError: AppColors.white,
          ),
      textTheme: TextTheme(
        displayLarge: AppTypography.largeTitle,
        displayMedium: AppTypography.title1,
        headlineMedium: AppTypography.title2,
        titleLarge: AppTypography.title3,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        labelLarge: AppTypography.headline,
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.elevatedBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassSurfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryOrange,
            width: 1.2,
          ),
        ),
        labelStyle: AppTypography.body.copyWith(color: AppColors.secondaryLabel),
        hintStyle: AppTypography.body.copyWith(color: AppColors.tertiaryLabel),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.headline,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 0.5,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevatedBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.glassBorder, width: 0.6),
        ),
      ),
    );
  }

  static CupertinoThemeData get cupertino =>
      cupertinoForTone(AppThemeTone.dark);
  static ThemeData get materialFallback => materialForTone(AppThemeTone.dark);
  static ThemeData get dark => materialFallback;
}