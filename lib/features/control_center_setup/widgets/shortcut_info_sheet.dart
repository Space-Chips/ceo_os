import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../../../components/liquid_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';

class ShortcutInfoSheet extends StatelessWidget {
  final ControlCenterShortcutItem shortcut;
  final bool canAdd;
  final VoidCallback onAdd;

  const ShortcutInfoSheet({
    super.key,
    required this.shortcut,
    required this.canAdd,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
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
                            shortcut.icon,
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
                                shortcut.title,
                                style: AppTypography.title3.copyWith(
                                  color: AppColors.label,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shortcut.subtitle,
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
                    Text(
                      'Action rapide',
                      style: AppTypography.overline.copyWith(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shortcut.subtitle,
                      style: AppTypography.body.copyWith(
                        color: AppColors.label,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LiquidButton(
                      label: canAdd ? 'Ajouter' : 'Ajouté',
                      onPressed: canAdd
                          ? () {
                              onAdd();
                              Navigator.of(context).pop();
                            }
                          : null,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          'Fermer',
                          style: AppTypography.headline.copyWith(
                            color: AppColors.label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
