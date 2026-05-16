import 'dart:async';

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

class CeoModeScreen extends StatefulWidget {
  const CeoModeScreen({super.key});

  @override
  State<CeoModeScreen> createState() => _CeoModeScreenState();
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

  Future<void> _persistWidgetDuration(int minutes) async {
    await HomeWidget.saveWidgetData<int>(
      CeoHomeWidgetService.keyFocusDurationMinutes,
      minutes,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CeoModeProvider>().initialize();
    });
  }

  String _durationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}m';
  }

  Future<void> _startSession(CeoModeProvider provider) async {
    final confirmed = await _showStartConfirmation(provider);
    if (confirmed != true) return;

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

  Future<bool?> _showStartConfirmation(CeoModeProvider provider) {
    return showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) {
        return CupertinoPopupSurface(
          isSurfacePainted: false,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xF314161C),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
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
                        color: CupertinoColors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Activate CEO Mode?',
                      textAlign: TextAlign.center,
                      style: AppTypography.title2.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You will not be able to access blocked apps until the session ends.',
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
                          'Session duration',
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
                          _confirmationDurationLabel(
                            provider.selectedDurationMinutes,
                          ),
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
                        'Cancel',
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
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFFFB04E), Color(0xFFFFD48A)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Start Session',
                            style: AppTypography.callout.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
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
            onPressed: ceo.isSessionActive ? null : () => context.go('/home'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: ceo.isSessionActive
                      ? AppColors.tertiaryLabel
                      : AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  'Home',
                  style: AppTypography.mono.copyWith(
                    fontSize: 16,
                    color: ceo.isSessionActive
                        ? AppColors.tertiaryLabel
                        : AppColors.secondaryLabel,
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
                'LOCKED',
                style: AppTypography.mono.copyWith(
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

  Widget _setupView(CeoModeProvider ceo) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      children: [
        Text(
          'CEO Mode',
          style: AppTypography.mono.copyWith(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: AppColors.label,
            height: 0.88,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Maximum Focus. Once activated, normal mode is unavailable until session ends or delayed exit unlocks.',
          style: AppTypography.mono.copyWith(
            fontSize: 14,
            color: AppColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 16),
        _glowSurface(
          glowColor: AppColors.primaryOrange.withValues(alpha: 0.22),
          borderRadius: 28,
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 28,
            level: GlassCardLevel.elevated,
            showEdgeGlow: true,
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.5),
              width: 0.85,
            ),
            gradientColors: [
              AppColors.primaryOrange.withValues(alpha: 0.2),
              AppColors.backgroundLight.withValues(alpha: 0.95),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DURATION',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 146,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.floatingGlassGradient.first.withValues(
                          alpha: 0.88,
                        ),
                        AppColors.floatingGlassGradient.last.withValues(
                          alpha: 0.78,
                        ),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.8),
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
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.5),
                          width: 0.7,
                        ),
                        color: AppColors.primaryOrange.withValues(alpha: 0.14),
                      ),
                    ),
                    children: _durationOptions
                        .map(
                          (minutes) => Center(
                            child: Text(
                              _durationLabel(minutes),
                              style: AppTypography.mono.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: minutes == ceo.selectedDurationMinutes
                                    ? AppColors.label
                                    : AppColors.secondaryLabel,
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
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(18),
          borderRadius: 24,
          level: GlassCardLevel.standard,
          showEdgeGlow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APPROVED APPS (3)',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.tertiaryLabel,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
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
          padding: const EdgeInsets.all(14),
          borderRadius: 18,
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
                  ceo.isAuthorized
                      ? 'Protection access granted'
                      : 'Grant Screen Time permissions for stronger enforcement',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                onPressed: ceo.requestPermissions,
                child: Text(
                  ceo.isAuthorized ? 'Refresh' : 'Enable',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LiquidButton(
          label: ceo.isBusy ? 'STARTING...' : 'START CEO SESSION',
          fullWidth: true,
          isLoading: ceo.isBusy,
          onPressed: () => _startSession(ceo),
        ),
      ],
    );
  }

  Widget _activeView(CeoModeProvider ceo) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      children: [
        _glowSurface(
          glowColor: AppColors.primaryOrange.withValues(alpha: 0.28),
          borderRadius: 30,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            borderRadius: 30,
            level: GlassCardLevel.elevated,
            showEdgeGlow: true,
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.56),
              width: 1.0,
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.flame_fill,
                  size: 54,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 12),
                Text(
                  'CEO SESSION ACTIVE',
                  style: AppTypography.mono.copyWith(
                    fontSize: 14,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ceo.sessionTimerLabel,
                  style: AppTypography.timer.copyWith(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryOrange,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only approved apps should be used during this session.',
                  textAlign: TextAlign.center,
                  style: AppTypography.mono.copyWith(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          level: GlassCardLevel.standard,
          showEdgeGlow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APPROVED APPS',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.tertiaryLabel,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _approvedAppItem(CupertinoIcons.phone, 'Phone'),
              const SizedBox(height: 8),
              _approvedAppItem(CupertinoIcons.chat_bubble_2, 'Messages'),
              const SizedBox(height: 8),
              _approvedAppItem(CupertinoIcons.calendar, 'Calendar'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LiquidButton(
          label: 'REQUEST EXIT (10 MIN)',
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
                                      'EXIT COUNTDOWN',
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
                        'If your screen turns off, countdown restarts to 10:00.',
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
                      label: 'RETURN TO SESSION',
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      level: GlassCardLevel.subtle,
      border: Border.all(
        color: AppColors.glassBorder.withValues(alpha: 0.82),
        width: 0.55,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accentSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 14,
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w700,
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
