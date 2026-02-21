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
    }
  }

  // Stop shielding
  Future<void> stopShield() async {
    try {
      await _channel.invokeMethod('stopShield');
    } on PlatformException catch (e) {
      print("Failed to stop shield: '${e.message}'.");
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
    }
  }
}
