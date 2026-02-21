import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
import '../../core/models/habit_models.dart';

/// App router — AdaptiveApp.router with AdaptiveBottomNavigationBar shell.
class AppRouter {
  static GoRouter create(BuildContext context) {
    return GoRouter(
      initialLocation: '/tasks',
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
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
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

        // 2. If logged in and on auth or onboarding pages, go to tasks
        if (auth.isAuthenticated && (loggingIn || onboarding)) {
          return '/tasks';
        }

        return null;
      },
      refreshListenable: context.read<AuthProvider>(),
    );
  }
}

/// App shell with AdaptiveBottomNavigationBar.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  static const _routes = [
    '/tasks',
    '/habits',
    '/calendar',
    '/focus',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _routes.indexOf(location).clamp(0, 4);

    return AdaptiveScaffold(
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        items: const [
          AdaptiveNavigationDestination(
            icon: 'checkmark.circle.fill',
            label: 'Tasks',
          ),
          AdaptiveNavigationDestination(icon: 'flame.fill', label: 'Habits'),
          AdaptiveNavigationDestination(icon: 'calendar', label: 'Calendar'),
          AdaptiveNavigationDestination(icon: 'shield.fill', label: 'Focus'),
          AdaptiveNavigationDestination(
            icon: 'gearshape.fill',
            label: 'Settings',
          ),
        ],
        selectedIndex: currentIndex,
        onTap: (index) => context.go(_routes[index]),
      ),
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
                // Don't show if we are on the Focus screen itself
                if (location == '/focus') return const SizedBox.shrink();
                
                // Show if a session is active
                if (focus.state != FocusState.idle) {
                  return GestureDetector(
                    onTap: () => context.go('/focus'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.timer, color: AppColors.primaryOrange, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      focus.stateLabel.toUpperCase(),
                                      style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.primaryOrange),
                                    ),
                                    Text(
                                      focus.timerDisplay,
                                      style: AppTypography.mono.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
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
