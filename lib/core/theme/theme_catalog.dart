import 'dart:ui';

enum AppThemeTone { dark, light }

enum AppTypographyProfile { neo, technical, editorial }

class AppThemePalette {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderSubtle;
  final Color borderStrong;
  final Color accent;
  final Color accentLight;
  final Color accentDeep;
  final Color accentGlow;
  final Color ambientTint;

  const AppThemePalette({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderSubtle,
    required this.borderStrong,
    required this.accent,
    required this.accentLight,
    required this.accentDeep,
    required this.accentGlow,
    required this.ambientTint,
  });
}

class AppThemeSemanticTokens {
  final Color appBackground;
  final Color sectionBackground;
  final Color cardBackground;
  final Color cardBackgroundAlt;
  final Color cardBackgroundStrong;
  final Color cardBorder;
  final Color cardBorderStrong;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color accentText;
  final Color accentIcon;
  final Color accentBorder;
  final Color accentSurfaceSoft;
  final Color accentSurfaceStrong;
  final Color accentGlow;
  final Color scoreValue;
  final Color progressFill;
  final Color focusRing;
  final Color activeToggle;
  final Color selectionOutline;
  final Color rankAccent;
  final Color topBarControlBackground;
  final Color topBarControlBorder;
  final Color pillBackground;
  final Color pillBorder;
  final Color inputBackground;
  final Color inputBorder;
  final Color moduleIconBackground;
  final Color dashboardGradientStart;
  final Color dashboardGradientEnd;
  final Color overlayScrim;

  const AppThemeSemanticTokens({
    required this.appBackground,
    required this.sectionBackground,
    required this.cardBackground,
    required this.cardBackgroundAlt,
    required this.cardBackgroundStrong,
    required this.cardBorder,
    required this.cardBorderStrong,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.accentText,
    required this.accentIcon,
    required this.accentBorder,
    required this.accentSurfaceSoft,
    required this.accentSurfaceStrong,
    required this.accentGlow,
    required this.scoreValue,
    required this.progressFill,
    required this.focusRing,
    required this.activeToggle,
    required this.selectionOutline,
    required this.rankAccent,
    required this.topBarControlBackground,
    required this.topBarControlBorder,
    required this.pillBackground,
    required this.pillBorder,
    required this.inputBackground,
    required this.inputBorder,
    required this.moduleIconBackground,
    required this.dashboardGradientStart,
    required this.dashboardGradientEnd,
    required this.overlayScrim,
  });
}

class AppThemePreset {
  final String id;
  final String name;
  final String subtitle;
  final AppThemeTone tone;
  final AppTypographyProfile typography;
  final AppThemePalette palette;
  final AppThemeSemanticTokens semantic;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.tone,
    required this.typography,
    required this.palette,
    required this.semantic,
  });

  bool get isDark => tone == AppThemeTone.dark;
}

class ThemeCatalog {
  ThemeCatalog._();

  static const String defaultPresetId = 'carbon_system';

  static final List<AppThemePreset> presets = [
    _buildPreset(
      id: 'carbon_system',
      name: 'Carbon System',
      subtitle: 'Default',
      tone: AppThemeTone.dark,
      typography: AppTypographyProfile.neo,
      palette: const AppThemePalette(
        bgPrimary: Color(0xFF0A0B0D),
        bgSecondary: Color(0xFF111315),
        surfacePrimary: Color(0xFF15181B),
        surfaceSecondary: Color(0xFF1C2024),
        surfaceTertiary: Color(0xFF242A2F),
        textPrimary: Color(0xFFF2F4F6),
        textSecondary: Color(0xFFB6BDC5),
        textTertiary: Color(0xFF808891),
        borderSubtle: Color(0x0DFFFFFF),
        borderStrong: Color(0x1AFFFFFF),
        accent: Color(0xFF9FA6AD),
        accentLight: Color(0xFFC7CDD3),
        accentDeep: Color(0xFF6E757C),
        accentGlow: Color(0x29D2D7DC),
        ambientTint: Color(0x08FFFFFF),
      ),
    ),
    _buildPreset(
      id: 'ember_protocol',
      name: 'Ember Protocol',
      subtitle: 'Protocol dark',
      tone: AppThemeTone.dark,
      typography: AppTypographyProfile.technical,
      palette: const AppThemePalette(
        bgPrimary: Color(0xFF0F0A07),
        bgSecondary: Color(0xFF15100C),
        surfacePrimary: Color(0xFF1A130E),
        surfaceSecondary: Color(0xFF221913),
        surfaceTertiary: Color(0xFF2A1F18),
        textPrimary: Color(0xFFFFF6EE),
        textSecondary: Color(0xFFD8C0B0),
        textTertiary: Color(0xFF9C8475),
        borderSubtle: Color(0x12FFF0E6),
        borderStrong: Color(0x21FFF0E6),
        accent: Color(0xFFFF8A3D),
        accentLight: Color(0xFFFFB078),
        accentDeep: Color(0xFFD56121),
        accentGlow: Color(0x3DFF8A3D),
        ambientTint: Color(0x14FF8E42),
      ),
    ),
    _buildPreset(
      id: 'royal_violet',
      name: 'Royal Violet',
      subtitle: 'Deep premium',
      tone: AppThemeTone.dark,
      typography: AppTypographyProfile.editorial,
      palette: const AppThemePalette(
        bgPrimary: Color(0xFF0D0A14),
        bgSecondary: Color(0xFF141020),
        surfacePrimary: Color(0xFF1A1628),
        surfaceSecondary: Color(0xFF211B34),
        surfaceTertiary: Color(0xFF2B2343),
        textPrimary: Color(0xFFF5F2FF),
        textSecondary: Color(0xFFC9C0E4),
        textTertiary: Color(0xFF9188AD),
        borderSubtle: Color(0x0FFFFFFF),
        borderStrong: Color(0x1CFFFFFF),
        accent: Color(0xFF9B7CFF),
        accentLight: Color(0xFFBBA6FF),
        accentDeep: Color(0xFF6E53D9),
        accentGlow: Color(0x479B7CFF),
        ambientTint: Color(0x1A9B7CFF),
      ),
    ),
    _buildPreset(
      id: 'modern_desert',
      name: 'Modern Desert',
      subtitle: 'Cream modern',
      tone: AppThemeTone.light,
      typography: AppTypographyProfile.editorial,
      palette: const AppThemePalette(
        bgPrimary: Color(0xFFF3E9DA),
        bgSecondary: Color(0xFFE9DDCB),
        surfacePrimary: Color(0xFFF7EFE2),
        surfaceSecondary: Color(0xFFEFE3D2),
        surfaceTertiary: Color(0xFFE3D4BF),
        textPrimary: Color(0xFF2F271F),
        textSecondary: Color(0xFF6C5F54),
        textTertiary: Color(0xFF9D8F82),
        borderSubtle: Color(0x143C2814),
        borderStrong: Color(0x243C2814),
        accent: Color(0xFFC48746),
        accentLight: Color(0xFFD9A971),
        accentDeep: Color(0xFF9F6733),
        accentGlow: Color(0x2EC48746),
        ambientTint: Color(0x10C48746),
      ),
    ),
    _buildPreset(
      id: 'cloud_studio',
      name: 'Cloud Studio',
      subtitle: 'Soft clean',
      tone: AppThemeTone.light,
      typography: AppTypographyProfile.neo,
      palette: const AppThemePalette(
        bgPrimary: Color(0xFFE9EEF3),
        bgSecondary: Color(0xFFDFE6ED),
        surfacePrimary: Color(0xFFF4F7FA),
        surfaceSecondary: Color(0xFFE9EEF4),
        surfaceTertiary: Color(0xFFD7DEE6),
        textPrimary: Color(0xFF1F2933),
        textSecondary: Color(0xFF5E6B79),
        textTertiary: Color(0xFF8A96A3),
        borderSubtle: Color(0x14333242),
        borderStrong: Color(0x24333242),
        accent: Color(0xFF5E88C9),
        accentLight: Color(0xFF88A9DD),
        accentDeep: Color(0xFF3E6BAF),
        accentGlow: Color(0x2E5E88C9),
        ambientTint: Color(0x105E88C9),
      ),
    ),
  ];

  static const Map<String, String> _legacyAliases = {
    'carbon_system': 'carbon_system',
    'graphite_system': 'carbon_system',
    'ember_protocol': 'ember_protocol',
    'royal_violet': 'royal_violet',
    'modern_desert': 'modern_desert',
    'cloud_studio': 'cloud_studio',
    'graphite_blue': 'carbon_system',
    'ember_focus': 'ember_protocol',
    'emerald_system': 'carbon_system',
    'ice_silver': 'cloud_studio',
    'midnight_blue': 'carbon_system',
    'graphite': 'carbon_system',
    'sandstone': 'modern_desert',
    'deep_forest': 'carbon_system',
    'light_premium': 'cloud_studio',
    'obsidian_dark': 'carbon_system',
    'nebula_dark': 'carbon_system',
    'ember_dark': 'ember_protocol',
    'obsidian_light': 'cloud_studio',
    'nebula_light': 'cloud_studio',
    'ember_light': 'modern_desert',
  };

  static AppThemePreset resolveById(String? id) {
    if (id == null || id.isEmpty) return presets.first;
    final resolvedId = _legacyAliases[id] ?? id;
    return presets.firstWhere(
      (preset) => preset.id == resolvedId,
      orElse: () => presets.first,
    );
  }

  static AppThemePreset _buildPreset({
    required String id,
    required String name,
    required String subtitle,
    required AppThemeTone tone,
    required AppTypographyProfile typography,
    required AppThemePalette palette,
  }) {
    Color blendOnSurface(Color color, Color surface, double amount) =>
        Color.alphaBlend(color.withValues(alpha: amount), surface);

    final accentBorder = switch (id) {
      'carbon_system' => palette.accent.withValues(alpha: 0.22),
      'ember_protocol' => palette.accent.withValues(alpha: 0.3),
      'royal_violet' => palette.accent.withValues(alpha: 0.34),
      'modern_desert' => palette.accentDeep.withValues(alpha: 0.24),
      'cloud_studio' => palette.accentDeep.withValues(alpha: 0.22),
      _ => palette.accent.withValues(alpha: 0.35),
    };

    final accentSurfaceSoft = switch (id) {
      'carbon_system' => blendOnSurface(
          palette.accentLight,
          palette.surfacePrimary,
          0.035,
        ),
      'ember_protocol' => blendOnSurface(
          palette.accent,
          palette.surfacePrimary,
          0.07,
        ),
      'royal_violet' => blendOnSurface(
          palette.accent,
          palette.surfacePrimary,
          0.085,
        ),
      'modern_desert' => blendOnSurface(
          palette.accentLight,
          palette.surfacePrimary,
          0.055,
        ),
      'cloud_studio' => blendOnSurface(
          palette.accentLight,
          palette.surfacePrimary,
          0.05,
        ),
      _ => Color.alphaBlend(palette.ambientTint, palette.surfacePrimary),
    };

    final accentSurfaceStrong = switch (id) {
      'carbon_system' => blendOnSurface(
          palette.accent,
          palette.surfaceSecondary,
          0.07,
        ),
      'ember_protocol' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.12,
        ),
      'royal_violet' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.13,
        ),
      'modern_desert' => blendOnSurface(
          palette.accent,
          palette.surfaceSecondary,
          0.08,
        ),
      'cloud_studio' => blendOnSurface(
          palette.accent,
          palette.surfaceSecondary,
          0.075,
        ),
      _ => Color.alphaBlend(
          palette.accentGlow.withValues(alpha: 0.16),
          palette.surfaceSecondary,
        ),
    };

    final topBarControlBackground = switch (id) {
      'carbon_system' => blendOnSurface(
          palette.textPrimary,
          palette.surfaceSecondary,
          0.018,
        ),
      'ember_protocol' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.05,
        ),
      'royal_violet' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.055,
        ),
      'modern_desert' => blendOnSurface(
          palette.textPrimary,
          palette.surfaceSecondary,
          0.028,
        ),
      'cloud_studio' => blendOnSurface(
          palette.textPrimary,
          palette.surfaceSecondary,
          0.022,
        ),
      _ => Color.alphaBlend(
          palette.borderSubtle.withValues(alpha: 0.85),
          palette.surfaceSecondary,
        ),
    };

    final pillBackground = switch (id) {
      'carbon_system' => blendOnSurface(
          palette.textPrimary,
          palette.surfacePrimary,
          0.018,
        ),
      'ember_protocol' => blendOnSurface(
          palette.accentDeep,
          palette.surfacePrimary,
          0.045,
        ),
      'royal_violet' => blendOnSurface(
          palette.accentDeep,
          palette.surfacePrimary,
          0.048,
        ),
      'modern_desert' => blendOnSurface(
          palette.textPrimary,
          palette.surfacePrimary,
          0.026,
        ),
      'cloud_studio' => blendOnSurface(
          palette.textPrimary,
          palette.surfacePrimary,
          0.02,
        ),
      _ => Color.alphaBlend(
          palette.borderSubtle.withValues(
            alpha: tone == AppThemeTone.dark ? 0.72 : 0.44,
          ),
          palette.surfacePrimary,
        ),
    };

    final inputBackground = switch (id) {
      'carbon_system' => blendOnSurface(
          palette.textPrimary,
          palette.surfaceSecondary,
          0.02,
        ),
      'ember_protocol' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.035,
        ),
      'royal_violet' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.04,
        ),
      'modern_desert' => blendOnSurface(
          palette.textPrimary,
          palette.surfaceSecondary,
          0.03,
        ),
      'cloud_studio' => blendOnSurface(
          palette.textPrimary,
          palette.surfaceSecondary,
          0.024,
        ),
      _ => Color.alphaBlend(
          palette.borderSubtle.withValues(
            alpha: tone == AppThemeTone.dark ? 0.62 : 0.36,
          ),
          palette.surfaceSecondary,
        ),
    };

    final dashboardGradientStart = switch (id) {
      'carbon_system' => blendOnSurface(
          palette.textPrimary,
          palette.surfaceSecondary,
          0.025,
        ),
      'ember_protocol' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.04,
        ),
      'royal_violet' => blendOnSurface(
          palette.accentDeep,
          palette.surfaceSecondary,
          0.055,
        ),
      'modern_desert' => blendOnSurface(
          palette.accentLight,
          palette.surfaceSecondary,
          0.035,
        ),
      'cloud_studio' => blendOnSurface(
          palette.accentLight,
          palette.surfaceSecondary,
          0.028,
        ),
      _ => palette.surfaceSecondary,
    };

    final dashboardGradientEnd = switch (id) {
      'carbon_system' => blendOnSurface(
          palette.textPrimary,
          palette.surfacePrimary,
          0.01,
        ),
      'ember_protocol' => blendOnSurface(
          palette.accent,
          palette.surfacePrimary,
          0.018,
        ),
      'royal_violet' => blendOnSurface(
          palette.accent,
          palette.surfacePrimary,
          0.024,
        ),
      'modern_desert' => blendOnSurface(
          palette.accentLight,
          palette.surfacePrimary,
          0.02,
        ),
      'cloud_studio' => blendOnSurface(
          palette.accentLight,
          palette.surfacePrimary,
          0.016,
        ),
      _ => palette.surfacePrimary,
    };

    final overlayScrim = switch (id) {
      'carbon_system' => const Color(0x9E000000),
      'ember_protocol' => const Color(0xA3000000),
      'royal_violet' => const Color(0xA6100A1B),
      'modern_desert' => const Color(0x45281C12),
      'cloud_studio' => const Color(0x3C2A3642),
      _ => tone == AppThemeTone.dark
          ? const Color(0xA6000000)
          : const Color(0x52101A24),
    };

    final scoreValue = switch (id) {
      'carbon_system' => palette.accentLight,
      'ember_protocol' => palette.accentLight,
      'royal_violet' => palette.accentLight,
      'modern_desert' => palette.accentDeep,
      'cloud_studio' => palette.accentDeep,
      _ => palette.accent,
    };

    final semantic = AppThemeSemanticTokens(
      appBackground: palette.bgPrimary,
      sectionBackground: palette.bgSecondary,
      cardBackground: palette.surfacePrimary,
      cardBackgroundAlt: palette.surfaceSecondary,
      cardBackgroundStrong: palette.surfaceTertiary,
      cardBorder: palette.borderSubtle,
      cardBorderStrong: palette.borderStrong,
      primaryText: palette.textPrimary,
      secondaryText: palette.textSecondary,
      tertiaryText: palette.textTertiary,
      accentText: palette.accent,
      accentIcon: palette.accent,
      accentBorder: accentBorder,
      accentSurfaceSoft: accentSurfaceSoft,
      accentSurfaceStrong: accentSurfaceStrong,
      accentGlow: palette.accentGlow,
      scoreValue: scoreValue,
      progressFill: palette.accent,
      focusRing: palette.accent,
      activeToggle: palette.accent,
      selectionOutline: palette.accent.withValues(alpha: 0.42),
      rankAccent: palette.accentLight,
      topBarControlBackground: topBarControlBackground,
      topBarControlBorder: palette.borderStrong,
      pillBackground: pillBackground,
      pillBorder: palette.borderStrong,
      inputBackground: inputBackground,
      inputBorder: palette.borderStrong,
      moduleIconBackground: Color.alphaBlend(
        palette.borderStrong.withValues(
          alpha: tone == AppThemeTone.dark ? 0.34 : 0.2,
        ),
        palette.surfaceSecondary,
      ),
      dashboardGradientStart: dashboardGradientStart,
      dashboardGradientEnd: dashboardGradientEnd,
      overlayScrim: overlayScrim,
    );

    return AppThemePreset(
      id: id,
      name: name,
      subtitle: subtitle,
      tone: tone,
      typography: typography,
      palette: palette,
      semantic: semantic,
    );
  }
}
