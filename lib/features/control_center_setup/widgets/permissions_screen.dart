import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../components/glass_card.dart';
import '../../../components/liquid_button.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../setup/setup_flow_controller.dart';
import '../control_center_setup_models.dart';

class PermissionsScreen extends StatelessWidget {
  final ControlCenterSetupState state;
  final bool isPersisting;
  final VoidCallback onOpenAndroidPermissions;
  final VoidCallback onFinish;

  const PermissionsScreen({
    super.key,
    required this.state,
    required this.isPersisting,
    required this.onOpenAndroidPermissions,
    required this.onFinish,
  });

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final setup = context.watch<SetupFlowController>();
    if (_isAndroid) {
      unawaited(setup.initialize());
    }
    final permissionStatus = _isAndroid
        ? (setup.allPermissionsGranted ? 'OK' : 'À activer')
        : 'Non requis sur ce device';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active les accès nécessaires',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ton centre a besoin de ces accès pour faire respecter tes règles.',
            style: AppTypography.subhead.copyWith(
              color: AppColors.secondaryLabel.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            level: GlassCardLevel.elevated,
            padding: const EdgeInsets.all(14),
            borderRadius: 22,
            border: Border.all(color: AppColors.borderStrong, width: 1),
            gradientColors: [AppColors.sectionBackground, AppColors.background],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: AppColors.accentIcon,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Statut',
                        style: AppTypography.headline.copyWith(
                          color: AppColors.label,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: AppColors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        permissionStatus,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.secondaryLabel,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PermissionRow(
                  title: 'Accessibilité',
                  subtitle: "Permet d'appliquer les protections.",
                  enabled: !_isAndroid || setup.accessibilityGranted,
                ),
                const SizedBox(height: 10),
                _PermissionRow(
                  title: 'Usage access',
                  subtitle: 'Comprend quelles apps consomment ton temps.',
                  enabled: !_isAndroid || setup.usageGranted,
                ),
                const SizedBox(height: 10),
                _PermissionRow(
                  title: 'Overlay',
                  subtitle: 'Affiche un écran de protection si nécessaire.',
                  enabled: !_isAndroid || setup.overlayGranted,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_isAndroid)
            LiquidButton(
              label: setup.allPermissionsGranted
                  ? 'Permissions OK'
                  : 'Activer les accès',
              onPressed: setup.allPermissionsGranted
                  ? null
                  : onOpenAndroidPermissions,
            )
          else
            LiquidButton(label: 'Continuer', onPressed: onFinish),
          const SizedBox(height: 10),
          _SecondaryButton(
            label: isPersisting ? 'Sauvegarde…' : 'Terminer',
            onTap: isPersisting ? null : onFinish,
          ),
          const SizedBox(height: 8),
          Text(
            'Tu pourras modifier ton centre et gérer les permissions plus tard depuis le menu.',
            style: AppTypography.caption1.copyWith(
              fontSize: 11,
              color: AppColors.tertiaryLabel.withValues(alpha: 0.78),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;

  const _PermissionRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.white.withValues(alpha: 0.05),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            enabled ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.circle,
            size: 18,
            color: enabled ? AppColors.success : AppColors.tertiaryLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.label,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: onTap == null,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.white.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              label,
              style: AppTypography.headline.copyWith(
                color: AppColors.label,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
