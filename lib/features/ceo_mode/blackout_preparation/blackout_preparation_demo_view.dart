import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'blackout_preparation_animation_view.dart';

class BlackoutPreparationDemoView extends StatelessWidget {
  const BlackoutPreparationDemoView({
    super.key,
    required this.onPrimary,
    required this.onSecondary,
  });

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.t('blackout_prep_demo_title'),
          style: AppTypography.title2.copyWith(
            fontSize: 28,
            height: 1.14,
            color: AppColors.label,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          language.t('blackout_prep_demo_body'),
          style: AppTypography.body.copyWith(
            fontSize: 15,
            height: 1.42,
            color: AppColors.secondaryLabel.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 16),
        const Expanded(child: BlackoutPreparationAnimationView()),
        const SizedBox(height: 18),
        _PrimaryButton(label: "J'optimise mon écran", onTap: onPrimary),
        const SizedBox(height: 10),
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onSecondary,
            child: Text(
              language.t('focus_later'),
              style: AppTypography.callout.copyWith(
                fontSize: 15,
                color: AppColors.secondaryLabel.withValues(alpha: 0.84),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: AppColors.buttonGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.themeGlow.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.callout.copyWith(
            fontSize: 16,
            color: AppColors.onAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
