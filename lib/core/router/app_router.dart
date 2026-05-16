import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ceo_mode_provider.dart';
import '../providers/focus_provider.dart';
import '../config/apple_review_compliance.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/habits/habit_completion_page.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/ceo_mode/ceo_mode_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/control_center_setup/control_center_setup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/stats_screen.dart';
import '../../features/debug/database_debug_screen.dart';
import '../../features/debug/blocking_debug_screen.dart';
import '../../features/debug/theme_preview_screen.dart';
import '../../features/debug/widget_gallery_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/rank/rank_screen.dart';
import '../../features/legacy/notes_screen.dart';
import '../../features/legacy/win_streak_screen.dart';
import '../../features/legacy/rewards_screen.dart';
import '../../features/legacy/screen_time_screen.dart';
import '../../features/widget_configuration/widget_configuration_screen.dart';
import '../../features/premium/upgrade_screen.dart';
import '../../features/screen_time_manager/screen_time_manager_screen.dart';
import '../../features/screen_time_manager/family_time_screen.dart';
import '../../features/screen_time_setup/screen_time_setup_screen.dart';
import '../../features/legacy/event_types_screen.dart';
import '../../features/legacy/biannual_report_screen.dart';
import '../../features/legacy/app_modules_screen.dart';
import '../../features/setup/setup_gate_screen.dart';
import '../../features/setup/setup_flow_screen.dart';
import '../../core/models/habit_models.dart';
import '../models/task_models.dart';
import '../providers/task_provider.dart';

/// App router — AdaptiveApp.router with AdaptiveBottomNavigationBar shell.
class AppRouter {
  static GoRouter create(BuildContext context) {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    const envInitialLocation = String.fromEnvironment('INITIAL_LOCATION');
    final initialLocation = envInitialLocation.trim().isEmpty
        ? '/home'
        : envInitialLocation.trim();
    return GoRouter(
      initialLocation: initialLocation,
      debugLogDiagnostics: false,
      routes: [
        GoRoute(
          path: '/setup-gate',
          builder: (context, state) => const SetupGateScreen(),
        ),
        GoRoute(
          path: '/setup',
          builder: (context, state) => const SetupFlowScreen(),
        ),
        GoRoute(
          path: '/screen-time-setup',
          builder: (context, state) => const ScreenTimeSetupScreen(),
        ),
        // ── Auth ──
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),

        // ── Onboarding ──
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/control-center-setup',
          builder: (context, state) {
            final edit = state.uri.queryParameters['edit'] == 'true';
            return ControlCenterSetupScreen(isEditing: edit);
          },
        ),
        GoRoute(
          path: '/control-center-setup',
          builder: (context, state) {
            final edit = state.uri.queryParameters['edit'] == 'true';
            return ControlCenterSetupScreen(isEditing: edit);
          },
        ),
        GoRoute(
          path: '/control-center-setup',
          builder: (context, state) {
            final edit = state.uri.queryParameters['edit'] == 'true';
            return ControlCenterSetupScreen(isEditing: edit);
          },
        ),
        GoRoute(
          path: '/control-center-setup',
          builder: (context, state) {
            final edit = state.uri.queryParameters['edit'] == 'true';
            return ControlCenterSetupScreen(isEditing: edit);
          },
        ),

        // ── Habit Completion (Full Screen) ──
        GoRoute(
          path: '/habits/complete',
          builder: (context, state) {
            final habit = state.extra as Habit;
            return HabitCompletionPage(habit: habit);
          },
        ),

        // ── Main App Shell ──
        ShellRoute(
          builder: (context, state, child) => _AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
            GoRoute(
              path: '/tasks',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TasksScreen()),
            ),
            GoRoute(
              path: '/habits',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HabitsScreen()),
            ),
            GoRoute(
              path: '/calendar',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarScreen()),
            ),
            GoRoute(
              path: '/focus',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FocusScreen()),
            ),
            GoRoute(
              path: '/ceo-mode',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CeoModeScreen()),
            ),
            if (AppleReviewCompliance.allowAdvancedStats)
              GoRoute(
                path: '/stats',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StatsScreen()),
              ),
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
            if (kDebugMode)
              GoRoute(
                path: '/debug/database',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DatabaseDebugScreen()),
              ),
            if (kDebugMode)
              GoRoute(
                path: '/debug/blocking',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BlockingDebugScreen()),
              ),
            if (kDebugMode)
              GoRoute(
                path: '/debug/themes',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ThemePreviewScreen()),
              ),
            if (kDebugMode)
              GoRoute(
                path: '/debug/widgets',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: WidgetGalleryScreen()),
              ),
            if (kDebugMode)
              GoRoute(
                path: '/debug/widgets',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: WidgetGalleryScreen()),
              ),
            if (kDebugMode)
              GoRoute(
                path: '/debug/widgets',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: WidgetGalleryScreen()),
              ),
            if (kDebugMode)
              GoRoute(
                path: '/debug/widgets',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: WidgetGalleryScreen()),
              ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
            GoRoute(
              path: '/rank',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: RankScreen()),
            ),
            if (AppleReviewCompliance.allowSocialScreenTimeSurfaces)
              GoRoute(
                path: '/leaderboard',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: LeaderboardScreen()),
              ),
            GoRoute(
              path: '/notes',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: NotesScreen()),
            ),
            GoRoute(
              path: '/widget-configuration',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: WidgetConfigurationScreen()),
            ),
            GoRoute(
              path: '/upgrade',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: UpgradeScreen()),
            ),
            GoRoute(
              path: '/win-streak',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: WinStreakScreen()),
            ),
            GoRoute(
              path: '/rewards',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: RewardsScreen()),
            ),
            GoRoute(
              path: '/screen-time',
              pageBuilder: (context, state) => NoTransitionPage(
                child: ScreenTimeScreen(
                  initialSection: state.uri.queryParameters['section'],
                ),
              ),
            ),
            GoRoute(
              path: '/screen-time-manager',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ScreenTimeManagerScreen()),
            ),
            if (AppleReviewCompliance.allowSocialScreenTimeSurfaces)
              GoRoute(
                path: '/family-time',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FamilyTimeScreen()),
              ),
            GoRoute(
              path: '/event-types',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: EventTypesScreen()),
            ),
            GoRoute(
              path: '/biannual-report',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: BiannualReportScreen()),
            ),
            GoRoute(
              path: '/app-modules',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AppModulesScreen()),
            ),
          ],
        ),
      ],
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final loggingIn =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';
        final onboarding = state.matchedLocation == '/onboarding';
        final setupFlow = state.matchedLocation == '/setup';
        final setupGate = state.matchedLocation == '/setup-gate';
        final setupOrigin = state.uri.queryParameters['origin'];

        // 1. If not logged in and not on auth/onboarding pages, go to onboarding
        if (!auth.isAuthenticated) {
          if (!loggingIn && !onboarding) {
            return '/onboarding';
          }
          return null;
        }

        // 2. If logged in and on auth or onboarding pages, go to home
        if (auth.isAuthenticated && (loggingIn || onboarding)) {
          return '/home';
        }

        if (auth.isAuthenticated && (setupFlow || setupGate)) {
          if (!isAndroid) {
            return '/home';
          }
          if (setupFlow && setupOrigin != 'screen-time') {
            return '/home';
          }
          return null;
        }

        return null;
      },
      refreshListenable: context.read<AuthProvider>(),
    );
  }
}

class _GlobalAtmosphereLayer extends StatelessWidget {
  const _GlobalAtmosphereLayer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -90,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSecondary.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _GlobalNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..style = PaintingStyle.fill;
    final dark = Paint()..style = PaintingStyle.fill;
    var seed = 0x1f123bb5 ^ size.width.floor() ^ (size.height.floor() << 2);

    double next() {
      seed = (1103515245 * seed + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    for (var i = 0; i < 220; i++) {
      final x = next() * size.width;
      final y = next() * size.height;
      final d = 0.8 + (next() * 1.2);
      light.color = Colors.white.withValues(alpha: 0.02 + (next() * 0.07));
      canvas.drawRect(Rect.fromLTWH(x, y, d, d), light);
    }

    for (var i = 0; i < 120; i++) {
      final x = next() * size.width;
      final y = next() * size.height;
      final d = 0.7 + next();
      dark.color = Colors.black.withValues(alpha: 0.01 + (next() * 0.05));
      canvas.drawRect(Rect.fromLTWH(x, y, d, d), dark);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobalNoisePainter oldDelegate) => false;
}

/// App shell containing the global focus bar.
class _AppShell extends StatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  Timer? _focusPlanTimer;
  DateTime _lastEventsRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  bool _focusPlanTickRunning = false;
  final Set<String> _warnedPlanKeys = <String>{};
  final Set<String> _startedPlanKeys = <String>{};
  String _lastNativeScheduleSignature = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runFocusPlanTick();
      _focusPlanTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _runFocusPlanTick();
      });
    });
  }

  @override
  void dispose() {
    _focusPlanTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncNativePlannedSessionsIfNeeded(
    FocusProvider focusProvider,
    List<CalendarEvent> events,
  ) async {
    final focusEvents = events
        .where(
          (event) => (event.sourceType ?? '').toLowerCase() == 'focus_plan',
        )
        .where((event) => event.eventDate != null && event.eventTime != null)
        .toList();

    final signature = focusEvents
        .map(
          (event) =>
              '${event.id}|${event.eventDate}|${event.eventTime}|${event.durationMinutes}|${event.recurrenceRule}',
        )
        .join('||');

    if (signature == _lastNativeScheduleSignature) return;
    _lastNativeScheduleSignature = signature;
    await focusProvider.syncPlannedFocusSessions(
      focusEvents
          .map(
            (event) => <String, dynamic>{
              'id': event.id,
              'eventDate': event.eventDate,
              'eventTime': event.eventTime,
              'durationMinutes': event.durationMinutes,
              'recurrenceRule': event.recurrenceRule,
            },
          )
          .toList(growable: false),
    );
  }

  Future<void> _runFocusPlanTick() async {
    if (!mounted || _focusPlanTickRunning) return;
    _focusPlanTickRunning = true;
    try {
      final now = DateTime.now();
      final taskProvider = context.read<TaskProvider>();
      final focusProvider = context.read<FocusProvider>();

      if (now.difference(_lastEventsRefresh) > const Duration(minutes: 5)) {
        await taskProvider.loadEvents();
        _lastEventsRefresh = now;
      }

      await _syncNativePlannedSessionsIfNeeded(
        focusProvider,
        taskProvider.events,
      );

      for (final event in taskProvider.events) {
        final source = (event.sourceType ?? '').trim().toLowerCase();
        if (source != 'focus_plan') continue;
        final eventDate = event.eventDate;
        final eventTime = event.eventTime;
        if (eventDate == null || eventTime == null) continue;

        final scheduled = _parseDateTime(eventDate, eventTime);
        if (scheduled == null) continue;
        final key = '${event.id}|${scheduled.toIso8601String()}';

        if (now.isAfter(scheduled.subtract(const Duration(minutes: 5))) &&
            now.isBefore(scheduled) &&
            !_warnedPlanKeys.contains(key)) {
          _warnedPlanKeys.add(key);
          _showPlanReminderSnackBar();
        }

        if (!now.isBefore(scheduled) &&
            now.isBefore(scheduled.add(const Duration(minutes: 2))) &&
            !_startedPlanKeys.contains(key) &&
            focusProvider.state == FocusState.idle) {
          final duration = (event.durationMinutes ?? 45).clamp(5, 180);
          focusProvider.focusDurationMinutes = duration;
          final started = await focusProvider.startFocus();
          if (started) {
            _startedPlanKeys.add(key);
            _showFocusStartedSnackBar(duration);
          }
        }
      }

      _trimPlanMemory(now);
    } catch (_) {
      // Keep shell resilient; scheduler must never crash UI.
    } finally {
      _focusPlanTickRunning = false;
    }
  }

  DateTime? _parseDateTime(String rawDate, String rawTime) {
    final date = DateTime.tryParse(rawDate);
    if (date == null) return null;
    final parts = rawTime.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  void _trimPlanMemory(DateTime now) {
    final stalePrefix = now.subtract(const Duration(days: 3)).toIso8601String();
    _warnedPlanKeys.removeWhere((key) {
      final split = key.split('|');
      if (split.length < 2) return true;
      return split.last.compareTo(stalePrefix) < 0;
    });
    _startedPlanKeys.removeWhere((key) {
      final split = key.split('|');
      if (split.length < 2) return true;
      return split.last.compareTo(stalePrefix) < 0;
    });
  }

  void _showPlanReminderSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Text(
          'Focus mode will start automatically in 5 minutes.',
        ),
      ),
    );
  }

  void _showFocusStartedSnackBar(int duration) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Text('Planned focus started ($duration min).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          widget.child,
          const Positioned.fill(
            child: IgnorePointer(child: _GlobalAtmosphereLayer()),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.075,
                child: CustomPaint(painter: _GlobalNoisePainter()),
              ),
            ),
          ),
          // Global Focus Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Consumer<FocusProvider>(
              builder: (context, focus, _) {
                // Keep a single indicator on Home and Focus screens.
                if (location == '/focus' || location == '/home') {
                  return const SizedBox.shrink();
                }

                // Show if a session is active
                if (focus.state != FocusState.idle) {
                  return GestureDetector(
                    onTap: () => context.go('/focus'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.3,
                              ),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.timer,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      focus.stateLabel.toUpperCase(),
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 10,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                    Text(
                                      focus.timerDisplay,
                                      style: AppTypography.timer.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CircularProgressIndicator(
                                value: focus.progress,
                                strokeWidth: 3,
                                color: AppColors.primaryOrange,
                                backgroundColor: AppColors.glassBorder,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Positioned.fill(
            child: Consumer<CeoModeProvider>(
              builder: (context, ceo, _) {
                final lockActive =
                    ceo.isSessionActive && location != '/ceo-mode';
                if (!lockActive) return const SizedBox.shrink();

                return Container(
                  color: AppColors.background.withValues(alpha: 0.94),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: () => context.go('/ceo-mode'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight.withValues(
                                    alpha: 0.82,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 0.7,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.lock_shield_fill,
                                      size: 30,
                                      color: AppColors.primaryOrange,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'BLACKOUT ACTIVE',
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryOrange,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ceo.homeCardLabel,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 14,
                                        color: AppColors.secondaryLabel,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tap to return to session',
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 11,
                                        color: AppColors.tertiaryLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
