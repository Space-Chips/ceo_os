import 'package:flutter/material.dart';

/// CEO OS Spacing System — Apple HIG-compliant 8pt grid.
class AppSpacing {
  AppSpacing._();

  // ── Spacing Scale (8pt grid) ──
  static const double xxs = 2;
  static const double xs = 4; // tight
  static const double sm = 8; // standard
  static const double md = 16; // section
  static const double lg = 24; // large
  static const double xl = 32; // extra-large
  static const double xxl = 48;
  static const double xxxl = 64;

  // ── Border Radius (HIG specifications) ──
  static const double radiusSm = 8; // buttons, small elements
  static const double radiusMd = 10; // cards, grouped content (HIG: 10pt)
  static const double radiusLg = 13; // large cards (HIG: 13pt)
  static const double radiusXl = 20; // sheets
  static const double radiusGrouped = 10; // Grouped table view cells
  static const double radiusFull = 999; // pills

  // ── Screen Padding (HIG: 16pt on iPhone) ──
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);

  /// Standard section spacing between major content blocks
  static const double sectionSpacing = lg;

  // ── Touch Target ──
  static const double minTouchTarget = 44; // HIG minimum tappable area

  // ── Padding Presets ──
  static const EdgeInsets paddingCard = EdgeInsets.all(md);
  static const EdgeInsets paddingCardList = EdgeInsets.symmetric(
    horizontal: md,
    vertical: 11,
  ); // HIG list cell padding
  static const EdgeInsets paddingSection = EdgeInsets.only(bottom: lg);

  // ── Icon Sizes ──
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
}
