import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppModulesScreen extends StatefulWidget {
  const AppModulesScreen({super.key});

  @override
  State<AppModulesScreen> createState() => _AppModulesScreenState();
}

class _AppModulesScreenState extends State<AppModulesScreen> {
  final FeatureRepository _repo = FeatureRepository();
  bool _loading = true;
  bool _saving = false;
  String? _settingsId;
  Set<String> _active = {};

  static const all = [
    'Pareto',
    'Habits',
    'Calendar',
    'Focus',
    'Insights',
    'Leaderboard',
    'Notes',
    'WinStreak',
    'Rewards',
    'ScreenTime',
    'ScreenTimeManager',
    'Rank',
    'EventTypes',
    'BiannualReport',
    'Settings',
  ];

  String _label(String id) {
    switch (id) {
      case 'Pareto':
        return 'To-Do';
      case 'Insights':
        return 'Dashboard';
      case 'WinStreak':
        return 'Win Streak';
      case 'ScreenTime':
        return 'Screen Time';
      case 'ScreenTimeManager':
        return 'Screen Time Manager';
      case 'EventTypes':
        return 'Event Types';
      case 'BiannualReport':
        return 'Biannual Report';
      default:
        return id;
    }
  }

  IconData _icon(String id) {
    switch (id) {
      case 'Pareto':
        return CupertinoIcons.checkmark_alt_circle_fill;
      case 'Habits':
        return CupertinoIcons.flame_fill;
      case 'Calendar':
        return CupertinoIcons.calendar;
      case 'Focus':
        return CupertinoIcons.timer_fill;
      case 'Insights':
        return CupertinoIcons.graph_square_fill;
      case 'Leaderboard':
        return CupertinoIcons.star_fill;
      case 'Notes':
        return CupertinoIcons.doc_text_fill;
      case 'WinStreak':
        return CupertinoIcons.flame;
      case 'Rewards':
        return CupertinoIcons.gift_fill;
      case 'ScreenTime':
        return CupertinoIcons.device_phone_portrait;
      case 'ScreenTimeManager':
        return CupertinoIcons.shield_lefthalf_fill;
      case 'Rank':
        return CupertinoIcons.flag_fill;
      case 'EventTypes':
        return CupertinoIcons.square_grid_2x2_fill;
      case 'BiannualReport':
        return CupertinoIcons.chart_bar_alt_fill;
      case 'Settings':
        return CupertinoIcons.settings;
      default:
        return CupertinoIcons.square_grid_2x2;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repo.getAppSettings();
    if (!mounted) return;
    setState(() {
      _settingsId = settings?.id;
      _active =
          (settings?.activeApps ??
                  ['Pareto', 'Habits', 'Calendar', 'Focus', 'Insights'])
              .toSet();
      _loading = false;
    });
  }

  Future<void> _toggle(String id, bool value) async {
    final previous = Set<String>.from(_active);
    setState(() {
      if (value) {
        _active.add(id);
      } else {
        _active.remove(id);
      }
      _saving = true;
    });
    try {
      final id = await _repo.saveActiveAppsFast(
        _active.toList(),
        settingsId: _settingsId,
      );
      _settingsId = id;
    } catch (_) {
      if (!mounted) return;
      setState(() => _active = previous);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: const Size(44, 44),
          onPressed: () => context.go('/home'),
          child: Icon(CupertinoIcons.back, color: AppColors.primaryOrange),
        ),
        middle: const NeoMonoText(
          'APP_MODULES',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: _saving
            ? CupertinoActivityIndicator(color: AppColors.primaryOrange)
            : null,
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _glowSurface(
                    glowColor: AppColors.primaryOrange.withValues(alpha: 0.14),
                    borderRadius: 16,
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.22),
                        width: 0.7,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.square_grid_2x2_fill,
                            size: 16,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select modules shown on Home.',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: AppColors.secondaryLabel,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.12,
                              ),
                            ),
                            child: Text(
                              '${_active.length}',
                              style: AppTypography.mono.copyWith(
                                fontSize: 9,
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...all.map((id) {
                    final enabled = _active.contains(id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        borderRadius: 14,
                        border: Border.all(
                          color: enabled
                              ? AppColors.primaryOrange.withValues(alpha: 0.22)
                              : AppColors.glassBorder,
                          width: 0.5,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _icon(id),
                              size: 16,
                              color: enabled
                                  ? AppColors.primaryOrange
                                  : AppColors.tertiaryLabel,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _label(id).toUpperCase(),
                                style: AppTypography.mono.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            CupertinoSwitch(
                              value: enabled,
                              activeTrackColor: AppColors.primaryOrange,
                              onChanged: (v) => _toggle(id, v),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _glowSurface({
    required Widget child,
    required Color glowColor,
    double borderRadius = 16,
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
                  BoxShadow(color: glowColor, blurRadius: 28, spreadRadius: 1),
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
