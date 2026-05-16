import 'package:flutter/cupertino.dart';

import '../../../components/glass_card.dart';
import '../../../components/liquid_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';
import 'control_center_preview.dart';

class ControlCenterEmptyState extends StatefulWidget {
  final VoidCallback onPrimary;

  const ControlCenterEmptyState({super.key, required this.onPrimary});

  @override
  State<ControlCenterEmptyState> createState() => _ControlCenterEmptyStateState();
}

class _ControlCenterEmptyStateState extends State<ControlCenterEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _slotProgress(int index, double global) {
    final start = index * 0.14;
    final end = start + 0.36;
    final t = ((global - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final empty = ControlCenterSetupState.initial().copyWith(
      selectedModules: const [],
      selectedShortcuts: const [],
      enabledDashboardWidgets: const {},
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Construis ton centre de contrôle',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute tes apps, tes raccourcis et ce qui compte vraiment.',
            style: AppTypography.subhead.copyWith(
              color: AppColors.secondaryLabel.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final g = _controller.value;
              return GlassCard(
                level: GlassCardLevel.elevated,
                padding: const EdgeInsets.all(14),
                borderRadius: 24,
                border: Border.all(color: AppColors.borderStrong, width: 1),
                gradientColors: [
                  AppColors.sectionBackground,
                  AppColors.background,
                ],
                child: ControlCenterPreview(
                  state: empty,
                  showDashboard: false,
                  slotAppearProgress: [
                    _slotProgress(0, g),
                    _slotProgress(1, g),
                    _slotProgress(2, g),
                    _slotProgress(3, g),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          LiquidButton(label: 'Choisir mes apps', onPressed: widget.onPrimary),
          const SizedBox(height: 10),
          Text(
            '1 écran = 1 idée. Tu construis, on guide.',
            style: AppTypography.caption1.copyWith(
              fontSize: 11,
              color: AppColors.tertiaryLabel.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
