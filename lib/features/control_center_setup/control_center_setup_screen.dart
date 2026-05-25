import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/repositories/feature_repository.dart';

import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../setup/setup_flow_controller.dart' hide SetupStep;
import 'control_center_setup_models.dart';
import 'control_center_setup_view_model.dart';
import 'widgets/control_center_empty_state.dart';
import 'widgets/dashboard_intro_screen.dart';
import 'widgets/dashboard_widgets_screen.dart';
import 'widgets/final_preview_screen.dart';
import 'widgets/module_picker_screen.dart';
import 'widgets/permissions_screen.dart';
import 'widgets/setup_progress_indicator.dart';
import 'widgets/shortcut_picker_screen.dart';
import 'widgets/theme_picker_screen.dart';
import 'widgets/control_center_preview.dart';

class ControlCenterSetupScreen extends StatefulWidget {
  final bool isEditing;

  const ControlCenterSetupScreen({super.key, this.isEditing = false});

  @override
  State<ControlCenterSetupScreen> createState() =>
      _ControlCenterSetupScreenState();
}

class _ControlCenterSetupScreenState extends State<ControlCenterSetupScreen> {
  late final ControlCenterSetupViewModel _viewModel =
      ControlCenterSetupViewModel();
  bool _didInit = false;
  SetupStep? _lastStep;
  int _lastStepIndex = 0;
  int _direction = 1;

  static const List<SetupStep> _orderedSteps = [
    SetupStep.emptyCenter,
    SetupStep.modulePicker,
    SetupStep.moduleConfirmation,
    SetupStep.shortcutPicker,
    SetupStep.shortcutConfirmation,
    SetupStep.dashboardIntro,
    SetupStep.themePicker,
    SetupStep.dashboardWidgets,
    SetupStep.finalPreview,
    SetupStep.permissions,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_kickoff());
  }

  Future<void> _kickoff() async {
    await _viewModel.initialize();
    if (!mounted) return;
    setState(() => _didInit = true);
    if (widget.isEditing) {
      _viewModel.goNext(); // Empty -> Module picker.
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  int _stepIndex(SetupStep step) {
    final index = _orderedSteps.indexOf(step);
    return index == -1 ? 0 : index;
  }

  // Map onboarding module IDs → home_screen active app IDs.
  static const Map<String, String> _moduleIdToHomeApp = {
    'module_screen_time': 'ScreenTimeManager',
    'module_schedule': 'Calendar',
    'module_habits': 'Habits',
    'module_todo': 'Pareto',
  };

  // Map onboarding shortcut IDs → home_screen shortcut keys.
  static const Map<String, String> _shortcutIdToHomeShortcut = {
    'shortcut_rank': 'rank',
    'shortcut_focus_mode': 'focus',
    'shortcut_block_apps_and_sites': 'block_apps',
    'shortcut_streak': 'streak',
    'shortcut_notes': 'notes',
  };

  Future<void> _propagateConfigToHome() async {
    final state = _viewModel.uiState;
    final modules = state.selectedModules
        .map((m) => _moduleIdToHomeApp[m.id])
        .whereType<String>()
        .toList(growable: false);
    final shortcuts = state.selectedShortcuts
        .map((s) => _shortcutIdToHomeShortcut[s.id])
        .whereType<String>()
        .toList(growable: false);

    // 1. Persist active modules to FeatureRepository (Supabase app_settings).
    try {
      await FeatureRepository().saveActiveApps(modules);
    } catch (_) {}

    // 2. Persist enabled shortcuts to SharedPreferences keyed by user.
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      await prefs.setStringList(
        'home::$userId::enabled_shortcuts_v2',
        shortcuts,
      );
    } catch (_) {}

    // 3. Persist current theme (selected during themePicker step).
    try {
      final theme = context.read<ThemeProvider>();
      await theme.saveThemeForCurrentUser(theme.currentPreset.id);
    } catch (_) {}
  }

  Future<void> _finish() async {
    await _viewModel.completeSetup();
    if (!mounted) return;
    await _propagateConfigToHome();
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _openAndroidPermissions() async {
    final setup = context.read<SetupFlowController>();
    await setup.initialize();
    if (!mounted) return;
    context.push('/setup?origin=screen-time');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ControlCenterSetupViewModel>(
        builder: (context, viewModel, _) {
          final state = viewModel.uiState;
          final index = _stepIndex(state.currentStep);
          if (_lastStep != state.currentStep) {
            _direction = index >= _lastStepIndex ? 1 : -1;
            _lastStep = state.currentStep;
            _lastStepIndex = index;
          }

          return AmbientBackdrop(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: !_didInit
                    ? const _SetupLoading()
                    : Stack(
                        children: [
                          _SetupDecorations(),
                          Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 10, 18, 10),
                                child: Row(
                                  children: [
                                    _TopBackButton(
                                      enabled:
                                          state.currentStep !=
                                          SetupStep.emptyCenter,
                                      onTap: viewModel.goBack,
                                    ),
                                    const Spacer(),
                                    SetupProgressIndicator(
                                      currentIndex: index,
                                      total: _orderedSteps.length,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 460),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                    return Stack(
                                      children: [
                                        ...previousChildren,
                                        if (currentChild != null)
                                          currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) {
                                    final curved = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    );
                                    final enteringOffset =
                                        Offset(0.12 * _direction, 0);
                                    return FadeTransition(
                                      opacity: curved,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: enteringOffset,
                                          end: Offset.zero,
                                        ).animate(curved),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey(state.currentStep),
                                    child: _buildStep(context, viewModel, state),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    ControlCenterSetupViewModel viewModel,
    ControlCenterSetupState state,
  ) {
    switch (state.currentStep) {
      case SetupStep.emptyCenter:
        return ControlCenterEmptyState(onPrimary: viewModel.goNext);
      case SetupStep.modulePicker:
        return ModulePickerScreen(
          state: state,
          onAdd: (module) {
            viewModel.addModule(module);
            viewModel.goNext();
          },
          onContinue: viewModel.goNext,
        );
      case SetupStep.moduleConfirmation:
        return _ModuleConfirmationScreen(
          state: state,
          onPrimary: viewModel.goNext,
          onSecondary: viewModel.goBack,
          onRemove: viewModel.removeItem,
          title: 'Ton centre prend forme',
          subtitle: 'Tu pourras tout changer plus tard depuis le menu.',
        );
      case SetupStep.shortcutPicker:
        return ShortcutPickerScreen(
          state: state,
          onAdd: (shortcut) {
            viewModel.addShortcut(shortcut);
            viewModel.goNext();
          },
          onContinue: viewModel.goNext,
        );
      case SetupStep.shortcutConfirmation:
        return _ModuleConfirmationScreen(
          state: state,
          onPrimary: viewModel.goNext,
          onSecondary: () => viewModel.goToStep(SetupStep.shortcutPicker),
          onRemove: viewModel.removeItem,
          title: 'Ajoute tes raccourcis',
          subtitle:
              'Tape sur un emplacement vide pour choisir un raccourci.',
          phaseBadge: 'PHASE 2 — RACCOURCIS',
        );
      case SetupStep.dashboardIntro:
        return DashboardIntroScreen(
          state: state,
          onContinue: viewModel.goNext,
        );
      case SetupStep.themePicker:
        return ThemePickerScreen(onContinue: viewModel.goNext);
      case SetupStep.dashboardWidgets:
        return DashboardWidgetsScreen(
          state: state,
          onToggle: viewModel.toggleDashboardWidget,
          onContinue: () {
            final isAndroid =
                !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
            if (isAndroid) {
              viewModel.goNext();
            } else {
              unawaited(_finish());
            }
          },
        );
      case SetupStep.finalPreview:
        return FinalPreviewScreen(
          state: state,
          onPrimary: viewModel.goNext,
          onSecondary: viewModel.goBack,
        );
      case SetupStep.permissions:
        return PermissionsScreen(
          state: state,
          isPersisting: viewModel.isPersisting,
          onOpenAndroidPermissions: _openAndroidPermissions,
          onFinish: _finish,
        );
    }
  }
}

class _SetupLoading extends StatelessWidget {
  const _SetupLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        level: GlassCardLevel.elevated,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        borderRadius: 18,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Préparation…',
              style: AppTypography.footnote.copyWith(
                color: AppColors.label,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupDecorations extends StatelessWidget {
  _SetupDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 28,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.07),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
              child: Container(
                color: AppColors.overlayScrim.withValues(alpha: 0),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -140,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.themeGlow.withValues(alpha: 0.06),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                color: AppColors.overlayScrim.withValues(alpha: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBackButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _TopBackButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.25,
      child: IgnorePointer(
        ignoring: !enabled,
        child: _Pressable(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.topBarControlBackground,
              border: Border.all(color: AppColors.topBarControlBorder),
            ),
            child: Icon(
              CupertinoIcons.back,
              color: AppColors.secondaryLabel,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  const _Pressable({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _ModuleConfirmationScreen extends StatelessWidget {
  final ControlCenterSetupState state;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final void Function(String itemId) onRemove;
  final String title;
  final String subtitle;
  final String? phaseBadge;

  const _ModuleConfirmationScreen({
    required this.state,
    required this.onPrimary,
    required this.onSecondary,
    required this.onRemove,
    required this.title,
    required this.subtitle,
    this.phaseBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (phaseBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.cardBackgroundStrong.withValues(alpha: 0.54),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.30),
                  width: 0.5,
                ),
              ),
              child: Text(
                phaseBadge!,
                style: AppTypography.overline.copyWith(
                  fontSize: 11,
                  color: AppColors.secondaryLabel,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.subhead.copyWith(
              color: AppColors.secondaryLabel.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ControlCenterPreview(
            state: state,
            showDashboard: false,
            bare: true,
            onRemoveItem: onRemove,
            onTapEmptySlot: (_) => onSecondary(),
          ),
          const Spacer(),
          LiquidButton(
            label: 'Continuer',
            onPressed: onPrimary,
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      pressedScale: 0.985,
      onTap: onTap,
      child: Container(
        height: 52,
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
