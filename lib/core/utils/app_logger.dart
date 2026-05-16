import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('WARNING: $message');
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      final suffix = error == null ? '' : ' $error';
      debugPrint('ERROR: $message$suffix');
    }
  }
}
