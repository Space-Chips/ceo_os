class TesterConfig {
  const TesterConfig._();

  static const bool testFlightPremiumEnabled = false;
  static const String testFlightBetaPremiumKey = '';

  /// DEV ONLY — force premium access on simulator/dev builds.
  /// MUST be `false` before any TestFlight / App Store build.
  static const bool devForcePremium = true;
}
