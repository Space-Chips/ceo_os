import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

/// Disciplined typography system.
///
/// Primary family is Inter with robust platform fallbacks.
class AppTypography {
  AppTypography._();

  static const String _primary = '.SF Pro Text';
  static const List<String> _fallbacks = [
    'SF Pro Text',
    '.SF Pro Text',
    'SF Pro Display',
    '.SF Pro Display',
    // iOS system fonts for non-Latin scripts (helps zh/hi/ar rendering).
    'PingFang SC',
    'PingFang TC',
    'Hiragino Sans',
    'Hiragino Kaku Gothic ProN',
    'Geeza Pro',
    'Devanagari Sangam MN',
    // Common cross-platform families (Android / desktop).
    'Noto Sans',
    'Noto Sans CJK SC',
    'Noto Sans CJK TC',
    'Noto Sans Arabic',
    'Noto Sans Devanagari',
    'Inter',
    'SF Pro Text',
    'SF Pro Display',
    '-apple-system',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const List<String> _monoFallbacks = [
    'SF Mono',
    'SFMono-Regular',
    'Menlo',
    'Monaco',
    'Courier New',
    'monospace',
  ];

  static TextStyle _base({required Color color}) => TextStyle(
    fontFamily: _primary,
    fontFamilyFallback: _fallbacks,
    color: color,
    decoration: TextDecoration.none,
    decorationColor: Color(0x00000000),
  );

  static TextStyle get timer => _base(color: AppColors.label).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 0.1,
  );

  static TextStyle get mono => _base(color: AppColors.label).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 0.1,
  );

  static TextStyle get largeTitle => _base(color: AppColors.label).copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.16,
    letterSpacing: -0.9,
  );

  static TextStyle get title1 => _base(color: AppColors.label).copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.6,
  );

  static TextStyle get title2 => _base(color: AppColors.label).copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.22,
    letterSpacing: -0.35,
  );

  static TextStyle get title3 => _base(color: AppColors.label).copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.24,
    letterSpacing: -0.2,
  );

  static TextStyle get headline => _base(color: AppColors.label).copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.15,
  );

  static TextStyle get body => _base(color: AppColors.label).copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
  );

  static TextStyle get callout => _base(
    color: AppColors.label,
  ).copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.32);

  static TextStyle get subhead => _base(
    color: AppColors.secondaryLabel,
  ).copyWith(fontSize: 15, fontWeight: FontWeight.w500, height: 1.32);

  static TextStyle get footnote => _base(
    color: AppColors.secondaryLabel,
  ).copyWith(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3);

  static TextStyle get caption1 => _base(
    color: AppColors.tertiaryLabel,
  ).copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.25);

  static TextStyle get caption2 => _base(
    color: AppColors.quaternaryLabel,
  ).copyWith(fontSize: 10, fontWeight: FontWeight.w500, height: 1.2);

  static TextStyle get overline =>
      _base(color: AppColors.tertiaryLabel).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.2,
      );

  static TextStyle get displayMono => timer.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.4,
    height: 1,
  );

  static TextStyle get heroNumber => timer.copyWith(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.8,
    height: 1,
  );

  static TextStyle get heroDisplay => TextStyle(
    fontFamily: '.SF Pro Display',
    fontFamilyFallback: const [
      'SF Pro Display',
      '.SF Pro Text',
      'SF Pro Text',
      'Inter',
      '-apple-system',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
    color: AppColors.label,
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: 56,
    fontWeight: FontWeight.w500,
    letterSpacing: -2.2,
    height: 1,
    decoration: TextDecoration.none,
    decorationColor: Color(0x00000000),
  );

  static TextStyle get focusDisplay => timer.copyWith(
    fontSize: 46,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.4,
    height: 1,
  );

  // Legacy aliases used across the codebase.
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
