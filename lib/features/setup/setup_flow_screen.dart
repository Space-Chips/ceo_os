import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'setup_flow_controller.dart';

class SetupFlowScreen extends StatefulWidget {
  const SetupFlowScreen({super.key});

  @override
  State<SetupFlowScreen> createState() => _SetupFlowScreenState();
}

class _SetupFlowScreenState extends State<SetupFlowScreen>
    with WidgetsBindingObserver {
  final ValueNotifier<bool> _showStepSuccess = ValueNotifier(false);
  final ValueNotifier<bool> _showReturnOverlay = ValueNotifier(false);
  final Set<SetupStep> _autoAdvancedSteps = <SetupStep>{};
  Timer? _successTimer;
  Timer? _returnOverlayTimer;
  SetupStep? _lastStep;
  int _lastStepIndex = 0;
  int _transitionDirection = 1;

  static const List<SetupStep> _stepOrder = [
    SetupStep.welcome,
    SetupStep.accessibility,
    SetupStep.usageAccess,
    SetupStep.overlay,
    SetupStep.success,
  ];

  String _t(String key) => context.read<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    final controller = context.read<SetupFlowController>();
    await controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _successTimer?.cancel();
    _returnOverlayTimer?.cancel();
    _showStepSuccess.dispose();
    _showReturnOverlay.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleReturnFromSettings();
    }
  }

  Future<void> _handleReturnFromSettings() async {
    final controller = context.read<SetupFlowController>();
    if (!controller.isPermissionStep(controller.currentStep)) return;
    await controller.refreshPermissionStates();
    if (!mounted) return;
    final granted = controller.isPermissionGrantedFor(controller.currentStep);
    if (!granted) {
      setState(() {});
      return;
    }
    await controller.clearPendingPermissionReturn();
    _showReturnOverlay.value = true;
    _returnOverlayTimer?.cancel();
    await controller.advance();
    _returnOverlayTimer = Timer(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      _showReturnOverlay.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    return Consumer<SetupFlowController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const _SetupLoadingScreen();
        }
        final stepIndex = _stepOrder
            .indexOf(controller.currentStep)
            .clamp(0, _stepOrder.length - 1);
        if (_lastStep != controller.currentStep) {
          _transitionDirection = stepIndex >= _lastStepIndex ? 1 : -1;
          _lastStep = controller.currentStep;
          _lastStepIndex = stepIndex;
        }
        return AmbientBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  const _SetupDecorations(),
                  ValueListenableBuilder<bool>(
                    valueListenable: _showReturnOverlay,
                    builder: (context, visible, _) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        opacity: visible ? 1 : 0,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.12),
                                  AppColors.themeGlow.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                            child: Center(
                              child: AnimatedScale(
                                scale: visible ? 1 : 0.98,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: GlassCard(
                                  level: GlassCardLevel.elevated,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  borderRadius: 18,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        color: AppColors.success,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _t('setup_back_in_wakeapp'),
                                            style: AppTypography.footnote
                                                .copyWith(
                                                  color: AppColors.label,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _t('setup_syncing_permission'),
                                            style: AppTypography.caption1
                                                .copyWith(
                                                  color:
                                                      AppColors.secondaryLabel,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _showReturnOverlay,
                    builder: (context, returning, child) {
                      return AnimatedSlide(
                        offset: returning ? const Offset(0, 0.02) : Offset.zero,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: child,
                      );
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 460),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final curve = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );
                        final direction = _transitionDirection.toDouble();
                        final enteringOffset = Offset(0.12 * direction, 0);
                        return FadeTransition(
                          opacity: curve,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: enteringOffset,
                              end: Offset.zero,
                            ).animate(curve),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(controller.currentStep),
                        child: _buildStep(
                          context,
                          controller,
                          controller.currentStep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(
    BuildContext context,
    SetupFlowController controller,
    SetupStep step,
  ) {
    switch (step) {
      case SetupStep.welcome:
        return _WelcomeStep(onContinue: controller.advance);
      case SetupStep.accessibility:
        _maybeAutoAdvance(controller, step, controller.accessibilityGranted);
        return _PermissionStep(
          stepIndex: 1,
          title: _t('setup_accessibility_title'),
          subtitle: _t('setup_accessibility_subtitle'),
          icon: CupertinoIcons.hand_raised_fill,
          accent: AppColors.accent,
          reassurance: _t('setup_accessibility_reassurance'),
          instructions: [
            _t('setup_step_tap_open_settings'),
            _t('setup_step_enable_service'),
            _t('setup_step_return_auto'),
          ],
          troubleshoot: [
            _t('setup_if_switch_disabled'),
            _t('setup_if_missing_service'),
          ],
          isGranted: controller.accessibilityGranted,
          showSuccess: _showStepSuccess,
          onOpenSettings: controller.openAccessibilitySettings,
          onContinue: controller.advance,
        );
      case SetupStep.usageAccess:
        _maybeAutoAdvance(controller, step, controller.usageGranted);
        return _PermissionStep(
          stepIndex: 2,
          title: _t('setup_usage_title'),
          subtitle: _t('setup_usage_subtitle'),
          icon: CupertinoIcons.chart_bar_fill,
          accent: AppColors.focusSecondary,
          instructions: [
            _t('setup_step_tap_open_settings'),
            _t('setup_step_allow_service'),
            _t('setup_step_return_auto'),
          ],
          troubleshoot: [
            _t('setup_if_missing_open_app'),
            _t('setup_then_open_usage_access'),
          ],
          isGranted: controller.usageGranted,
          showSuccess: _showStepSuccess,
          onOpenSettings: controller.openUsageAccessSettings,
          onContinue: controller.advance,
        );
      case SetupStep.overlay:
        _maybeAutoAdvance(controller, step, controller.overlayGranted);
        return _PermissionStep(
          stepIndex: 3,
          title: _t('setup_overlay_title'),
          subtitle: _t('setup_overlay_subtitle'),
          icon: CupertinoIcons.rectangle_stack_fill,
          accent: AppColors.focusPrimary,
          instructions: [
            _t('setup_step_tap_open_settings'),
            _t('setup_step_allow_overlay'),
            _t('setup_step_return_auto'),
          ],
          troubleshoot: [
            _t('setup_if_cant_toggle_overlay'),
            _t('setup_enable_wakeapp_and_return'),
          ],
          isGranted: controller.overlayGranted,
          showSuccess: _showStepSuccess,
          onOpenSettings: controller.openOverlaySettings,
          onContinue: controller.advance,
        );
      case SetupStep.success:
        return _SuccessStep(onContinue: controller.markSetupComplete);
    }
  }

  void _maybeAutoAdvance(
    SetupFlowController controller,
    SetupStep step,
    bool isGranted,
  ) {
    if (!isGranted) return;
    if (_autoAdvancedSteps.contains(step)) return;
    _autoAdvancedSteps.add(step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.advance();
    });
  }
}

class _SetupLoadingScreen extends StatelessWidget {
  const _SetupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 16),
                Text(
                  t('setup_preparing'),
                  style: AppTypography.body.copyWith(
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupDecorations extends StatelessWidget {
  const _SetupDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              size: 240,
              colors: [
                AppColors.accent.withValues(alpha: 0.16),
                AppColors.accentLight.withValues(alpha: 0.02),
              ],
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _GlowBlob(
              size: 260,
              colors: [
                AppColors.themeGlow.withValues(alpha: 0.12),
                AppColors.background.withValues(alpha: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors, stops: const [0.0, 1.0]),
      ),
    );
  }
}

class _SetupStepScaffold extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  final int? progressStep;
  final int progressTotal;

  const _SetupStepScaffold({
    required this.child,
    this.footer,
    this.progressStep,
    this.progressTotal = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Column(
        children: [
          if (progressStep != null) ...[
            _SetupProgressBar(step: progressStep!, total: progressTotal),
            const SizedBox(height: 14),
          ],
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onContinue;

  const _WelcomeStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    return _SetupStepScaffold(
      footer: LiquidButton(
        label: t('setup_start'),
        fullWidth: true,
        onPressed: onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            level: GlassCardLevel.elevated,
            showEdgeGlow: true,
            glowColor: AppColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepProgressPill(step: 0, total: 3),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconOrb(
                      icon: CupertinoIcons.timer,
                      accent: AppColors.accent,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            t('setup_welcome_subtitle'),
                            style: AppTypography.body.copyWith(
                              color: AppColors.secondaryLabel,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            level: GlassCardLevel.standard,
            showTopHighlight: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('setup_what_unlocks'), style: AppTypography.title3),
                const SizedBox(height: 10),
                _BulletLine(text: t('setup_unlock_instant_blocking')),
                _BulletLine(text: t('setup_unlock_usage_limits')),
                _BulletLine(text: t('setup_unlock_focus_blackout')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            level: GlassCardLevel.subtle,
            showTopHighlight: false,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.time_solid,
                  color: AppColors.secondaryLabel,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('setup_takes_45s'),
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('setup_return_auto'),
            style: AppTypography.footnote.copyWith(
              color: AppColors.tertiaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  final int stepIndex;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String? reassurance;
  final List<String> instructions;
  final List<String> troubleshoot;
  final bool isGranted;
  final ValueNotifier<bool> showSuccess;
  final Future<void> Function() onOpenSettings;
  final VoidCallback onContinue;

  const _PermissionStep({
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.instructions,
    required this.isGranted,
    required this.showSuccess,
    required this.onOpenSettings,
    required this.onContinue,
    this.reassurance,
    this.troubleshoot = const [],
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    return _SetupStepScaffold(
      progressStep: stepIndex,
      footer: Column(
        children: [
          LiquidButton(
            label: isGranted ? t('setup_continue') : t('setup_open_settings'),
            fullWidth: true,
            onPressed: isGranted ? onContinue : () => onOpenSettings(),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            level: GlassCardLevel.elevated,
            showEdgeGlow: true,
            glowColor: accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconOrb(icon: icon, accent: accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.title2),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: AppTypography.body.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _StatusPill(
                    text: isGranted
                        ? t('setup_enabled')
                        : t('setup_not_enabled'),
                    color: isGranted ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          if (reassurance != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              level: GlassCardLevel.subtle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  reassurance!,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          GlassCard(
            level: GlassCardLevel.elevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('setup_quick_steps'), style: AppTypography.headline),
                  const SizedBox(height: 10),
                  for (int i = 0; i < instructions.length; i++)
                    _InstructionRow(index: i + 1, text: instructions[i]),
                ],
              ),
            ),
          ),
          if (troubleshoot.isNotEmpty) ...[
            const SizedBox(height: 14),
            GlassCard(
              level: GlassCardLevel.subtle,
              showTopHighlight: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('setup_switch_locked'), style: AppTypography.headline),
                  const SizedBox(height: 8),
                  for (final line in troubleshoot) _BulletLine(text: line),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: showSuccess,
            builder: (context, success, _) {
              if (!isGranted && !success) return const SizedBox.shrink();
              return _SuccessBanner(
                text: t('setup_permission_granted'),
                visible: success || isGranted,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final Future<void> Function() onContinue;

  const _SuccessStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    return _SetupStepScaffold(
      progressStep: 3,
      footer: LiquidButton(
        label: t('setup_open_screen_time'),
        fullWidth: true,
        height: 58,
        borderRadius: 16,
        labelStyle: AppTypography.callout.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        onPressed: () async {
          await onContinue();
          if (context.mounted) context.go('/screen-time-manager');
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          _SuccessHero(),
          const SizedBox(height: 16),
          Text(t('setup_success_title'), style: AppTypography.largeTitle),
          const SizedBox(height: 6),
          Text(
            t('setup_success_subtitle'),
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            level: GlassCardLevel.standard,
            showTopHighlight: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulletLine(text: t('setup_success_instant_blocking')),
                _BulletLine(text: t('setup_success_usage_limits')),
                _BulletLine(text: t('setup_success_focus_blackout')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.36),
            AppColors.success.withValues(alpha: 0.12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.18),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
          ),
          child: Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: AppColors.success,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _StepProgressPill extends StatelessWidget {
  final int step;
  final int total;

  const _StepProgressPill({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    final label = step <= 0
        ? t('setup_steps_label').replaceAll('{total}', '$total')
        : '$step / $total';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.caption1.copyWith(color: AppColors.secondaryLabel),
      ),
    );
  }
}

class _SetupProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const _SetupProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    final clamped = step.clamp(0, total);
    final progress = total == 0 ? 0.0 : clamped / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t('setup_step_of')
                  .replaceAll('{step}', '$clamped')
                  .replaceAll('{total}', '$total'),
              style: AppTypography.caption1.copyWith(
                color: AppColors.secondaryLabel,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: AppTypography.caption1.copyWith(
                color: AppColors.tertiaryLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentLight.withValues(alpha: 0.9),
                          AppColors.accent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _IconOrb extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _IconOrb({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: 0.25),
            AppColors.glassHighlightSoft.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: 26),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: AppTypography.caption1.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final int index;
  final String text;

  const _InstructionRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              index.toString(),
              style: AppTypography.caption1.copyWith(
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String text;
  final bool visible;

  const _SuccessBanner({required this.text, required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: visible ? 1 : 0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.checkmark, color: AppColors.success, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTypography.body),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
