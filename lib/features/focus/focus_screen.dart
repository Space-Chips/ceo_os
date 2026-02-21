import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, CircularProgressIndicator;
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../components/components.dart';
import '../../core/models/block_list_model.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'block_list_sheet.dart';

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
      context.read<FocusProvider>().loadInitialData();
    });
  }

  void _showBlockListSheet([BlockList? list]) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => BlockListSheet(blockList: list),
    );
  }

  void _showBlockListManager() {
    final prov = context.read<FocusProvider>();
    BlockList? activeList;
    if (prov.blockLists.isNotEmpty) {
      activeList = prov.blockLists.firstWhere(
        (l) => l.id == prov.activeBlockListId,
        orElse: () => prov.blockLists.first,
      );
    }
    _showBlockListSheet(activeList);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Consumer<FocusProvider>(
              builder: (context, prov, _) {
                final isIdle = prov.state == FocusState.idle;

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const NeoMonoText('SYSTEM_FOCUS', fontSize: 24, fontWeight: FontWeight.bold),
                          if (!isIdle)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: prov.reset,
                              child: const Icon(CupertinoIcons.stop_fill, color: AppColors.primaryOrange, size: 20),
                            )
                          else
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: prov.requestPermissions,
                              child: const Icon(CupertinoIcons.shield_fill, color: AppColors.secondaryLabel, size: 20),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: Stack(
                        children: [
                          // Base Content
                          Opacity(
                            opacity: isIdle ? 1.0 : 0.2,
                            child: AbsorbPointer(
                              absorbing: !isIdle,
                              child: _StatsView(
                                provider: prov, 
                                onManageBlockList: _showBlockListManager,
                                onEditBlockList: _showBlockListSheet,
                              ),
                            ),
                          ),

                          // Quick Start Bar
                          if (isIdle)
                            Positioned(
                              top: 0,
                              left: 24,
                              right: 24,
                              child: _QuickStartBar(provider: prov),
                            ),

                          // Active Overlay
                          if (!isIdle)
                            Positioned.fill(
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    color: AppColors.background.withOpacity(0.4),
                                    child: _buildActiveOverlay(prov),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOverlay(FocusProvider prov) {
    switch (prov.state) {
      case FocusState.requestingBreak:
        return _BreakWaitView(provider: prov);
      case FocusState.breakOptionsMenu:
        return _BreakOptionsView(provider: prov);
      default:
        return _TimerView(provider: prov);
    }
  }
}

class _QuickStartBar extends StatelessWidget {
  final FocusProvider provider;
  const _QuickStartBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 24,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SESSION_LENGTH', style: AppTypography.mono.copyWith(fontSize: 8, color: AppColors.tertiaryLabel)),
                const SizedBox(height: 4),
                NeoMonoText('${provider.focusDurationMinutes}M', fontSize: 16, color: AppColors.primaryOrange),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: AdaptiveSlider(
              value: provider.focusDurationMinutes.toDouble(),
              min: 5,
              max: 90,
              onChanged: (v) {
                provider.focusDurationMinutes = v.round();
                provider.reset();
              },
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              final success = await provider.startFocus();
              if (!success) {
                // Permission warning
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: provider.isAuthorized ? AppColors.primaryOrange : AppColors.tertiaryLabel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerView extends StatelessWidget {
  final FocusProvider provider;
  const _TimerView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isFocusing = provider.state == FocusState.focusing;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
            ),
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: provider.progress,
                strokeWidth: 6,
                color: AppColors.primaryOrange,
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeoMonoText(provider.timerDisplay, fontSize: 56, fontWeight: FontWeight.bold),
                Text(
                  provider.stateLabel.toUpperCase(),
                  style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.primaryOrange, letterSpacing: 2),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 64),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: LiquidButton(
            label: isFocusing ? 'REQUEST_BREAK' : 'SKIP_BREAK',
            onPressed: isFocusing ? provider.requestBreak : provider.skip,
          ),
        ),
      ],
    );
  }
}

class _BreakWaitView extends StatelessWidget {
  final FocusProvider provider;
  const _BreakWaitView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const NeoMonoText('ANALYZING_BREAK_REQUEST', fontSize: 16, fontWeight: FontWeight.bold),
        const SizedBox(height: 12),
        Text(
          'PROTOCOL_DELAY_ACTIVE',
          style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.error, letterSpacing: 2),
        ),
        const SizedBox(height: 48),
        NeoMonoText(provider.waitTimerDisplay, fontSize: 84, fontWeight: FontWeight.w200, color: AppColors.primaryOrange),
        const SizedBox(height: 64),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: CupertinoButton(
            color: AppColors.backgroundLight,
            onPressed: provider.cancelBreakRequest,
            child: const NeoMonoText('NEVERMIND', fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _BreakOptionsView extends StatelessWidget {
  final FocusProvider provider;
  const _BreakOptionsView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NeoMonoText('OVERRIDE_OPTIONS', fontSize: 18, fontWeight: FontWeight.bold),
              const SizedBox(height: 32),
              
              _optionButton('TAKE_5M_BREAK', () => provider.takeCustomBreak(5)),
              const SizedBox(height: 12),
              _optionButton('TAKE_15M_BREAK', () => provider.takeCustomBreak(15)),
              const SizedBox(height: 12),
              _optionButton('TERMINATE_BLOCKING', provider.cancelBlocking, isDanger: true),
              const SizedBox(height: 24),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: provider.cancelBreakRequest,
                child: const NeoMonoText('RESUME_PROTOCOL', fontSize: 12, color: AppColors.primaryOrange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionButton(String label, VoidCallback onTap, {bool isDanger = false}) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: isDanger ? AppColors.error.withOpacity(0.1) : AppColors.primaryOrange.withOpacity(0.1),
        onPressed: onTap,
        child: NeoMonoText(label, fontSize: 12, color: isDanger ? AppColors.error : AppColors.primaryOrange, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  final FocusProvider provider;
  final VoidCallback onManageBlockList;
  final Function(BlockList) onEditBlockList;
  
  const _StatsView({
    required this.provider, 
    required this.onManageBlockList,
    required this.onEditBlockList,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100), // Space for QuickStartBar
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SCREEN_USAGE', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel)),
                      const SizedBox(height: 8),
                      NeoMonoText(_fmt(provider.screenTimeToday.toInt()), fontSize: 20, color: AppColors.primaryOrange),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SESSIONS', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel)),
                      const SizedBox(height: 8),
                      NeoMonoText('${provider.completedSessions}', fontSize: 20, color: AppColors.primaryOrange),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('USAGE_STATISTICS', style: AppTypography.mono.copyWith(fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          GlassCard(
            height: 180,
            child: _buildChart(),
          ),
          const SizedBox(height: 32),
          
          // Block List Manager
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DISTRACTION_CONTROL', style: AppTypography.mono.copyWith(fontSize: 12, letterSpacing: 1.5)),
              GestureDetector(
                onTap: onManageBlockList,
                child: Text('CONFIGURE', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (provider.blockLists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('NO_CONFIGURED_LISTS', style: AppTypography.mono.copyWith(color: AppColors.secondaryLabel)),
              ),
            )
          else
            ...provider.blockLists.map(
              (list) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onEditBlockList(list),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: list.id == provider.activeBlockListId 
                                ? AppColors.primaryOrange.withOpacity(0.2) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            list.adultBlocking ? CupertinoIcons.exclamationmark_shield_fill : CupertinoIcons.shield_fill,
                            size: 16,
                            color: list.id == provider.activeBlockListId ? AppColors.primaryOrange : AppColors.tertiaryLabel,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(list.name.toUpperCase(), style: AppTypography.mono.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                Platform.isIOS 
                                    ? 'PROTOCOL_CONFIGURED' 
                                    : '${list.blockedPackageNames.length} APPS, ${list.blockedCategories.length} CATS', 
                                style: AppTypography.mono.copyWith(fontSize: 9, color: AppColors.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                        if (list.id == provider.activeBlockListId)
                          const Icon(CupertinoIcons.checkmark_alt, color: AppColors.primaryOrange, size: 16)
                        else
                          GestureDetector(
                            onTap: () => provider.setActiveBlockList(list.id),
                            child: Text('ACTIVATE', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final data = provider.hourlyUsage.sublist(6, min(24, provider.hourlyUsage.length));
    final maxVal = data.reduce(max).clamp(1.0, double.infinity);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.asMap().entries.map((e) {
              final r = e.value / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FractionallySizedBox(
                    heightFactor: r.clamp(0.1, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryOrange,
                            AppColors.primaryOrange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['06:00', '12:00', '18:00', '23:59']
              .map((l) => Text(l, style: AppTypography.mono.copyWith(fontSize: 8, color: AppColors.tertiaryLabel)))
              .toList(),
        ),
      ],
    );
  }

  String _fmt(int m) {
    final h = m ~/ 60, r = m % 60;
    return h > 0 ? '${h}H ${r}M' : '${r}M';
  }
}
