import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/block_list_model.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/home_widget_service.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/android_protection_disclosure.dart';
import '../calendar/add_event_sheet.dart';
import 'block_list_sheet.dart';
import 'focus_preparation/focus_preparation_flow_view.dart';
import 'focus_preparation/focus_preparation_models.dart';
import 'focus_starter_sheet.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;

  const _FocusProgressRingPainter({
    required this.progress,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 10;
    const startAngle = -1.5707963267948966;
    final sweep = 6.283185307179586 * progress.clamp(0.0, 1.0);

    final basePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}

class _FocusScreenState extends State<FocusScreen> {
  static const List<int> _focusDurationOptions = [
    15,
    25,
    30,
    45,
    60,
    75,
    90,
    105,
    120,
    150,
    180,
  ];

  String _focusDurationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return "${hours}h ${remainingMinutes.toString().padLeft(2, '0')}";
    }
    return '${minutes}m';
  }

  final FeatureRepository _repo = FeatureRepository();
  final TextEditingController _customDurationCtrl = TextEditingController();

  WinStreak? _streak;
  bool _loading = true;
  bool _didPresentPreparationOnEntry = false;
  bool _appliedDeepLinkParams = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _presentPreparationIfNeeded(FocusProvider provider) async {
    if (_didPresentPreparationOnEntry) return;
    if (!provider.shouldShowPreparationFlowBeforeFocus) return;
    _didPresentPreparationOnEntry = true;
    final outcome = await showFocusPreparationFlow(
      context: context,
      launchContext: FocusPreparationLaunchContext.preFocus,
    );
    if (!mounted) return;
    await provider.persistPreparationOutcome(
      outcome ?? FocusPreparationFlowOutcome.skipped,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FocusProvider>();
      await provider.loadInitialData();
      _customDurationCtrl.text = provider.focusDurationMinutes.toString();
      await _loadStreak();
      await _presentPreparationIfNeeded(provider);
    });
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
        _setDuration(duration);
      });
    }
  }

  void _openPlanSheet(FocusProvider provider) {
    final now = DateTime.now();
    final future = now.add(const Duration(minutes: 5));
    final rounded = DateTime(
      future.year,
      future.month,
      future.day,
      future.hour,
      future.minute - (future.minute % 5),
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => AddEventSheet(
        selectedDate: rounded,
        initialTime: TimeOfDay(hour: rounded.hour, minute: rounded.minute),
        preset: AddEventPreset.focusPlan,
        presetDurationMinutes: provider.focusDurationMinutes,
      ),
    );
  }

  void _openStarterSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => const FocusStarterSheet(),
    );
  }

  void _openBlockListSheet(FocusProvider provider) {
    final activeId = provider.activeBlockListId;
    BlockList? activeList;
    for (final list in provider.blockLists) {
      if (list.id == activeId) {
        activeList = list;
        break;
      }
    }
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => BlockListSheet(blockList: activeList),
    );
  }

  Future<void> _handleProtectionAction(FocusProvider provider) async {
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

  Future<bool?> _showProtectionNotice(FocusProvider provider) {
    final language = context.read<LanguageProvider>();
    final status = provider.protectionStatus;
    final title = status.isSupported
        ? (status.shouldOpenSettings
              ? (_isAndroid
                    ? language.t('focus_turn_on_android_access')
                    : language.t('focus_turn_on_screen_time_access'))
              : language.t('focus_blocking_not_active_yet'))
        : language.t('focus_blocking_unavailable_here');
    final message = status.isSupported
        ? (status.shouldOpenSettings
              ? (_isAndroid
                    ? language.t('focus_notice_android_settings_off')
                    : language.t('focus_notice_ios_settings_off'))
              : (_isAndroid
                    ? language.t('focus_notice_android_timer_only')
                    : language.t('focus_notice_ios_timer_only')))
        : (_isAndroid
              ? language.t('focus_notice_android_runtime_unavailable')
              : language.t('focus_notice_ios_runtime_unavailable'));

    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(language.t('cancel')),
          ),
          if (status.shouldOpenSettings)
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(ctx).pop(false);
                if (_isAndroid) {
                  final confirmed = await showAndroidProtectionDisclosure(
                    context: context,
                    nextStep: provider.getNextAndroidProtectionStep,
                  );
                  if (!confirmed) return;
                }
                await provider.openSystemSettings();
              },
              child: Text(language.t('open_settings')),
            ),
          CupertinoDialogAction(
            isDefaultAction: !status.shouldOpenSettings,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(language.t('focus_start_timer_only')),
          ),
        ],
      ),
    );
  }

  String _protectionWarningMessage(FocusProvider provider) {
    final language = context.read<LanguageProvider>();
    final status = provider.protectionStatus;
    if (!status.isSupported) {
      return _isAndroid
          ? language.t('focus_warning_android_runtime_unavailable')
          : language.t('focus_warning_ios_runtime_unavailable');
    }
    if (status.shouldOpenSettings) {
      return _isAndroid
          ? language.t('focus_warning_android_access_off')
          : language.t('focus_warning_ios_access_off');
    }
    return _isAndroid
        ? language.t('focus_warning_android_not_enabled')
        : language.t('focus_warning_ios_not_enabled');
  }

  String _protectionActionLabel(FocusProvider provider) {
    final language = context.read<LanguageProvider>();
    return provider.protectionStatus.shouldOpenSettings
        ? language.t('open_settings')
        : language.t('focus_enable_protection');
  }

  @override
  void dispose() {
    _customDurationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStreak() async {
    final streak = await _repo.getWinStreak();
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _loading = false;
    });
  }

  void _setDuration(int value) {
    final minutes = value.clamp(5, 180);
    final provider = context.read<FocusProvider>();
    provider.focusDurationMinutes = minutes;
    provider.reset();
    _customDurationCtrl.text = '$minutes';
    unawaited(
      HomeWidget.saveWidgetData<int>(
        CeoHomeWidgetService.keyFocusDurationMinutes,
        minutes,
      ),
    );
  }

  Future<void> _start(FocusProvider provider) async {
    if (provider.shouldShowPreparationFlowBeforeFocus) {
      final outcome = await showFocusPreparationFlow(
        context: context,
        launchContext: FocusPreparationLaunchContext.preFocus,
      );
      if (!mounted) return;
      await provider.persistPreparationOutcome(
        outcome ?? FocusPreparationFlowOutcome.skipped,
      );
      if (!mounted) return;
    }

    if (!provider.isAuthorized) {
      if (_isAndroid) {
        final confirmed = await showAndroidProtectionDisclosure(
          context: context,
          nextStep: provider.getNextAndroidProtectionStep,
        );
        if (!confirmed) return;
      }
      final granted = await provider.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        final continueWithoutBlocking = await _showProtectionNotice(provider);
        if (continueWithoutBlocking != true) {
          return;
        }
      }
    }
    final success = await provider.startFocus();
    if (!success && mounted) {
      final premiumBlock = provider.lastPremiumCheck;
      if (premiumBlock != null && !premiumBlock.allowed) {
        await showPremiumGateDialog(context, premiumBlock);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: Consumer<FocusProvider>(
            builder: (context, provider, _) {
              if (_loading) {
                return Center(
                  child: CupertinoActivityIndicator(
                    color: AppColors.primaryOrange,
                  ),
                );
              }
              final isIdle = provider.state == FocusState.idle;
              return Stack(
                children: [
                  isIdle ? _buildIdle(provider) : _buildActive(provider),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: _header(
                            title: isIdle
                                ? (_isAndroid ? 'Focus Protection' : 'Screen Time')
                                : 'Focus',
                            showHome: isIdle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header({
    required String title,
    bool showHome = false,
    VoidCallback? trailingTap,
    IconData? trailingIcon,
  }) {
    final language = context.watch<LanguageProvider>();
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            minimumSize: Size.zero,
            onPressed: () => context.go('/screen-time-manager'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
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
          if (showHome)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              minimumSize: Size.zero,
              onPressed: () => context.go('/home'),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.house,
                    size: 20,
                    color: AppColors.secondaryLabel,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    language.t('home'),
                    style: AppTypography.callout.copyWith(
                      fontSize: 16,
                      color: AppColors.secondaryLabel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (!showHome && trailingIcon != null)
            _FocusPressScale(
              onTap: trailingTap ?? () {},
              scaleWhenPressed: 0.97,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.topBarControlBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.topBarControlBorder,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  trailingIcon,
                  size: 18,
                  color: AppColors.secondaryLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdle(FocusProvider provider) {
    final language = context.watch<LanguageProvider>();
    const presets = [25, 45, 90];
    final currentStreak = _streak?.currentStreak ?? 0;
    final sessions = _streak?.totalCompletedSessions ?? 0;
    final failed = _streak?.totalFailedSessions ?? 0;
    final successRate = sessions + failed == 0
        ? 0
        : ((sessions / (sessions + failed)) * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 18),
      child: Column(
        children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              language.t('focus_enter_zone'),
              textAlign: TextAlign.center,
              style: AppTypography.largeTitle.copyWith(
                fontSize: 44,
                color: AppColors.label,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          borderRadius: 24,
          level: GlassCardLevel.standard,
          showEdgeGlow: false,
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.30),
            width: 0.5,
          ),
          gradientColors: [
            AppColors.cardBackgroundStrong.withValues(alpha: 0.46),
            AppColors.cardBackgroundAlt.withValues(alpha: 0.36),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duration',
                style: AppTypography.callout.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryLabel,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.background.withValues(alpha: 0.5),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.30),
                    width: 0.5,
                  ),
                ),
                child: CupertinoPicker(
                  itemExtent: 34,
                  scrollController: FixedExtentScrollController(
                    initialItem: _focusDurationOptions
                        .indexWhere(
                          (m) => m == provider.focusDurationMinutes,
                        )
                        .clamp(0, _focusDurationOptions.length - 1),
                  ),
                  onSelectedItemChanged: (index) {
                    final value = _focusDurationOptions[index];
                    _setDuration(value);
                  },
                  selectionOverlay: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.40),
                        width: 0.5,
                      ),
                      color: AppColors.white.withValues(alpha: 0.035),
                    ),
                  ),
                  children: _focusDurationOptions
                      .map(
                        (minutes) => Center(
                          child: Text(
                            _focusDurationLabel(minutes),
                            style: AppTypography.mono.copyWith(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: minutes == provider.focusDurationMinutes
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
        const Spacer(flex: 2),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.35),
              width: 0.9,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: AppColors.error,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.t('focus_warning'),
                      style: AppTypography.callout.copyWith(
                        fontSize: 16,
                        color: AppColors.error.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language.t('focus_warning_exit_resets_streak'),
                      style: AppTypography.footnote.copyWith(
                        fontSize: 14,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
        Text(
          language.t('focus_current_streak'),
          textAlign: TextAlign.center,
          style: AppTypography.overline.copyWith(
            fontSize: 13,
            color: AppColors.secondaryLabel.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Text(
              '$currentStreak',
              style: AppTypography.heroNumber.copyWith(
                fontSize: 40,
                color: AppColors.label,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
        const Spacer(flex: 3),
        _FocusPrimaryButton(
          label: language.t('focus_begin_mode'),
          onTap: () => _start(provider),
        ),
        const SizedBox(height: 12),
        _FocusSecondaryButton(
          label: 'Schedule a session',
          onTap: () => _openPlanSheet(provider),
        ),
        ],
      ),
    );
  }

  Widget _buildActive(FocusProvider provider) {
    final isFocusing = provider.state == FocusState.focusing;
    final isBreak =
        provider.state == FocusState.shortBreak ||
        provider.state == FocusState.longBreak;
    final accentColor = isBreak
        ? const Color(0xFF7ED6A5)
        : const Color(0xFF4C7DFF);
    final progressColor = isBreak
        ? const Color(0x997ED6A5)
        : const Color(0x994C7DFF);
    final timerLabel = isFocusing ? 'DEEP WORK' : 'BREAK';
    final controlTitle = switch (provider.state) {
      FocusState.focusing => 'Focus Session',
      FocusState.shortBreak => 'Short Break',
      FocusState.longBreak => 'Long Break',
      FocusState.requestingBreak => 'Break Request Pending',
      FocusState.breakOptionsMenu => 'Break Selection',
      FocusState.exitPending => 'Exit Pending',
      FocusState.idle => 'Focus Session',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 22),
      child: Column(
        children: [
          Text(
            provider.stateLabel,
            style: AppTypography.mono.copyWith(
              fontSize: 20,
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.glassBorder.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CupertinoActivityIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.timerDisplay,
                        style: AppTypography.timer.copyWith(
                          fontSize: 68,
                          color: AppColors.label,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                        ),
                      ),
                      Text(
                        isFocusing ? 'DEEP WORK' : 'BREAK',
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          color: AppColors.primaryOrange,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (provider.state == FocusState.focusing)
            LiquidButton(
              label: 'REQUEST BREAK',
              fullWidth: true,
              onPressed: provider.requestBreak,
            )
          else if (provider.state == FocusState.requestingBreak)
            LiquidButton(
              label: 'Cancel (${provider.waitTimerDisplay})',
              labelStyle: AppTypography.timer.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              fullWidth: true,
              onPressed: provider.cancelBreakRequest,
            )
          else if (provider.state == FocusState.breakOptionsMenu)
            Row(
              children: [
                Expanded(
                  child: LiquidButton(
                    label: '5m break',
                    onPressed: () => provider.takeCustomBreak(5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LiquidButton(
                    label: '15m break',
                    onPressed: () => provider.takeCustomBreak(15),
                  ),
                ),
              ],
            )
          else
            LiquidButton(
              label: 'Skip break',
              fullWidth: true,
              onPressed: provider.skip,
            ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.floatingGlassGradient.first.withValues(alpha: 0.84),
            AppColors.floatingGlassGradient.last.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.7),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 54,
              color: color,
              fontWeight: FontWeight.w900,
              height: 0.86,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              color: AppColors.tertiaryLabel,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleWhenPressed;

  const _FocusPressScale({
    required this.child,
    required this.onTap,
    this.scaleWhenPressed = 1.01,
  });

  @override
  State<_FocusPressScale> createState() => _FocusPressScaleState();
}

class _FocusPressScaleState extends State<_FocusPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleWhenPressed : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}

class _FocusPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FocusPrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _FocusPressScale(
      onTap: onTap,
      scaleWhenPressed: 0.97,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.buttonGradientEnd,
              AppColors.buttonGradientStart,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderStrong, width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.callout.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }
}

class _FocusSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FocusSecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _FocusPressScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundAlt.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStrong, width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.callout.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.label,
          ),
        ),
      ),
    );
  }
}
