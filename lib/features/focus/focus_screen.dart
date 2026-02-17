import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/platform/adaptive_widgets.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_card.dart';
import '../../core/widgets/ceo_progress_ring.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FocusProvider>().loadSampleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text('Focus', style: AppTypography.displayMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Eliminate distractions. Get in the zone.',
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              _PomodoroSection(),
              const SizedBox(height: AppSpacing.sectionSpacing),
              _FocusModeSection(),
              const SizedBox(height: AppSpacing.sectionSpacing),
              _UsageChartSection(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PomodoroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FocusProvider>(builder: (_, p, __) {
      return Column(children: [
        Center(
          child: CeoProgressRing(
            progress: p.progress,
            size: 220,
            strokeWidth: 8,
            gradientColors: p.state == FocusState.focusing
                ? AppColors.accentGradient
                : [AppColors.success, AppColors.success.withValues(alpha: 0.6)],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.timerDisplay, style: AppTypography.mono),
                const SizedBox(height: AppSpacing.xs),
                Text(p.stateLabel,
                    style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Session dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final done = i < p.completedSessions % 4;
            final current = i == p.completedSessions % 4 &&
                p.state == FocusState.focusing;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: current ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: done || current
                      ? AppColors.accent
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${p.completedSessions} sessions · ${p.totalFocusMinutesToday} min',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (p.state != FocusState.idle) ...[
              _CtrlBtn(
                  icon: CupertinoIcons.stop_fill,
                  label: 'Reset',
                  onTap: p.reset),
              const SizedBox(width: AppSpacing.lg),
            ],
            GestureDetector(
              onTap: () {
                if (p.state == FocusState.idle) {
                  p.startFocus();
                } else if (p.isRunning) {
                  p.pause();
                } else {
                  p.resume();
                }
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  p.state == FocusState.idle || !p.isRunning
                      ? CupertinoIcons.play_fill
                      : CupertinoIcons.pause_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            if (p.state != FocusState.idle) ...[
              const SizedBox(width: AppSpacing.lg),
              _CtrlBtn(
                  icon: CupertinoIcons.forward_fill,
                  label: 'Skip',
                  onTap: p.skip),
            ],
          ],
        ),
      ]);
    });
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CtrlBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ]),
    );
  }
}

class _FocusModeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FocusProvider>(builder: (_, p, __) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CeoCard(
            onTap: p.toggleFocusMode,
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.isFocusModeActive
                      ? AppColors.accent
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  CupertinoIcons.shield_fill,
                  color: p.isFocusModeActive
                      ? Colors.white
                      : AppColors.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Focus Mode', style: AppTypography.headingSmall),
                    Text(
                      p.isFocusModeActive
                          ? 'Active — Apps blocked'
                          : 'Tap to activate',
                      style: AppTypography.caption.copyWith(
                        color: p.isFocusModeActive
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              AdaptiveSwitch(
                value: p.isFocusModeActive,
                onChanged: (_) => p.toggleFocusMode(),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'BLOCKED APPS',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...p.blockedApps.asMap().entries.map((e) {
            final app = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: CeoCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                onTap: () => p.toggleBlockedApp(e.key),
                child: Row(children: [
                  Icon(app.icon, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(app.name, style: AppTypography.bodyMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: app.isBlocked
                          ? AppColors.errorMuted
                          : AppColors.successMuted,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull),
                    ),
                    child: Text(
                      app.isBlocked ? 'Blocked' : 'Allowed',
                      style: AppTypography.labelSmall.copyWith(
                        color: app.isBlocked
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ],
      );
    });
  }
}

class _UsageChartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FocusProvider>(builder: (_, p, __) {
      final totalH = p.hourlyUsage.reduce((a, b) => a + b).toStringAsFixed(1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Screen Time', style: AppTypography.headingSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.warningMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${totalH}h today',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CeoCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: 120,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: p.hourlyUsage
                    .reduce(max)
                    .clamp(1, 10)
                    .toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => v.toInt() % 6 == 0
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${v.toInt()}h',
                                style: AppTypography.caption
                                    .copyWith(fontSize: 9),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(24, (i) {
                  final v = p.hourlyUsage[i];
                  final h = DateTime.now().hour;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        width: 6,
                        color: i == h
                            ? AppColors.accent
                            : v > 2
                                ? AppColors.warning
                                : AppColors.surfaceLighter,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
              )),
            ),
          ),
        ],
      );
    });
  }
}
