import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../platform/adaptive_widgets.dart';
import 'app_colors.dart';

/// CEO OS Typography — matches iOS Dynamic Type scale.
/// SF Pro on iOS (system font), Inter on Android.
class AppTypography {
  AppTypography._();

  static TextStyle get _base {
    if (isApplePlatform) {
      return const TextStyle(
        fontFamily: '.AppleSystemUIFont',
        color: AppColors.textPrimary,
      );
    }
    return GoogleFonts.inter(color: AppColors.textPrimary);
  }

  // ── Large Title (34pt Bold) ──
  static TextStyle get displayLarge => _base.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 41 / 34, // 1.21
  );

  // ── Title 1 (28pt Regular) ──
  static TextStyle get displayMedium => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.36,
    height: 34 / 28, // 1.21
  );

  // ── Title 2 (22pt Regular) ──
  static TextStyle get headingLarge => _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.35,
    height: 28 / 22, // 1.27
  );

  // ── Title 3 (20pt Regular) ──
  static TextStyle get headingMedium => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.38,
    height: 25 / 20, // 1.25
  );

  // ── Headline (17pt Semibold) ──
  static TextStyle get headingSmall => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 22 / 17, // 1.29
  );

  // ── Body (17pt Regular) ──
  static TextStyle get bodyLarge => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    height: 22 / 17, // 1.29
  );

  // ── Subheadline (15pt Regular) ──
  static TextStyle get bodyMedium => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 20 / 15, // 1.33
  );

  // ── Footnote (13pt Regular) ──
  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 18 / 13, // 1.38
  );

  // ── Callout (16pt Regular) ──
  static TextStyle get labelLarge => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 21 / 16, // 1.31
  );

  // ── Caption 1 (12pt Regular) ──
  static TextStyle get labelMedium => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 16 / 12, // 1.33
  );

  // ── Caption 2 (11pt Regular) ──
  static TextStyle get labelSmall => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
    height: 13 / 11, // 1.18
  );

  // ── Caption alias ──
  static TextStyle get caption =>
      labelSmall.copyWith(color: AppColors.textSecondary);

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
