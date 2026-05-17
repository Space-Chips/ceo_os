import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/block_list_model.dart';
import '../models/settings_models.dart';

class FamilyControlsLocalStore {
  static const String _blockListsKey = 'ios_family_controls_block_lists_v1';
  static const String _blockedAppsKey = 'ios_family_controls_blocked_apps_v1';
  static const String _blockedWebsitesKey =
      'ios_family_controls_blocked_websites_v1';
  static const String _restPeriodsKey = 'ios_family_controls_rest_periods_v1';

  Future<List<BlockList>> getBlockLists() async {
    final rows = await _loadRows(_blockListsKey);
    return rows.map(BlockList.fromJson).toList(growable: false);
  }

  Future<void> saveBlockList(BlockList list) async {
    final rows = await _loadRows(_blockListsKey);
    final next = List<Map<String, dynamic>>.from(rows);
    final index = next.indexWhere((row) => row['id'] == list.id);
    if (index >= 0) {
      next[index] = list.toJson();
    } else {
      next.add(list.toJson());
    }
    await _saveRows(_blockListsKey, next);
  }

  Future<void> setActiveBlockList(String? activeId) async {
    final rows = await _loadRows(_blockListsKey);
    final next = rows
        .map(
          (row) => {
            ...row,
            'is_active': activeId != null && row['id'] == activeId,
          },
        )
        .toList(growable: false);
    await _saveRows(_blockListsKey, next);
  }

  Future<void> deleteBlockList(String id) async {
    final rows = await _loadRows(_blockListsKey);
    final next = rows.where((row) => row['id'] != id).toList(growable: false);
    await _saveRows(_blockListsKey, next);
  }

  Future<List<BlockedApp>> getBlockedApps() async {
    final rows = await _loadRows(_blockedAppsKey);
    final apps = rows.map(BlockedApp.fromJson).toList(growable: false);
    apps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return apps;
  }

  Future<BlockedApp?> createBlockedAppRecord({
    required String createdBy,
    required String appName,
  }) async {
    final trimmedName = appName.trim();
    if (trimmedName.isEmpty) return null;

    final item = BlockedApp(
      id: _newId('blocked_app'),
      createdBy: createdBy,
      appName: trimmedName,
      timeLimitMinutes: 0,
      createdAt: DateTime.now(),
    );
    final rows = await _loadRows(_blockedAppsKey);
    final next = List<Map<String, dynamic>>.from(rows)..add(_blockedAppToJson(item));
    await _saveRows(_blockedAppsKey, next);
    return item;
  }

  Future<void> deleteBlockedApp(String id) async {
    final rows = await _loadRows(_blockedAppsKey);
    final next = rows.where((row) => row['id'] != id).toList(growable: false);
    await _saveRows(_blockedAppsKey, next);
  }

  Future<void> updateBlockedAppName(String id, String appName) async {
    final trimmed = appName.trim();
    if (trimmed.isEmpty) return;
    final rows = await _loadRows(_blockedAppsKey);
    final next = rows
        .map(
          (row) => row['id'] == id
              ? {
                  ...row,
                  'app_name': trimmed,
                }
              : row,
        )
        .toList(growable: false);
    await _saveRows(_blockedAppsKey, next);
  }

  Future<void> setBlockedAppTime(String id, int minutes) async {
    final safe = minutes < 0 ? 0 : minutes;
    final rows = await _loadRows(_blockedAppsKey);
    final next = rows
        .map(
          (row) => row['id'] == id
              ? {
                  ...row,
                  'time_limit_minutes': safe,
                }
              : row,
        )
        .toList(growable: false);
    await _saveRows(_blockedAppsKey, next);
  }

  Future<void> addBlockedAppTime(String id, int minutes) async {
    final rows = await _loadRows(_blockedAppsKey);
    final next = rows
        .map((row) {
          if (row['id'] != id) return row;
          final current = (row['time_limit_minutes'] as num?)?.toInt() ?? 0;
          return {
            ...row,
            'time_limit_minutes': current + minutes,
          };
        })
        .toList(growable: false);
    await _saveRows(_blockedAppsKey, next);
  }

  Future<List<BlockedWebsite>> getBlockedWebsites() async {
    final rows = await _loadRows(_blockedWebsitesKey);
    final websites = rows
        .map(BlockedWebsite.fromJson)
        .toList(growable: false);
    websites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return websites;
  }

  Future<BlockedWebsite?> createBlockedWebsiteRecord({
    required String createdBy,
    String? urlDomain,
  }) async {
    final trimmedDomain = urlDomain?.trim();

    final item = BlockedWebsite(
      id: _newId('blocked_website'),
      createdBy: createdBy,
      urlDomain: (trimmedDomain?.isNotEmpty ?? false) ? trimmedDomain : null,
      timeLimitMinutes: 0,
      createdAt: DateTime.now(),
    );
    final rows = await _loadRows(_blockedWebsitesKey);
    final next = List<Map<String, dynamic>>.from(rows)
      ..add(_blockedWebsiteToJson(item));
    await _saveRows(_blockedWebsitesKey, next);
    return item;
  }

  Future<void> deleteBlockedWebsite(String id) async {
    final rows = await _loadRows(_blockedWebsitesKey);
    final next = rows.where((row) => row['id'] != id).toList(growable: false);
    await _saveRows(_blockedWebsitesKey, next);
  }

  Future<void> updateBlockedWebsiteDomain(String id, String? domain) async {
    final trimmed = domain?.trim();
    final normalized = (trimmed != null && trimmed.isNotEmpty)
        ? trimmed
        : null;
    final rows = await _loadRows(_blockedWebsitesKey);
    final next = rows
        .map(
          (row) => row['id'] == id
              ? {
                  ...row,
                  'url_domain': normalized,
                }
              : row,
        )
        .toList(growable: false);
    await _saveRows(_blockedWebsitesKey, next);
  }

  Future<void> setBlockedWebsiteTime(String id, int minutes) async {
    final safe = minutes < 0 ? 0 : minutes;
    final rows = await _loadRows(_blockedWebsitesKey);
    final next = rows
        .map(
          (row) => row['id'] == id
              ? {
                  ...row,
                  'time_limit_minutes': safe,
                }
              : row,
        )
        .toList(growable: false);
    await _saveRows(_blockedWebsitesKey, next);
  }

  Future<void> addBlockedWebsiteTime(String id, int minutes) async {
    final rows = await _loadRows(_blockedWebsitesKey);
    final next = rows
        .map((row) {
          if (row['id'] != id) return row;
          final current = (row['time_limit_minutes'] as num?)?.toInt() ?? 0;
          return {
            ...row,
            'time_limit_minutes': current + minutes,
          };
        })
        .toList(growable: false);
    await _saveRows(_blockedWebsitesKey, next);
  }

  Future<void> setAdultContentShieldEnabled({
    required bool enabled,
    required String createdBy,
    required String marker,
  }) async {
    final rows = await _loadRows(_blockedWebsitesKey);
    final next = List<Map<String, dynamic>>.from(rows);
    final index = next.indexWhere((row) => row['url_domain'] == marker);

    if (enabled) {
      if (index < 0) {
        final item = BlockedWebsite(
          id: _newId('blocked_website'),
          createdBy: createdBy,
          urlDomain: marker,
          timeLimitMinutes: 0,
          createdAt: DateTime.now(),
        );
        next.add(_blockedWebsiteToJson(item));
      }
    } else if (index >= 0) {
      next.removeAt(index);
    }

    await _saveRows(_blockedWebsitesKey, next);
  }

  Future<List<RestPeriod>> getRestPeriods() async {
    final rows = await _loadRows(_restPeriodsKey);
    final periods = rows.map(RestPeriod.fromJson).toList(growable: false);
    periods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return periods;
  }

  Future<void> createRestPeriod({
    required String createdBy,
    required DateTime startTime,
    required DateTime endTime,
    required bool active,
  }) async {
    final item = RestPeriod(
      id: _newId('rest_period'),
      createdBy: createdBy,
      startTime: startTime,
      endTime: endTime,
      active: active,
      createdAt: DateTime.now(),
    );
    final rows = await _loadRows(_restPeriodsKey);
    final next = List<Map<String, dynamic>>.from(rows)..add(_restPeriodToJson(item));
    await _saveRows(_restPeriodsKey, next);
  }

  Future<void> updateRestPeriodActive(String id, bool active) async {
    final rows = await _loadRows(_restPeriodsKey);
    final next = rows
        .map(
          (row) => row['id'] == id
              ? {
                  ...row,
                  'active': active,
                }
              : row,
        )
        .toList(growable: false);
    await _saveRows(_restPeriodsKey, next);
  }

  Future<void> updateRestPeriod({
    required String id,
    DateTime? startTime,
    DateTime? endTime,
    bool? active,
  }) async {
    final rows = await _loadRows(_restPeriodsKey);
    final next = rows
        .map((row) {
          if (row['id'] != id) return row;
          return {
            ...row,
            if (startTime != null) 'start_time': startTime.toIso8601String(),
            if (endTime != null) 'end_time': endTime.toIso8601String(),
            if (active != null) 'active': active,
          };
        })
        .toList(growable: false);
    await _saveRows(_restPeriodsKey, next);
  }

  Future<void> deleteRestPeriod(String id) async {
    final rows = await _loadRows(_restPeriodsKey);
    final next = rows.where((row) => row['id'] != id).toList(growable: false);
    await _saveRows(_restPeriodsKey, next);
  }

  Map<String, dynamic> _blockedAppToJson(BlockedApp item) => {
    'id': item.id,
    'created_by': item.createdBy,
    'app_name': item.appName,
    'time_limit_minutes': item.timeLimitMinutes ?? 0,
    'created_at': item.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _blockedWebsiteToJson(BlockedWebsite item) => {
    'id': item.id,
    'created_by': item.createdBy,
    'url_domain': item.urlDomain,
    'time_limit_minutes': item.timeLimitMinutes ?? 0,
    'created_at': item.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _restPeriodToJson(RestPeriod item) => {
    'id': item.id,
    'created_by': item.createdBy,
    'start_time': item.startTime?.toIso8601String(),
    'end_time': item.endTime?.toIso8601String(),
    'active': item.active,
    'created_at': item.createdAt.toIso8601String(),
  };

  String _newId(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$micros';
  }

  Future<List<Map<String, dynamic>>> _loadRows(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (row) => row.map(
              (entryKey, value) => MapEntry(entryKey.toString(), value),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveRows(String key, List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(rows));
  }
}
