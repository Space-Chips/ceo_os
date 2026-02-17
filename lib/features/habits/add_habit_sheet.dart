import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_button.dart';
import '../../core/widgets/ceo_text_field.dart';

/// Add habit modal sheet — Cupertino style.
class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});
  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  IconData _selectedIcon = CupertinoIcons.checkmark_circle;
  Color _selectedColor = AppColors.systemBlue;
  int _targetPerDay = 1;

  static const _icons = [
    CupertinoIcons.checkmark_circle,
    CupertinoIcons.heart,
    CupertinoIcons.book,
    CupertinoIcons.sportscourt,
    CupertinoIcons.pencil,
    CupertinoIcons.moon,
    CupertinoIcons.drop,
    CupertinoIcons.music_note,
    CupertinoIcons.leaf_arrow_circlepath,
    CupertinoIcons.person_2,
    CupertinoIcons.desktopcomputer,
    CupertinoIcons.cart,
  ];

  static const _colors = [
    AppColors.systemBlue,
    AppColors.systemPurple,
    AppColors.systemGreen,
    AppColors.systemOrange,
    AppColors.systemRed,
    AppColors.systemTeal,
    AppColors.systemPink,
    AppColors.systemYellow,
    AppColors.systemIndigo,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addHabit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    context.read<HabitProvider>().addHabit(
      Habit(
        name: _nameCtrl.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        targetPerDay: _targetPerDay,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryLabel,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'New Habit',
                style: AppTypography.title3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name
              CeoTextField(
                hint: 'Habit name',
                controller: _nameCtrl,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),

              // Icon picker
              Text(
                'Icon',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _icons.map((ic) {
                  final isSelected = _selectedIcon == ic;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = ic),
                    child: Container(
                      width: AppSpacing.minTouchTarget,
                      height: AppSpacing.minTouchTarget,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.18)
                            : AppColors.tertiarySystemBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        border: isSelected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                      ),
                      child: Icon(
                        ic,
                        size: 20,
                        color: isSelected
                            ? _selectedColor
                            : AppColors.secondaryLabel,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Color picker
              Text(
                'Color',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: isSelected
                            ? Border.all(color: CupertinoColors.white, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Daily target
              Row(
                children: [
                  Text('Daily Target', style: AppTypography.body),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _targetPerDay > 1
                        ? () => setState(() => _targetPerDay--)
                        : null,
                    child: const Icon(CupertinoIcons.minus_circle, size: 28),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      '$_targetPerDay',
                      style: AppTypography.title3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _targetPerDay++),
                    child: const Icon(CupertinoIcons.plus_circle, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Create
              CeoButton(
                label: 'Create Habit',
                expand: true,
                onPressed: _addHabit,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
