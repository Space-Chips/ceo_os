import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// CEO OS Typography — Apple HIG Dynamic Type scale.
/// Uses system font on all platforms for Cupertino-native feel.
/// All sizes, weights, and line heights match the HIG "Large" default.
class AppTypography {
  AppTypography._();

  static const TextStyle _base = TextStyle(
    fontFamily: '.AppleSystemUIFont',
    color: AppColors.label,
  );

  // ── HIG Dynamic Type Scale ──

  /// 34pt Bold — Main page headings (collapsible large title)
  static TextStyle get largeTitle => _base.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 41 / 34,
    letterSpacing: 0.37,
  );

  /// 28pt Regular — Primary page headers
  static TextStyle get title1 => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 34 / 28,
    letterSpacing: 0.36,
  );

  /// 22pt Regular — Section headers
  static TextStyle get title2 => _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 28 / 22,
    letterSpacing: 0.35,
  );

  /// 20pt Regular — Subsection headers
  static TextStyle get title3 => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 25 / 20,
    letterSpacing: 0.38,
  );

  /// 17pt Semibold — Bolded text to distinguish from body
  static TextStyle get headline => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 22 / 17,
    letterSpacing: -0.41,
  );

  /// 17pt Regular — Primary content text
  static TextStyle get body => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 22 / 17,
    letterSpacing: -0.41,
  );

  /// 16pt Regular — Highlighted info
  static TextStyle get callout => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 21 / 16,
    letterSpacing: -0.32,
  );

  /// 15pt Regular — Secondary descriptions
  static TextStyle get subhead => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 20 / 15,
    letterSpacing: -0.24,
  );

  /// 13pt Regular — Disclaimers, timestamps
  static TextStyle get footnote => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    letterSpacing: -0.08,
  );

  /// 12pt Regular — Image captions
  static TextStyle get caption1 => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  /// 11pt Regular — Smallest legible metadata
  static TextStyle get caption2 => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 13 / 11,
  );

  // ── Mono (for timers / large numeric displays) ──
  static TextStyle get mono => _base.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w200,
    letterSpacing: 2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Large hero number for Opal-style stats display
  static TextStyle get heroNumber => _base.copyWith(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -2,
  );

  /// Ultra-large display for Focus timer (42pt, regular weight)
  static TextStyle get focusDisplay => _base.copyWith(
    fontSize: 42,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: -1,
  );

  // ── Legacy aliases ──
  static TextStyle get displayLarge => largeTitle;
  static TextStyle get displayMedium => title1;
  static TextStyle get headingLarge => title2;
  static TextStyle get headingMedium => title3;
  static TextStyle get headingSmall => headline;
  static TextStyle get bodyLarge => body;
  static TextStyle get bodyMedium => body;
  static TextStyle get bodySmall => subhead;
  static TextStyle get labelLarge => headline;
  static TextStyle get labelMedium => footnote;
  static TextStyle get labelSmall => caption2;
  static TextStyle get caption => caption1;
}
