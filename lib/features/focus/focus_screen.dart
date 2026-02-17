import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_progress_ring.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _subTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FocusProvider>().loadSampleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground,
      child: SafeArea(
        child: Consumer<FocusProvider>(
          builder: (context, prov, _) => Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: CNSegmentedControl(
                  labels: const ['Sessions', 'Stats'],
                  selectedIndex: _subTab,
                  onValueChanged: (i) => setState(() => _subTab = i),
                ),
              ),
              Expanded(
                child: _subTab == 0
                    ? _TimerView(provider: prov)
                    : _StatsView(provider: prov),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerView extends StatelessWidget {
  final FocusProvider provider;
  const _TimerView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isActive = provider.state != FocusState.idle;
    final isFocusing = provider.state == FocusState.focusing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          const Spacer(),
          Text('Focus Time', style: AppTypography.focusDisplay),
          const SizedBox(height: AppSpacing.xs),
          Text(
            provider.stateLabel,
            style: AppTypography.subhead.copyWith(
              color: AppColors.secondaryLabel,
            ),
          ),
          const Spacer(),
          CeoProgressRing(
            progress: provider.progress,
            size: 220,
            strokeWidth: 4,
            gradientColors: isFocusing
                ? [AppColors.systemYellow, AppColors.systemOrange]
                : [AppColors.systemGreen, AppColors.systemMint],
            trackColor: AppColors.tertiarySystemBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.timerDisplay,
                  style: AppTypography.mono.copyWith(
                    fontSize: 52,
                    fontWeight: FontWeight.w200,
                    color: isFocusing
                        ? AppColors.systemYellow
                        : AppColors.label,
                  ),
                ),
                if (isActive)
                  Text(
                    '${provider.completedSessions} sessions',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          if (provider.isFocusModeActive)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.systemRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.bell_slash_fill,
                    size: 14,
                    color: AppColors.systemRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Notifications Blocked',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.systemRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          _buildControls(isActive, isFocusing),
          const SizedBox(height: AppSpacing.lg),
          if (!isActive) _buildSlider(),
          _buildFocusModeToggle(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildControls(bool isActive, bool isFocusing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isActive) ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: provider.reset,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiarySystemBackground,
              ),
              child: const Icon(
                CupertinoIcons.arrow_counterclockwise,
                size: 20,
                color: AppColors.label,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (provider.state == FocusState.idle) {
              provider.startFocus();
            } else if (provider.isRunning) {
              provider.pause();
            } else {
              provider.resume();
            }
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFocusing ? AppColors.systemYellow : AppColors.systemBlue,
            ),
            child: Icon(
              provider.state == FocusState.idle || !provider.isRunning
                  ? CupertinoIcons.play_fill
                  : CupertinoIcons.pause_fill,
              size: 28,
              color: isFocusing
                  ? AppColors.systemBackground
                  : CupertinoColors.white,
            ),
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: AppSpacing.lg),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: provider.skip,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiarySystemBackground,
              ),
              child: const Icon(
                CupertinoIcons.forward_end_fill,
                size: 20,
                color: AppColors.label,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            '${provider.focusDurationMinutes} min session',
            style: AppTypography.caption1.copyWith(
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CNSlider(
            value: provider.focusDurationMinutes.toDouble(),
            min: 5,
            max: 90,
            onChanged: (v) {
              provider.focusDurationMinutes = v.round();
              provider.reset();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.shield_fill,
              size: 20,
              color: provider.isFocusModeActive
                  ? AppColors.systemGreen
                  : AppColors.secondaryLabel,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('Block Distractions', style: AppTypography.body),
            ),
            CNSwitch(
              value: provider.isFocusModeActive,
              onChanged: (_) => provider.toggleFocusMode(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  final FocusProvider provider;
  const _StatsView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.hourlyUsage.sublist(
      6,
      min(24, provider.hourlyUsage.length),
    );
    final maxVal = data.reduce(max).clamp(1.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          _StatCard(
            label: 'Focus Today',
            value: _fmt(provider.totalFocusMinutesToday),
            color: AppColors.systemGreen,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Sessions',
                  value: '${provider.completedSessions}',
                  color: AppColors.systemBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Score',
                  value: '${min(100, provider.completedSessions * 25)}%',
                  color: AppColors.systemPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Usage by Hour', style: AppTypography.headline),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 140,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondarySystemBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.asMap().entries.map((e) {
                      final r = e.value / maxVal;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: FractionallySizedBox(
                            heightFactor: r.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    (e.value < 1.0
                                            ? AppColors.systemGreen
                                            : AppColors.systemOrange)
                                        .withValues(alpha: 0.7),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['6AM', '12PM', '6PM', '11PM']
                      .map(
                        (l) => Text(
                          l,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          if (provider.blockedApps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Blocked Apps', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.sm),
            ...provider.blockedApps.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySystemBackground,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusGrouped,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Icon(
                          e.value.icon,
                          size: 20,
                          color: e.value.isBlocked
                              ? AppColors.systemRed
                              : AppColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(e.value.name, style: AppTypography.body),
                      ),
                      CNSwitch(
                        value: e.value.isBlocked,
                        onChanged: (_) => provider.toggleBlockedApp(e.key),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _fmt(int m) {
    final h = m ~/ 60, r = m % 60;
    return h > 0 ? '${h}h ${r}m' : '${r}m';
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.secondarySystemBackground,
      borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption2.copyWith(
            color: AppColors.secondaryLabel,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.title1.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}
