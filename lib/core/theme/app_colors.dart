import 'dart:ui';

/// CEO OS Color Palette — Apple HIG Dark Mode system colors.
/// Uses iOS semantic color equivalents for native consistency.
class AppColors {
  AppColors._();

  // ── Background (iOS systemBackground hierarchy) ──
  static const Color background = Color(0xFF000000);           // systemBackground
  static const Color surface = Color(0xFF1C1C1E);              // secondarySystemBackground
  static const Color surfaceLight = Color(0xFF2C2C2E);         // tertiarySystemBackground
  static const Color surfaceLighter = Color(0xFF3A3A3C);       // tertiarySystemGroupedBackground

  // ── Border / Separator ──
  static const Color border = Color(0xFF38383A);               // opaqueSeparator
  static const Color borderLight = Color(0x99545458);          // separator (65% opacity)

  // ── Text (iOS label hierarchy) ──
  static const Color textPrimary = Color(0xFFFFFFFF);          // label
  static const Color textSecondary = Color(0x99EBEBF5);        // secondaryLabel (60%)
  static const Color textTertiary = Color(0x4DEBEBF5);         // tertiaryLabel (30%)
  static const Color textMuted = Color(0x2EEBEBF5);            // quaternaryLabel (18%)

  // ── Accent (iOS systemBlue) ──
  static const Color accent = Color(0xFF0A84FF);               // systemBlue
  static const Color accentLight = Color(0xFF409CFF);          // systemBlue elevated
  static const Color accentDark = Color(0xFF0064E1);           // systemBlue pressed
  static const Color accentMuted = Color(0x330A84FF);          // systemBlue @ 20%

  // ── Semantic (iOS system colors) ──
  static const Color success = Color(0xFF30D158);              // systemGreen
  static const Color successMuted = Color(0x3330D158);
  static const Color warning = Color(0xFFFF9F0A);              // systemOrange
  static const Color warningMuted = Color(0x33FF9F0A);
  static const Color error = Color(0xFFFF453A);                // systemRed
  static const Color errorMuted = Color(0x33FF453A);

  // ── Priority Colors ──
  static const Color priorityUrgent = Color(0xFFFF453A);       // systemRed
  static const Color priorityHigh = Color(0xFFFF9F0A);         // systemOrange
  static const Color priorityMedium = Color(0xFFFFD60A);       // systemYellow
  static const Color priorityLow = Color(0xFF0A84FF);          // systemBlue

  // ── Gradient (Blue only) ──
  static const List<Color> accentGradient = [
    Color(0xFF0064E1),
    Color(0xFF0A84FF),
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFF1C1C1E),
    Color(0xFF000000),
  ];

  // ── System Fill Colors ──
  static const Color systemFill = Color(0x5C787880);           // systemFill
  static const Color secondarySystemFill = Color(0x52787880);  // secondarySystemFill
}
