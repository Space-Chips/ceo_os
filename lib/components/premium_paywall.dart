import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/premium_models.dart';
import '../core/providers/language_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/repositories/premium_repository.dart';
import '../core/services/billing_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'glass_card.dart';
import 'legal_document_sheet.dart';
import 'liquid_button.dart';

Future<void> showPremiumPaywallSheet({
  required BuildContext context,
  PremiumRuntime? runtime,
  PremiumCheckResult? checkResult,
  String? reason,
}) async {
  final languageCode = context.read<LanguageProvider>().languageCode;
  final resolvedRuntime = runtime ?? await PremiumRepository().getRuntime();
  if (!context.mounted) return;

  final message = premiumMessageForReason(
    reason ?? checkResult?.reason,
    languageCode: languageCode,
  );

  await showCupertinoModalPopup<void>(
    context: context,
    barrierColor: AppColors.overlayScrim.withValues(alpha: 0.76),
    builder: (sheetContext) => PremiumPaywallSheet(
      runtime: resolvedRuntime,
      message: message,
      limit: checkResult?.limit,
      current: checkResult?.current,
      isFr: languageCode.trim().toLowerCase() == 'fr',
    ),
  );
}

class PremiumPaywallSheet extends StatelessWidget {
  final PremiumRuntime runtime;
  final PremiumMessage message;
  final int? limit;
  final int? current;
  final bool isFr;

  const PremiumPaywallSheet({
    super.key,
    required this.runtime,
    required this.message,
    required this.isFr,
    this.limit,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure paywall updates when the user switches themes while the sheet is open.
    context.watch<ThemeProvider>();
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: GlassCard(
              borderRadius: 28,
              level: GlassCardLevel.elevated,
              textured: true,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: PremiumPaywallContent(
                runtime: runtime,
                message: message,
                limit: limit,
                current: current,
                isFr: isFr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumPaywallContent extends StatefulWidget {
  final PremiumRuntime runtime;
  final PremiumMessage message;
  final int? limit;
  final int? current;
  final bool isFr;
  final String? reason;
  final bool showRestoreButton;

  const PremiumPaywallContent({
    super.key,
    required this.runtime,
    required this.message,
    required this.isFr,
    this.limit,
    this.current,
    this.reason,
    this.showRestoreButton = true,
  });

  @override
  State<PremiumPaywallContent> createState() => _PremiumPaywallContentState();
}

class _PremiumPaywallContentState extends State<PremiumPaywallContent> {
  late final Future<List<BillingPackageOption>> _packageOptionsFuture =
      BillingService().getPackageOptions();
  String? _selectedIdentifier;
  bool _purchaseInFlight = false;
  bool _restoreInFlight = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String get _storeName => _isAndroid ? 'Google Play' : 'App Store';

  Future<void> _openManageSubscriptions() async {
    final Uri uri = _isAndroid
        ? Uri.parse('https://play.google.com/store/account/subscriptions')
        : Uri.parse('https://apps.apple.com/account/subscriptions');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openTerms() async {
    await LegalDocumentSheet.showTermsOfUse(context, isFr: widget.isFr);
  }

  Future<void> _openPrivacy() async {
    await LegalDocumentSheet.showPrivacyPolicy(context, isFr: widget.isFr);
  }

  String _purchaseButtonLabel(BillingPackageOption? selected) {
    if (!widget.runtime.config.paywallEnabled) {
      return widget.isFr ? 'Premium bientôt disponible' : 'Premium coming soon';
    }
    if (selected == null) return widget.isFr ? 'Indisponible' : 'Unavailable';
    return widget.isFr ? 'Passer Premium' : 'Upgrade to Premium';
  }

  BillingPackageOption? _resolveSelected(List<BillingPackageOption> options) {
    if (options.isEmpty) return null;
    if (_selectedIdentifier == null) return options.first;
    return options.firstWhere(
      (opt) => opt.identifier == _selectedIdentifier,
      orElse: () => options.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BillingPackageOption>>(
      future: _packageOptionsFuture,
      builder: (context, snapshot) {
        final options = snapshot.data ?? const <BillingPackageOption>[];
        final selected = _resolveSelected(options);
        final purchaseEnabled =
            !_purchaseInFlight &&
            widget.runtime.config.paywallEnabled &&
            selected != null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'WakeApp Premium',
              style: AppTypography.overline.copyWith(
                color: AppColors.accentText.withValues(alpha: 0.9),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.message.title,
              style: AppTypography.title1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.label,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.message.description,
              style: AppTypography.body.copyWith(
                fontSize: 15,
                color: AppColors.secondaryLabel.withValues(alpha: 0.92),
                height: 1.42,
              ),
            ),
            if (widget.limit != null && widget.current != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                borderRadius: 18,
                level: GlassCardLevel.subtle,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isFr ? 'Utilisation actuelle' : 'Current usage',
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.current} / ${widget.limit}',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              widget.isFr ? 'Included with Premium' : 'Included with Premium',
              style: AppTypography.headline.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._benefitsForReason(widget.message, widget.runtime, widget.isFr)
                .map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            size: 16,
                            color: AppColors.accentText.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            benefit,
                            style: AppTypography.callout.copyWith(
                              color: AppColors.secondaryLabel.withValues(
                                alpha: 0.92,
                              ),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 14),
            if (options.isNotEmpty) ...[
              ...options.map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PackageOptionCard(
                    option: opt,
                    selected: opt.identifier == selected?.identifier,
                    onTap: () =>
                        setState(() => _selectedIdentifier = opt.identifier),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            LiquidButton(
              label: _purchaseButtonLabel(selected),
              isLoading: _purchaseInFlight,
              fullWidth: true,
              onPressed: purchaseEnabled
                  ? () async {
                      setState(() => _purchaseInFlight = true);
                      try {
                        final result = await BillingService().purchasePremium();
                        if (!context.mounted) return;
                        final title = result.succeeded
                            ? (widget.isFr ? 'Premium activé' : 'Premium activated')
                            : (widget.isFr ? 'Synchronisation en cours' : 'Activation pending');
                        final message = result.succeeded
                            ? (widget.isFr
                                ? 'Ton achat a été confirmé. Ton accès Premium est maintenant actif.'
                                : 'Your purchase was confirmed. Premium is now active.')
                            : (widget.isFr
                                ? 'Le store a confirmé ton achat. Ton accès Premium est en cours de synchronisation.'
                                : 'Store confirmed your purchase. Premium is still syncing.');
                        showCupertinoDialog<void>(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: Text(title),
                            content: Text(message),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _purchaseInFlight = false);
                        }
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _restoreInFlight
                        ? null
                        : () async {
                            setState(() => _restoreInFlight = true);
                            try {
                              final result =
                                  await BillingService().restorePurchases();
                              if (!context.mounted) return;
                              final title = result.succeeded
                                  ? (widget.isFr ? 'Restauré' : 'Restored')
                                  : (widget.isFr ? 'Échec' : 'Restore failed');
                              showCupertinoDialog<void>(
                                context: context,
                                builder: (_) => CupertinoAlertDialog(
                                  title: Text(title),
                                  content: Text(result.message ?? ''),
                                  actions: [
                                    CupertinoDialogAction(
                                      isDefaultAction: true,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _restoreInFlight = false);
                              }
                            }
                          },
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.topBarControlBackground,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.45),
                        ),
                      ),
                      child: _restoreInFlight
                          ? CupertinoActivityIndicator()
                          : Text(
                              widget.isFr ? 'Restaurer' : 'Restore',
                              style: AppTypography.subhead.copyWith(
                                color: AppColors.label,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _openManageSubscriptions,
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.topBarControlBackground,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        widget.isFr ? 'Gérer' : 'Manage',
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _openManageSubscriptions,
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.topBarControlBackground,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        widget.isFr ? 'Gérer' : 'Manage',
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.isFr
                  ? (widget.showRestoreButton
                      ? 'Paiement traité par $_storeName. Abonnement à renouvellement automatique, annulable dans les réglages Apple ID/Google Play. Restaurer disponible ci‑dessus.'
                      : 'Paiement traité par $_storeName. Abonnement à renouvellement automatique, annulable dans les réglages Apple ID/Google Play.')
                  : (widget.showRestoreButton
                      ? 'Billing is processed by $_storeName. Auto‑renewing subscription, cancel anytime in your Apple ID/Google Play settings. Restore is available above.'
                      : 'Billing is processed by $_storeName. Auto‑renewing subscription, cancel anytime in your Apple ID/Google Play settings.'),
              style: AppTypography.caption1.copyWith(
                color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _openTerms,
                    child: Text(
                      widget.isFr ? 'Conditions' : 'Terms',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.secondaryLabel.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _openPrivacy,
                    child: Text(
                      widget.isFr ? 'Confidentialité' : 'Privacy',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.secondaryLabel.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

List<String> _benefitsForReason(
  PremiumMessage message,
  PremiumRuntime runtime,
  bool isFr,
) {
  // Keep this tight & high-converting; do not overpromise.
  final base = isFr
      ? <String>[
          'Habitudes illimitées',
          'Tâches illimitées',
          'Sessions Focus & Blackout étendues',
          'Rapports avancés + thèmes Premium',
        ]
      : <String>[
          'Unlimited habits',
          'Unlimited tasks',
          'Extended Focus & Blackout sessions',
          'Advanced reports + premium themes',
        ];
  return base;
}

class _PackageOptionCard extends StatelessWidget {
  final BillingPackageOption option;
  final bool selected;
  final VoidCallback onTap;

  const _PackageOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 18,
        level: selected ? GlassCardLevel.elevated : GlassCardLevel.subtle,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        border: Border.all(
          color: selected
              ? AppColors.accentText.withValues(alpha: 0.28)
              : AppColors.border.withValues(alpha: 0.35),
          width: 0.8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTypography.headline.copyWith(
                      color: AppColors.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.durationLabel,
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              option.priceLabel,
              style: AppTypography.headline.copyWith(
                color: AppColors.label,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
