import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, TimeOfDay, Divider;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../components/components.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AddHabitSheet extends StatefulWidget {
  final Map<String, String>? preset;
  const AddHabitSheet({super.key, this.preset});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final FeatureRepository _featureRepository = FeatureRepository();
  final _nameCtrl = TextEditingController();
  final _quoteCtrl = TextEditingController();
  final _targetValueCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  // Frequency
  String _frequencyType = 'daily'; // daily, specific_days, interval
  int _intervalDays = 2;
  List<int> _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7]; // 1=Mon, 7=Sun

  // Goal
  String _targetType = 'all'; // all, amount
  String _targetUnit = 'min'; // min, hr, km, page, cup...

  // Schedule
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay? _reminderTime;

  // Settings
  bool _autoPopup = false;
  bool _syncToCalendar = true;
  String _selectedIcon = 'bolt';
  List<String> _goals = [];
  String? _selectedGoal;

  final List<String> _icons = [
    'bolt',
    'flame',
    'drop',
    'heart',
    'star',
    'timer',
    'briefcase',
    'book',
    'leaf',
    'moon',
    'sun',
    'water',
    'dumbbell',
    'run',
    'walk',
    'brain',
    'meditation',
    'money',
    'code',
    'phone_off',
    'book_open',
    'camera',
    'music',
    'sleep',
    'apple',
    'calendar',
    'check',
    'target',
  ];
  final List<String> _units = [
    'min',
    'hr',
    'km',
    'm',
    'page',
    'cup',
    'glass',
    'step',
    'cal',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    if (widget.preset != null) {
      _nameCtrl.text = widget.preset!['title'] ?? '';
      _quoteCtrl.text = widget.preset!['quote'] ?? '';
      _selectedIcon = widget.preset!['icon'] ?? 'bolt';
    }
  }

  Future<void> _loadGoals() async {
    final objectives = await _featureRepository.getObjectives();
    if (!mounted) return;
    setState(() {
      _goals = objectives
          .map((o) => (o.title ?? '').trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (_selectedGoal == null && _goals.isNotEmpty) {
        _selectedGoal = _goals.first;
      }
    });
  }

  Future<void> _createGoal() async {
    final title = _goalCtrl.text.trim();
    if (title.isEmpty) return;
    await _featureRepository.createObjective(title);
    _goalCtrl.clear();
    await _loadGoals();
    if (!mounted) return;
    setState(() => _selectedGoal = title);
    Navigator.of(context).pop();
  }

  void _showCreateGoalDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'NEW_GOAL',
          style: AppTypography.mono.copyWith(fontSize: 13),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: _goalCtrl,
            placeholder: 'GOAL_NAME...',
            style: AppTypography.mono.copyWith(color: AppColors.label),
            placeholderStyle: AppTypography.mono.copyWith(
              color: AppColors.tertiaryLabel,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          CupertinoDialogAction(
            onPressed: _createGoal,
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quoteCtrl.dispose();
    _targetValueCtrl.dispose();
    _customUnitCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _addHabit() {
    if (_nameCtrl.text.trim().isEmpty) return;

    final reminderStr = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final unit = _targetUnit == 'custom'
        ? _customUnitCtrl.text.trim()
        : _targetUnit;

    context.read<HabitProvider>().createHabit(
      _nameCtrl.text.trim(),
      isDaily: _frequencyType == 'daily',
      icon: _selectedIcon,
      category: _selectedGoal,
      quote: _quoteCtrl.text.trim(),
      frequencyType: _frequencyType,
      intervalDays: _frequencyType == 'interval' ? _intervalDays : null,
      targetType: _targetType,
      targetValue: int.tryParse(_targetValueCtrl.text),
      targetUnit: unit.isEmpty ? null : unit,
      reminderTime: reminderStr,
      autoPopup: _autoPopup,
      colorTheme: 'orange', // Default for now
      specificDays: _frequencyType == 'specific_days'
          ? _selectedWeekdays
          : null,
      syncToCalendar: _syncToCalendar,
    );
    Navigator.of(context).pop();
  }

  IconData _getIconData(String iconName) {
    // extensive mapping or simplified fallback
    switch (iconName) {
      case 'bolt':
        return CupertinoIcons.bolt_fill;
      case 'flame':
        return CupertinoIcons.flame_fill;
      case 'drop':
        return CupertinoIcons.drop_fill;
      case 'heart':
        return CupertinoIcons.heart_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'timer':
        return CupertinoIcons.timer;
      case 'briefcase':
        return CupertinoIcons.briefcase_fill;
      case 'book':
        return CupertinoIcons.book_fill;
      case 'leaf':
        return CupertinoIcons.refresh;
      case 'moon':
        return CupertinoIcons.moon_fill;
      case 'sun':
        return CupertinoIcons.sun_max_fill;
      case 'water':
        return CupertinoIcons.drop_fill; // distinct from drop?
      case 'dumbbell':
        return CupertinoIcons.sportscourt_fill;
      case 'run':
        return CupertinoIcons.hare_fill;
      case 'walk':
        return CupertinoIcons.person;
      case 'brain':
        return CupertinoIcons.lightbulb_fill;
      case 'meditation':
        return CupertinoIcons.sparkles;
      case 'money':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'code':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'phone_off':
        return CupertinoIcons.phone_down_fill;
      case 'book_open':
        return CupertinoIcons.book_circle_fill;
      case 'camera':
        return CupertinoIcons.camera_fill;
      case 'music':
        return CupertinoIcons.music_note_2;
      case 'sleep':
        return CupertinoIcons.moon_stars_fill;
      case 'apple':
        return CupertinoIcons.shopping_cart;
      case 'calendar':
        return CupertinoIcons.calendar;
      case 'check':
        return CupertinoIcons.check_mark_circled_solid;
      case 'target':
        return CupertinoIcons.scope;
      default:
        return CupertinoIcons.bolt_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Goal selection
                    _sectionHeader('GOAL_LINK'),
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_goals.isEmpty)
                            Text(
                              'No goals yet. Create your first goal.',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: AppColors.tertiaryLabel,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _goals.map((goal) {
                                final selected = _selectedGoal == goal;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedGoal = goal),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryOrange.withOpacity(
                                              0.2,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primaryOrange
                                            : AppColors.glassBorder,
                                      ),
                                    ),
                                    child: Text(
                                      goal.toUpperCase(),
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 10,
                                        color: selected
                                            ? AppColors.primaryOrange
                                            : AppColors.secondaryLabel,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _showCreateGoalDialog,
                            child: Text(
                              '+ CREATE_GOAL',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const NeoMonoText(
                      'CUSTOM_PROTOCOL_INIT',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ).copyWith(bottom: 120),
                  children: [
                    // 1. Identity
                    _sectionHeader('IDENTITY_MATRIX'),
                    GlassInputField(
                      placeholder: 'PROTOCOL_NAME...',
                      controller: _nameCtrl,
                      autofocus: widget.preset == null,
                    ),
                    const SizedBox(height: 16),
                    GlassInputField(
                      placeholder: 'INSPIRATIONAL_QUOTE...',
                      controller: _quoteCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // 2. Icon Selection
                    _sectionHeader('VISUAL_IDENTIFIER'),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _icons.length,
                        itemBuilder: (context, i) {
                          final iconName = _icons[i];
                          final isSelected = _selectedIcon == iconName;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedIcon = iconName),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.glassBorder,
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                _getIconData(iconName),
                                size: 20,
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : AppColors.secondaryLabel,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Frequency Container
                    _sectionHeader('TEMPORAL_SETTINGS'),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _FrequencyOption(
                                'DAILY',
                                'daily',
                                _frequencyType,
                                (v) => setState(() => _frequencyType = v),
                              ),
                              _FrequencyOption(
                                'SPECIFIC',
                                'specific_days',
                                _frequencyType,
                                (v) => setState(() => _frequencyType = v),
                              ),
                              _FrequencyOption(
                                'INTERVAL',
                                'interval',
                                _frequencyType,
                                (v) => setState(() => _frequencyType = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_frequencyType == 'specific_days')
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(7, (index) {
                                final day = index + 1;
                                final isSelected = _selectedWeekdays.contains(
                                  day,
                                );
                                final days = [
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                  'S',
                                ];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        if (_selectedWeekdays.length > 1)
                                          _selectedWeekdays.remove(day);
                                      } else {
                                        _selectedWeekdays.add(day);
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryOrange
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryOrange
                                            : AppColors.glassBorder,
                                      ),
                                    ),
                                    child: Text(
                                      days[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.secondaryLabel,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),

                          if (_frequencyType == 'interval')
                            Row(
                              children: [
                                Text(
                                  'EVERY',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 60,
                                  child: GlassInputField(
                                    controller: TextEditingController(
                                      text: _intervalDays.toString(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        _intervalDays = int.tryParse(v) ?? 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'DAYS',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Goal Settings
                    _sectionHeader('OBJECTIVE_PARAMETERS'),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _GoalOption(
                                  'ACHIEVE_ALL',
                                  'all',
                                  _targetType,
                                  (v) => setState(() => _targetType = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _GoalOption(
                                  'REACH_AMOUNT',
                                  'amount',
                                  _targetType,
                                  (v) => setState(() => _targetType = v),
                                ),
                              ),
                            ],
                          ),
                          if (_targetType == 'amount') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: GlassInputField(
                                    placeholder: '0',
                                    controller: _targetValueCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 50,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _units.length,
                                      itemBuilder: (context, i) {
                                        final u = _units[i];
                                        final isSel = _targetUnit == u;
                                        return GestureDetector(
                                          onTap: () =>
                                              setState(() => _targetUnit = u),
                                          child: Container(
                                            alignment: Alignment.center,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSel
                                                  ? AppColors.primaryOrange
                                                        .withOpacity(0.2)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSel
                                                    ? AppColors.primaryOrange
                                                    : AppColors.glassBorder,
                                              ),
                                            ),
                                            child: Text(
                                              u.toUpperCase(),
                                              style: AppTypography.mono
                                                  .copyWith(
                                                    fontSize: 10,
                                                    color: isSel
                                                        ? AppColors
                                                              .primaryOrange
                                                        : AppColors
                                                              .secondaryLabel,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_targetUnit == 'custom') ...[
                              const SizedBox(height: 12),
                              GlassInputField(
                                placeholder: 'CUSTOM_UNIT_NAME...',
                                controller: _customUnitCtrl,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Schedule & Reminder
                    _sectionHeader('EXECUTION_LOGISTICS'),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DatePickerRow(
                            'START_DATE',
                            _startDate,
                            (d) => setState(() => _startDate = d),
                          ),
                          Divider(color: AppColors.glassBorder, height: 24),
                          _TimePickerRow(
                            'REMINDER',
                            _reminderTime,
                            (t) => setState(() => _reminderTime = t),
                          ),
                          Divider(color: AppColors.glassBorder, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'AUTO_POPUP_LOG',
                                style: AppTypography.mono.copyWith(
                                  fontSize: 12,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                              CupertinoSwitch(
                                value: _autoPopup,
                                activeColor: AppColors.primaryOrange,
                                onChanged: (v) =>
                                    setState(() => _autoPopup = v),
                              ),
                            ],
                          ),
                          Divider(color: AppColors.glassBorder, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SYNC_TO_CALENDAR',
                                style: AppTypography.mono.copyWith(
                                  fontSize: 12,
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                              CupertinoSwitch(
                                value: _syncToCalendar,
                                activeColor: AppColors.primaryOrange,
                                onChanged: (v) =>
                                    setState(() => _syncToCalendar = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: LiquidButton(
                  label: 'INITIATE_PROTOCOL',
                  fullWidth: true,
                  onPressed: _addHabit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: AppTypography.mono.copyWith(
          fontSize: 10,
          color: AppColors.primaryOrange,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _FrequencyOption(
    this.label,
    this.value,
    this.groupValue,
    this.onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.mono.copyWith(
            fontSize: 10,
            color: isSelected ? Colors.white : AppColors.secondaryLabel,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _GoalOption(this.label, this.value, this.groupValue, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.mono.copyWith(
            fontSize: 10,
            color: isSelected
                ? AppColors.primaryOrange
                : AppColors.secondaryLabel,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerRow(this.label, this.date, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.mono.copyWith(
            fontSize: 12,
            color: AppColors.secondaryLabel,
          ),
        ),
        GestureDetector(
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              builder: (_) => Container(
                height: 250,
                color: AppColors.background,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: date,
                  onDateTimeChanged: onChanged,
                ),
              ),
            );
          },
          child: Text(
            DateFormat('MMM dd, yyyy').format(date).toUpperCase(),
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerRow(this.label, this.time, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.mono.copyWith(
            fontSize: 12,
            color: AppColors.secondaryLabel,
          ),
        ),
        GestureDetector(
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              builder: (_) => Container(
                height: 250,
                color: AppColors.background,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    time?.hour ?? 9,
                    time?.minute ?? 0,
                  ),
                  onDateTimeChanged: (d) =>
                      onChanged(TimeOfDay.fromDateTime(d)),
                ),
              ),
            );
          },
          child: Text(
            time != null ? time!.format(context) : 'NONE',
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
