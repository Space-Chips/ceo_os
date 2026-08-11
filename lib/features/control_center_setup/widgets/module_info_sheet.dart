import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../../../components/glass_card.dart';
import '../../../components/liquid_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';

class ModuleInfoSheet extends StatefulWidget {
  final ControlCenterModuleItem module;
  final bool canAdd;
  final VoidCallback onAdd;

  const ModuleInfoSheet({
    super.key,
    required this.module,
    required this.canAdd,
    required this.onAdd,
  });

  @override
  State<ModuleInfoSheet> createState() => _ModuleInfoSheetState();
}

class _ModuleInfoSheetState extends State<ModuleInfoSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.sectionBackground.withValues(alpha: 0.92),
                    AppColors.background.withValues(alpha: 0.92),
                  ],
                ),
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Icon(
                            module.icon,
                            color: AppColors.accentIcon,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                module.title,
                                style: AppTypography.title3.copyWith(
                                  color: AppColors.label,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                module.subtitle,
                                style: AppTypography.footnote.copyWith(
                                  color: AppColors.secondaryLabel.withValues(
                                    alpha: 0.72,
                                  ),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: AppColors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 18,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: _ModuleMiniAnimation(
                        module: module.module,
                        animation: _controller,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'En bref',
                      style: AppTypography.overline.copyWith(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      module.subtitle,
                      style: AppTypography.body.copyWith(
                        color: AppColors.label,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LiquidButton(
                      label: widget.canAdd ? 'Ajouter' : 'Ajouté',
                      onPressed: widget.canAdd
                          ? () {
                              widget.onAdd();
                              Navigator.of(context).pop();
                            }
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _SheetSecondaryButton(
                      label: 'Fermer',
                      onTap: () => Navigator.of(context).pop(),
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

class _SheetSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SheetSecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
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
    );
  }
}

class _ModuleMiniAnimation extends StatelessWidget {
  final MainModule module;
  final Animation<double> animation;

  const _ModuleMiniAnimation({required this.module, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return Stack(
          children: [
            Positioned.fill(
              child: GlassCard(
                level: GlassCardLevel.subtle,
                padding: const EdgeInsets.all(14),
                borderRadius: 20,
                border: Border.all(color: AppColors.border),
                gradientColors: [
                  AppColors.cardBackgroundAlt,
                  AppColors.cardBase,
                ],
                child: _buildScene(t),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScene(double t) {
    switch (module) {
      case MainModule.screenTime:
        return _threeBeat(
          t,
          a: 'App',
          b: 'Limite',
          c: 'Blocage',
          iconA: CupertinoIcons.app_fill,
          iconB: CupertinoIcons.timer,
          iconC: CupertinoIcons.lock_fill,
        );
      case MainModule.schedule:
        return _threeBeat(
          t,
          a: 'Planning',
          b: 'Plage',
          c: 'Règle active',
          iconA: CupertinoIcons.calendar,
          iconB: CupertinoIcons.clock_fill,
          iconC: CupertinoIcons.checkmark_seal_fill,
        );
      case MainModule.habits:
        return _threeBeat(
          t,
          a: 'Habitude',
          b: 'Check',
          c: 'Streak +1',
          iconA: CupertinoIcons.flame_fill,
          iconB: CupertinoIcons.checkmark_circle_fill,
          iconC: CupertinoIcons.arrow_up_right_circle_fill,
        );
      case MainModule.todo:
        return _threeBeat(
          t,
          a: 'Tâche',
          b: 'Fait',
          c: 'Action',
          iconA: CupertinoIcons.list_bullet,
          iconB: CupertinoIcons.check_mark_circled_solid,
          iconC: CupertinoIcons.bolt_fill,
        );
    }
  }

  Widget _threeBeat(
    double t, {
    required String a,
    required String b,
    required String c,
    required IconData iconA,
    required IconData iconB,
    required IconData iconC,
  }) {
    final beat = (t * 3) % 3;
    final showA = beat < 1.1;
    final showB = beat >= 0.7 && beat < 2.1;
    final showC = beat >= 1.7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniRow(label: a, icon: iconA, active: showA),
        const SizedBox(height: 10),
        _miniRow(label: b, icon: iconB, active: showB),
        const SizedBox(height: 10),
        _miniRow(label: c, icon: iconC, active: showC, strong: true),
      ],
    );
  }

  Widget _miniRow({
    required String label,
    required IconData icon,
    required bool active,
    bool strong = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: active ? 1 : 0.25,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.white.withValues(alpha: strong ? 0.08 : 0.05),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(
              icon,
              size: 18,
              color: strong ? AppColors.accentIcon : AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.footnote.copyWith(
              color: strong ? AppColors.label : AppColors.secondaryLabel,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
