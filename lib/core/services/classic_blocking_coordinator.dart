import 'dart:io';

import '../models/settings_models.dart';
import '../utils/app_logger.dart';
import '../utils/domain_utils.dart';
import 'classic_blocking_local_store.dart';
import 'focus_service.dart';

class ClassicBlockingSyncResult {
  final bool activePause;
  final int enforceableAppCount;
  final int enforceableWebsiteCount;
  final int effectiveTargetCount;

  const ClassicBlockingSyncResult({
    required this.activePause,
    required this.enforceableAppCount,
    required this.enforceableWebsiteCount,
    required this.effectiveTargetCount,
  });
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
    final hydratedAppBindings = await _backfillIosAppBindings(
      apps: apps,
      existingBindings: appBindings,
    );
    var websiteBindings = await _localStore.loadWebsiteBindings();
    websiteBindings = await _backfillAndroidWebsiteBindings(
      websites: websites,
      existingBindings: websiteBindings,
    );
    websiteBindings = await _backfillIosWebsiteBindings(
      websites: websites,
      existingBindings: websiteBindings,
    );
    final pauseActive = _hasActivePause(restPeriods);

    final alwaysBlockedApps = apps.where(
      (item) =>
          _isFullyBlocked(item.timeLimitMinutes) &&
          _isAppEnforceable(hydratedAppBindings[item.id]),
    );
    final pauseScopedApps = apps.where(
      (item) => _isAppEnforceable(hydratedAppBindings[item.id]),
    );

    final alwaysBlockedSites = websites.where(
      (item) =>
          _isFullyBlocked(item.timeLimitMinutes) &&
          _isWebsiteEnforceable(websiteBindings[item.id]),
    );
    final pauseScopedSites = websites.where(
      (item) => _isWebsiteEnforceable(websiteBindings[item.id]),
    );

    final baseAppBindings = {
      for (final item in alwaysBlockedApps)
        item.id: hydratedAppBindings[item.id]!,
    };
    final baseWebsiteBindings = {
      for (final item in alwaysBlockedSites) item.id: websiteBindings[item.id]!,
    };
    final pauseAppBindings = {
      for (final item in pauseScopedApps)
        item.id: hydratedAppBindings[item.id]!,
    };
    final pauseWebsiteBindings = {
      for (final item in pauseScopedSites) item.id: websiteBindings[item.id]!,
    };

    final basePackageIdentifiers = _collectNonEmpty(
      baseAppBindings.values.map((binding) => binding.nativeIdentifier),
    );

    final basePayloads = _collectNonEmpty([
      ...baseAppBindings.values.map((binding) => binding.nativePayload),
      ...baseWebsiteBindings.values.map((binding) => binding.nativePayload),
    ]);

    final baseWebsiteDomains = _collectNonEmpty(
      baseWebsiteBindings.values.map((binding) => binding.nativeIdentifier),
    );

    final pausePackageIdentifiers = _collectNonEmpty(
      pauseAppBindings.values.map((binding) => binding.nativeIdentifier),
    );

    final pausePayloads = _collectNonEmpty([
      ...pauseAppBindings.values.map((binding) => binding.nativePayload),
      ...pauseWebsiteBindings.values.map((binding) => binding.nativePayload),
    ]);

    final pauseWebsiteDomains = _collectNonEmpty(
      pauseWebsiteBindings.values.map((binding) => binding.nativeIdentifier),
    );

    final baseClassicPackages = Platform.isIOS
        ? basePayloads
        : basePackageIdentifiers;
    final pauseClassicPackages = Platform.isIOS
        ? pausePayloads
        : pausePackageIdentifiers;
    final enabled =
        baseClassicPackages.isNotEmpty || baseWebsiteDomains.isNotEmpty;
    final dailyLimitEntries = _buildDailyLimitEntries(
      apps: apps,
      websites: websites,
      appBindings: hydratedAppBindings,
      websiteBindings: websiteBindings,
    );
    final scheduledPausePeriods = restPeriods
        .map(_toNativePausePeriod)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    try {
      await _focusService.syncClassicShieldConfig(
        baseClassicPackages,
        const [],
        websiteDomains: baseWebsiteDomains,
      );
      await _focusService.setClassicShieldEnabled(enabled);
      await _focusService.syncClassicPauseSchedule(
        pauseClassicPackages,
        const [],
        scheduledPausePeriods,
        websiteDomains: pauseWebsiteDomains,
      );
      await _focusService.syncClassicDailyLimits(dailyLimitEntries);
    } catch (error) {
      AppLogger.error('Failed to sync classic blocking state.', error);
    }

    return ClassicBlockingSyncResult(
      activePause: pauseActive,
      enforceableAppCount: hydratedAppBindings.values
          .where((item) => item.isEnforceable)
          .length,
      enforceableWebsiteCount: websiteBindings.values
          .where((item) => item.isEnforceable)
          .length,
      effectiveTargetCount: pauseActive
          ? pauseAppBindings.length + pauseWebsiteBindings.length
          : baseAppBindings.length + baseWebsiteBindings.length,
    );
  }

  bool _hasActivePause(List<RestPeriod> periods) {
    final now = DateTime.now();
    return periods.any((period) {
      final start = period.startTime;
      final end = period.endTime;
      if (end == null) return false;
      if (start != null && start.isAfter(now)) return false;
      return end.isAfter(now);
    });
  }

  Map<String, dynamic>? _toNativePausePeriod(RestPeriod period) {
    final start = period.startTime;
    final end = period.endTime;
    if (start == null || end == null) return null;
    if (!end.isAfter(start)) return null;
    return {
      'id': period.id,
      'startMillis': start.millisecondsSinceEpoch,
      'endMillis': end.millisecondsSinceEpoch,
    };
  }

  bool _isFullyBlocked(int? limitMinutes) => (limitMinutes ?? 0) <= 0;

  bool _isAppEnforceable(ClassicBlockBinding? binding) =>
      binding != null &&
      (Platform.isIOS
          ? (binding.nativePayload?.trim().isNotEmpty ?? false)
          : (binding.nativeIdentifier?.trim().isNotEmpty ?? false));

  bool _isWebsiteEnforceable(ClassicBlockBinding? binding) =>
      binding != null &&
      (Platform.isIOS
          ? ((binding.nativePayload?.trim().isNotEmpty ?? false) ||
                (binding.nativeIdentifier?.trim().isNotEmpty ?? false))
          : (binding.nativeIdentifier?.trim().isNotEmpty ?? false));

  Future<Map<String, ClassicBlockBinding>> _backfillIosAppBindings({
    required List<BlockedApp> apps,
    required Map<String, ClassicBlockBinding> existingBindings,
  }) async {
    if (!Platform.isIOS) return existingBindings;

    var changed = false;
    final mutable = Map<String, ClassicBlockBinding>.from(existingBindings);
    for (final app in apps) {
      final existing = mutable[app.id];
      if (existing?.nativePayload?.trim().isNotEmpty ?? false) {
        continue;
      }
      final bundleId = existing?.nativeIdentifier?.trim();
      if (bundleId == null || bundleId.isEmpty) continue;
      final encoded = await _focusService.encodeApplicationBundleSelection(
        bundleId,
      );
      if (encoded == null || encoded.trim().isEmpty) continue;

      final binding = ClassicBlockBinding(
        nativeIdentifier: bundleId,
        nativePayload: encoded.trim(),
      );
      mutable[app.id] = binding;
      await _localStore.saveAppBinding(
        rowId: app.id,
        nativeIdentifier: binding.nativeIdentifier,
        nativePayload: binding.nativePayload,
      );
      changed = true;
    }
    return changed ? mutable : existingBindings;
  }

  Future<Map<String, ClassicBlockBinding>> _backfillAndroidWebsiteBindings({
    required List<BlockedWebsite> websites,
    required Map<String, ClassicBlockBinding> existingBindings,
  }) async {
    if (!Platform.isAndroid) return existingBindings;

    var changed = false;
    final mutable = Map<String, ClassicBlockBinding>.from(existingBindings);
    for (final website in websites) {
      final existing = mutable[website.id];
      if (existing?.nativeIdentifier?.trim().isNotEmpty ?? false) {
        continue;
      }
      final normalized = normalizeDomainInput(
        website.urlDomain,
        allowedSpecialValues: {'__ADULT_CONTENT__'},
      );
      if (normalized == null || normalized == '__ADULT_CONTENT__') continue;
      final binding = ClassicBlockBinding(nativeIdentifier: normalized);
      mutable[website.id] = binding;
      await _localStore.saveWebsiteBinding(
        rowId: website.id,
        nativeIdentifier: normalized,
      );
      changed = true;
    }
    return changed ? mutable : existingBindings;
  }

  Future<Map<String, ClassicBlockBinding>> _backfillIosWebsiteBindings({
    required List<BlockedWebsite> websites,
    required Map<String, ClassicBlockBinding> existingBindings,
  }) async {
    if (!Platform.isIOS) return existingBindings;

    var changed = false;
    final mutable = Map<String, ClassicBlockBinding>.from(existingBindings);
    for (final website in websites) {
      final existing = mutable[website.id];
      if (existing?.nativePayload?.trim().isNotEmpty ?? false) {
        continue;
      }
      final normalized = normalizeDomainInput(website.urlDomain);
      if (normalized == null || normalized.isEmpty) continue;
      final encoded = await _focusService.encodeWebsiteDomainSelection(
        normalized,
      );
      if (encoded == null || encoded.trim().isEmpty) continue;

      final binding = ClassicBlockBinding(
        nativeIdentifier:
            _clean(existing?.nativeIdentifier) ?? normalized,
        nativePayload: encoded.trim(),
      );
      mutable[website.id] = binding;
      await _localStore.saveWebsiteBinding(
        rowId: website.id,
        nativeIdentifier: binding.nativeIdentifier,
        nativePayload: binding.nativePayload,
      );
      changed = true;
    }
    return changed ? mutable : existingBindings;
  }

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
}
