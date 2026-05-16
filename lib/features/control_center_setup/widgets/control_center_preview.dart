import 'package:flutter/cupertino.dart';

import '../../../components/glass_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';
import 'control_center_slot_grid.dart';

class ControlCenterPreview extends StatelessWidget {
  final ControlCenterSetupState state;
  final bool showDashboard;
  final void Function(String itemId)? onRemoveItem;
  final List<double>? slotAppearProgress;
  final int? pulsingSlotIndex;
  final List<GlobalKey>? slotKeys;

  const ControlCenterPreview({
    super.key,
    required this.state,
    this.showDashboard = true,
    this.onRemoveItem,
    this.slotAppearProgress,
    this.pulsingSlotIndex,
    this.slotKeys,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = state.enabledDashboardWidgets;
    return GlassCard(
      level: GlassCardLevel.elevated,
      padding: const EdgeInsets.all(14),
      borderRadius: 24,
      border: Border.all(color: AppColors.borderStrong, width: 1),
      gradientColors: [AppColors.sectionBackground, AppColors.background],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 2,
              color: AppColors.secondaryLabel.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          ControlCenterSlotGrid(
            slots: state.slots,
            showRemove: onRemoveItem != null,
            onRemoveItem: onRemoveItem,
            appearProgressByIndex: slotAppearProgress,
            pulsingIndex: pulsingSlotIndex,
            slotKeys: slotKeys,
          ),
          if (showDashboard) ...[
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _DashboardPreview(widgets: widgets),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardPreview extends StatelessWidget {
  final Set<DashboardWidget> widgets;

  const _DashboardPreview({required this.widgets});

  @override
  Widget build(BuildContext context) {
    final items = <_WidgetChipData>[
      _WidgetChipData(
        widget: DashboardWidget.focus,
        label: 'Focus',
        icon: CupertinoIcons.bolt_fill,
      ),
      _WidgetChipData(
        widget: DashboardWidget.notes,
        label: 'Notes',
        icon: CupertinoIcons.doc_text_fill,
      ),
      _WidgetChipData(
        widget: DashboardWidget.winStreak,
        label: 'Win streak',
        icon: CupertinoIcons.flame_fill,
      ),
      _WidgetChipData(
        widget: DashboardWidget.rank,
        label: 'Rank',
        icon: CupertinoIcons.star_fill,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale:
                          Tween<double>(begin: 0.98, end: 1).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: widgets.contains(item.widget)
                    ? _WidgetChip(
                        key: ValueKey(item.widget),
                        label: item.label,
                        icon: item.icon,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
        if (widgets.contains(DashboardWidget.blackoutButton)) ...[
          const SizedBox(height: 12),
          Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: AppColors.buttonGradient),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.moon_fill, color: AppColors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Blackout',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _WidgetChipData {
  final DashboardWidget widget;
  final String label;
  final IconData icon;

  const _WidgetChipData({
    required this.widget,
    required this.label,
    required this.icon,
  });
}

class _WidgetChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _WidgetChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.white.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accentIcon),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.footnote.copyWith(
              color: AppColors.label,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
