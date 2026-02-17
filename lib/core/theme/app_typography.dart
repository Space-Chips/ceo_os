import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../platform/adaptive_widgets.dart';
import 'app_colors.dart';

/// CEO OS Typography — SF Pro on iOS, Inter on Android.
class AppTypography {
  AppTypography._();

  static TextStyle get _base {
    if (isApplePlatform) {
      // System SF Pro — automatically liquid glass compatible
      return const TextStyle(
        fontFamily: '.AppleSystemUIFont',
        color: AppColors.textPrimary,
      );
    }
    return GoogleFonts.inter(color: AppColors.textPrimary);
  }

  // ── Display ──
  static TextStyle get displayLarge => _base.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static TextStyle get displayMedium => _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.15,
  );

  // ── Heading ──
  static TextStyle get headingLarge => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get headingMedium => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle get headingSmall => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // ── Body ──
  static TextStyle get bodyLarge => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Label ──
  static TextStyle get labelLarge => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get labelMedium => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle get labelSmall => _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // ── Caption ──
  static TextStyle get caption => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
    height: 1.4,
  );

  // ── Mono (for timers) ──
  static TextStyle get mono {
    if (isApplePlatform) {
      return const TextStyle(
        fontFamily: 'Menlo',
        color: AppColors.textPrimary,
        fontSize: 48,
        fontWeight: FontWeight.w300,
        letterSpacing: 2,
      );
    }
    return GoogleFonts.jetBrainsMono(
      color: AppColors.textPrimary,
      fontSize: 48,
      fontWeight: FontWeight.w300,
      letterSpacing: 2,
    );
  }
}
