import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  bool _isDaily = true;
  String _selectedIcon = 'bolt';

  final List<String> _icons = ['bolt', 'flame', 'drop', 'heart', 'star', 'timer', 'briefcase', 'book'];

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'bolt': return CupertinoIcons.bolt_fill;
      case 'flame': return CupertinoIcons.flame_fill;
      case 'drop': return CupertinoIcons.drop_fill;
      case 'heart': return CupertinoIcons.heart_fill;
      case 'star': return CupertinoIcons.star_fill;
      case 'timer': return CupertinoIcons.timer;
      case 'briefcase': return CupertinoIcons.briefcase_fill;
      case 'book': return CupertinoIcons.book_fill;
      default: return CupertinoIcons.bolt_fill;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addHabit() {
    if (_nameCtrl.text.trim().isEmpty) return;

    context.read<HabitProvider>().createHabit(
      _nameCtrl.text.trim(),
      isDaily: _isDaily,
      icon: _selectedIcon,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const NeoMonoText('NEW_PROTOCOL_INIT', fontSize: 18, fontWeight: FontWeight.bold),
                const SizedBox(height: 24),

                GlassInputField(
                  placeholder: 'PROTOCOL_NAME...',
                  controller: _nameCtrl,
                  autofocus: true,
                ),
                const SizedBox(height: 24),

                _sectionLabel('SELECT_IDENTIFIER'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _icons.length,
                    itemBuilder: (context, i) {
                      final iconName = _icons[i];
                      final isSelected = _selectedIcon == iconName;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = iconName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryOrange.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryOrange : AppColors.glassBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            _getIconData(iconName),
                            size: 20,
                            color: isSelected ? AppColors.primaryOrange : AppColors.secondaryLabel,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                _sectionLabel('EXECUTION_FREQUENCY'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FrequencyChip(
                      label: 'DAILY_RECURRENCE',
                      isSelected: _isDaily,
                      onTap: () => setState(() => _isDaily = true),
                    ),
                    const SizedBox(width: 12),
                    _FrequencyChip(
                      label: 'WEEKLY_RECURRENCE',
                      isSelected: !_isDaily,
                      onTap: () => setState(() => _isDaily = false),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                LiquidButton(
                  label: 'AUTHORIZE_PROTOCOL',
                  fullWidth: true,
                  onPressed: _addHabit,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel, letterSpacing: 1.5),
  );
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.mono.copyWith(
            fontSize: 10,
            color: isSelected ? AppColors.primaryOrange : AppColors.secondaryLabel,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}