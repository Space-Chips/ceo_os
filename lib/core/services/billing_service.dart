import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/premium_models.dart';
import '../repositories/premium_repository.dart';
import 'billing_diagnostics_service.dart';

enum BillingPurchaseStatus {
  success,
  pendingBackendSync,
  userCancelled,
  unavailable,
  failed,
}

class BillingPurchaseResult {
  final BillingPurchaseStatus status;
  final String? message;

  const BillingPurchaseResult({required this.status, this.message});

  bool get succeeded =>
      status == BillingPurchaseStatus.success ||
      status == BillingPurchaseStatus.pendingBackendSync;
}

class BillingService {
  static final BillingService _instance = BillingService._internal();

  factory BillingService() => _instance;

  BillingService._internal();

  final PremiumRepository _premiumRepository = PremiumRepository();
  final SupabaseClient _client = Supabase.instance.client;
  final BillingDiagnosticsService _diag = BillingDiagnosticsService();

  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  bool _configured = false;
  String? _configuredUserId;
  PremiumConfig? _config;

  bool get isConfigured => _configured;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _configureIfPossible();
    } catch (_) {
      _configured = false;
      _configuredUserId = null;
    }
    _authSubscription = _client.auth.onAuthStateChange.listen((event) async {
      await _syncIdentity(event.session?.user.id);
    });
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _initialized = false;
    _configured = false;
    _configuredUserId = null;
  }

  Future<List<BillingPackageOption>> getPackageOptions() async {
    if (!await _configureIfPossible()) return const [];

    try {
      await _diag.log('offerings_fetch_start');
      final offerings = await Purchases.getOfferings();
      final offering = _selectOffering(offerings);
      if (offering == null) {
        await _diag.log('offerings_fetch_empty');
        return const [];
      }

      final options = <BillingPackageOption>[];
      void addIfPresent(Package? package) {
        if (package == null) return;
        options.add(BillingPackageOption.fromPackage(package));
      }

      addIfPresent(offering.monthly);
      addIfPresent(offering.annual);
      addIfPresent(offering.lifetime);
      for (final package in offering.availablePackages) {
        if (options.any((entry) => entry.identifier == package.identifier)) {
          continue;
        }
        options.add(BillingPackageOption.fromPackage(package));
      }
      await _diag.log(
        'offerings_fetch_success',
        data: {'count': options.length},
      );
      return options;
    } catch (_) {
      await _diag.log('offerings_fetch_failed');
      return const [];
    }
  }

  Future<BillingPurchaseResult> purchasePremium() async {
    if (!await _configureIfPossible()) {
      await _diag.log('purchase_unavailable');
      return const BillingPurchaseResult(
        status: BillingPurchaseStatus.unavailable,
      );
    }

    try {
      await _diag.log('purchase_start');
      final offerings = await Purchases.getOfferings();
      final offering = _selectOffering(offerings);
      final package = _preferredPackage(offering);
      if (package == null) {
        await _diag.log('purchase_no_package');
        return const BillingPurchaseResult(
          status: BillingPurchaseStatus.unavailable,
        );
      }

      await _diag.log(
        'purchase_package_selected',
        data: {
          'identifier': package.identifier,
          'storeProductId': package.storeProduct.identifier,
        },
      );
      await Purchases.purchase(PurchaseParams.package(package));
      final rcActive = await _isRevenueCatEntitlementActive();
      await _diag.log(
        'purchase_revenuecat_entitlement',
        data: {'active': rcActive},
      );
      if (rcActive) {
        await _premiumRepository.activateClientGraceWindow();
      }

      final synced = await _premiumRepository.waitForBillingActivation();
      final runtime = await _premiumRepository.getRuntime();
      await _diag.log(
        'purchase_post_activation',
        data: {
          'synced': synced,
          'subscriptionStatus': runtime.subscriptionStatus,
          'isPremiumUser': runtime.resolved.isPremiumUser,
          'clientGraceActive': runtime.resolved.clientGraceActive,
          'hasPaidSubscription': runtime.resolved.hasPaidSubscription,
          'isTrialing': runtime.resolved.isTrialing,
        },
      );
      return BillingPurchaseResult(
        status: synced
            ? BillingPurchaseStatus.success
            : BillingPurchaseStatus.pendingBackendSync,
      );
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        await _diag.log('purchase_cancelled');
        return const BillingPurchaseResult(
          status: BillingPurchaseStatus.userCancelled,
        );
      }
      await _diag.log(
        'purchase_failed_platform',
        data: {
          'code': code.name,
          'message': error.message,
        },
      );
      return BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
        message: error.message,
      );
    } catch (error) {
      await _diag.log('purchase_failed', data: {'error': error.toString()});
      return BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
        message: error.toString(),
      );
    }
  }

  Future<BillingPurchaseResult> restorePurchases() async {
    if (!await _configureIfPossible()) {
      await _diag.log('restore_unavailable');
      return const BillingPurchaseResult(
        status: BillingPurchaseStatus.unavailable,
      );
    }

    try {
      await _diag.log('restore_start');
      await Purchases.restorePurchases();
      final rcActive = await _isRevenueCatEntitlementActive();
      await _diag.log(
        'restore_revenuecat_entitlement',
        data: {'active': rcActive},
      );
      if (rcActive) {
        await _premiumRepository.activateClientGraceWindow();
      }

      final synced = await _premiumRepository.waitForBillingActivation();
      final runtime = await _premiumRepository.getRuntime();
      await _diag.log(
        'restore_post_activation',
        data: {
          'synced': synced,
          'subscriptionStatus': runtime.subscriptionStatus,
          'isPremiumUser': runtime.resolved.isPremiumUser,
          'clientGraceActive': runtime.resolved.clientGraceActive,
          'hasPaidSubscription': runtime.resolved.hasPaidSubscription,
          'isTrialing': runtime.resolved.isTrialing,
        },
      );
      return BillingPurchaseResult(
        status: synced
            ? BillingPurchaseStatus.success
            : BillingPurchaseStatus.pendingBackendSync,
      );
    } on PlatformException catch (error) {
      await _diag.log(
        'restore_failed_platform',
        data: {'message': error.message},
      );
      return BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
        message: error.message,
      );
    } catch (error) {
      await _diag.log('restore_failed', data: {'error': error.toString()});
      return BillingPurchaseResult(
        status: BillingPurchaseStatus.failed,
        message: error.toString(),
      );
    }
  }

  Future<bool> _configureIfPossible() async {
    try {
      _config = await _premiumRepository.getConfig();
      final apiKey = _apiKeyForPlatform(_config!);
      if (apiKey == null || apiKey.isEmpty) {
        _configured = false;
        await _diag.log('configure_no_api_key');
        return false;
      }

      final userId = _client.auth.currentUser?.id;
      if (_configured && _configuredUserId == userId) {
        return true;
      }

      final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;

      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(configuration);
      _configured = true;
      _configuredUserId = userId;
      await _diag.log(
        'configure_success',
        data: {'hasUser': userId != null && userId.isNotEmpty},
      );
      return true;
    } catch (_) {
      _configured = false;
      _configuredUserId = null;
      await _diag.log('configure_failed');
      return false;
    }
  }

  Future<void> _syncIdentity(String? userId) async {
    if (!_configured) {
      await _configureIfPossible();
      return;
    }

    try {
      if (userId == null || userId.isEmpty) {
        if (_configuredUserId != null) {
          await _diag.log('identity_logout');
          await Purchases.logOut();
          _configuredUserId = null;
        }
        return;
      }
      if (_configuredUserId != userId) {
        await _diag.log('identity_login');
        await Purchases.logIn(userId);
        _configuredUserId = userId;
      }
    } catch (_) {
      _configured = false;
      _configuredUserId = null;
      await _diag.log('identity_sync_failed');
    }
  }

  Future<bool> _isRevenueCatEntitlementActive() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      final config = _config ?? await _premiumRepository.getConfig();
      final info = await Purchases.getCustomerInfo();
      final entitlementId = config.revenuecatEntitlementId.trim();
      if (entitlementId.isEmpty) return false;
      final entitlement = info.entitlements.all[entitlementId];
      return entitlement?.isActive == true;
    } catch (_) {
      return false;
    }
  }

  Offering? _selectOffering(Offerings offerings) {
    final preferredId = _config?.revenuecatOfferingId?.trim();
    if (preferredId != null && preferredId.isNotEmpty) {
      final candidate = offerings.getOffering(preferredId);
      if (candidate != null) return candidate;
    }
    return offerings.current;
  }

  Package? _preferredPackage(Offering? offering) {
    if (offering == null) return null;
    return offering.annual ??
        offering.monthly ??
        offering.lifetime ??
        (offering.availablePackages.isNotEmpty
            ? offering.availablePackages.first
            : null);
  }

  String? _apiKeyForPlatform(PremiumConfig config) {
    if (Platform.isIOS) return config.revenuecatIosApiKey;
    if (Platform.isAndroid) return config.revenuecatAndroidApiKey;
    return null;
  }
}

class BillingPackageOption {
  final String identifier;
  final String title;
  final String priceLabel;
  final String durationLabel;

  const BillingPackageOption({
    required this.identifier,
    required this.title,
    required this.priceLabel,
    required this.durationLabel,
  });

  factory BillingPackageOption.fromPackage(Package package) {
    final storeProduct = package.storeProduct;
    return BillingPackageOption(
      identifier: package.identifier,
      title: storeProduct.title,
      priceLabel: storeProduct.priceString,
      durationLabel: _durationLabel(package),
    );
  }

  static String _durationLabel(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annual';
      case PackageType.lifetime:
        return 'Lifetime';
      default:
        return package.identifier;
    }
  }
}
