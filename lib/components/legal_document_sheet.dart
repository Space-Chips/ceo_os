import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'glass_card.dart';

class LegalDocumentSheet {
  const LegalDocumentSheet._();

  static Future<void> showPrivacyPolicy(BuildContext context, {bool isFr = false}) async {
    final title = isFr ? 'Politique de confidentialité' : 'Privacy Policy';
    final sections = const <_LegalSection>[
      _LegalSection(
        'Information We Collect',
        'We collect the account details required to sign you in and operate the product, including your email address, profile name, authentication identifiers, habits, tasks, calendar events created inside WakeApp, focus sessions, selected blocked apps and websites, settings, rank and streak history, and billing status needed to unlock Premium.',
      ),
      _LegalSection(
        'How Data Is Used',
        'Data is used to authenticate your account, sync your data across your devices, run focus protections, restore purchases, and provide support when you contact us. On iPhone, Screen Time / Family Controls activity and device usage data stay on-device and are not synced, exported, or shared beyond the individual user. On Android, blocking and daily-limit enforcement use on-device permission flows such as Accessibility and Usage Access, and are not used for ads or unrelated analytics. Personal data is not sold to third parties.',
      ),
      _LegalSection(
        'Third-Party Services',
        'WakeApp uses Supabase for account, database, and cloud sync infrastructure, Google Sign-In when you choose Google authentication, RevenueCat plus Apple or Google Play for subscription and purchase status, and platform system frameworks for blocking, widgets, notifications, and scheduling. These services process only the data needed to provide their part of the product.',
      ),
      _LegalSection(
        'Storage and Security',
        'Productivity records and account settings may be stored in Supabase to support sync and continuity. On iPhone, Screen Time / Family Controls selections, schedules, limits, and activity data remain local to the device. On Android, selected app and website protections are enforced on-device, and usage measurements used for daily limits are not used for ads or unrelated profiling. Row-level security is used so users can only access records they own. Purchase state may also be synced from RevenueCat to determine Premium access.',
      ),
      _LegalSection(
        'Your Rights',
        'You can update profile information inside the app and permanently delete your account from the settings area. Account deletion is irreversible and removes the associated cloud data we control.',
      ),
    ];

    await _show(context, title: title, subtitle: isFr ? 'Dernière mise à jour : Déc 2025' : 'Last updated: Dec 2025', sections: sections);
  }

  static Future<void> showTermsOfUse(BuildContext context, {bool isFr = false}) async {
    final storeName = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Google Play',
      TargetPlatform.iOS => 'App Store',
      _ => 'the store',
    };
    final subscriptionSettingsLabel = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Google Play subscription settings',
      TargetPlatform.iOS => 'Apple ID subscription settings',
      _ => 'your store subscription settings',
    };
    final title = isFr ? "Conditions d'utilisation" : 'Terms of Use';
    final sections = <_LegalSection>[
      const _LegalSection(
        'Acceptance',
        'Using this app means you accept the terms and operate within lawful use.',
      ),
      const _LegalSection(
        'Account Responsibility',
        'You are responsible for the confidentiality of your account credentials and activities under your account.',
      ),
      const _LegalSection(
        'Service Availability',
        'Service may occasionally be interrupted for maintenance, updates, or infrastructure events.',
      ),
      _LegalSection(
        'Subscriptions',
        'Premium subscriptions and purchases are processed by $storeName and may renew automatically unless canceled in your $subscriptionSettingsLabel. Purchase restoration is available from the Premium paywall.',
      ),
      const _LegalSection(
        'Termination',
        'Accounts may be suspended for terms violations. Users can also terminate their account through deletion flow.',
      ),
    ];

    await _show(context, title: title, subtitle: isFr ? 'Dernière mise à jour : Déc 2025' : 'Last updated: Dec 2025', sections: sections);
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_LegalSection> sections,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      barrierColor: AppColors.overlayScrim.withValues(alpha: 0.76),
      builder: (popupContext) => BackdropFilter(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.headline.copyWith(
                                  color: AppColors.label,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.secondaryLabel
                                      .withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(popupContext).pop(),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: AppColors.secondaryLabel
                                .withValues(alpha: 0.82),
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.62,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: sections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final section = sections[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: AppColors.sectionBackground.withValues(
                                alpha: 0.55,
                              ),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.title,
                                  style: AppTypography.overline.copyWith(
                                    fontSize: 11,
                                    color: AppColors.primaryOrange,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  section.body,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppColors.secondaryLabel,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection(this.title, this.body);
}
