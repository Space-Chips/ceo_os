import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/components.dart';
import '../../components/premium_surface_card.dart';
import '../../core/models/premium_models.dart';
import '../../core/config/tester_config.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/services/billing_diagnostics_service.dart';
import '../../core/services/app_environment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'premium_comparison_table.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  Future<Map<String, String>> _loadDebugInfo() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isTestFlight = await AppEnvironmentService.isTestFlight();
    final prefs = await SharedPreferences.getInstance();
    final key = uid == null ? null : 'testflight_premium_sync_at_v1_$uid';
    final millis = key == null ? null : prefs.getInt(key);
    final lastSync = millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis).toIso8601String();
    return <String, String>{
      'build_channel': isTestFlight ? 'TestFlight' : 'Store/Dev',
      'testflight_enabled': '${TesterConfig.testFlightPremiumEnabled}',
      'beta_key_present':
          TesterConfig.testFlightBetaPremiumKey.trim().isNotEmpty
          ? 'true'
          : 'false',
      'server_override_last_sync': lastSync ?? 'never',
    };
  }

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
                  PremiumComparisonTable(isFr: isFr),
                  const SizedBox(height: 14),
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
                  GlassCard(
                    borderRadius: 20,
                    level: GlassCardLevel.subtle,
                    textured: false,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isFr ? 'Support' : 'Support',
                          style: AppTypography.title3.copyWith(
                            color: AppColors.label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<String, String>>(
                          future: _loadDebugInfo(),
                          builder: (context, debugSnap) {
                            final info = debugSnap.data;
                            if (info == null) return const SizedBox.shrink();
                            final lines = <String>[
                              'Channel: ${info['build_channel']}',
                              'TestFlight premium enabled: ${info['testflight_enabled']}',
                              'Beta key present: ${info['beta_key_present']}',
                              'Server override last sync: ${info['server_override_last_sync']}',
                              'Status: ${runtime.subscriptionStatus}',
                              'Resolved premium: ${runtime.resolved.isPremiumUser}',
                              'Grace active: ${runtime.resolved.clientGraceActive}',
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                lines.join('\n'),
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.secondaryLabel.withValues(
                                    alpha: 0.78,
                                  ),
                                  height: 1.25,
                                ),
                              ),
                            );
                          },
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.sectionBackground.withValues(
                            alpha: 0.55,
                          ),
                          onPressed: () async {
                            final text = await BillingDiagnosticsService()
                                .exportText();
                            await Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              await showCupertinoDialog<void>(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: Text(
                                    isFr
                                        ? 'Diagnostics copiés'
                                        : 'Diagnostics copied',
                                  ),
                                  content: Text(
                                    isFr
                                        ? 'Colle-les dans un email au support si besoin.'
                                        : 'Paste them into a support email if needed.',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: Text(isFr ? 'OK' : 'OK'),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.doc_on_doc,
                                color: AppColors.label,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isFr
                                      ? 'Copier diagnostics paiement'
                                      : 'Copy purchase diagnostics',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.label,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
