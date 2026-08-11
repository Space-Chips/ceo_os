import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
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
    context.watch<ThemeProvider>();
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
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.30),
                width: 0.8,
              ),
            ),
            child: Icon(
              CupertinoIcons.shield_lefthalf_fill,
              size: 28,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Configure Screen Time',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
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
          const SizedBox(height: 28),
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What you'll unlock",
                  style: AppTypography.title3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _BenefitRow(
                  icon: CupertinoIcons.bolt_fill,
                  title: 'Instant blocking',
                  subtitle: 'Protected apps close immediately during sessions.',
                ),
                const SizedBox(height: 16),
                _BenefitRow(
                  icon: CupertinoIcons.lock_shield_fill,
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

  // Rotative wheel range: 15 → 180 minutes by 15-minute steps. Covers the
  // previous chip options (30 / 60 / 90) and then some.
  static const List<int> _valueOptions = [
    15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180,
  ];
  static const int _defaultMinutes = 60;

  static String _labelFor(int minutes) => '$minutes min';

  int? _parseSelection(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    final selectedMinutes = _parseSelection(selection) ?? _defaultMinutes;
    final initialIndex = _valueOptions
        .indexOf(selectedMinutes)
        .clamp(0, _valueOptions.length - 1);

    return _SetupStepScaffold(
      showBack: true,
      onBack: () => context.read<ScreenTimeSetupController>().jumpTo(
        ScreenTimeSetupStep.intro,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'How much time do you want back each day?',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pick a target to personalize your Screen Time protection.',
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // Live read-out of the current wheel value.
          Center(
            child: Column(
              children: [
                Text(
                  _labelFor(selectedMinutes),
                  style: AppTypography.largeTitle.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'back each day',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.tertiaryLabel,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GlassCard(
            level: GlassCardLevel.subtle,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            borderRadius: 22,
            child: SizedBox(
              height: 180,
              child: CupertinoPicker(
                itemExtent: 40,
                magnification: 1.05,
                squeeze: 1.1,
                diameterRatio: 1.25,
                scrollController:
                    FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (index) =>
                    onSelect(_labelFor(_valueOptions[index])),
                selectionOverlay: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.primaryOrange.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppColors.primaryOrange.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                ),
                children: _valueOptions.map((minutes) {
                  final isSelected = minutes == selectedMinutes;
                  return Center(
                    child: Text(
                      _labelFor(minutes),
                      style: AppTypography.mono.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.label
                            : AppColors.secondaryLabel.withValues(alpha: 0.45),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
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
          const SizedBox(height: 8),
          Text(
            'Setup checklist',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "We'll ask for one permission to enable Screen Time protections.",
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 18,
            child: Row(
              children: [
                _StatusDot(isComplete: isAuthorized),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Screen Time / Family Controls',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Required to block apps and websites instantly.',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.secondaryLabel,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isAuthorized
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.circle,
                  color: isAuthorized
                      ? AppColors.success
                      : AppColors.tertiaryLabel,
                  size: 22,
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
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.30),
                width: 0.8,
              ),
            ),
            child: Icon(
              isSupported
                  ? CupertinoIcons.checkmark_shield_fill
                  : CupertinoIcons.exclamationmark_shield_fill,
              size: 28,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (shouldOpenSettings) ...[
            // Show manual steps only when the user has previously denied
            // permission and must re-enable it from iOS Settings. In every
            // other state the in-app native AuthorizationCenter popup handles
            // the grant without leaving the app.
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
                    text: 'Choose Screen Time → See All Activity.',
                  ),
                  const SizedBox(height: 8),
                  const _InstructionRow(
                    index: 3,
                    text: 'Enable WakeApp under Family Controls.',
                  ),
                  const SizedBox(height: 8),
                  const _InstructionRow(
                    index: 4,
                    text: 'Return to WakeApp.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ] else if (shouldPrompt && isSupported) ...[
            // First-time grant: just tell the user a system popup will appear.
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    size: 22,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'iOS will show a confirmation. Tap "Continue" then "Allow" — you stay in WakeApp the whole time.',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.secondaryLabel,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ] else if (!isSupported) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Text(
                'Screen Time access is only available on supported iPhone builds.',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
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

class _BenefitRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _BenefitRow({
    required this.title,
    required this.subtitle,
    this.icon = CupertinoIcons.circle_fill,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.30),
              width: 0.6,
            ),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.secondaryLabel,
                  height: 1.35,
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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.35),
              width: 0.6,
            ),
          ),
          child: Center(
            child: Text(
              '$index',
              style: AppTypography.caption1.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
