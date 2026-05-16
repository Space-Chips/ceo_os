import 'dart:ui';
import 'theme_runtime.dart';

/// Dynamic app color access bound to the active theme preset.
class AppColors {
  AppColors._();

  static bool get isDark => ThemeRuntime.preset.isDark;

  static Color get _background => ThemeRuntime.preset.colors.background;
  static Color get _backgroundLight =>
      ThemeRuntime.preset.colors.backgroundLight;
  static Color get _surface => ThemeRuntime.preset.colors.surface;
  static Color get _glassBase => ThemeRuntime.preset.colors.glassBase;
  static Color get _glassBorder => ThemeRuntime.preset.colors.glassBorder;
  static Color get _cardGradientStart =>
      ThemeRuntime.preset.colors.cardGradientStart;
  static Color get _cardGradientEnd =>
      ThemeRuntime.preset.colors.cardGradientEnd;
  static Color get _accent => ThemeRuntime.preset.colors.accent;
  static Color get _accentSecondary =>
      ThemeRuntime.preset.colors.accentSecondary;
  static Color get _label => ThemeRuntime.preset.colors.label;
  static Color get _secondaryLabel =>
      ThemeRuntime.preset.colors.secondaryLabel;
  static Color get _tertiaryLabel =>
      ThemeRuntime.preset.colors.tertiaryLabel;
  static Color get _quaternaryLabel =>
      ThemeRuntime.preset.colors.quaternaryLabel;
  static Color get _success => ThemeRuntime.preset.colors.success;
  static Color get _warning => ThemeRuntime.preset.colors.warning;
  static Color get _error => ThemeRuntime.preset.colors.error;
  static Color get _separator => ThemeRuntime.preset.colors.separator;
  static Color get _opaqueSeparator =>
      ThemeRuntime.preset.colors.opaqueSeparator;
  static Color get _accentMuted => ThemeRuntime.preset.colors.accentMuted;

  static Color get background => _background;
  static Color get backgroundLight => _backgroundLight;
  static Color get surface => _surface;
  static Color get glassBase => _glassBase;
  static Color get glassBorder => _glassBorder;
  static Color get cardGradientStart => _cardGradientStart;
  static Color get cardGradientEnd => _cardGradientEnd;

  static Color get primaryOrange => _accent;
  static Color get orangeDim => _accentSecondary;

  static Color get accent => _accent;
  static Color get accentSecondary => _accentSecondary;
  static const Color white = Color(0xFFFFFFFF);

  static Color get label => _label;
  static Color get secondaryLabel => _secondaryLabel;
  static Color get tertiaryLabel => _tertiaryLabel;
  static Color get quaternaryLabel => _quaternaryLabel;

  static Color get success => _success;
  static Color get warning => _warning;
  static Color get error => _error;
  static Color get systemRed => _error;

  static List<Color> get liquidGradient => [primaryOrange, orangeDim];
  static List<Color> get glassGradient => [cardGradientStart, cardGradientEnd];

  static Color get electricCyan => primaryOrange;
  static Color get royalPurple => orangeDim;
  static Color get softIndigo => orangeDim;
  static Color get vibrantPink => primaryOrange;

  static Color get systemBackground => background;
  static Color get secondarySystemBackground => backgroundLight;
  static Color get tertiarySystemBackground => surface;
  static Color get systemGroupedBackground => background;
  static Color get separator => _separator;
  static Color get opaqueSeparator => _opaqueSeparator;
  static Color get systemBlue => primaryOrange;
  static Color get accentMuted => _accentMuted;
  static const Color black = Color(0xFF000000);

  static Color get onAccent =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF090909);

  static Color get elevatedBackground => Color.lerp(
        backgroundLight,
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        isDark ? 0.06 : 0.04,
      )!;

  static Color get glassSurfaceStrong =>
      isDark ? const Color(0x38FFFFFF) : const Color(0xD9FFFFFF);
  static Color get glassSurfaceSoft =>
      isDark ? const Color(0x22FFFFFF) : const Color(0xC2FFFFFF);

  static Color get glassHighlight =>
      isDark ? const Color(0x66FFFFFF) : const Color(0x73FFFFFF);
  static Color get glassHighlightSoft =>
      isDark ? const Color(0x2EFFFFFF) : const Color(0x59FFFFFF);

  static Color get glassShadow =>
      isDark ? const Color(0xA6000000) : const Color(0x29000000);
  static Color get glassShadowSoft =>
      isDark ? const Color(0x66000000) : const Color(0x1A000000);

  static Color get edgeGlow => accent.withValues(alpha: isDark ? 0.24 : 0.14);
  static Color get edgeGlowSoft =>
      accentSecondary.withValues(alpha: isDark ? 0.16 : 0.1);

  static List<Color> get backdropGradient => [
        background,
        backgroundLight.withValues(alpha: isDark ? 0.95 : 0.92),
        background,
      ];

  static List<Color> get floatingGlassGradient => [
        glassSurfaceStrong,
        glassSurfaceSoft,
      ];

  static List<Color> get inputGlassGradient => [
        isDark
            ? const Color(0x2EFFFFFF)
            : const Color(0xF0FFFFFF),
        isDark
            ? const Color(0x14FFFFFF)
            : const Color(0xD9FFFFFF),
      ];

  static Color get border => glassBorder;
  static Color get borderStrong =>
      isDark ? const Color(0x42FFFFFF) : const Color(0x33000000);
  static Color get cardBase => surface;
  static Color get cardBackgroundAlt => elevatedBackground;
  static Color get cardBackgroundStrong => glassSurfaceStrong;
  static Color get cardRaised => elevatedBackground;
  static Color get cardBorder => border;
  static Color get sectionBackground => backgroundLight;
  static Color get surfaceMuted => backgroundLight;
  static Color get glassSurface => glassSurfaceSoft;
  static Color get overlayScrim => black;
  static Color get topBarControlBackground => glassSurfaceSoft;
  static Color get topBarControlBorder => border;
  static Color get inputBackground => glassSurfaceSoft;
  static Color get inputBorder => border;
  static Color get pillBackground => glassSurfaceSoft;
  static Color get pillBorder => border;
  static Color get moduleIconBackground => accent.withValues(alpha: 0.12);
  static Color get selectionOutline => accent.withValues(alpha: 0.62);
  static Color get activeBorder => selectionOutline;
  static Color get themeGlow => accent;
  static Color get rankAccent => accent;
  static Color get scoreValue => accent;
  static Color get toggleOn => success;
  static Color get info => systemBlue;
  static Color get accentText => accent;
  static Color get accentIcon => accent;
  static Color get accentLight => accent.withValues(alpha: 0.18);
  static Color get accentSoft => accent.withValues(alpha: 0.12);
  static Color get accentSurfaceSoft => accent.withValues(alpha: 0.10);
  static Color get accentSurfaceStrong => accent.withValues(alpha: 0.18);
  static Color get primaryAccent => accent;
  static Color get focusPrimary => accent;
  static Color get focusSecondary => accentSecondary;
  static Color get buttonGradientStart => accent;
  static Color get buttonGradientEnd => accentSecondary;
  static List<Color> get buttonGradient => [buttonGradientStart, buttonGradientEnd];
  static Color get dashboardGradientStart => background;
  static Color get dashboardGradientEnd => backgroundLight;
}
