import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks network connectivity. Used app-wide to gate network actions,
/// show offline banners, and trigger sync flushes when reconnected.
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool _initialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final result = await _connectivity.checkConnectivity();
      _applyResult(result);
    } catch (_) {
      // If detection fails, assume online (better than locking the user out)
      _isOnline = true;
    }
    _sub = _connectivity.onConnectivityChanged.listen(_applyResult);
    notifyListeners();
  }

  void _applyResult(List<ConnectivityResult> result) {
    final wasOnline = _isOnline;
    final online = result.any(
      (r) => r != ConnectivityResult.none,
    );
    if (online != wasOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
