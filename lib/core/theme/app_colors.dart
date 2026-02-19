import 'dart:ui';

/// CEO OS Color Palette — Dark, Sleek, Monochromatic with Orange Accent.
class AppColors {
  AppColors._();

  // ── Core Backgrounds ──
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color backgroundLight = Color(0xFF0F0F0F); // Very Dark Grey
  static const Color surface = Color(0xFF141414); // Slightly lighter for cards

  // ── Glass & Surfaces ──
  static const Color glassBase = Color(0x1A1A1A1A); // Dark Glass
  static const Color glassBorder = Color(0x1FFFFFFF); // Subtle White Border
  static const Color cardGradientStart = Color(0x14FFFFFF);
  static const Color cardGradientEnd = Color(0x05FFFFFF);

  // ── Accent Color ──
  static const Color primaryOrange = Color(0xFFFF5500); // Vibrant Orange
  static const Color orangeDim = Color(0xFFCC4400);

  static const Color accent = primaryOrange;
  static const Color accentSecondary = orangeDim;
  static const Color white = Color(0xFFFFFFFF);

  // ── Labels ──
  static const Color label = Color(0xFFFFFFFF);
  static const Color secondaryLabel = Color(0x99FFFFFF); // 60% white
  static const Color tertiaryLabel = Color(0x66FFFFFF); // 40% white
  static const Color quaternaryLabel = Color(0x33FFFFFF); // 20% white

  // ── Semantic Status ──
  static const Color success = Color(0xFF30D158);
  static const Color warning = primaryOrange;
  static const Color error = Color(0xFFFF453A);
  static const Color systemRed = error;

  // ── Gradients ──
  static const List<Color> liquidGradient = [primaryOrange, orangeDim];

  static const List<Color> glassGradient = [
    Color(0x1AFFFFFF),
    Color(0x05FFFFFF),
  ];

  // ── Legacy Aliases ──
  static const Color electricCyan = primaryOrange; // Mapping old to new
  static const Color royalPurple = orangeDim;
  static const Color softIndigo = orangeDim;
  static const Color vibrantPink = primaryOrange;

  static const Color systemBackground = background;
  static const Color secondarySystemBackground = backgroundLight;
  static const Color tertiarySystemBackground = surface;
  static const Color systemGroupedBackground = background;
  static const Color separator = glassBorder;
  static const Color opaqueSeparator = Color(0x33FFFFFF);
  static const Color systemBlue = primaryOrange;
  static const Color accentMuted = Color(0x33FF5500);
}
