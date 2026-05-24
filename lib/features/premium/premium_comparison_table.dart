import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PremiumComparisonTable extends StatelessWidget {
  final bool isFr;

  const PremiumComparisonTable({super.key, required this.isFr});

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.isDark ? AppColors.surface : AppColors.cardBackgroundAlt;
    final headerFree = isFr ? 'Gratuit' : 'Free';
    final headerPremium = isFr ? 'Premium' : 'Premium';
    final coffeeLine = isFr
        ? "Tout ça pour le prix d'un café par mois."
        : 'All this for the price of a coffee per month.';

    // NOTE: Limits below must mirror PremiumConfig fallbacks
    // (lib/core/repositories/premium_repository.dart : _configFromJson).
    final rows = <_RowSpec>[
      _RowSpec(
        title: isFr ? 'Tâches' : 'Tasks',
        free: isFr ? '5 max' : 'Up to 5',
        premium: isFr ? 'Illimité' : 'Unlimited',
      ),
      _RowSpec(
        title: isFr ? 'Habitudes' : 'Habits',
        free: isFr ? '3 max' : 'Up to 3',
        premium: isFr ? 'Illimité' : 'Unlimited',
      ),
      _RowSpec(
        title: isFr ? 'Notes' : 'Notes',
        free: isFr ? '50 max' : 'Up to 50',
        premium: isFr ? 'Illimité' : 'Unlimited',
      ),
      _RowSpec(
        title: isFr ? 'Focus' : 'Focus',
        free: isFr ? '1 / jour · 1 h' : '1/day · 1h',
        premium: isFr ? 'Illimité · durée libre' : 'Unlimited · any duration',
      ),
      _RowSpec(
        title: isFr ? 'Blackout' : 'Blackout',
        free: isFr ? '1 / semaine' : '1/week',
        premium: isFr ? 'Illimité · durée libre' : 'Unlimited · any duration',
      ),
      _RowSpec(
        title: isFr ? 'Rapports' : 'Reports',
        free: isFr ? 'Essentiels' : 'Essentials',
        premium: isFr ? 'Avancés' : 'Advanced',
      ),
      _RowSpec(
        title: isFr ? 'Calendrier avancé' : 'Advanced calendar',
        free: isFr ? 'Basique' : 'Basic',
        premium: isFr ? 'Débloqué' : 'Unlocked',
      ),
      _RowSpec(
        title: isFr ? 'Thèmes' : 'Themes',
        free: isFr ? 'Gratuits' : 'Free only',
        premium: isFr ? 'Thèmes Premium' : 'Premium themes',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.45),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.06),
            blurRadius: 22,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _headerCell(
                    isFr ? 'Fonctionnalité' : 'Feature',
                    AppColors.tertiaryLabel,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: _headerCell(headerFree, AppColors.tertiaryLabel),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: _headerCell(
                    headerPremium,
                    AppColors.primaryOrange,
                    accent: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < rows.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      rows[i].title,
                      style: AppTypography.callout.copyWith(
                        fontSize: 15,
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].free,
                      style: AppTypography.footnote.copyWith(
                        fontSize: 13,
                        color: AppColors.tertiaryLabel.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].premium,
                      style: AppTypography.footnote.copyWith(
                        fontSize: 13,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              if (i < rows.length - 1) ...[
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 16),
              ],
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: 0.18),
                    AppColors.primaryOrange.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.32),
                  width: 0.6,
                ),
              ),
              child: Text(
                coffeeLine,
                textAlign: TextAlign.center,
                style: AppTypography.footnote.copyWith(
                  fontSize: 13,
                  color: AppColors.label,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 0.5,
        color: AppColors.border.withValues(alpha: 0.18),
      );

  Widget _headerCell(String text, Color color, {bool accent = false}) => Text(
        text,
        style: AppTypography.overline.copyWith(
          fontSize: 11,
          color: accent ? color : color.withValues(alpha: 0.85),
          fontWeight: accent ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: 1.6,
        ),
      );
}

class _RowSpec {
  final String title;
  final String free;
  final String premium;

  const _RowSpec({required this.title, required this.free, required this.premium});
}
