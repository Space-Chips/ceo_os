import 'package:flutter/services.dart';
import 'dart:typed_data';

enum FocusPermissionState { unknown, approved, denied, unsupported }

enum AndroidProtectionStep { unknown, overlay, usageAccess, accessibility, complete }

class FocusProtectionStatus {
  final bool isSupported;
  final bool isAuthorized;
  final bool shouldOpenSettings;
  final AndroidProtectionStep nextStep;
  final FocusPermissionState permissionState;
  bool get shouldPrompt => isSupported && !isAuthorized;

  const FocusProtectionStatus({
    this.isSupported = true,
    this.isAuthorized = false,
    this.shouldOpenSettings = false,
    this.nextStep = AndroidProtectionStep.overlay,
    this.permissionState = FocusPermissionState.unknown,
  });

  static const unknown = FocusProtectionStatus(
    isSupported: true,
    isAuthorized: false,
    shouldOpenSettings: false,
    nextStep: AndroidProtectionStep.overlay,
  );

  static const authorized = FocusProtectionStatus(
    isSupported: true,
    isAuthorized: true,
    shouldOpenSettings: false,
    nextStep: AndroidProtectionStep.complete,
  );
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

  factory AndroidLaunchableApp.fromMap(Map<String, dynamic> map) {
    final icon = map['iconBytes'] ?? map['icon'];
    return AndroidLaunchableApp(
      name: (map['name'] ?? map['label'] ?? map['packageName'] ?? '').toString(),
      packageName: (map['packageName'] ?? map['package'] ?? '').toString(),
      iconBytes: icon is Uint8List ? icon : null,
    );
  }
}

class FocusService {
  static const MethodChannel _channel = MethodChannel('com.ceoos.app/focus');

  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to request permissions: '${e.message}'.");
      return false;
    } on MissingPluginException {
      print('Native permissions method missing. Rebuild required.');
      return false;
    }
  }

  Future<void> syncScreenTimeTheme(Map<String, dynamic> payload) async {
    await _invokeVoid('syncScreenTimeTheme', payload);
  }

  Future<void> syncClassicShieldConfig(
    List<String> packageNames, [
    List<String> websitePayloads = const [],
  ]) async {
    await _invokeVoid('syncClassicShieldConfig', {
      'packages': packageNames,
      'websites': websitePayloads,
    });
  }

  Future<void> setClassicShieldEnabled(bool enabled) async {
    await _invokeVoid('setClassicShieldEnabled', {'enabled': enabled});
  }

  Future<Map<String, dynamic>> getBlockingDebugState() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getBlockingDebugState',
      );
      return result ?? const <String, dynamic>{};
    } on MissingPluginException {
      return const <String, dynamic>{};
    } on PlatformException {
      return const <String, dynamic>{};
    }
  }

  Future<List<AndroidLaunchableApp>> listAndroidLaunchableApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'listAndroidLaunchableApps',
      );
      return (result ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => AndroidLaunchableApp.fromMap(Map<String, dynamic>.from(entry)))
          .toList();
    } on MissingPluginException {
      return const <AndroidLaunchableApp>[];
    } on PlatformException {
      return const <AndroidLaunchableApp>[];
    }
  }

  Future<bool> isAuthorized() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAuthorized');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to check authorization: '${e.message}'.");
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<FocusProtectionStatus> getProtectionStatus() async {
    final authorized = await isAuthorized();
    return authorized
        ? FocusProtectionStatus.authorized
        : FocusProtectionStatus.unknown;
  }

  Future<AndroidProtectionStep> getNextAndroidProtectionStep() async {
    try {
      final raw = await _channel.invokeMethod<String>('getNextAndroidProtectionStep');
      return AndroidProtectionStep.values.firstWhere(
        (step) => step.name == raw,
        orElse: () => AndroidProtectionStep.overlay,
      );
    } on MissingPluginException {
      return AndroidProtectionStep.overlay;
    } on PlatformException {
      return AndroidProtectionStep.overlay;
    }
  }

  Future<bool> openSystemSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openSystemSettings');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openOverlaySettings() async {
    await _invokeVoid('openOverlaySettings');
  }

  Future<void> openUsageAccessSettings() async {
    await _invokeVoid('openUsageAccessSettings');
  }

  Future<void> openAccessibilitySettings() async {
    await _invokeVoid('openAccessibilitySettings');
  }

  Future<FocusPermissionState> getOverlayPermissionState() async {
    return _permissionState('getOverlayPermissionState');
  }

  Future<FocusPermissionState> getUsageAccessPermissionState() async {
    return _permissionState('getUsageAccessPermissionState');
  }

  Future<FocusPermissionState> getAccessibilityPermissionState() async {
    return _permissionState('getAccessibilityPermissionState');
  }

  Future<void> setPendingPermissionReturn(AndroidProtectionStep step) async {
    await _invokeVoid('setPendingPermissionReturn', {'step': step.name});
  }

  Future<void> clearPendingPermissionReturn() async {
    await _invokeVoid('clearPendingPermissionReturn');
  }

  Future<void> syncPlannedSessions(List<Map<String, dynamic>> sessions) async {
    await _invokeVoid('syncPlannedSessions', {'sessions': sessions});
  }

  Future<bool> startCeoShield() async {
    return _invokeBool('startCeoShield');
  }

  Future<void> startShield(
    List<String> packageNames,
    List<String> categories,
  ) async {
    await _invokeVoid('startShield', {
      'packages': packageNames,
      'categories': categories,
    });
  }

  Future<void> stopShield() async {
    await _invokeVoid('stopShield');
  }

  Future<bool> isShieldActive() async {
    return _invokeBool('isShieldActive');
  }

  Future<List<String>?> openFamilyActivityPicker() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'openFamilyActivityPicker',
      );
      return result?.cast<String>();
    } on PlatformException catch (e) {
      print("Failed to open picker: '${e.message}'.");
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> cacheSelection(
    List<String> packageNames,
    List<String> categories,
  ) async {
    await _invokeVoid('cacheSelection', {
      'packages': packageNames,
      'categories': categories,
    });
  }

  Future<bool> _invokeBool(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on PlatformException catch (e) {
      print("Focus method '$method' failed: '${e.message}'.");
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _invokeVoid(String method, [Map<String, dynamic>? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException catch (e) {
      print("Focus method '$method' failed: '${e.message}'.");
    } on MissingPluginException {
      // Unsupported runtime; keep Dart surfaces usable.
    }
  }

  Future<FocusPermissionState> _permissionState(String method) async {
    try {
      final raw = await _channel.invokeMethod<String>(method);
      return FocusPermissionState.values.firstWhere(
        (state) => state.name == raw,
        orElse: () => FocusPermissionState.unknown,
      );
    } on MissingPluginException {
      return FocusPermissionState.unsupported;
    } on PlatformException {
      return FocusPermissionState.unknown;
    }
  }
}
