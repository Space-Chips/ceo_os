import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class BlackoutPreparationChecklistView extends StatelessWidget {
  const BlackoutPreparationChecklistView({
    super.key,
    required this.onDone,
    required this.onSkip,
  });

  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Maintiens une app',
      'Fais-la glisser sur une autre',
      'Crée un dossier "Hors Focus"',
      'Ajoute les apps système visibles',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          'Fais-le en 20 secondes',
          style: AppTypography.title1.copyWith(
            fontSize: 34,
            height: 1.08,
            letterSpacing: -0.8,
            color: AppColors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Quand c'est terminé, reviens ici.",
          style: AppTypography.body.copyWith(
            fontSize: 15,
            height: 1.42,
            color: AppColors.secondaryLabel.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
            ),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 0.9,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentSoft.withValues(alpha: 0.32),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.accentText,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          steps[i],
                          style: AppTypography.callout.copyWith(
                            fontSize: 15,
                            color: AppColors.label.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (i != steps.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const Spacer(),
        _PrimaryButton(label: "C'est fait", onTap: onDone),
        const SizedBox(height: 10),
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onSkip,
            child: Text(
              "Passer pour l'instant",
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
