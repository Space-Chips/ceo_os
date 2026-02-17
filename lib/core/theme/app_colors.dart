import 'dart:ui';

/// CEO OS Color Palette — Zinc-based dark theme with electric blue accent.
/// Single accent color system — no purple, no multi-color gradients.
class AppColors {
  AppColors._();

  // ── Background ──
  static const Color background = Color(0xFF09090B);      // zinc-950
  static const Color surface = Color(0xFF18181B);          // zinc-900
  static const Color surfaceLight = Color(0xFF27272A);     // zinc-800
  static const Color surfaceLighter = Color(0xFF3F3F46);   // zinc-700

  // ── Border ──
  static const Color border = Color(0xFF27272A);           // zinc-800
  static const Color borderLight = Color(0xFF3F3F46);      // zinc-700

  // ── Text ──
  static const Color textPrimary = Color(0xFFFAFAFA);      // zinc-50
  static const Color textSecondary = Color(0xFFA1A1AA);    // zinc-400
  static const Color textTertiary = Color(0xFF71717A);     // zinc-500
  static const Color textMuted = Color(0xFF52525B);        // zinc-600

  // ── Accent (Blue only) ──
  static const Color accent = Color(0xFF3B82F6);           // blue-500
  static const Color accentLight = Color(0xFF60A5FA);      // blue-400
  static const Color accentDark = Color(0xFF2563EB);       // blue-600
  static const Color accentMuted = Color(0x333B82F6);      // blue-500 @ 20%

  // ── Semantic ──
  static const Color success = Color(0xFF22C55E);          // green-500
  static const Color successMuted = Color(0x3322C55E);
  static const Color warning = Color(0xFFF59E0B);          // amber-500
  static const Color warningMuted = Color(0x33F59E0B);
  static const Color error = Color(0xFFEF4444);            // red-500
  static const Color errorMuted = Color(0x33EF4444);

  // ── Priority Colors ──
  static const Color priorityUrgent = Color(0xFFEF4444);
  static const Color priorityHigh = Color(0xFFF97316);     // orange-500
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF3B82F6);

  // ── Gradient (Blue only — no purple) ──
  static const List<Color> accentGradient = [
    Color(0xFF2563EB),   // blue-600
    Color(0xFF3B82F6),   // blue-500
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFF18181B),
    Color(0xFF09090B),
  ];
}
