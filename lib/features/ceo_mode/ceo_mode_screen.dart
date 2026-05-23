import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/providers/ceo_mode_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/services/home_widget_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/android_protection_disclosure.dart';
import 'blackout_preparation/blackout_preparation_flow_view.dart';
import 'blackout_preparation/blackout_preparation_models.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';

class CeoModeScreen extends StatefulWidget {
  const CeoModeScreen({super.key});

  @override
  State<CeoModeScreen> createState() => _CeoModeScreenState();
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const _PressScale({required this.child, this.pressedScale = 0.97});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

class _CeoModeScreenState extends State<CeoModeScreen> {
  static const List<int> _durationOptions = [
    15,
    30,
    45,
    60,
    75,
    90,
    120,
    150,
    180,
    210,
    240,
  ];

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String _t(String key) => context.watch<LanguageProvider>().t(key);
  bool _appliedDeepLinkParams = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CeoModeProvider>().initialize();
    });
  }

  Future<void> _persistWidgetDuration(int minutes) async {
    await HomeWidget.saveWidgetData<int>(
      CeoHomeWidgetService.keyBlackoutDurationMinutes,
      minutes,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedDeepLinkParams) return;
    final params = GoRouterState.of(context).uri.queryParameters;
    final rawDuration = params['duration'];
    final rawStart = params['start'];
    if ((rawDuration == null || rawDuration.trim().isEmpty) &&
        (rawStart == null || rawStart.trim().isEmpty)) {
      return;
    }
    _appliedDeepLinkParams = true;
    final duration = int.tryParse(rawDuration ?? '');
    if (duration != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = context.read<CeoModeProvider>();
        final clamped = duration.clamp(15, 240);
        provider.setDuration(clamped);
        unawaited(_persistWidgetDuration(clamped));
      });
    }
  }

  String _durationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return "${hours}h ${remainingMinutes.toString().padLeft(2, '0')}";
    }
    return '${minutes}m';
  }

  Future<void> _startSession(CeoModeProvider provider) async {
    final confirmed = await _showStartConfirmation(provider);
    if (confirmed != true) return;
    if (!mounted) return;

    if (provider.shouldShowPreparationFlowBeforeBlackout) {
      final outcome = await showBlackoutPreparationFlow(
        context: context,
        launchContext: BlackoutPreparationLaunchContext.preBlackout,
      );
      if (!mounted) return;
      await provider.persistPreparationOutcome(
        outcome ?? BlackoutPreparationFlowOutcome.skipped,
      );
      if (!mounted) return;
    }

    if (_isAndroid && !provider.isAuthorized) {
      final permissionConfirmed = await showAndroidProtectionDisclosure(
        context: context,
        nextStep: provider.getNextAndroidProtectionStep,
      );
      if (!permissionConfirmed) return;
    }

    await HapticFeedback.mediumImpact();
    final success = await provider.startSession();
    if (!mounted) return;
    if (!success) {
      final check = provider.lastPremiumCheck;
      if (check != null && !check.allowed) {
        await showPremiumGateDialog(context, check);
        return;
      }
      final issue = provider.lastStartIssue;
      final (title, message) = switch (issue) {
        'block_list' => (
          'Block List Required',
          'Choose at least one blocked app or category before starting CEO Mode so the session can be enforced.',
        ),
        _ => (
          'Setup Required',
          'Enable Screen Time / Family Controls permissions to enforce CEO Mode protections.',
        ),
      };
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (issue == 'permissions_denied')
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (_isAndroid) {
                    final confirmed = await showAndroidProtectionDisclosure(
                      context: context,
                      nextStep: provider.getNextAndroidProtectionStep,
                    );
                    if (!confirmed) return;
                  }
                  await provider.openSystemSettings();
                },
                child: Text(
                  context.read<LanguageProvider>().t('open_settings'),
                ),
              ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.read<LanguageProvider>().t('ok')),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleProtectionAction(CeoModeProvider provider) async {
    if (_isAndroid) {
      final confirmed = await showAndroidProtectionDisclosure(
        context: context,
        nextStep: provider.getNextAndroidProtectionStep,
      );
      if (!confirmed) return;
    }
    if (provider.protectionStatus.shouldOpenSettings) {
      await provider.openSystemSettings();
      if (!mounted) return;
      await provider.refreshProtectionStatus();
      return;
    }
    await provider.requestPermissions();
  }

  String _protectionStatusMessage(CeoModeProvider provider) {
    final status = provider.protectionStatus;
    if (provider.isAuthorized) {
      return _t('blackout_protection_granted');
    }
    if (!status.isSupported) {
      return _isAndroid
          ? _t('blackout_protection_unavailable_android')
          : _t('blackout_protection_unavailable_ios');
    }
    if (status.shouldOpenSettings) {
      return _isAndroid
          ? _t('blackout_protection_off_android')
          : _t('blackout_protection_off_ios');
    }
    return _isAndroid
        ? _t('blackout_protection_grant_android')
        : _t('blackout_protection_grant_ios');
  }

  String _protectionActionLabel(CeoModeProvider provider) {
    if (provider.isAuthorized) return _t('blackout_action_refresh');
    if (!provider.protectionStatus.isSupported) {
      return _t('blackout_action_unavailable');
    }
    return provider.protectionStatus.shouldOpenSettings
        ? _t('blackout_action_open_settings')
        : _t('blackout_action_enable');
  }

  Future<bool?> _showStartConfirmation(CeoModeProvider provider) {
    return showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) {
        return CupertinoPopupSurface(
          isSurfacePainted: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundAlt.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow.withValues(alpha: 0.4),
                  blurRadius: 28,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _t('blackout_confirm_title'),
                      textAlign: TextAlign.center,
                      style: AppTypography.title2.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _t('blackout_confirm_body'),
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          _t('focus_session_duration'),
                          textAlign: TextAlign.center,
                          style: AppTypography.subhead.copyWith(
                            fontSize: 14,
                            color: AppColors.secondaryLabel.withValues(
                              alpha: 0.74,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _durationLabel(provider.selectedDurationMinutes),
                          textAlign: TextAlign.center,
                          style: AppTypography.title3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        _t('cancel'),
                        style: AppTypography.callout.copyWith(
                          color: AppColors.label.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PressScale(
                      pressedScale: 0.97,
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(true),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFFFB04E), Color(0xFFFFD48A)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _t('blackout_confirm_start'),
                            style: AppTypography.callout.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _confirmationDurationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes / 60;
      if (hours == hours.roundToDouble()) {
        final value = hours.toInt();
        return value == 1 ? '1 hour' : '$value hours';
      }
      return '${hours.toStringAsFixed(1)} hours';
    }
    return minutes == 1 ? '1 minute' : '$minutes minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CeoModeProvider>(
      builder: (context, ceo, _) {
        final canPop = !ceo.isSessionActive;

        return PopScope(
          canPop: canPop,
          child: CupertinoPageScaffold(
            backgroundColor: AppColors.background,
            child: AmbientBackdrop(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Column(
                    children: [
                      _header(ceo),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ceo.isInitialized
                            ? (ceo.state == CeoModeState.idle
                                  ? _setupView(ceo)
                                  : ceo.state == CeoModeState.active
                                  ? _activeView(ceo)
                                  : _exitPendingView(ceo))
                            : Center(
                                child: CupertinoActivityIndicator(
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(CeoModeProvider ceo) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            onPressed: () => context.go('/home'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  _t('home'),
                  style: AppTypography.callout.copyWith(
                    fontSize: 16,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (ceo.isSessionActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primaryOrange.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.42),
                  width: 0.6,
                ),
              ),
              child: Text(
                _t('blackout_locked'),
                style: AppTypography.caption1.copyWith(
                  fontSize: 10,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _CeoCountdownRing({
    required int remainingSeconds,
    required int totalSeconds,
  }) {
    final total = totalSeconds <= 0 ? 1 : totalSeconds;
    final progress = (remainingSeconds / total).clamp(0.0, 1.0);
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _CountdownRingPainter(
              progress: progress,
              baseColor: AppColors.borderStrong.withValues(alpha: 0.2),
              accentColor: AppColors.primaryOrange,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$minutes:$seconds',
                style: AppTypography.heroDisplay.copyWith(
                  fontSize: 46,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t('blackout_remaining'),
                style: AppTypography.caption1.copyWith(
                  fontSize: 11,
                  color: AppColors.secondaryLabel,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _setupView(CeoModeProvider ceo) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        Text(
          _t('blackout_mode'),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 39,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: 0,
            color: AppColors.label,
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          borderRadius: 24,
          level: GlassCardLevel.standard,
          showEdgeGlow: false,
          border: Border.all(
            color: AppColors.glassBorder.withValues(alpha: 0.82),
            width: 0.75,
          ),
          gradientColors: [
            AppColors.cardBackgroundStrong.withValues(alpha: 0.46),
            AppColors.cardBackgroundAlt.withValues(alpha: 0.36),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _setupSectionTitle('Duration'),
              const SizedBox(height: 11),
              Container(
                height: 136,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.background.withValues(alpha: 0.5),
                  border: Border.all(
                    color: AppColors.glassBorder.withValues(alpha: 0.72),
                    width: 0.7,
                  ),
                ),
                child: CupertinoPicker(
                  itemExtent: 34,
                  scrollController: FixedExtentScrollController(
                    initialItem: _durationOptions
                        .indexWhere((m) => m == ceo.selectedDurationMinutes)
                        .clamp(0, _durationOptions.length - 1),
                  ),
                  onSelectedItemChanged: (index) {
                    final value = _durationOptions[index];
                    ceo.setDuration(value);
                    unawaited(_persistWidgetDuration(value));
                  },
                  selectionOverlay: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.label.withValues(alpha: 0.36),
                        width: 0.55,
                      ),
                      color: AppColors.white.withValues(alpha: 0.035),
                    ),
                  ),
                  children: _durationOptions
                      .map(
                        (minutes) => Center(
                          child: Text(
                            _durationLabel(minutes),
                            style: AppTypography.mono.copyWith(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: minutes == ceo.selectedDurationMinutes
                                  ? AppColors.label
                                  : AppColors.secondaryLabel.withValues(
                                      alpha: 0.42,
                                    ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          borderRadius: 24,
          level: GlassCardLevel.standard,
          showEdgeGlow: false,
          border: Border.all(
            color: AppColors.glassBorder.withValues(alpha: 0.82),
            width: 0.75,
          ),
          gradientColors: [
            AppColors.cardBackgroundStrong.withValues(alpha: 0.46),
            AppColors.cardBackgroundAlt.withValues(alpha: 0.36),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _setupSectionTitle('Essential apps (3)'),
              const SizedBox(height: 11),
              _approvedAppItem(CupertinoIcons.phone, 'Phone'),
              const SizedBox(height: 8),
              _approvedAppItem(CupertinoIcons.chat_bubble_2, 'Messages'),
              const SizedBox(height: 8),
              _approvedAppItem(CupertinoIcons.calendar, 'Calendar'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          borderRadius: 18,
          level: GlassCardLevel.standard,
          showEdgeGlow: false,
          border: Border.all(
            color: AppColors.glassBorder.withValues(alpha: 0.72),
            width: 0.75,
          ),
          child: Row(
            children: [
              Icon(
                ceo.isAuthorized
                    ? CupertinoIcons.checkmark_shield_fill
                    : CupertinoIcons.shield_lefthalf_fill,
                size: 18,
                color: ceo.isAuthorized
                    ? AppColors.success
                    : AppColors.primaryOrange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _protectionStatusMessage(ceo),
                  style: AppTypography.footnote.copyWith(
                    fontSize: 12,
                    height: 1.25,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                onPressed: () => _handleProtectionAction(ceo),
                child: Text(
                  _protectionActionLabel(ceo),
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF4C7DFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _t('blackout_essential_note'),
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            color: AppColors.secondaryLabel.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 16),
        _PressScale(
          pressedScale: 0.96,
          child: GestureDetector(
            onTap: ceo.isBusy ? null : () => _startSession(ceo),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: ceo.isBusy ? 0.85 : 1,
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.label.withValues(alpha: 0.88),
                      AppColors.secondaryLabel.withValues(alpha: 0.84),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.38),
                    width: 0.55,
                  ),
                ),
                alignment: Alignment.center,
                child: ceo.isBusy
                    ? CupertinoActivityIndicator(color: AppColors.background)
                    : Text(
                        _t('blackout_confirm_start'),
                        style: AppTypography.callout.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _setupSectionTitle(String label) {
    return Text(
      label,
      style: AppTypography.callout.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryLabel,
        letterSpacing: 0,
      ),
    );
  }

  Widget _activeView(CeoModeProvider ceo) {
    final totalSeconds = ceo.selectedDurationMinutes * 60;
    final remainingSeconds = ceo.sessionRemainingSeconds;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      children: [
        _glowSurface(
          glowColor: AppColors.primaryOrange.withValues(alpha: 0.22),
          borderRadius: 32,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.cardBackgroundAlt.withValues(alpha: 0.96),
                  AppColors.cardBase.withValues(alpha: 0.98),
                ],
              ),
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _t('blackout_active'),
                  style: AppTypography.caption1.copyWith(
                    fontSize: 12,
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                _CeoCountdownRing(
                  remainingSeconds: remainingSeconds,
                  totalSeconds: totalSeconds,
                ),
                const SizedBox(height: 16),
                Text(
                  _t('blackout_active_description'),
                  textAlign: TextAlign.center,
                  style: AppTypography.subhead.copyWith(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        LiquidButton(
          label: _t('blackout_request_exit').replaceAll('{minutes}', '10'),
          fullWidth: true,
          onPressed: ceo.requestExit,
        ),
      ],
    );
  }

  Widget _exitPendingView(CeoModeProvider ceo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dialSize = constraints.maxWidth.clamp(260.0, 340.0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 22),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  children: [
                    _glowSurface(
                      glowColor: AppColors.error.withValues(alpha: 0.16),
                      borderRadius: 220,
                      child: SizedBox(
                        width: dialSize,
                        height: dialSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.08),
                              radius: 0.92,
                              colors: [
                                AppColors.backgroundLight.withValues(
                                  alpha: 0.96,
                                ),
                                AppColors.cardBackgroundAlt.withValues(
                                  alpha: 0.96,
                                ),
                                AppColors.background.withValues(alpha: 0.98),
                              ],
                              stops: const [0, 0.62, 1],
                            ),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.38),
                              width: 1.15,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.12),
                                blurRadius: 44,
                                spreadRadius: -10,
                              ),
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.22),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                                spreadRadius: -12,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: dialSize * 0.82,
                                height: dialSize * 0.82,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white.withValues(
                                      alpha: 0.04,
                                    ),
                                    width: 1,
                                  ),
                                ),
                              ),
                              Container(
                                width: dialSize * 0.56,
                                height: dialSize * 0.56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white.withValues(
                                    alpha: 0.015,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.white.withValues(
                                          alpha: 0.055,
                                        ),
                                        border: Border.all(
                                          color: AppColors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        CupertinoIcons.timer,
                                        size: 22,
                                        color: AppColors.secondaryLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      _t('blackout_exit_countdown'),
                                      textAlign: TextAlign.center,
                                      style: AppTypography.overline.copyWith(
                                        fontSize: 12,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      ceo.exitCountdownLabel,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.heroDisplay.copyWith(
                                        fontSize: dialSize < 300 ? 62 : 72,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.label,
                                        letterSpacing: -2.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 290),
                      child: Text(
                        _t('blackout_exit_hint'),
                        textAlign: TextAlign.center,
                        style: AppTypography.footnote.copyWith(
                          fontSize: 13,
                          height: 1.42,
                          color: AppColors.secondaryLabel.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LiquidButton(
                      label: _t('blackout_return_to_session'),
                      fullWidth: true,
                      onPressed: ceo.returnToSession,
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: ceo.canFinalizeExit ? 1 : 0.45,
                      child: LiquidButton(
                        label: ceo.canFinalizeExit
                            ? 'QUIT NOW'
                            : 'WAIT FOR COUNTDOWN',
                        fullWidth: true,
                        onPressed: ceo.canFinalizeExit
                            ? ceo.finalizeExit
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _approvedAppItem(IconData icon, String label) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.background.withValues(alpha: 0.32),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.34),
          width: 0.55,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.moduleIconBackground.withValues(alpha: 0.72),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: AppColors.secondaryLabel.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              color: AppColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowSurface({
    required Widget child,
    required Color glowColor,
    double borderRadius = 20,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 26, spreadRadius: -2),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.baseColor,
    required this.accentColor,
  });

  final double progress;
  final Color baseColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          accentColor.withValues(alpha: 0.12),
          accentColor.withValues(alpha: 0.7),
          accentColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    final sweep = math.pi * 2 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor;
  }
}
