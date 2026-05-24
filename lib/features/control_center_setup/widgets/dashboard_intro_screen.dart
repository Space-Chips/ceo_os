import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../components/glass_card.dart';
import '../../../components/liquid_button.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';
import 'control_center_slot_grid.dart';

class DashboardIntroScreen extends StatefulWidget {
  final ControlCenterSetupState state;
  final VoidCallback onContinue;

  const DashboardIntroScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  State<DashboardIntroScreen> createState() => _DashboardIntroScreenState();
}

class _DashboardIntroScreenState extends State<DashboardIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _stagger(int index, double global) {
    final start = 0.25 + index * 0.12;
    final end = start + 0.36;
    final t = ((global - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final slots = widget.state.slots;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tout reste à portée de main',
                    style: AppTypography.largeTitle.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ton centre affiche aussi tes notes, ton élan et tes raccourcis intégrés.',
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final g = _controller.value;
                      final slideUp = Tween<double>(
                        begin: 0.0,
                        end: -8.0,
                      ).transform(Curves.easeOutCubic.transform(g));
                      return Transform.translate(
                        offset: Offset(0, slideUp),
                        child: GlassCard(
                          level: GlassCardLevel.elevated,
                          padding: const EdgeInsets.all(14),
                          borderRadius: 24,
                          border: Border.all(
                            color: AppColors.borderStrong,
                            width: 1,
                          ),
                          gradientColors: [
                            AppColors.sectionBackground,
                            AppColors.background,
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Centre',
                                style: AppTypography.overline.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: AppColors.secondaryLabel.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ControlCenterSlotGrid(slots: slots),
                              const SizedBox(height: 14),
                              Text(
                                'Dashboard intégré',
                                style: AppTypography.overline.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: AppColors.secondaryLabel.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _IntroWidgets(
                                globalProgress: g,
                                stagger: _stagger,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          LiquidButton(label: 'Continuer', onPressed: widget.onContinue),
        ],
      ),
    );
  }
}

class _IntroWidgets extends StatelessWidget {
  final double globalProgress;
  final double Function(int index, double global) stagger;

  const _IntroWidgets({required this.globalProgress, required this.stagger});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Focus', CupertinoIcons.bolt_fill),
      ('Notes', CupertinoIcons.doc_text_fill),
      ('Win streak', CupertinoIcons.flame_fill),
      ('Rank', CupertinoIcons.star_fill),
      ('Blackout', CupertinoIcons.moon_fill),
    ];
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _widgetRow(
            label: items[i].$1,
            icon: items[i].$2,
            progress: stagger(i, globalProgress),
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _widgetRow({
    required String label,
    required IconData icon,
    required double progress,
  }) {
    final opacity = progress.clamp(0.0, 1.0).toDouble();
    final translate = Tween<double>(
      begin: 12.0,
      end: 0.0,
    ).transform(Curves.easeOutCubic.transform(progress));
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, translate),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.white.withValues(alpha: 0.05),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.accentIcon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.tertiaryLabel.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
