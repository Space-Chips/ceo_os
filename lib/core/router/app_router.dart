import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/focus_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/habits/habit_completion_page.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/stats_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/legacy/notes_screen.dart';
import '../../features/legacy/win_streak_screen.dart';
import '../../features/legacy/rewards_screen.dart';
import '../../features/legacy/screen_time_screen.dart';
import '../../features/legacy/event_types_screen.dart';
import '../../features/legacy/biannual_report_screen.dart';
import '../../features/legacy/app_modules_screen.dart';
import '../../core/models/habit_models.dart';

/// App router — AdaptiveApp.router with AdaptiveBottomNavigationBar shell.
class AppRouter {
  static GoRouter create(BuildContext context) {
    return GoRouter(
      initialLocation: '/home',
      debugLogDiagnostics: false,
      routes: [
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
              path: '/stats',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: StatsScreen()),
            ),
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: StatsScreen()),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
            GoRoute(
              path: '/rank',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
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
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ScreenTimeScreen()),
            ),
            GoRoute(
              path: '/screen-time-manager',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ScreenTimeScreen()),
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

        return null;
      },
      refreshListenable: context.read<AuthProvider>(),
    );
  }
}

/// App shell containing the global focus bar.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          child,
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
                            color: AppColors.backgroundLight.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryOrange.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
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
                                      style: AppTypography.mono.copyWith(
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
        ],
      ),
    );
  }
}
