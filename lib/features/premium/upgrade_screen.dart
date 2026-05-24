import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../components/premium_surface_card.dart';
import '../../core/models/premium_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'premium_comparison_table.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep this screen reactive to live theme changes.
    context.watch<ThemeProvider>();
    final languageCode = context.watch<LanguageProvider>().languageCode;
    final isFr = languageCode.trim().toLowerCase() == 'fr';
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.92),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        middle: Text(
          isFr ? 'Abonnement' : 'Upgrade',
          style: AppTypography.headline.copyWith(color: AppColors.label),
        ),
      ),
      child: AmbientBackdrop(
        child: SafeArea(
          child: FutureBuilder<PremiumRuntime>(
            future: PremiumRepository().getRuntime(),
            builder: (context, snapshot) {
              final runtime = snapshot.data;
              if (runtime == null) {
                return const Center(child: CupertinoActivityIndicator());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  PremiumSurfaceCard(
                    child: PremiumPaywallContent(
                      runtime: runtime,
                      message: premiumMessageForReason(
                        'upgrade',
                        languageCode: languageCode,
                      ),
                      reason: 'upgrade',
                      isFr: isFr,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PremiumComparisonTable(isFr: isFr),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
