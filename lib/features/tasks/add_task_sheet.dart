import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  String _importance = 'Medium';
  String _duration = '30m';
  TaskGroup? _selectedGroup;

  final _importances = ['Low', 'Medium', 'High', 'Critical'];
  final _durations = ['15m', '30m', '1h', '2h', '4h+'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadGroups();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _groupCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    await context.read<TaskProvider>().addTask(
      _titleCtrl.text.trim(),
      importance: _importance,
      duration: _duration,
      groupId: _selectedGroup?.id,
    );

    if (mounted) Navigator.of(context).pop();
  }

  void _showAddGroup() {
    showCupertinoDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: CupertinoAlertDialog(
          title: Text('NEW_GROUP_PROTOCOL', style: AppTypography.mono.copyWith(fontSize: 14)),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: _groupCtrl,
              placeholder: 'GROUP_NAME',
              style: AppTypography.mono.copyWith(color: Colors.white),
              placeholderStyle: AppTypography.mono.copyWith(color: AppColors.tertiaryLabel),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('CANCEL', style: TextStyle(color: AppColors.secondaryLabel)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('CREATE', style: TextStyle(color: AppColors.primaryOrange)),
              onPressed: () async {
                if (_groupCtrl.text.isNotEmpty) {
                  await context.read<TaskProvider>().addTaskGroup(_groupCtrl.text);
                  _groupCtrl.clear();
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
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

                const NeoMonoText('NEW_TASK_INPUT', fontSize: 18, fontWeight: FontWeight.bold),
                const SizedBox(height: 24),

                GlassInputField(
                  placeholder: 'TASK_DESCRIPTION...',
                  controller: _titleCtrl,
                  autofocus: true,
                ),
                const SizedBox(height: 24),

                // Group Selection
                _sectionLabel('ASSIGN_GROUP'),
                const SizedBox(height: 12),
                Consumer<TaskProvider>(
                  builder: (context, prov, _) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _GroupChip(
                          label: 'NONE',
                          isSelected: _selectedGroup == null,
                          onTap: () => setState(() => _selectedGroup = null),
                        ),
                        ...prov.groups.map((g) => _GroupChip(
                          label: g.name.toUpperCase(),
                          isSelected: _selectedGroup?.id == g.id,
                          onTap: () => setState(() => _selectedGroup = g),
                        )),
                        GestureDetector(
                          onTap: _showAddGroup,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryOrange.withOpacity(0.5)),
                            ),
                            child: const Icon(CupertinoIcons.plus, size: 14, color: AppColors.primaryOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('PRIORITY_LEVEL'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: CupertinoPicker(
                              itemExtent: 32,
                              onSelectedItemChanged: (i) {
                                setState(() => _importance = _importances[i]);
                              },
                              children: _importances
                                  .map((e) => Center(child: Text(e.toUpperCase(), style: AppTypography.mono.copyWith(fontSize: 12, color: AppColors.label))))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('EST_DURATION'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: CupertinoPicker(
                              itemExtent: 32,
                              scrollController: FixedExtentScrollController(initialItem: 1),
                              onSelectedItemChanged: (i) {
                                setState(() => _duration = _durations[i]);
                              },
                              children: _durations
                                  .map((e) => Center(child: Text(e.toUpperCase(), style: AppTypography.mono.copyWith(fontSize: 12, color: AppColors.label))))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                LiquidButton(
                  label: 'INITIALIZE_TASK',
                  fullWidth: true,
                  onPressed: _addTask,
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

class _GroupChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GroupChip({
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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