import 'dart:io';

import '../models/settings_models.dart';
import '../utils/app_logger.dart';
import 'classic_blocking_local_store.dart';
import 'focus_service.dart';

class ClassicBlockingSyncResult {
  final bool activePause;
  final int enforceableAppCount;
  final int enforceableWebsiteCount;
  final int effectiveTargetCount;
  final int unresolvedAppCount;
  final int unresolvedWebsiteCount;
  final int pushedClassicPackageCount;
  final int pushedClassicWebsiteCount;
  final int pushedPausePackageCount;
  final int pushedPauseWebsiteCount;
  final int pushedDailyLimitCount;
  final bool syncApplied;
  final String? failureReason;

  const ClassicBlockingSyncResult({
    required this.activePause,
    required this.enforceableAppCount,
    required this.enforceableWebsiteCount,
    required this.effectiveTargetCount,
    required this.unresolvedAppCount,
    required this.unresolvedWebsiteCount,
    required this.pushedClassicPackageCount,
    required this.pushedClassicWebsiteCount,
    required this.pushedPausePackageCount,
    required this.pushedPauseWebsiteCount,
    required this.pushedDailyLimitCount,
    required this.syncApplied,
    this.failureReason,
  });

  ClassicBlockingSyncResult copyWith({
    bool? activePause,
    int? enforceableAppCount,
    int? enforceableWebsiteCount,
    int? effectiveTargetCount,
    int? unresolvedAppCount,
    int? unresolvedWebsiteCount,
    int? pushedClassicPackageCount,
    int? pushedClassicWebsiteCount,
    int? pushedPausePackageCount,
    int? pushedPauseWebsiteCount,
    int? pushedDailyLimitCount,
    bool? syncApplied,
    String? failureReason,
  }) {
    return ClassicBlockingSyncResult(
      activePause: activePause ?? this.activePause,
      enforceableAppCount: enforceableAppCount ?? this.enforceableAppCount,
      enforceableWebsiteCount:
          enforceableWebsiteCount ?? this.enforceableWebsiteCount,
      effectiveTargetCount: effectiveTargetCount ?? this.effectiveTargetCount,
      unresolvedAppCount: unresolvedAppCount ?? this.unresolvedAppCount,
      unresolvedWebsiteCount:
          unresolvedWebsiteCount ?? this.unresolvedWebsiteCount,
      pushedClassicPackageCount:
          pushedClassicPackageCount ?? this.pushedClassicPackageCount,
      pushedClassicWebsiteCount:
          pushedClassicWebsiteCount ?? this.pushedClassicWebsiteCount,
      pushedPausePackageCount:
          pushedPausePackageCount ?? this.pushedPausePackageCount,
      pushedPauseWebsiteCount:
          pushedPauseWebsiteCount ?? this.pushedPauseWebsiteCount,
      pushedDailyLimitCount: pushedDailyLimitCount ?? this.pushedDailyLimitCount,
      syncApplied: syncApplied ?? this.syncApplied,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

class ClassicBlockingCoordinator {
  ClassicBlockingCoordinator({
    ClassicBlockingLocalStore? localStore,
    FocusService? focusService,
  }) : _localStore = localStore ?? ClassicBlockingLocalStore(),
       _focusService = focusService ?? FocusService();

  final ClassicBlockingLocalStore _localStore;
  final FocusService _focusService;

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  List<String> _collectNonEmpty(Iterable<String?> values) {
    final out = <String>{};
    for (final value in values) {
      final cleaned = _clean(value);
      if (cleaned != null) {
        out.add(cleaned);
      }
    }
    return out.toList(growable: false);
  }

  Future<ClassicBlockingSyncResult> syncNativeState({
    required List<BlockedApp> apps,
    required List<BlockedWebsite> websites,
    required List<RestPeriod> restPeriods,
  }) async {
    await _localStore.prune(
      appIds: apps.map((item) => item.id).toSet(),
      websiteIds: websites.map((item) => item.id).toSet(),
    );

    final appBindings = await _localStore.loadAppBindings();
    final websiteBindings = await _localStore.loadWebsiteBindings();
    final pauseActive = _hasActivePause(restPeriods);

    final alwaysBlockedApps = apps.where(
      (item) => _isFullyBlocked(item.timeLimitMinutes) && _isAppEnforceable(appBindings[item.id]),
    );
    final pauseScopedApps = pauseActive
        ? apps.where((item) => _isAppEnforceable(appBindings[item.id]))
        : const <BlockedApp>[];

    final alwaysBlockedSites = websites.where(
      (item) =>
          _isFullyBlocked(item.timeLimitMinutes) &&
          _isWebsiteEnforceable(websiteBindings[item.id]),
    );
    final pauseScopedSites = pauseActive
        ? websites.where((item) => _isWebsiteEnforceable(websiteBindings[item.id]))
        : const <BlockedWebsite>[];

    final effectiveAppBindings = {
      for (final item in [...alwaysBlockedApps, ...pauseScopedApps])
        item.id: appBindings[item.id]!,
    };
    final effectiveWebsiteBindings = {
      for (final item in [...alwaysBlockedSites, ...pauseScopedSites])
        item.id: websiteBindings[item.id]!,
    };

    final packageIdentifiers = <String>{
      for (final binding in effectiveAppBindings.values)
        if (binding.nativeIdentifier?.trim().isNotEmpty ?? false)
          binding.nativeIdentifier!.trim(),
    }.toList(growable: false);

    final payloads = <String>[
      for (final binding in [...effectiveAppBindings.values, ...effectiveWebsiteBindings.values])
        if (binding.nativePayload?.trim().isNotEmpty ?? false)
          binding.nativePayload!.trim(),
    ];

    final classicPackages = Platform.isIOS ? payloads : packageIdentifiers;
    final enabled = classicPackages.isNotEmpty;

    try {
      await _focusService.syncClassicShieldConfig(classicPackages, const []);
      await _focusService.setClassicShieldEnabled(enabled);
    } catch (error) {
      AppLogger.error('Failed to sync classic blocking state.', error);
    }

    return ClassicBlockingSyncResult(
      activePause: pauseActive,
      enforceableAppCount: appBindings.values.where((item) => item.isEnforceable).length,
      enforceableWebsiteCount:
          websiteBindings.values.where((item) => item.isEnforceable).length,
      effectiveTargetCount:
          effectiveAppBindings.length + effectiveWebsiteBindings.length,
    );
  }

  bool _hasActivePause(List<RestPeriod> periods) {
    final now = DateTime.now();
    return periods.any((period) {
      if (!period.active) return false;
      final start = period.startTime;
      final end = period.endTime;
      if (start != null && start.isAfter(now)) return false;
      return end == null || end.isAfter(now);
    });
  }

  bool _isFullyBlocked(int? limitMinutes) => (limitMinutes ?? 0) <= 0;

  bool _isAppEnforceable(ClassicBlockBinding? binding) =>
      binding != null &&
      (Platform.isIOS
          ? (binding.nativePayload?.trim().isNotEmpty ?? false)
          : (binding.nativeIdentifier?.trim().isNotEmpty ?? false));

  bool _isWebsiteEnforceable(ClassicBlockBinding? binding) =>
      binding != null && (binding.nativePayload?.trim().isNotEmpty ?? false);

  List<Map<String, dynamic>> _buildDailyLimitEntries({
    required List<BlockedApp> apps,
    required List<BlockedWebsite> websites,
    required Map<String, ClassicBlockBinding> appBindings,
    required Map<String, ClassicBlockBinding> websiteBindings,
  }) {
    final bySelector = <String, Map<String, dynamic>>{};

    for (final app in apps) {
      final limit = app.timeLimitMinutes;
      if (limit == null || limit <= 0) continue;
      final binding = appBindings[app.id];
      if (!_isAppEnforceable(binding)) continue;
      final selector = Platform.isIOS
          ? _clean(binding?.nativePayload)
          : _clean(binding?.nativeIdentifier);
      if (selector == null) continue;
      _mergeDailyLimitEntry(
        bySelector: bySelector,
        selector: selector,
        rowId: app.id,
        limitMinutes: limit,
        kind: 'app',
      );
    }

    for (final website in websites) {
      final limit = website.timeLimitMinutes;
      if (limit == null || limit <= 0) continue;
      final binding = websiteBindings[website.id];
      if (!_isWebsiteEnforceable(binding)) continue;
      final selector = Platform.isIOS
          ? _clean(binding?.nativePayload)
          : _clean(binding?.nativeIdentifier);
      if (selector == null) continue;
      _mergeDailyLimitEntry(
        bySelector: bySelector,
        selector: selector,
        rowId: website.id,
        limitMinutes: limit,
        kind: 'website',
      );
    }

    return bySelector.values.toList(growable: false);
  }

  void _mergeDailyLimitEntry({
    required Map<String, Map<String, dynamic>> bySelector,
    required String selector,
    required String rowId,
    required int limitMinutes,
    required String kind,
  }) {
    final trimmed = selector.trim();
    if (trimmed.isEmpty) return;
    final existing = bySelector[trimmed];
    if (existing == null || (existing['limitMinutes'] as int) > limitMinutes) {
      bySelector[trimmed] = {
        'id': rowId,
        'selector': trimmed,
        'limitMinutes': limitMinutes,
        'kind': kind,
      };
    }
  }

  String _normalizeLabel(String? raw) {
    return (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _looksLikePackageName(String value) {
    return RegExp(r'^[a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+$').hasMatch(value);
  }

  String? _inferAndroidPackageName({
    required String? rawName,
    required Set<String> installedPackages,
    required Map<String, Set<String>> packagesByLabel,
  }) {
    final cleaned = _clean(rawName);
    if (cleaned == null) return null;

    if (_looksLikePackageName(cleaned) && installedPackages.contains(cleaned)) {
      return cleaned;
    }

    final normalizedLabel = _normalizeLabel(cleaned);
    final matches = packagesByLabel[normalizedLabel];
    if (matches != null && matches.length == 1) {
      return matches.first;
    }

    return null;
  }
}
