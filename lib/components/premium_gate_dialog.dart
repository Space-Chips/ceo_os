import 'package:flutter/cupertino.dart';

import '../core/models/premium_models.dart';
import 'premium_paywall.dart';

Future<void> showPremiumGateDialog(
  BuildContext context,
  PremiumCheckResult result,
) async {
  if (result.allowed) return;
  await showPremiumPaywallSheet(
    context: context,
    checkResult: result,
  );
}
