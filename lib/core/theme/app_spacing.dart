import 'package:flutter/material.dart';

/// CEO OS Spacing System — HIG 8pt grid with Apple-standard values.
class AppSpacing {
  AppSpacing._();

  // ── Spacing Scale (8pt grid) ──
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ── Border Radius (HIG standard) ──
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusGrouped = 10; // Grouped table view cells
  static const double radiusFull = 999;

  // ── Screen Padding (HIG: 16pt standard margins) ──
  static EdgeInsets get screenPadding =>
      const EdgeInsets.symmetric(horizontal: md);

  /// Standard section spacing between major content blocks
  static const double sectionSpacing = lg;

  // ── Padding Presets ──
  static const EdgeInsets paddingCard = EdgeInsets.all(md);
  static const EdgeInsets paddingSection = EdgeInsets.only(bottom: lg);

  // ── HIG Touch Targets ──
  static const double minTouchTarget = 44; // 44×44pt minimum

  // ── Icon Sizes ──
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
}
