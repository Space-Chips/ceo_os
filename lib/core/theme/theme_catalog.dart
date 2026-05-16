import 'dart:ui';

enum AppThemeTone { dark, light }

enum AppTypographyProfile { neo, technical, editorial }

class AppColorPalette {
  final Color background;
  final Color backgroundLight;
  final Color surface;
  final Color glassBase;
  final Color glassBorder;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color accent;
  final Color accentSecondary;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color quaternaryLabel;
  final Color success;
  final Color warning;
  final Color error;
  final Color separator;
  final Color opaqueSeparator;
  final Color accentMuted;

  const AppColorPalette({
    required this.background,
    required this.backgroundLight,
    required this.surface,
    required this.glassBase,
    required this.glassBorder,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.accent,
    required this.accentSecondary,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.quaternaryLabel,
    required this.success,
    required this.warning,
    required this.error,
    required this.separator,
    required this.opaqueSeparator,
    required this.accentMuted,
  });

  // Compatibility aliases used by legacy preview/UI code.
}

class AppThemePreset {
  final String id;
  final String name;
  final String subtitle;
  final AppThemeTone tone;
  final AppTypographyProfile typography;
  final AppColorPalette colors;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.tone,
    required this.typography,
    required this.colors,
  });

  bool get isDark => tone == AppThemeTone.dark;
}

class ThemeCatalog {
  ThemeCatalog._();

  static const String defaultPresetId = 'obsidian_dark';

  static const List<AppThemePreset> presets = [
    AppThemePreset(
      id: 'obsidian_dark',
      name: 'Obsidian',
      subtitle: 'Current dark',
      tone: AppThemeTone.dark,
      typography: AppTypographyProfile.neo,
      colors: AppColorPalette(
        background: Color(0xFF000000),
        backgroundLight: Color(0xFF0F0F0F),
        surface: Color(0xFF141414),
        glassBase: Color(0x1A1A1A1A),
        glassBorder: Color(0x1FFFFFFF),
        cardGradientStart: Color(0x14FFFFFF),
        cardGradientEnd: Color(0x05FFFFFF),
        accent: Color(0xFFFF5500),
        accentSecondary: Color(0xFFCC4400),
        label: Color(0xFFFFFFFF),
        secondaryLabel: Color(0x99FFFFFF),
        tertiaryLabel: Color(0x66FFFFFF),
        quaternaryLabel: Color(0x33FFFFFF),
        success: Color(0xFF30D158),
        warning: Color(0xFFFF5500),
        error: Color(0xFFFF453A),
        separator: Color(0x1FFFFFFF),
        opaqueSeparator: Color(0x33FFFFFF),
        accentMuted: Color(0x33FF5500),
      ),
    ),
    AppThemePreset(
      id: 'nebula_dark',
      name: 'Nebula',
      subtitle: 'Ink + cyan',
      tone: AppThemeTone.dark,
      typography: AppTypographyProfile.technical,
      colors: AppColorPalette(
        background: Color(0xFF070A14),
        backgroundLight: Color(0xFF10192A),
        surface: Color(0xFF162238),
        glassBase: Color(0x1A0E1A2B),
        glassBorder: Color(0x3394C1FF),
        cardGradientStart: Color(0x2694C1FF),
        cardGradientEnd: Color(0x0D94C1FF),
        accent: Color(0xFF4DB7FF),
        accentSecondary: Color(0xFF2E7EB7),
        label: Color(0xFFF4F8FF),
        secondaryLabel: Color(0xB3C6D3EA),
        tertiaryLabel: Color(0x809BAFCC),
        quaternaryLabel: Color(0x4D8B99B0),
        success: Color(0xFF3DDC97),
        warning: Color(0xFFFFCC66),
        error: Color(0xFFFF6B6B),
        separator: Color(0x3394C1FF),
        opaqueSeparator: Color(0x4D94C1FF),
        accentMuted: Color(0x334DB7FF),
      ),
    ),
    AppThemePreset(
      id: 'ember_dark',
      name: 'Ember',
      subtitle: 'Coal + crimson',
      tone: AppThemeTone.dark,
      typography: AppTypographyProfile.editorial,
      colors: AppColorPalette(
        background: Color(0xFF100B0B),
        backgroundLight: Color(0xFF1A1313),
        surface: Color(0xFF211818),
        glassBase: Color(0x1A2A1F1F),
        glassBorder: Color(0x33E69A9A),
        cardGradientStart: Color(0x26E69A9A),
        cardGradientEnd: Color(0x0DE69A9A),
        accent: Color(0xFFFF7262),
        accentSecondary: Color(0xFFCC5649),
        label: Color(0xFFFFF6F5),
        secondaryLabel: Color(0xB3E8CECA),
        tertiaryLabel: Color(0x809E8B88),
        quaternaryLabel: Color(0x4D9A7E7A),
        success: Color(0xFF66D18F),
        warning: Color(0xFFFFC06A),
        error: Color(0xFFFF5A5F),
        separator: Color(0x33E69A9A),
        opaqueSeparator: Color(0x4DE69A9A),
        accentMuted: Color(0x33FF7262),
      ),
    ),
    AppThemePreset(
      id: 'obsidian_light',
      name: 'Obsidian Light',
      subtitle: 'Current light counterpart',
      tone: AppThemeTone.light,
      typography: AppTypographyProfile.neo,
      colors: AppColorPalette(
        background: Color(0xFFF7F7F8),
        backgroundLight: Color(0xFFEDEEF0),
        surface: Color(0xFFFFFFFF),
        glassBase: Color(0xF2FFFFFF),
        glassBorder: Color(0x26000000),
        cardGradientStart: Color(0x14FFFFFF),
        cardGradientEnd: Color(0x08FFFFFF),
        accent: Color(0xFFE24E00),
        accentSecondary: Color(0xFFB33E00),
        label: Color(0xFF0D0D0E),
        secondaryLabel: Color(0xB31D1D1F),
        tertiaryLabel: Color(0x80262629),
        quaternaryLabel: Color(0x4D343438),
        success: Color(0xFF23884A),
        warning: Color(0xFFE24E00),
        error: Color(0xFFD7443E),
        separator: Color(0x26000000),
        opaqueSeparator: Color(0x33000000),
        accentMuted: Color(0x33E24E00),
      ),
    ),
    AppThemePreset(
      id: 'nebula_light',
      name: 'Nebula Light',
      subtitle: 'Mist + azure counterpart',
      tone: AppThemeTone.light,
      typography: AppTypographyProfile.technical,
      colors: AppColorPalette(
        background: Color(0xFFF3F8FF),
        backgroundLight: Color(0xFFE4EEFB),
        surface: Color(0xFFFFFFFF),
        glassBase: Color(0xF2FFFFFF),
        glassBorder: Color(0x3394A4C7),
        cardGradientStart: Color(0x1F7AA8F5),
        cardGradientEnd: Color(0x0D7AA8F5),
        accent: Color(0xFF1D6FD6),
        accentSecondary: Color(0xFF1656A6),
        label: Color(0xFF0A1A33),
        secondaryLabel: Color(0xB3142C4D),
        tertiaryLabel: Color(0x80364A68),
        quaternaryLabel: Color(0x4D4E617D),
        success: Color(0xFF2A9D67),
        warning: Color(0xFFC67620),
        error: Color(0xFFC64A5E),
        separator: Color(0x3394A4C7),
        opaqueSeparator: Color(0x4D94A4C7),
        accentMuted: Color(0x331D6FD6),
      ),
    ),
    AppThemePreset(
      id: 'ember_light',
      name: 'Ember Light',
      subtitle: 'Ivory + coral counterpart',
      tone: AppThemeTone.light,
      typography: AppTypographyProfile.editorial,
      colors: AppColorPalette(
        background: Color(0xFFFFF7F4),
        backgroundLight: Color(0xFFFDEAE4),
        surface: Color(0xFFFFFFFF),
        glassBase: Color(0xF2FFFFFF),
        glassBorder: Color(0x33D9A49A),
        cardGradientStart: Color(0x26FFB09E),
        cardGradientEnd: Color(0x0DFFB09E),
        accent: Color(0xFFD95845),
        accentSecondary: Color(0xFFAA4133),
        label: Color(0xFF2B1611),
        secondaryLabel: Color(0xB350352E),
        tertiaryLabel: Color(0x8067524A),
        quaternaryLabel: Color(0x4D80685E),
        success: Color(0xFF2D9A62),
        warning: Color(0xFFB8701A),
        error: Color(0xFFB53F3F),
        separator: Color(0x33D9A49A),
        opaqueSeparator: Color(0x4DD9A49A),
        accentMuted: Color(0x33D95845),
      ),
    ),
  ];

  static AppThemePreset resolveById(String? id) {
    if (id == null) return presets.first;
    return presets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => presets.first,
    );
  }
}
