import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/focus_service.dart';

class LauncherProvider extends ChangeNotifier {
  LauncherProvider({FocusService? focusService})
    : _focusService = focusService ?? FocusService();

  final FocusService _focusService;

  List<AndroidLaunchableApp> _apps = const [];
  String _query = '';
  bool _loading = false;
  bool _initialized = false;

  bool get isLoading => _loading;
  bool get isInitialized => _initialized;
  String get query => _query;

  List<AndroidLaunchableApp> get visibleApps {
    final trimmed = _query.trim().toLowerCase();
    final source = _apps;
    if (trimmed.isEmpty) return source;
    return source.where((app) {
      return app.name.toLowerCase().contains(trimmed) ||
          app.packageName.toLowerCase().contains(trimmed);
    }).toList(growable: false);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _apps = await _focusService.listAndroidLaunchableApps();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  Future<bool> launch(AndroidLaunchableApp app) {
    return _focusService.launchExternalApp(app.packageName);
  }
}
