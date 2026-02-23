import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, CircularProgressIndicator;
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class FocusStarterSheet extends StatefulWidget {
  const FocusStarterSheet({super.key});

  @override
  State<FocusStarterSheet> createState() => _FocusStarterSheetState();
}

class _FocusStarterSheetState extends State<FocusStarterSheet> {
  final _titleCtrl = TextEditingController();
  ParetoTask? _selectedTask;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final focusProv = context.read<FocusProvider>();
    
    // Set session info
    focusProv.sessionTitle = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : _selectedTask?.title;
    focusProv.linkedTaskId = _selectedTask?.id;

    final success = await focusProv.startFocus();
    if (mounted) Navigator.pop(context);
    if (!success && mounted) {
      // Could show a permission dialog here
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusProv = context.read<FocusProvider>();
    final taskProv = context.read<TaskProvider>();
    final activeTasks = taskProv.tasks.where((t) => !t.completed).toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(CupertinoIcons.bolt_fill, color: AppColors.primaryOrange, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NeoMonoText('ENTER_FOCUS', fontSize: 20, fontWeight: FontWeight.bold),
                        Text(
                          'CONFIGURE_SESSION',
                          style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Session Title
                Text(
                  'SESSION_TITLE',
                  style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                GlassInputField(
                  placeholder: 'DEEP_WORK_SESSION...',
                  controller: _titleCtrl,
                ),
                const SizedBox(height: 24),

                // Link a Task
                Text(
                  'LINK_TASK',
                  style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                if (activeTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'NO_TASKS_AVAILABLE',
                      style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.tertiaryLabel.withOpacity(0.5)),
                    ),
                  )
                else
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final task = activeTasks[i];
                        final isSelected = _selectedTask?.id == task.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTask = isSelected ? null : task;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryOrange.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryOrange : AppColors.glassBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(CupertinoIcons.checkmark_alt, size: 12, color: AppColors.primaryOrange),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  task.title.length > 20 ? '${task.title.substring(0, 20)}...' : task.title,
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 11,
                                    color: isSelected ? AppColors.primaryOrange : AppColors.secondaryLabel,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 28),

                // Duration slider
                Text(
                  'SESSION_LENGTH',
                  style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  borderRadius: 16,
                  child: StatefulBuilder(
                    builder: (context, setSliderState) {
                      return Row(
                        children: [
                          NeoMonoText(
                            '${focusProv.focusDurationMinutes}M',
                            fontSize: 24,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AdaptiveSlider(
                              value: focusProv.focusDurationMinutes.toDouble(),
                              min: 5,
                              max: 90,
                              onChanged: (v) {
                                setSliderState(() {
                                  focusProv.focusDurationMinutes = v.round();
                                  focusProv.reset();
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Start Button
                LiquidButton(
                  label: 'START_FOCUS',
                  fullWidth: true,
                  onPressed: _startSession,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
