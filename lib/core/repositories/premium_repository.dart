import '../models/premium_models.dart';

class PremiumRepository {
  const PremiumRepository();

  Future<PremiumConfig> getConfig() async => const PremiumConfig();

  Future<PremiumRuntime> getRuntime() async {
    final config = await getConfig();
    return PremiumRuntime(config: config);
  }

  Future<PremiumCheckResult> canAccessAdvancedCalendar() async {
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canUseTheme(String presetId) async {
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canCreateTask([int currentCount = 0]) async {
    final runtime = await getRuntime();
    if (runtime.resolved.canCreateUnlimitedTasks ||
        currentCount < runtime.config.tasksFreeLimit) {
      return const PremiumCheckResult.allowed();
    }
    return PremiumCheckResult.blocked(
      reason: 'tasks',
      limit: runtime.config.tasksFreeLimit,
      current: currentCount,
    );
  }

  Future<PremiumCheckResult> canCreateNote([int currentCount = 0]) async {
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canAccessReports() async {
    return const PremiumCheckResult.allowed();
  }

  Future<PremiumCheckResult> canStartFocusSession(int minutes) async {
    final runtime = await getRuntime();
    if (runtime.resolved.canUseExtendedFocus ||
        minutes <= runtime.config.focusFreeMinutesLimit) {
      return const PremiumCheckResult.allowed();
    }
    return PremiumCheckResult.blocked(
      reason: 'focus',
      limit: runtime.config.focusFreeMinutesLimit,
      current: minutes,
    );
  }

  Future<PremiumCheckResult> canStartCeoSession(int minutes) async {
    final runtime = await getRuntime();
    if (runtime.resolved.canUseExtendedCeoMode ||
        minutes <= runtime.config.ceoModeFreeMinutesLimit) {
      return const PremiumCheckResult.allowed();
    }
    return PremiumCheckResult.blocked(
      reason: 'ceo_mode',
      limit: runtime.config.ceoModeFreeMinutesLimit,
      current: minutes,
    );
  }

  Future<void> activateClientGraceWindow() async {}

  Future<bool> waitForBillingActivation() async => false;
}
