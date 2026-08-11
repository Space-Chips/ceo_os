import 'dart:ui';
import 'theme_runtime.dart';

/// Dynamic color tokens bound to the active theme preset.
///
/// New semantic tokens are exposed first, with legacy aliases kept for
/// compatibility across existing screens.
class AppColors {
  AppColors._();

  static bool get isDark => ThemeRuntime.preset.isDark;
  static String get themeId => ThemeRuntime.preset.id;
  static bool get isCarbonSystem => themeId == 'carbon_system';

  static Color get background => ThemeRuntime.preset.semantic.appBackground;
  static Color get backgroundElevated =>
      ThemeRuntime.preset.semantic.sectionBackground;
  static Color get sectionBackground =>
      ThemeRuntime.preset.semantic.sectionBackground;
  static Color get backgroundLight => backgroundElevated;
  static Color get surface => ThemeRuntime.preset.semantic.cardBackground;
  static Color get cardBackgroundAlt =>
      ThemeRuntime.preset.semantic.cardBackgroundAlt;
  static Color get cardBackgroundStrong =>
      ThemeRuntime.preset.semantic.cardBackgroundStrong;
  static Color get surfaceMuted => ThemeRuntime.preset.palette.surfaceTertiary;
  static Color get cardBase => ThemeRuntime.preset.semantic.cardBackground;
  static Color get cardRaised => ThemeRuntime.preset.semantic.cardBackgroundAlt;

  static Color get accent => ThemeRuntime.preset.palette.accent;
  static Color get accentLight => ThemeRuntime.preset.palette.accentLight;
  static Color get accentDeep => ThemeRuntime.preset.palette.accentDeep;
  static Color get accentSoft => ThemeRuntime.preset.semantic.accentSurfaceSoft;
  static Color get accentSurfaceSoft =>
      ThemeRuntime.preset.semantic.accentSurfaceSoft;
  static Color get accentSecondary =>
      Color.lerp(accent, backgroundLight, isDark ? 0.22 : 0.32) ?? accent;
  static Color get themeGlow => ThemeRuntime.preset.semantic.accentGlow;
  static Color get activeBorder => ThemeRuntime.preset.semantic.accentBorder;
  static Color get toggleOn => ThemeRuntime.preset.semantic.activeToggle;
  static Color get selectionOutline =>
      ThemeRuntime.preset.semantic.selectionOutline;
  static Color get accentSurfaceStrong =>
      ThemeRuntime.preset.semantic.accentSurfaceStrong;
  static Color get buttonGradientStart => accent;
  static Color get buttonGradientEnd => accentLight;
  static List<Color> get buttonGradient => [
    buttonGradientStart,
    buttonGradientEnd,
  ];

  static Color get label => ThemeRuntime.preset.semantic.primaryText;
  static Color get secondaryLabel => ThemeRuntime.preset.semantic.secondaryText;
  static Color get tertiaryLabel => ThemeRuntime.preset.semantic.tertiaryText;
  static Color get quaternaryLabel => tertiaryLabel.withValues(alpha: 0.72);
  static Color get accentText => ThemeRuntime.preset.semantic.accentText;
  static Color get accentIcon => ThemeRuntime.preset.semantic.accentIcon;
  static Color get rankAccent => ThemeRuntime.preset.semantic.rankAccent;
  static Color get scoreValue => ThemeRuntime.preset.semantic.scoreValue;

  static const Color success = Color(0xFF2CB67D);
  static const Color warning = Color(0xFFF5A524);
  static const Color error = Color(0xFFEA5E67);
  static const Color info = Color(0xFF4F8CFF);

  static Color get chartA => accentLight;
  static Color get chartB => accent;
  static Color get chartC => warning;
  static Color get chartD => success.withValues(alpha: 0.88);

  static Color get focusPrimary => ThemeRuntime.preset.semantic.focusRing;
  static Color get focusSecondary => accentLight;
  static const Color ceoPrimary = Color(0xFFFFB04E);
  static const Color ceoSecondary = Color(0xFFFFD48A);

  static Color get border => ThemeRuntime.preset.semantic.cardBorder;
  static Color get borderStrong =>
      ThemeRuntime.preset.semantic.cardBorderStrong;
  static Color get cardBorder => border;
  static Color get cardBorderStrong => borderStrong;

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // New system tokens.
  static Color get systemBackground => background;
  static Color get secondarySystemBackground => backgroundLight;
  static Color get tertiarySystemBackground => surface;
  static Color get elevatedBackground => cardRaised;
  static Color get separator => border;
  static Color get opaqueSeparator => borderStrong;
  static Color get onAccent => isDark ? white : const Color(0xFFF9FBFF);

  // Low-noise materials.
  static Color get glassBase => cardBase;
  static Color get glassBorder => border;
  static Color get topBarControlBackground =>
      ThemeRuntime.preset.semantic.topBarControlBackground;
  static Color get topBarControlBorder =>
      ThemeRuntime.preset.semantic.topBarControlBorder;
  static Color get pillBackground =>
      ThemeRuntime.preset.semantic.pillBackground;
  static Color get pillBorder => ThemeRuntime.preset.semantic.pillBorder;
  static Color get inputBackground =>
      ThemeRuntime.preset.semantic.inputBackground;
  static Color get inputBorder => ThemeRuntime.preset.semantic.inputBorder;
  static Color get moduleIconBackground =>
      ThemeRuntime.preset.semantic.moduleIconBackground;
  static Color get dashboardGradientStart =>
      ThemeRuntime.preset.semantic.dashboardGradientStart;
  static Color get dashboardGradientEnd =>
      ThemeRuntime.preset.semantic.dashboardGradientEnd;
  static Color get overlayScrim => ThemeRuntime.preset.semantic.overlayScrim;
  static Color get ambientTint => ThemeRuntime.preset.palette.ambientTint;
  static Color get glassSurfaceSoft =>
      Color.alphaBlend(border.withValues(alpha: 0.48), cardBase);
  static Color get glassSurfaceStrong => Color.alphaBlend(
    borderStrong.withValues(alpha: 0.78),
    cardBackgroundStrong,
  );

  static Color get glassHighlight => Color.alphaBlend(
    white.withValues(alpha: isDark ? 0.14 : 0.34),
    backgroundLight,
  );
  static Color get glassHighlightSoft => Color.alphaBlend(
    white.withValues(alpha: isDark ? 0.08 : 0.22),
    background,
  );

  static Color get glassShadow => switch (themeId) {
    'modern_desert' => const Color(0x2E7B5A35),
    'cloud_studio' => const Color(0x1F42586F),
    _ => isDark ? const Color(0xB1000000) : const Color(0x260E1A2A),
  };
  static Color get glassShadowSoft => switch (themeId) {
    'modern_desert' => const Color(0x1C8A6440),
    'cloud_studio' => const Color(0x143E556D),
    _ => isDark ? const Color(0x6E000000) : const Color(0x180E1A2A),
  };

  static Color get edgeGlow =>
      themeGlow.withValues(alpha: isDark ? themeGlow.a : 0.1);
  static Color get edgeGlowSoft =>
      themeGlow.withValues(alpha: isDark ? 0.12 : 0.06);

  static List<Color> get backdropGradient => [
    background,
    Color.alphaBlend(
      ThemeRuntime.preset.palette.ambientTint.withValues(
        alpha: isDark
            ? ThemeRuntime.preset.palette.ambientTint.a
            : ThemeRuntime.preset.palette.ambientTint.a * 0.4,
      ),
      backgroundLight,
    ),
    background,
  ];

  static List<Color> get floatingGlassGradient => [
    Color.alphaBlend(
      ambientTint.withValues(alpha: isDark ? 0.14 : 0.08),
      cardRaised,
    ),
    Color.alphaBlend(border.withValues(alpha: 0.42), cardBase),
  ];

  static List<Color> get inputGlassGradient => [
    inputBackground,
    Color.alphaBlend(border.withValues(alpha: 0.22), cardBackgroundStrong),
  ];

  // Legacy aliases (for existing feature screens).
  static Color get primaryOrange => accent;
  static Color get orangeDim => accentSoft;
  static Color get accentMuted =>
      accentSoft.withValues(alpha: isDark ? 0.28 : 0.16);
  static Color get liquidGradientStart => buttonGradientStart;
  static Color get liquidGradientEnd => buttonGradientEnd;
  static List<Color> get liquidGradient => buttonGradient;

  static Color get electricCyan => accent;
  static Color get royalPurple => accentSoft;
  static Color get softIndigo => accentSoft;
  static Color get vibrantPink => accent;

  static Color get systemBlue => accent;
  static Color get systemRed => error;

  // Carbon micro-accents: restrained, slightly colored, never neon.
  static const Color _carbonWarmTone = Color(0xFFC9935F);
  static const Color _carbonCoolTone = Color(0xFF88A0B7);
  static const Color _carbonNoteTone = Color(0xFF9990AA);
  static const Color _carbonSageTone = Color(0xFF8EAB97);

  static Color get streakAccent =>
      isCarbonSystem ? _carbonWarmTone : primaryOrange;
  static Color get focusControlAccent =>
      isCarbonSystem ? _carbonCoolTone : accentIcon;
  static Color get notesControlAccent =>
      isCarbonSystem ? _carbonNoteTone : accentIcon;
  static Color get screenTimeDailyAccentBorder => isCarbonSystem
      ? _carbonCoolTone.withValues(alpha: 0.54)
      : selectionOutline;
  static Color get familyCreateAccent =>
      isCarbonSystem ? _carbonWarmTone : accent;
  static Color get habitsWeekAccent =>
      isCarbonSystem ? _carbonSageTone : scoreValue;
  static Color get habitsCompletionAccent =>
      isCarbonSystem ? _carbonSageTone : accent;
  static Color get habitsOpenRingAccent => isCarbonSystem
      ? _carbonSageTone.withValues(alpha: 0.42)
      : white.withValues(alpha: 0.25);
  static Color get habitsTodayRingAccent => isCarbonSystem
      ? _carbonWarmTone.withValues(alpha: 0.72)
      : primaryOrange.withValues(alpha: 0.6);
}
