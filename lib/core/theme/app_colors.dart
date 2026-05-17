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

  static Color get background => ThemeRuntime.preset.colors.background;
  static Color get backgroundElevated =>
      ThemeRuntime.preset.colors.backgroundElevated;
  static Color get backgroundLight => backgroundElevated;
  static Color get surface => ThemeRuntime.preset.colors.surface;
  static Color get surfaceMuted => ThemeRuntime.preset.colors.surfaceMuted;
  static Color get cardBase => ThemeRuntime.preset.colors.cardBase;
  static Color get cardRaised => ThemeRuntime.preset.colors.cardRaised;

  static Color get accent => ThemeRuntime.preset.colors.accent;
  static Color get accentSoft => ThemeRuntime.preset.colors.accentSoft;
  static Color get accentSecondary => Color.lerp(accent, backgroundLight, isDark ? 0.22 : 0.32)!;

  static Color get label => ThemeRuntime.preset.colors.label;
  static Color get secondaryLabel => ThemeRuntime.preset.colors.secondaryLabel;
  static Color get tertiaryLabel => ThemeRuntime.preset.colors.tertiaryLabel;
  static Color get quaternaryLabel => ThemeRuntime.preset.colors.quaternaryLabel;

  static Color get success => ThemeRuntime.preset.colors.success;
  static Color get warning => ThemeRuntime.preset.colors.warning;
  static Color get error => ThemeRuntime.preset.colors.error;

  static Color get chartA => ThemeRuntime.preset.colors.chartA;
  static Color get chartB => ThemeRuntime.preset.colors.chartB;
  static Color get chartC => ThemeRuntime.preset.colors.chartC;
  static Color get chartD => ThemeRuntime.preset.colors.chartD;

  static Color get focusPrimary => ThemeRuntime.preset.colors.focusPrimary;
  static Color get focusSecondary => ThemeRuntime.preset.colors.focusSecondary;
  static Color get ceoPrimary => ThemeRuntime.preset.colors.ceoPrimary;
  static Color get ceoSecondary => ThemeRuntime.preset.colors.ceoSecondary;

  static Color get border => ThemeRuntime.preset.colors.border;
  static Color get borderStrong => ThemeRuntime.preset.colors.borderStrong;

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
  static Color get pillBackground => ThemeRuntime.preset.semantic.pillBackground;
  static Color get pillBorder => ThemeRuntime.preset.semantic.pillBorder;
  static Color get inputBackground => ThemeRuntime.preset.semantic.inputBackground;
  static Color get inputBorder => ThemeRuntime.preset.semantic.inputBorder;
  static Color get moduleIconBackground =>
      ThemeRuntime.preset.semantic.moduleIconBackground;
  static Color get dashboardGradientStart =>
      ThemeRuntime.preset.semantic.dashboardGradientStart;
  static Color get dashboardGradientEnd =>
      ThemeRuntime.preset.semantic.dashboardGradientEnd;
  static Color get overlayScrim => ThemeRuntime.preset.semantic.overlayScrim;
  static Color get ambientTint => ThemeRuntime.preset.palette.ambientTint;
  static Color get glassSurfaceSoft => Color.alphaBlend(
    border.withValues(alpha: 0.48),
    cardBase,
  );
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

  static Color get glassShadow => isDark
      ? const Color(0xB1000000)
      : const Color(0x260E1A2A);
  static Color get glassShadowSoft => isDark
      ? const Color(0x6E000000)
      : const Color(0x180E1A2A);

  static Color get edgeGlow => accent.withValues(alpha: isDark ? 0.18 : 0.1);
  static Color get edgeGlowSoft => accent.withValues(alpha: isDark ? 0.1 : 0.06);

  static List<Color> get backdropGradient => [
    background,
    Color.lerp(background, backgroundLight, 0.58)!,
    background,
  ];

  static List<Color> get floatingGlassGradient => [
    Color.alphaBlend(
      isDark ? const Color(0x08FFFFFF) : const Color(0xCCFFFFFF),
      cardRaised,
    ),
    Color.alphaBlend(
      isDark ? const Color(0x04FFFFFF) : const Color(0xAAFFFFFF),
      cardBase,
    ),
  ];

  static List<Color> get inputGlassGradient => [
    Color.alphaBlend(
      isDark ? const Color(0x0AFFFFFF) : const Color(0xF2FFFFFF),
      surface,
    ),
    Color.alphaBlend(
      isDark ? const Color(0x04FFFFFF) : const Color(0xE8FFFFFF),
      surfaceMuted,
    ),
  ];

  // Legacy aliases (for existing feature screens).
  static Color get primaryOrange => accent;
  static Color get orangeDim => accentSoft;
  static Color get accentMuted => accentSoft.withValues(alpha: isDark ? 0.28 : 0.16);
  static Color get liquidGradientStart => focusPrimary;
  static Color get liquidGradientEnd => focusSecondary;
  static List<Color> get liquidGradient => [focusPrimary, focusSecondary];

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

  // ---- Recovered from Codex session patches (2026-02 to 2026-05) ----
  static Color get _backgroundLight =>
  static Color get _cardGradientStart =>
  static Color get _cardGradientEnd =>
  static Color get _accentSecondary =>
  static Color get _secondaryLabel =>
  static Color get _tertiaryLabel =>
  static Color get _quaternaryLabel =>
  static Color get _opaqueSeparator =>
  static Color get cardGradientStart => _cardGradientStart;
  static Color get cardGradientEnd => _cardGradientEnd;
  static Color get systemGroupedBackground => background;
  static Color get _background => ThemeRuntime.preset.colors.background;
  static Color get _surface => ThemeRuntime.preset.colors.surface;
  static Color get _glassBase => ThemeRuntime.preset.colors.glassBase;
  static Color get _glassBorder => ThemeRuntime.preset.colors.glassBorder;
  static Color get _accent => ThemeRuntime.preset.colors.accent;
  static Color get _label => ThemeRuntime.preset.colors.label;
  static Color get _success => ThemeRuntime.preset.colors.success;
  static Color get _warning => ThemeRuntime.preset.colors.warning;
  static Color get _error => ThemeRuntime.preset.colors.error;
  static Color get _separator => ThemeRuntime.preset.colors.separator;
  static Color get _accentMuted => ThemeRuntime.preset.colors.accentMuted;
  static Color get accentDeep => ThemeRuntime.preset.palette.accentDeep;
  static Color get cardBorderStrong => borderStrong;
  static Color get accentLight => accent.withValues(alpha: 0.18);
  static Color get themeGlow => accent;
  static Color get activeBorder => selectionOutline;
  static Color get toggleOn => success;
  static Color get buttonGradientStart => accent;
  static Color get buttonGradientEnd => accentSecondary;
  static Color get sectionBackground => backgroundLight;
  static Color get cardBackgroundAlt => elevatedBackground;
  static Color get selectionOutline => accent.withValues(alpha: 0.62);
  static Color get accentSurfaceStrong => accent.withValues(alpha: 0.18);
  static Color get accentText => accent;
  static Color get accentIcon => accent;
  static Color get rankAccent => accent;
  static Color get accentSurfaceSoft => accent.withValues(alpha: 0.10);
  static Color get scoreValue => accent;
  static Color get cardBackgroundStrong => glassSurfaceStrong;
  static Color get cardBorder => border;
  static Color get glassSurface => glassSurfaceSoft;
  static Color get info => systemBlue;
  static Color get primaryAccent => accent;
}
