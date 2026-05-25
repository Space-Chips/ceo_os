import 'dart:io';

import 'package:live_activities/live_activities.dart';

import '../utils/app_logger.dart';

/// Type of session displayed on the Live Activity.
enum LiveActivitySession { focus, blackout }

/// Wrapper around the `live_activities` plugin to start/update/end
/// the lockscreen + Dynamic Island activity for Focus and Blackout sessions.
///
/// iOS-only (ActivityKit). All methods are no-ops on other platforms.
///
/// Setup checklist (see ios/LiveActivityExtension/README.md):
/// 1. Add a Widget Extension target in Xcode named `LiveActivityExtension`.
/// 2. Link the prepared Swift files under `ios/LiveActivityExtension/`.
/// 3. Set the App Group both on Runner and on the extension target so the
///    plugin can share state.
class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();

  final LiveActivities _plugin = LiveActivities();
  bool _initialized = false;

  // App Group used by both Runner and the Widget Extension. Keep this in sync
  // with Signing & Capabilities → App Groups in Xcode (matches the bundle
  // identifier namespace `com.wakeapp.ceoos`).
  static const String _appGroupId = 'group.com.wakeapp.ceoos.liveactivity';

  // Active activity identifiers, keyed by session type so we can update/end them.
  final Map<LiveActivitySession, String> _activeIds = {};

  bool get _isSupported => Platform.isIOS;

  Future<void> _ensureInit() async {
    if (_initialized || !_isSupported) return;
    try {
      await _plugin.init(appGroupId: _appGroupId);
      _initialized = true;
    } catch (e) {
      AppLogger.error('Failed to init LiveActivities plugin.', e);
    }
  }

  /// Start a Live Activity for the given session.
  ///
  /// [endAt] is the absolute moment the session is scheduled to end — the
  /// SwiftUI widget uses it with `Text(timerInterval:...)` to render a live
  /// countdown without needing per-second updates.
  Future<void> start({
    required LiveActivitySession session,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    if (!_isSupported) return;
    await _ensureInit();
    if (!_initialized) return;

    try {
      // End any prior activity of the same kind to avoid duplicates.
      final prior = _activeIds.remove(session);
      if (prior != null) {
        await _plugin.endActivity(prior);
      }

      final activityId =
          '${session.name}_${DateTime.now().millisecondsSinceEpoch}';
      final payload = <String, dynamic>{
        'sessionType': session.name,
        'title': title,
        'startAtMs': startAt.millisecondsSinceEpoch,
        'endAtMs': endAt.millisecondsSinceEpoch,
      };
      final result = await _plugin.createActivity(activityId, payload);
      // The plugin returns either the same id or a platform-generated one.
      _activeIds[session] = result ?? activityId;
    } catch (e) {
      AppLogger.error('Failed to start Live Activity.', e);
    }
  }

  /// Push an update to an existing Live Activity. Generally only needed when
  /// the *endAt* changes (e.g. user paused/resumed); the timer widget itself
  /// counts down without any extra push.
  Future<void> update({
    required LiveActivitySession session,
    required DateTime endAt,
    String? title,
  }) async {
    if (!_isSupported) return;
    final id = _activeIds[session];
    if (id == null) return;
    try {
      final payload = <String, dynamic>{
        'sessionType': session.name,
        'endAtMs': endAt.millisecondsSinceEpoch,
        if (title != null) 'title': title,
      };
      await _plugin.updateActivity(id, payload);
    } catch (e) {
      AppLogger.error('Failed to update Live Activity.', e);
    }
  }

  /// End and dismiss the Live Activity for the given session.
  Future<void> end(LiveActivitySession session) async {
    if (!_isSupported) return;
    final id = _activeIds.remove(session);
    if (id == null) return;
    try {
      await _plugin.endActivity(id);
    } catch (e) {
      AppLogger.error('Failed to end Live Activity.', e);
    }
  }

  /// End every tracked activity (e.g. on user logout or hard reset).
  Future<void> endAll() async {
    if (!_isSupported) return;
    final ids = List<String>.from(_activeIds.values);
    _activeIds.clear();
    for (final id in ids) {
      try {
        await _plugin.endActivity(id);
      } catch (_) {}
    }
  }
}
