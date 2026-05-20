import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/focus_service.dart';
import 'screen_time_setup_controller.dart';

class ScreenTimeSetupScreen extends StatefulWidget {
  const ScreenTimeSetupScreen({super.key});

  @override
  State<ScreenTimeSetupScreen> createState() => _ScreenTimeSetupScreenState();
}

class _ScreenTimeSetupScreenState extends State<ScreenTimeSetupScreen>
    with WidgetsBindingObserver {
  final ValueNotifier<bool> _showStepSuccess = ValueNotifier(false);
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    final controller = context.read<ScreenTimeSetupController>();
    await controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _successTimer?.cancel();
    _showStepSuccess.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleReturnFromSettings();
    }
  }

  Future<void> _handleReturnFromSettings() async {
    final controller = context.read<ScreenTimeSetupController>();
    if (controller.currentStep != ScreenTimeSetupStep.permission) return;
    await controller.refreshAndSync();
    if (!mounted) return;
    if (!controller.isAuthorized) {
      setState(() {});
      return;
    }
    _showStepSuccess.value = true;
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      _showStepSuccess.value = false;
      await controller.advance();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    return Consumer<ScreenTimeSetupController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const _SetupLoadingScreen();
        }
        return AmbientBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _buildStep(context, controller, controller.currentStep),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(
    BuildContext context,
    ScreenTimeSetupController controller,
    ScreenTimeSetupStep step,
  ) {
    switch (step) {
      case ScreenTimeSetupStep.intro:
        return _IntroStep(onContinue: controller.advance);
      case ScreenTimeSetupStep.value:
        return _ValueStep(
          selection: controller.valueSelection,
          onSelect: controller.setValueSelection,
          onContinue: controller.advance,
        );
      case ScreenTimeSetupStep.overview:
        return _OverviewStep(
          isAuthorized: controller.isAuthorized,
          onContinue: controller.advance,
        );
      case ScreenTimeSetupStep.permission:
        return _PermissionStep(
          status: controller.protectionStatus,
          showSuccess: _showStepSuccess,
          onRequest: controller.requestScreenTimeAccess,
          onOpenSettings: controller.openSystemSettings,
          onContinue: controller.advance,
        );
      case ScreenTimeSetupStep.success:
        return _SuccessStep(
          onContinue: () async {
            await controller.markSetupComplete();
            if (!mounted) return;
            context.go('/screen-time-manager');
          },
        );
    }
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
                const CupertinoActivityIndicator(),
                const SizedBox(height: 14),
                Text(
                  t('ios_setup_preparing'),
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

class _SetupStepScaffold extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  final bool showBack;
  final VoidCallback? onBack;
  final String? progressLabel;

  const _SetupStepScaffold({
    required this.child,
    this.footer,
    this.showBack = false,
    this.onBack,
    this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  onPressed: onBack,
                  child: Icon(
                    CupertinoIcons.back,
                    size: 20,
                    color: AppColors.secondaryLabel,
                  ),
                )
              else
                const SizedBox(width: 32),
              const Spacer(),
              _ProgressPill(
                label: progressLabel ?? t('ios_setup_progress_label'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final String label;

  const _ProgressPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: AppTypography.caption1.copyWith(
          fontSize: 11,
          color: AppColors.secondaryLabel,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  final VoidCallback onContinue;

  const _IntroStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return _SetupStepScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Configure Screen Time',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 34,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Let's set up the protections that keep your focus sessions enforced on this iPhone.",
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("What you'll unlock", style: AppTypography.title3),
                const SizedBox(height: 10),
                _BenefitRow(
                  title: 'Instant blocking',
                  subtitle: 'Protected apps close immediately during sessions.',
                ),
                const SizedBox(height: 10),
                _BenefitRow(
                  title: 'On-device privacy',
                  subtitle:
                      'Your Screen Time data stays on this device — never synced.',
                ),
              ],
            ),
          ),
        ],
      ),
      footer: LiquidButton(label: 'Start setup', onPressed: onContinue),
    );
  }
}

class _ValueStep extends StatelessWidget {
  final String? selection;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  const _ValueStep({
    required this.selection,
    required this.onSelect,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final options = const ['30 min', '60 min', '90 min'];
    return _SetupStepScaffold(
      showBack: true,
      onBack: () => context.read<ScreenTimeSetupController>().jumpTo(
        ScreenTimeSetupStep.intro,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            'How much time do you want back each day?',
            style: AppTypography.title1.copyWith(height: 1.12),
          ),
          const SizedBox(height: 12),
          Text(
            'Pick a target to personalize your Screen Time protection.',
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options
                .map(
                  (option) => _SelectionChip(
                    label: option,
                    isSelected: selection == option,
                    onTap: () => onSelect(option),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
      footer: LiquidButton(label: 'Continue', onPressed: onContinue),
    );
  }
}

class _OverviewStep extends StatelessWidget {
  final bool isAuthorized;
  final VoidCallback onContinue;

  const _OverviewStep({required this.isAuthorized, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return _SetupStepScaffold(
      showBack: true,
      onBack: () => context.read<ScreenTimeSetupController>().jumpTo(
        ScreenTimeSetupStep.value,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text('Setup checklist', style: AppTypography.title1),
          const SizedBox(height: 10),
          Text(
            "We'll ask for one permission to enable Screen Time protections.",
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Row(
              children: [
                _StatusDot(isComplete: isAuthorized),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Screen Time / Family Controls',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Required to block apps and websites instantly.',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuthorized)
                  Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: AppColors.success,
                    size: 20,
                  ),
              ],
            ),
          ),
        ],
      ),
      footer: LiquidButton(label: 'Continue setup', onPressed: onContinue),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  final FocusProtectionStatus status;
  final ValueNotifier<bool> showSuccess;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;
  final VoidCallback onContinue;

  const _PermissionStep({
    required this.status,
    required this.showSuccess,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    final isAuthorized = status.isAuthorized;
    final shouldPrompt = status.shouldPrompt;
    final shouldOpenSettings = status.shouldOpenSettings;
    final isSupported = status.isSupported;

    final title = isSupported
        ? 'Allow Screen Time access'
        : 'Screen Time unavailable';
    final subtitle = !isSupported
        ? 'This device cannot grant Apple Screen Time access.'
        : "Screen Time access lets WakeApp enforce blocks and focus rules using Apple's on-device APIs.";

    final actionLabel = isAuthorized
        ? 'Continue'
        : shouldOpenSettings
        ? 'Open Settings'
        : 'Allow Screen Time';

    final action = isAuthorized
        ? onContinue
        : shouldOpenSettings
        ? onOpenSettings
        : onRequest;

    return _SetupStepScaffold(
      showBack: true,
      onBack: () => context.read<ScreenTimeSetupController>().jumpTo(
        ScreenTimeSetupStep.overview,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(title, style: AppTypography.title1),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('ios_setup_steps_title'),
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.secondaryLabel,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const _InstructionRow(index: 1, text: 'Tap "Open Settings".'),
                const SizedBox(height: 8),
                const _InstructionRow(
                  index: 2,
                  text: 'Choose WakeApp in the list.',
                ),
                const SizedBox(height: 8),
                const _InstructionRow(
                  index: 3,
                  text: 'Enable Screen Time access.',
                ),
                const SizedBox(height: 8),
                const _InstructionRow(index: 4, text: 'Return to WakeApp.'),
                const SizedBox(height: 12),
                if (!isSupported)
                  Text(
                    'Screen Time access is only available on supported iPhone builds.',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _PermissionStatusPill(status: status, showSuccess: showSuccess),
        ],
      ),
      footer: LiquidButton(label: actionLabel, onPressed: action),
    );
  }
}

class _PermissionStatusPill extends StatelessWidget {
  final FocusProtectionStatus status;
  final ValueNotifier<bool> showSuccess;

  const _PermissionStatusPill({
    required this.status,
    required this.showSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    return ValueListenableBuilder<bool>(
      valueListenable: showSuccess,
      builder: (context, success, _) {
        final isAuthorized = status.isAuthorized;
        final label = success || isAuthorized
            ? t('ios_setup_permission_granted')
            : status.shouldOpenSettings
            ? t('ios_setup_access_turned_off')
            : t('ios_setup_waiting_approval');
        final color = success || isAuthorized
            ? AppColors.success
            : status.shouldOpenSettings
            ? AppColors.primaryOrange
            : AppColors.secondaryLabel;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success || isAuthorized
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.info_circle_fill,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.caption1.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final VoidCallback onContinue;

  const _SuccessStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final t = context.read<LanguageProvider>().t;
    return _SetupStepScaffold(
      progressLabel: t('ios_setup_completed'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: AppColors.success,
            size: 48,
          ),
          const SizedBox(height: 18),
          Text(
            t('ios_setup_ready_title'),
            style: AppTypography.largeTitle.copyWith(
              fontSize: 32,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('ios_setup_ready_subtitle'),
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('ios_setup_next'),
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('ios_setup_next_subtitle'),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: LiquidButton(
        label: t('ios_setup_open_screen_time'),
        onPressed: onContinue,
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isSelected
        ? AppColors.primaryOrange.withValues(alpha: 0.22)
        : AppColors.glassSurfaceSoft;
    final border = isSelected ? AppColors.primaryOrange : AppColors.border;
    final textColor = isSelected ? AppColors.primaryOrange : AppColors.label;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BenefitRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final int index;
  final String text;

  const _InstructionRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.glassSurfaceStrong,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Text(
              '$index',
              style: AppTypography.caption1.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTypography.body.copyWith(height: 1.4)),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isComplete;

  const _StatusDot({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? AppColors.success : AppColors.primaryOrange;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
    );
  }
}
