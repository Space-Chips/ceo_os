import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/premium_paywall.dart';
import '../repositories/premium_repository.dart';

class PremiumOnboardingPromptService {
  static const String _keyPrefix = 'premium_onboarding_prompt_shown_v1';

  static Future<void> maybeShow(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '${_keyPrefix}_$userId';
    if (prefs.getBool(key) ?? false) return;

    final runtime = await PremiumRepository().getRuntime();
    if (!context.mounted) return;

    // TestFlight users are premium automatically; do not show the upsell.
    if (runtime.resolved.isPremiumUser) {
      await prefs.setBool(key, true);
      return;
    }

    await prefs.setBool(key, true);
    if (!context.mounted) return;
    await showPremiumPaywallSheet(
      context: context,
      runtime: runtime,
      reason: 'onboarding',
    );
  }
}
