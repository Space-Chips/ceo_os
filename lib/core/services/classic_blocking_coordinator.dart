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
}
