import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_button.dart';
import '../../core/widgets/ceo_text_field.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _nameController = TextEditingController();
  IconData _icon = Icons.check_circle_outline;
  Color _color = const Color(0xFF0A84FF); // systemBlue
  int _target = 1;

  static const _iconOptions = [
    Icons.self_improvement,
    Icons.fitness_center,
    Icons.menu_book,
    Icons.edit_note,
    Icons.water_drop_outlined,
    Icons.bedtime_outlined,
    Icons.directions_run,
    Icons.code,
    Icons.music_note,
    Icons.restaurant_outlined,
    Icons.phone_disabled,
    Icons.check_circle_outline,
  ];

  static const _colorOptions = [
    Color(0xFF0A84FF), // systemBlue
    Color(0xFFBF5AF2), // systemPurple
    Color(0xFF30D158), // systemGreen
    Color(0xFFFFD60A), // systemYellow
    Color(0xFFFF453A), // systemRed
    Color(0xFFFF375F), // systemPink
    Color(0xFF64D2FF), // systemCyan
    Color(0xFFFF9F0A), // systemOrange
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    context.read<HabitProvider>().addHabit(
      Habit(
        name: _nameController.text.trim(),
        icon: _icon,
        color: _color,
        targetPerDay: _target,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLighter,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('New Habit', style: AppTypography.headingLarge),
            const SizedBox(height: AppSpacing.lg),

            CeoTextField(
              hint: 'Habit name',
              controller: _nameController,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Icon selector
            Text(
              'Icon',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _iconOptions.map((icon) {
                final isSelected = _icon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _color.withValues(alpha: 0.15)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected ? _color : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? _color : AppColors.textTertiary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Color selector
            Text(
              'Color',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: _colorOptions.map((color) {
                final isSelected = _color == color;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Target per day
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily target',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _target > 1
                          ? () => setState(() => _target--)
                          : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        '$_target',
                        style: AppTypography.headingSmall,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _target++),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            CeoButton(
              label: 'Create Habit',
              icon: Icons.add,
              expand: true,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
