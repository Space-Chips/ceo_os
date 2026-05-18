import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

enum FocusPermissionState { unknown, approved, notDetermined, denied, unsupported }

class FocusProtectionStatus {
  final FocusPermissionState permissionState;

  const FocusProtectionStatus({required this.permissionState});

  static const unknown = FocusProtectionStatus(
    permissionState: FocusPermissionState.unknown,
  );

  bool get isAuthorized => permissionState == FocusPermissionState.approved;
  bool get isSupported => permissionState != FocusPermissionState.unsupported;
  bool get shouldPrompt =>
      permissionState == FocusPermissionState.notDetermined ||
      permissionState == FocusPermissionState.unknown;
  bool get shouldOpenSettings =>
      permissionState == FocusPermissionState.denied;

  factory FocusProtectionStatus.fromNativeStatus(String? rawStatus) {
    switch ((rawStatus ?? '').trim().toLowerCase()) {
      case 'approved':
        return const FocusProtectionStatus(
          permissionState: FocusPermissionState.approved,
        );
      case 'not_determined':
        return const FocusProtectionStatus(
          permissionState: FocusPermissionState.notDetermined,
        );
      case 'denied':
        return const FocusProtectionStatus(
          permissionState: FocusPermissionState.denied,
        );
      case 'unsupported':
      case 'unsupported_os':
        return const FocusProtectionStatus(
          permissionState: FocusPermissionState.unsupported,
        );
      default:
        return FocusProtectionStatus.unknown;
    }
  }
}

class AndroidLaunchableApp {
  final String name;
  final String packageName;
  final Uint8List? iconBytes;

  const AndroidLaunchableApp({
    required this.name,
    required this.packageName,
    this.iconBytes,
  });

  factory AndroidLaunchableApp.fromJson(Map<Object?, Object?> json) {
    final rawIcon = json['icon'];
    return AndroidLaunchableApp(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : ((json['packageName'] as String?)?.trim() ?? 'App'),
      packageName: (json['packageName'] as String?)?.trim() ?? '',
      iconBytes: rawIcon is Uint8List ? rawIcon : null,
    );
  }
}

class FocusService {
  static const MethodChannel _channel = MethodChannel('com.ceoos.app/focus');
  static final Set<String> _missingNativeMethods = <String>{};

  bool _shouldSkipMissingMethod(String method) {
    return _missingNativeMethods.contains(method);
  }

  void _markMissingMethod(String method) {
    if (_missingNativeMethods.add(method)) {
      AppLogger.warning(
        "Native $method method missing in the current runtime. Stop the app completely and relaunch it; hot restart does not load new native channel methods.",
      );
    }
  }

  // Request permissions for Accessibility (Android) or Family Controls (iOS)
  Future<bool> requestPermissions() async {
    const method = 'requestPermissions';
    if (_shouldSkipMissingMethod(method)) return false;
    try {
      final bool result = await _channel.invokeMethod(method);
      return result;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to request permissions: '${e.message}'.");
      return false;
    } on MissingPluginException {
      _markMissingMethod(method);
      return false;
    }
  }

  // Check if authorized
  Future<bool> isAuthorized() async {
    const method = 'isAuthorized';
    if (_shouldSkipMissingMethod(method)) return false;
    try {
      final bool result = await _channel.invokeMethod(method);
      return result;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to check authorization: '${e.message}'.");
      return false;
    } on MissingPluginException {
      _markMissingMethod(method);
      return false;
    }
  }

  Future<FocusProtectionStatus> getProtectionStatus() async {
    const method = 'getAuthorizationStatus';
    if (_shouldSkipMissingMethod(method)) {
      final authorized = await isAuthorized();
      return authorized
          ? const FocusProtectionStatus(
              permissionState: FocusPermissionState.approved,
            )
          : FocusProtectionStatus.unknown;
    }
    try {
      final String? result = await _channel.invokeMethod<String>(method);
      return FocusProtectionStatus.fromNativeStatus(result);
    } on PlatformException catch (e) {
      AppLogger.error("Failed to read protection status: '${e.message}'.");
      final authorized = await isAuthorized();
      return authorized
          ? const FocusProtectionStatus(
              permissionState: FocusPermissionState.approved,
            )
          : FocusProtectionStatus.unknown;
    } on MissingPluginException {
      _markMissingMethod(method);
      final authorized = await isAuthorized();
      return authorized
          ? const FocusProtectionStatus(
              permissionState: FocusPermissionState.approved,
            )
          : FocusProtectionStatus.unknown;
    }
  }

  Future<bool> openSystemSettings() async {
    const method = 'openSystemSettings';
    if (_shouldSkipMissingMethod(method)) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>(method);
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to open system settings: '${e.message}'.");
      return false;
    } on MissingPluginException {
      _markMissingMethod(method);
      return false;
    }
  }

  // Start shielding specific apps/categories
  Future<void> startShield(
    List<String> packageNames,
    List<String> categories,
  ) async {
    const method = 'startShield';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method, {
        'packages': packageNames,
        'categories': categories,
      });
    } on PlatformException catch (e) {
      AppLogger.error("Failed to start shield: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  // Persist iOS FamilyActivity selection natively without turning shield on.
  Future<void> cacheSelection(
    List<String> packageNames,
    List<String> categories,
  ) async {
    const method = 'cacheSelection';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method, {
        'packages': packageNames,
        'categories': categories,
      });
    } on PlatformException catch (e) {
      AppLogger.error("Failed to cache selection: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  Future<void> syncClassicShieldConfig(
    List<String> packageNames,
    List<String> categories, {
    List<String> websiteDomains = const [],
  }) async {
    const method = 'syncClassicShieldConfig';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method, {
        'packages': packageNames,
        'categories': categories,
        'websites': websiteDomains,
      });
    } on PlatformException catch (e) {
      AppLogger.error("Failed to sync classic shield config: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  Future<void> setClassicShieldEnabled(bool enabled) async {
    const method = 'setClassicShieldEnabled';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method, {'enabled': enabled});
    } on PlatformException catch (e) {
      AppLogger.error("Failed to toggle classic shield: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  Future<void> syncClassicPauseSchedule(
    List<String> packageNames,
    List<String> categories,
    List<Map<String, dynamic>> periods, {
    List<String> websiteDomains = const [],
  }) async {
    const method = 'syncClassicPauseSchedule';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method, {
        'packages': packageNames,
        'categories': categories,
        'websites': websiteDomains,
        'periods': periods,
      });
    } on PlatformException catch (e) {
      AppLogger.error("Failed to sync classic pause schedule: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  Future<void> syncClassicDailyLimits(
    List<Map<String, dynamic>> entries,
  ) async {
    const method = 'syncClassicDailyLimits';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method, {'entries': entries});
    } on PlatformException catch (e) {
      AppLogger.error("Failed to sync classic daily limits: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  // Start a strict CEO shield profile (platform specific).
  Future<bool> startCeoShield() async {
    const method = 'startCeoShield';
    if (_shouldSkipMissingMethod(method)) return false;
    try {
      await _channel.invokeMethod(method);
      return true;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to start CEO shield: '${e.message}'.");
      return false;
    } on MissingPluginException {
      _markMissingMethod(method);
      return false;
    }
  }

  // Stop shielding
  Future<void> stopShield() async {
    const method = 'stopShield';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method);
    } on PlatformException catch (e) {
      AppLogger.error("Failed to stop shield: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  // Check if shield is active
  Future<bool> isShieldActive() async {
    const method = 'isShieldActive';
    if (_shouldSkipMissingMethod(method)) return false;
    try {
      final bool result = await _channel.invokeMethod(method);
      return result;
    } on PlatformException catch (e) {
      AppLogger.error("Failed to check shield status: '${e.message}'.");
      return false;
    } on MissingPluginException {
      _markMissingMethod(method);
      return false;
    }
  }

  // Sync planned focus sessions to native iOS scheduler (notifications + reminders).
  Future<void> syncPlannedSessions(List<Map<String, dynamic>> sessions) async {
    const method = 'syncPlannedSessions';
    if (_shouldSkipMissingMethod(method)) return;
    try {
      await _channel.invokeMethod(method, {'sessions': sessions});
    } on PlatformException catch (e) {
      AppLogger.error("Failed to sync planned sessions: '${e.message}'.");
    } on MissingPluginException {
      _markMissingMethod(method);
    }
  }

  // iOS only: Open Family Activity Picker
  Future<List<String>?> openFamilyActivityPicker() async {
    const method = 'openFamilyActivityPicker';
    if (_shouldSkipMissingMethod(method)) return null;
    try {
      // Returns a list of opaque tokens representing selected apps/categories
      final List<dynamic>? result = await _channel.invokeMethod(method);
      return result?.cast<String>();
    } on PlatformException catch (e) {
      AppLogger.error("Failed to open picker: '${e.message}'.");
      return null;
    } on MissingPluginException {
      _markMissingMethod(method);
      return null;
    }
  }

  Future<List<AndroidLaunchableApp>> listAndroidLaunchableApps() async {
    const method = 'listLaunchableApps';
    if (_shouldSkipMissingMethod(method)) return const [];
    try {
      final List<dynamic>? result = await _channel.invokeMethod(method);
      if (result == null) return const [];
      return result
          .whereType<Map<Object?, Object?>>()
          .map(AndroidLaunchableApp.fromJson)
          .where((app) => app.packageName.isNotEmpty)
          .toList(growable: false);
    } on PlatformException catch (e) {
      AppLogger.error("Failed to list launchable apps: '${e.message}'.");
      return const [];
    } on MissingPluginException {
      _markMissingMethod(method);
      return const [];
    }
  }
}
