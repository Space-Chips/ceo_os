import 'package:flutter/services.dart';

class FocusService {
  static const MethodChannel _channel = MethodChannel('com.ceoos.app/focus');

  // Request permissions for Accessibility (Android) or Family Controls (iOS)
  Future<bool> requestPermissions() async {
    try {
      final bool result = await _channel.invokeMethod('requestPermissions');
      return result;
    } on PlatformException catch (e) {
      print("Failed to request permissions: '${e.message}'.");
      return false;
    } on MissingPluginException {
      print("Native permissions method missing. Rebuild required.");
      return false;
    }
  }

  // Check if authorized
  Future<bool> isAuthorized() async {
    try {
      final bool result = await _channel.invokeMethod('isAuthorized');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check authorization: '${e.message}'.");
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // Start shielding specific apps/categories
  Future<void> startShield(List<String> packageNames, List<String> categories) async {
    try {
      await _channel.invokeMethod('startShield', {
        'packages': packageNames,
        'categories': categories,
      });
    } on PlatformException catch (e) {
      print("Failed to start shield: '${e.message}'.");
    } on MissingPluginException {
      print("Native startShield method missing. Rebuild required.");
    }
  }

  // Stop shielding
  Future<void> stopShield() async {
    try {
      await _channel.invokeMethod('stopShield');
    } on PlatformException catch (e) {
      print("Failed to stop shield: '${e.message}'.");
    } on MissingPluginException {
      print("Native stopShield method missing. Rebuild required.");
    }
  }

  // Check if shield is active
  Future<bool> isShieldActive() async {
    try {
      final bool result = await _channel.invokeMethod('isShieldActive');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check shield status: '${e.message}'.");
      return false;
    } on MissingPluginException {
      print("Native isShieldActive method missing. Rebuild required.");
      return false;
    }
  }
  
  // iOS only: Open Family Activity Picker
  Future<List<String>?> openFamilyActivityPicker() async {
    try {
        // Returns a list of opaque tokens representing selected apps/categories
      final List<dynamic>? result = await _channel.invokeMethod('openFamilyActivityPicker');
      return result?.cast<String>(); 
    } on PlatformException catch (e) {
      print("Failed to open picker: '${e.message}'.");
      return null;
    } on MissingPluginException catch (e) {
      print("CRITICAL: Native focus plugin missing. Please STOP the app and run 'flutter run' again to apply native changes. Error: $e");
      return null;
    }
  }
}
