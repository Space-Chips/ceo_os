import 'package:flutter/foundation.dart';

@immutable
class PremiumConfig {
  final bool paywallEnabled;
  final int habitsFreeLimit;
  final int tasksFreeLimit;
  final int notesFreeLimit;
  final int focusFreeDailyLimit;
  final int focusFreeMinutesLimit;
  final int ceoModeFreeWeeklyLimit;
  final int ceoModeFreeMinutesLimit;
  final String revenuecatEntitlementId;
  final String? revenuecatOfferingId;
  final String? revenuecatIosApiKey;
  final String? revenuecatAndroidApiKey;
  final Set<String> premiumThemes;
  final bool launchPremiumLabelsEnabled;

  const PremiumConfig({
    this.paywallEnabled = false,
    this.habitsFreeLimit = 3,
    this.tasksFreeLimit = 12,
    this.notesFreeLimit = 50,
    this.focusFreeDailyLimit = 1,
    this.focusFreeMinutesLimit = 25,
    this.ceoModeFreeWeeklyLimit = 1,
    this.ceoModeFreeMinutesLimit = 30,
    this.revenuecatEntitlementId = 'premium',
    this.revenuecatOfferingId,
    this.revenuecatIosApiKey,
    this.revenuecatAndroidApiKey,
    this.premiumThemes = const {},
    this.launchPremiumLabelsEnabled = false,
  });
}

@immutable
class PremiumResolvedAccess {
  final bool isPremiumUser;
  final bool clientGraceActive;
  final bool hasPaidSubscription;
  final bool isTrialing;

  const PremiumResolvedAccess({
    this.isPremiumUser = false,
    this.clientGraceActive = false,
    this.hasPaidSubscription = false,
    this.isTrialing = false,
  });

  bool get canCreateUnlimitedHabits => isPremiumUser;
  bool get canCreateUnlimitedTasks => isPremiumUser;
  bool get canUseExtendedFocus => isPremiumUser;
  bool get canUseExtendedCeoMode => isPremiumUser;
  bool get launchPremiumActive => isPremiumUser;
}

@immutable
class PremiumRuntime {
  final PremiumConfig config;
  final PremiumResolvedAccess resolved;
  final String subscriptionStatus;

  const PremiumRuntime({
    this.config = const PremiumConfig(),
    this.resolved = const PremiumResolvedAccess(),
    this.subscriptionStatus = 'free',
  });
}

@immutable
class PremiumCheckResult {
  final bool allowed;
  final String? reason;
  final int? limit;
  final int? current;

  const PremiumCheckResult.allowed()
    : allowed = true,
      reason = null,
      limit = null,
      current = null;

  const PremiumCheckResult.blocked({
    required this.reason,
    this.limit,
    this.current,
  }) : allowed = false;
}

@immutable
class PremiumMessage {
  final String title;
  final String description;

  const PremiumMessage({required this.title, required this.description});
}

PremiumMessage premiumMessageForReason(
  String? reason, {
  String languageCode = 'en',
}) {
  final isFr = languageCode.trim().toLowerCase().startsWith('fr');
  switch (reason) {
    case 'habits':
      return PremiumMessage(
        title: isFr ? 'Habitudes illimitees' : 'Unlimited habits',
        description: isFr
            ? 'Passe Premium pour creer plus d habitudes et garder ton systeme complet.'
            : 'Upgrade to Premium to create more habits and keep your system complete.',
      );
    case 'tasks':
      return PremiumMessage(
        title: isFr ? 'Taches illimitees' : 'Unlimited tasks',
        description: isFr
            ? 'Passe Premium pour ajouter plus de taches actives.'
            : 'Upgrade to Premium to add more active tasks.',
      );
    case 'focus':
      return PremiumMessage(
        title: isFr ? 'Focus etendu' : 'Extended Focus',
        description: isFr
            ? 'Debloque des sessions Focus plus longues avec Premium.'
            : 'Unlock longer Focus sessions with Premium.',
      );
    case 'ceo_mode':
    case 'blackout':
      return PremiumMessage(
        title: isFr ? 'Blackout etendu' : 'Extended Blackout',
        description: isFr
            ? 'Debloque des sessions CEO Mode plus longues avec Premium.'
            : 'Unlock longer CEO Mode sessions with Premium.',
      );
    default:
      return PremiumMessage(
        title: isFr ? 'Debloque Premium' : 'Unlock Premium',
        description: isFr
            ? 'Active les limites et fonctionnalites avancees de WakeApp.'
            : 'Enable advanced WakeApp limits and features.',
      );
  }
}
