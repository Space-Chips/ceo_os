import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'control_center_setup_models.dart';

class ControlCenterSetupStore {
  static const _keySlots = 'control_center.slot_items.v1';
  static const _keyWidgets = 'control_center.enabled_widgets.v1';
  static const _keyCompleted = 'control_center.setup_completed.v1';

  final SharedPreferences _prefs;

  const ControlCenterSetupStore._(this._prefs);

  static Future<ControlCenterSetupStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ControlCenterSetupStore._(prefs);
  }

  String _scopedKey(String base) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return '$base::$userId';
  }

  Future<ControlCenterConfiguration> load() async {
    final slots = _prefs.getStringList(_scopedKey(_keySlots)) ?? const [];
    final widgets = _prefs.getStringList(_scopedKey(_keyWidgets)) ?? const [];
    final completed =
        _prefs.getBool(_scopedKey(_keyCompleted)) ?? false;
    return ControlCenterConfiguration(
      slotItems: slots,
      enabledWidgets: widgets.toSet(),
      setupCompleted: completed,
    );
  }

  Future<void> save(ControlCenterConfiguration configuration) async {
    await _prefs.setStringList(
      _scopedKey(_keySlots),
      configuration.slotItems,
    );
    await _prefs.setStringList(
      _scopedKey(_keyWidgets),
      configuration.enabledWidgets.toList(growable: false),
    );
    await _prefs.setBool(
      _scopedKey(_keyCompleted),
      configuration.setupCompleted,
    );
  }

  Future<void> markSetupCompleted() async {
    await _prefs.setBool(_scopedKey(_keyCompleted), true);
  }
}
