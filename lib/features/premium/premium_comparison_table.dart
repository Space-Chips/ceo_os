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

    final rows = <_RowSpec>[
      _RowSpec(
        title: isFr ? 'Tâches' : 'Tasks',
        free: isFr ? 'Limité' : 'Limited',
        premium: isFr ? 'Illimité' : 'Unlimited',
      ),
      _RowSpec(
        title: isFr ? 'Habitudes' : 'Habits',
        free: isFr ? 'Limité' : 'Limited',
        premium: isFr ? 'Illimité' : 'Unlimited',
      ),
      _RowSpec(
        title: isFr ? 'Notes' : 'Notes',
        free: isFr ? 'Limité' : 'Limited',
        premium: isFr ? 'Illimité' : 'Unlimited',
      ),
      _RowSpec(
        title: isFr ? 'Focus' : 'Focus',
        free: isFr ? 'Limites quotidiennes' : 'Daily limits',
        premium: isFr ? 'Sessions illimitées + durées longues' : 'Unlimited + long sessions',
      ),
      _RowSpec(
        title: isFr ? 'Blackout' : 'Blackout',
        free: isFr ? 'Limites hebdo + durées courtes' : 'Weekly limits + shorter',
        premium: isFr ? 'Sessions illimitées + durées longues' : 'Unlimited + long sessions',
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
        free: isFr ? 'Gratuits' : 'Free',
        premium: isFr ? 'Thèmes Premium' : 'Premium themes',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderStrong, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.themeGlow.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _headerCell(
                    isFr ? 'Fonctionnalité' : 'Feature',
                    AppColors.secondaryLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _headerCell(headerFree, AppColors.secondaryLabel)),
                const SizedBox(width: 10),
                Expanded(child: _headerCell(headerPremium, AppColors.secondaryLabel)),
              ],
            ),
            const SizedBox(height: 10),
            for (final row in rows) ...[
              _divider(),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.title,
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _valueCell(row.free, AppColors.secondaryLabel)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _valueCell(
                      row.premium,
                      AppColors.secondaryLabel,
                      emphasize: true,
                      primaryColor: AppColors.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            _divider(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Text(
                coffeeLine,
                textAlign: TextAlign.center,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.label.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.24),
      );

  Widget _headerCell(String text, Color secondary) => Text(
        text,
        style: AppTypography.overline.copyWith(
          color: secondary.withValues(alpha: 0.75),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      );

  Widget _valueCell(
    String text,
    Color secondary, {
    bool emphasize = false,
    Color? primaryColor,
  }) =>
      Text(
        text,
        style: AppTypography.footnote.copyWith(
          color: emphasize
              ? (primaryColor ?? AppColors.label)
              : secondary.withValues(alpha: 0.9),
          fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          height: 1.25,
        ),
      );
}

class _RowSpec {
  final String title;
  final String free;
  final String premium;

  const _RowSpec({required this.title, required this.free, required this.premium});
}
