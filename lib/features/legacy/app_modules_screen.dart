import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/glass_card.dart';
import '../../components/neo_mono_text.dart';

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
    final language = context.watch<LanguageProvider>();
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
        return language.t('event_types');
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: const NeoMonoText(
          'APP_MODULES',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: _saving
            ? const CupertinoActivityIndicator(color: AppColors.primaryOrange)
            : null,
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? const Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: all.length,
                itemBuilder: (context, index) {
                  final id = all[index];
                  final enabled = _active.contains(id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      borderRadius: 14,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _label(id).toUpperCase(),
                              style: AppTypography.mono.copyWith(fontSize: 11),
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
                },
              ),
            ),
    );
  }
}
