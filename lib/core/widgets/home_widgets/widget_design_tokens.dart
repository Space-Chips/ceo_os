import 'package:flutter/cupertino.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class WidgetDesignTokens {
  const WidgetDesignTokens._();

  static const double radiusOuter = 26;
  static const double radiusInner = 20;
  static const double radiusCard = 18;

  // Safe internal padding that never touches rounded corners.
  // small widgets: 14–16 pt, medium widgets: 18–20 pt (per spec).
  static const EdgeInsets padSquare = EdgeInsets.fromLTRB(15, 15, 15, 14);
  static const EdgeInsets padRect = EdgeInsets.fromLTRB(19, 18, 19, 16);

  static Color get bg => const Color(0xFF0A0B0D);

  static LinearGradient get bgGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF111318),
          const Color(0xFF07080A),
        ],
      );

  static LinearGradient get focusGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1B1236),
          Color(0xFF07080A),
        ],
      );

  static LinearGradient get blackoutGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A0B10),
          Color(0xFF07080A),
        ],
      );



  static BoxDecoration outerDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusOuter),
        gradient: bgGradient,
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: 0.9),
            blurRadius: 42,
            offset: const Offset(0, 18),
            spreadRadius: -18,
          ),
        ],
      );

  static BoxDecoration innerSurface({Color? tint}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusInner),
        color: Color.alphaBlend(
          (tint ?? const Color(0xFF1A1D23)).withValues(alpha: 0.55),
          const Color(0xFF0C0D10),
        ),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.65),
          width: 1,
        ),
      );

  static TextStyle get title => AppTypography.largeTitle.copyWith(
        fontSize: 22,
        height: 1.0,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w700,
        color: AppColors.label,
      );

  static TextStyle get subtitle => AppTypography.subhead.copyWith(
        fontSize: 12,
        height: 1.2,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLabel.withValues(alpha: 0.72),
      );

  static TextStyle get section => AppTypography.overline.copyWith(
        fontSize: 11,
        letterSpacing: 2.2,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryLabel.withValues(alpha: 0.58),
      );

  static TextStyle get body => AppTypography.callout.copyWith(
        fontSize: 13,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: AppColors.label.withValues(alpha: 0.92),
      );

  static Color get primaryText => AppColors.label;
  static Color get secondaryText => AppColors.secondaryLabel;
}
