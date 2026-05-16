import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography palette forced to SF Pro across the app.
class AppTypography {
  AppTypography._();

  static const String _sfProText = '.SF Pro Text';
  static const String _sfProDisplay = '.SF Pro Display';
  static const List<String> _fallbacks = [
    'SF Pro Text',
    'SF Pro Display',
    'San Francisco',
    '-apple-system',
    'Helvetica Neue',
    'Helvetica',
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

  static TextStyle _displayFont({
    required Color color,
    required double letterSpacing,
  }) => TextStyle(
    fontFamily: _sfProDisplay,
    fontFamilyFallback: _fallbacks,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle _bodyFont({required Color color}) => TextStyle(
    fontFamily: _sfProText,
    fontFamilyFallback: _fallbacks,
    color: color,
  );

  static TextStyle _monoFont({required Color color}) => TextStyle(
    fontFamily: 'SF Mono',
    fontFamilyFallback: _monoFallbacks,
    color: color,
  );

  static TextStyle get timer => TextStyle(
    fontFamily: 'SF Mono',
    fontFamilyFallback: _monoFallbacks,
    color: AppColors.label,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 0.2,
  );

  static TextStyle get _displayBase =>
      _displayFont(color: AppColors.label, letterSpacing: -0.5);

  static TextStyle get _bodyBase => _bodyFont(color: AppColors.label);

  static TextStyle get mono => _monoFont(color: AppColors.label);

  // ── Type Scale ──

  static TextStyle get largeTitle => _displayBase.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle get title1 => _displayBase.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle get title2 =>
      _displayBase.copyWith(fontSize: 22, fontWeight: FontWeight.w600);

  static TextStyle get title3 =>
      _displayBase.copyWith(fontSize: 20, fontWeight: FontWeight.w500);

  static TextStyle get headline => _bodyBase.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static TextStyle get body => _bodyBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get callout =>
      _bodyBase.copyWith(fontSize: 15, fontWeight: FontWeight.w400);

  static TextStyle get subhead =>
      _bodyBase.copyWith(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get footnote => _bodyBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryLabel,
  );

  static TextStyle get caption1 => _bodyBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.tertiaryLabel,
  );

  static TextStyle get caption2 => _bodyBase.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.quaternaryLabel,
  );

  // ── Special ──

  static TextStyle get displayMono => mono.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w200,
    color: AppColors.label,
  );

  static TextStyle get heroNumber => mono.copyWith(
    fontSize: 64,
    fontWeight: FontWeight.w700,
    letterSpacing: -3,
    height: 1.0,
  );

  static TextStyle get focusDisplay => mono.copyWith(
    fontSize: 54,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
  );

  static TextStyle get heroDisplay => _displayBase.copyWith(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.04,
  );

  static TextStyle get overline => _bodyBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.secondaryLabel,
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
