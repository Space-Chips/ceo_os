import 'dart:ui';

/// CEO OS Color Palette — Apple HIG semantic dark-mode colors.
/// All values match Apple's iOS dark-mode system colors.
class AppColors {
  AppColors._();

  // ── Backgrounds (HIG Semantic) ──
  static const Color systemBackground = Color(0xFF000000); // Pure black
  static const Color secondarySystemBackground = Color(
    0xFF1C1C1E,
  ); // Elevated surface
  static const Color tertiarySystemBackground = Color(
    0xFF2C2C2E,
  ); // Third level
  static const Color systemGroupedBackground = Color(
    0xFF000000,
  ); // Grouped table bg
  static const Color secondarySystemGroupedBackground = Color(
    0xFF1C1C1E,
  ); // Grouped cell

  // ── Labels (HIG Semantic) ──
  static const Color label = Color(0xFFFFFFFF);
  static const Color secondaryLabel = Color(0x99EBEBF5); // ~60% white
  static const Color tertiaryLabel = Color(0x4DEBEBF5); // ~30% white
  static const Color quaternaryLabel = Color(0x29EBEBF5); // ~16% white

  // ── Separators ──
  static const Color separator = Color(0x99545458); // Standard
  static const Color opaqueSeparator = Color(0xFF38383A); // Opaque variant

  // ── Fills ──
  static const Color systemFill = Color(0x5C787880);
  static const Color secondarySystemFill = Color(0x52787880);
  static const Color tertiarySystemFill = Color(0x3D767680);
  static const Color quaternarySystemFill = Color(0x2E747480);

  // ── System Tints (Dark Mode) ──
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF30D158);
  static const Color systemRed = Color(0xFFFF453A);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemYellow = Color(0xFFFFD60A);
  static const Color systemTeal = Color(0xFF64D2FF);
  static const Color systemPurple = Color(0xFFBF5AF2);
  static const Color systemPink = Color(0xFFFF375F);
  static const Color systemIndigo = Color(0xFF5E5CE6);
  static const Color systemMint = Color(0xFF63E6E2);
  static const Color systemCyan = Color(0xFF64D2FF);

  // ── Accent (Primary app tint) ──
  static const Color accent = systemBlue;
  static const Color accentLight = Color(0xFF409CFF);
  static const Color accentDark = Color(0xFF0064E1);
  static const Color accentMuted = Color(0x330A84FF); // systemBlue @ 20%

  // ── Semantic Status ──
  static const Color success = systemGreen;
  static const Color successMuted = Color(0x3330D158);
  static const Color warning = systemOrange;
  static const Color warningMuted = Color(0x33FF9F0A);
  static const Color error = systemRed;
  static const Color errorMuted = Color(0x33FF453A);

  // ── Priority Colors (Tuned to HIG system tints) ──
  static const Color priorityUrgent = systemRed;
  static const Color priorityHigh = systemOrange;
  static const Color priorityMedium = systemYellow;
  static const Color priorityLow = systemBlue;

  // ── Gradients ──
  static const List<Color> accentGradient = [
    Color(0xFF0A84FF),
    Color(0xFF409CFF),
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFF1C1C1E),
    Color(0xFF000000),
  ];

  // ── Legacy aliases (ease migration) ──
  static const Color background = systemBackground;
  static const Color surface = secondarySystemBackground;
  static const Color surfaceLight = tertiarySystemBackground;
  static const Color surfaceLighter = Color(0xFF3A3A3C);
  static const Color border = separator;
  static const Color borderLight = opaqueSeparator;
  static const Color textPrimary = label;
  static const Color textSecondary = secondaryLabel;
  static const Color textTertiary = tertiaryLabel;
  static const Color textMuted = quaternaryLabel;
}
