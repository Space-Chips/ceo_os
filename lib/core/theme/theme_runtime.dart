import 'theme_catalog.dart';

class ThemeRuntime {
  ThemeRuntime._();

  static AppThemePreset _preset = ThemeCatalog.resolveById(
    ThemeCatalog.defaultPresetId,
  );

  static AppThemePreset get preset => _preset;

  static void setPreset(AppThemePreset preset) {
    _preset = preset;
  }
}
