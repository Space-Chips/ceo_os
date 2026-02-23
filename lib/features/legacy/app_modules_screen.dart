import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
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
      case 'EventTypes':
        return 'Event Types';
      case 'BiannualReport':
        return 'Biannual Report';
      default:
        return id;
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
