import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/insights_models.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/insights_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../calendar/add_event_sheet.dart';
import '../focus/focus_starter_sheet.dart';
import '../habits/habit_gallery_sheet.dart';
import '../tasks/add_task_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InsightsRepository _insightsRepository = InsightsRepository();
  final UserRepository _userRepository = UserRepository();
  final FeatureRepository _featureRepository = FeatureRepository();

  Future<DashboardSnapshot>? _snapshotFuture;
  String _userLabel = 'You';
  Set<String> _activeApps = {
    'Pareto',
    'Habits',
    'Calendar',
    'Focus',
    'Insights',
  };

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _insightsRepository.getDashboardSnapshot();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _loadBaseData();
      } catch (_) {}
      if (!mounted) return;
      await _hydrateUser();
      if (!mounted) return;
      await _loadActiveApps();
      if (!mounted) return;
      _reloadSnapshot();
    });
  }

  Future<void> _loadBaseData() async {
    final taskProvider = context.read<TaskProvider>();
    final habitProvider = context.read<HabitProvider>();
    await taskProvider.loadTasks();
    await taskProvider.loadEvents();
    await habitProvider.loadData();
  }

  Future<void> _loadActiveApps() async {
    final settings = await _featureRepository.getAppSettings();
    if (!mounted) return;
    final configured = settings?.activeApps;
    if (configured != null && configured.isNotEmpty) {
      setState(() => _activeApps = configured.toSet());
    }
  }

  Future<void> _hydrateUser() async {
    final existing = await _userRepository.getProfile();
    if (existing == null) {
      await _userRepository.upsertProfile();
    }
    final profile = await _userRepository.getProfile();
    if (!mounted) return;
    setState(() {
      final name = profile?.fullName?.trim();
      _userLabel = (name != null && name.isNotEmpty)
          ? name
          : (profile?.email?.split('@').first ?? 'You');
    });
  }

  void _reloadSnapshot() {
    setState(() {
      _snapshotFuture = _insightsRepository.getDashboardSnapshot();
    });
  }

  Future<void> _openModules() async {
    await context.push('/app-modules');
    await _loadActiveApps();
    if (!mounted) return;
    setState(() {});
  }

  void _openFocusStarter() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const FocusStarterSheet(),
    );
  }

  void _openQuickAddTask() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddTaskSheet(),
    );
  }

  void _openQuickAddHabit() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const HabitGallerySheet(),
    );
  }

  void _openQuickAddEvent() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddEventSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusProv = context.watch<FocusProvider>();
    final isFocusing = focusProv.state != FocusState.idle;

    final modules = <_HomeModule>[
      _HomeModule(
        id: 'Pareto',
        label: 'To-Do',
        icon: CupertinoIcons.checkmark_alt_circle_fill,
        route: '/tasks',
        onQuickAdd: _openQuickAddTask,
      ),
      _HomeModule(
        id: 'Habits',
        label: 'Habits',
        icon: CupertinoIcons.flame_fill,
        route: '/habits',
        onQuickAdd: _openQuickAddHabit,
      ),
      _HomeModule(
        id: 'Calendar',
        label: 'Calendar',
        icon: CupertinoIcons.calendar,
        route: '/calendar',
        onQuickAdd: _openQuickAddEvent,
      ),
      _HomeModule(
        id: 'Focus',
        label: 'Focus',
        icon: CupertinoIcons.timer_fill,
        route: '/focus',
      ),
      _HomeModule(
        id: 'Insights',
        label: 'Dashboard',
        icon: CupertinoIcons.graph_square_fill,
        route: '/stats',
      ),
      _HomeModule(
        id: 'Leaderboard',
        label: 'Leaderboard',
        icon: CupertinoIcons.star_fill,
        route: '/leaderboard',
      ),
      _HomeModule(
        id: 'Notes',
        label: 'Notes',
        icon: CupertinoIcons.doc_text_fill,
        route: '/notes',
      ),
      _HomeModule(
        id: 'WinStreak',
        label: 'Win Streak',
        icon: CupertinoIcons.flame,
        route: '/win-streak',
      ),
      _HomeModule(
        id: 'Rewards',
        label: 'Rewards',
        icon: CupertinoIcons.gift_fill,
        route: '/rewards',
      ),
      _HomeModule(
        id: 'ScreenTime',
        label: 'Screen Time',
        icon: CupertinoIcons.device_phone_portrait,
        route: '/screen-time',
      ),
      _HomeModule(
        id: 'EventTypes',
        label: 'Event Types',
        icon: CupertinoIcons.square_grid_2x2_fill,
        route: '/event-types',
      ),
      _HomeModule(
        id: 'BiannualReport',
        label: 'Biannual',
        icon: CupertinoIcons.chart_bar_alt_fill,
        route: '/biannual-report',
      ),
    ];

    final activeModules = modules
        .where((m) => _activeApps.contains(m.id))
        .toList();

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF050507),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          children: [
            _HomeHeader(
              userLabel: _userLabel,
              onOpenProfile: () => context.push('/profile'),
              onOpenModules: _openModules,
            ),
            const SizedBox(height: 18),
            FutureBuilder<DashboardSnapshot>(
              future: _snapshotFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard load failed',
                          style: AppTypography.mono.copyWith(
                            fontSize: 12,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to retry after DB migration.',
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LiquidButton(
                          label: 'RETRY',
                          onPressed: _reloadSnapshot,
                        ),
                      ],
                    ),
                  );
                }
                final data = snapshot.data;
                if (data == null) {
                  return const GlassCard(
                    padding: EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Center(
                      child: CupertinoActivityIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  );
                }
                return _ControlCenterCard(data: data);
              },
            ),
            const SizedBox(height: 14),
            _ModuleGrid(modules: activeModules),
            const SizedBox(height: 14),
            FutureBuilder<DashboardSnapshot>(
              future: _snapshotFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                final data = snapshot.data;
                if (data == null) {
                  return const SizedBox.shrink();
                }
                return _DailyIndexes(data: data);
              },
            ),
            const SizedBox(height: 14),
            if (isFocusing)
              _UnifiedFocusIndicator(
                focusProv: focusProv,
                onOpen: () => context.push('/focus'),
              )
            else
              LiquidButton(
                label: 'START_FOCUS',
                fullWidth: true,
                onPressed: _openFocusStarter,
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeModule {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final VoidCallback? onQuickAdd;

  const _HomeModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.onQuickAdd,
  });
}

class _HomeHeader extends StatelessWidget {
  final String userLabel;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenModules;

  const _HomeHeader({
    required this.userLabel,
    required this.onOpenProfile,
    required this.onOpenModules,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CEO OS',
                style: AppTypography.mono.copyWith(
                  fontSize: 22,
                  color: AppColors.label,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome, $userLabel',
                style: AppTypography.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.tertiaryLabel,
                ),
              ),
            ],
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.only(right: 6),
          onPressed: onOpenModules,
          child: const Icon(
            CupertinoIcons.square_grid_2x2,
            color: AppColors.primaryOrange,
            size: 21,
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onOpenProfile,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                width: 0.6,
              ),
            ),
            child: const Icon(
              CupertinoIcons.person_crop_circle,
              color: AppColors.primaryOrange,
              size: 21,
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlCenterCard extends StatelessWidget {
  final DashboardSnapshot data;

  const _ControlCenterCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/stats'),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.25),
          width: 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Control Center',
                  style: AppTypography.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${data.productivityScore}/100',
                  style: AppTypography.mono.copyWith(
                    fontSize: 15,
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatPill(
                  label: 'TASKS',
                  value: '${data.completedTasks}/${data.totalTasks}',
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'HABITS',
                  value: '${data.habitsCompletedToday}/${data.totalHabits}',
                ),
                const SizedBox(width: 8),
                _StatPill(label: 'RANK', value: 'L${data.rankLevel}'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${data.totalFocusMinutes7d} focus minutes in 7 days • ${data.eventsNext7d} events planned',
              style: AppTypography.mono.copyWith(
                fontSize: 10,
                color: AppColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.mono.copyWith(
                fontSize: 8,
                color: AppColors.tertiaryLabel,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final List<_HomeModule> modules;

  const _ModuleGrid({required this.modules});

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        child: Text(
          'No active modules. Enable modules from the grid button in the header.',
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.tertiaryLabel,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final module = modules[index];
        return GestureDetector(
          onTap: () => context.push(module.route),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF111216),
              border: Border.all(
                color: AppColors.glassBorder.withValues(alpha: 0.22),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(module.icon, color: AppColors.primaryOrange, size: 20),
                    const Spacer(),
                    if (module.onQuickAdd != null)
                      GestureDetector(
                        onTap: module.onQuickAdd,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            size: 12,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  module.label,
                  style: AppTypography.mono.copyWith(
                    fontSize: 13,
                    color: AppColors.label,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyIndexes extends StatelessWidget {
  final DashboardSnapshot data;

  const _DailyIndexes({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Indexes',
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _indexRow(
            'Task index',
            '${(data.taskCompletionRate * 100).round()}%',
          ),
          _indexRow(
            'Habit index',
            '${(data.habitCompletionRate * 100).round()}%',
          ),
          _indexRow('Consistency', '${data.currentHabitStreak} day streak'),
          _indexRow('Planning', '${data.eventsNext7d} events / 7d'),
        ],
      ),
    );
  }

  Widget _indexRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.label,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedFocusIndicator extends StatelessWidget {
  final FocusProvider focusProv;
  final VoidCallback onOpen;

  const _UnifiedFocusIndicator({required this.focusProv, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 18,
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
          width: 0.6,
        ),
        child: Row(
          children: [
            Text(
              focusProv.timerDisplay,
              style: AppTypography.mono.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    focusProv.stateLabel.toUpperCase(),
                    style: AppTypography.mono.copyWith(
                      fontSize: 9,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to manage focus mode',
                    style: AppTypography.mono.copyWith(
                      fontSize: 10,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 22,
              height: 22,
              child: CupertinoActivityIndicator.partiallyRevealed(
                progress: focusProv.progress.clamp(0.05, 1),
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
