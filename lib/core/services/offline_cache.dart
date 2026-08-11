import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight read-cache used by repositories to keep the last known
/// snapshot of a collection on disk. Reads return the cached value when
/// the network/Supabase call fails so the UI never has to face a blank
/// state offline.
///
/// Keys are auto-scoped per current Supabase user so that switching
/// accounts on the same device cannot leak data across sessions.
class OfflineCache {
  OfflineCache._();

  static String _scopedKey(String base) {
    final uid =
        Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'cache::$uid::$base';
  }

  /// Persist a list of JSON-serialisable maps under [key].
  static Future<void> writeList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_scopedKey(key), jsonEncode(items));
    } catch (_) {}
  }

  /// Read a previously persisted list of maps under [key]. Returns null if
  /// nothing was cached or if the cached blob can't be decoded.
  static Future<List<Map<String, dynamic>>?> readList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedKey(key));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  /// Convenience wrapper to read a list of typed entities. [parser] gets
  /// each map and returns a domain model.
  static Future<List<T>?> readTypedList<T>(
    String key,
    T Function(Map<String, dynamic>) parser,
  ) async {
    final raw = await readList(key);
    if (raw == null) return null;
    try {
      return raw.map(parser).toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  /// Erase a single cache key.
  static Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scopedKey(key));
    } catch (_) {}
  }
}
