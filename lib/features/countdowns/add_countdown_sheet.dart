import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AddCountdownSheet extends StatefulWidget {
  const AddCountdownSheet({super.key});
  @override
  State<AddCountdownSheet> createState() => _AddCountdownSheetState();
}

class _AddCountdownSheetState extends State<AddCountdownSheet> {
  final _titleCtrl = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));
  int _colorIndex = 0;
  int _iconIndex = 0;

  static const _colors = [
    Color(0xFF0A84FF),
    Color(0xFFFF9F0A),
    Color(0xFFBF5AF2),
    Color(0xFFFF453A),
    Color(0xFF30D158),
    Color(0xFFFF375F),
    Color(0xFF64D2FF),
    Color(0xFFFFD60A),
  ];

  static const _icons = [
    CupertinoIcons.calendar,
    CupertinoIcons.rocket,
    CupertinoIcons.flag,
    CupertinoIcons.star,
    CupertinoIcons.airplane,
    CupertinoIcons.person_3,
    CupertinoIcons.gift,
    CupertinoIcons.heart,
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addCountdown() {
    if (_titleCtrl.text.trim().isEmpty) return;
    context.read<CountdownProvider>().addEvent(
      CountdownEvent(
        title: _titleCtrl.text.trim(),
        targetDate: _targetDate,
        color: _colors[_colorIndex],
        icon: _icons[_iconIndex],
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
                'New Countdown',
                style: AppTypography.title3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CupertinoTextField(
                controller: _titleCtrl,
                placeholder: 'Event name',
                autofocus: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                style: AppTypography.body,
                placeholderStyle: AppTypography.body.copyWith(
                  color: AppColors.tertiaryLabel,
                ),
                cursorColor: AppColors.systemBlue,
              ),
              const SizedBox(height: AppSpacing.md),

              // Date picker
              Text(
                'Target Date',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 160,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: DateTime.now(),
                  initialDateTime: _targetDate,
                  onDateTimeChanged: (date) =>
                      setState(() => _targetDate = date),
                ),
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
              Row(
                children: _colors
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: GestureDetector(
                          onTap: () => setState(() => _colorIndex = e.key),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.value,
                              border: _colorIndex == e.key
                                  ? Border.all(
                                      color: CupertinoColors.white,
                                      width: 2.5,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
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
              Row(
                children: _icons
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: GestureDetector(
                          onTap: () => setState(() => _iconIndex = e.key),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _iconIndex == e.key
                                  ? _colors[_colorIndex].withValues(alpha: 0.2)
                                  : AppColors.tertiarySystemBackground,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Icon(
                              e.value,
                              size: 18,
                              color: _iconIndex == e.key
                                  ? _colors[_colorIndex]
                                  : AppColors.secondaryLabel,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: AdaptiveButton(
                  label: 'Create Countdown',
                  onPressed: _addCountdown,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
