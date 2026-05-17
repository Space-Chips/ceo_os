import 'package:flutter/material.dart';

/// Spacing tokens for a denser and more readable premium layout.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  static const double radiusXs = 8;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radiusGrouped = 20;
  static const double radiusFull = 999;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double sectionSpacing = 16;

  static const double minTouchTarget = 44;

  static const EdgeInsets paddingCard = EdgeInsets.all(14);
  static const EdgeInsets paddingCardList = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const EdgeInsets paddingSection = EdgeInsets.only(bottom: 16);

  static const double iconSm = 14;
  static const double iconMd = 18;
  static const double iconLg = 22;
  static const double iconXl = 28;
}
