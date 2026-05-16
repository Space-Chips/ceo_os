import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FocusPreparationIntroView extends StatelessWidget {
  const FocusPreparationIntroView({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          language.t('focus_prep_intro_title'),
          style: AppTypography.title1.copyWith(
            fontSize: 34,
            height: 1.08,
            letterSpacing: -0.8,
            color: AppColors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          language.t('focus_prep_intro_body'),
          style: AppTypography.body.copyWith(
            fontSize: 16,
            height: 1.45,
            color: AppColors.secondaryLabel.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBackgroundAlt.withValues(alpha: 0.94),
                AppColors.cardBase.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: AppColors.borderStrong.withValues(alpha: 0.95),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentSoft.withValues(alpha: 0.26),
                ),
                child: Icon(
                  CupertinoIcons.lock_shield_fill,
                  size: 18,
                  color: AppColors.accentIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language.t('focus_prep_intro_goal'),
                  style: AppTypography.callout.copyWith(
                    fontSize: 14,
                    color: AppColors.secondaryLabel.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _PrimaryButton(label: language.t('focus_continue'), onTap: onContinue),
        const SizedBox(height: 10),
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onSkip,
            child: Text(
              language.t('focus_skip'),
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
