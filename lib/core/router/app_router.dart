import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../platform/adaptive_widgets.dart';

/// App router — auth bypassed for now, direct to tasks.
class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/tasks',
      debugLogDiagnostics: false,
      routes: [
        // ── Onboarding (accessible but not enforced) ──
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // ── Main App Shell ──
        ShellRoute(
          builder: (context, state, child) => _AppShell(child: child),
          routes: [
            GoRoute(
              path: '/tasks',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TasksScreen(),
              ),
            ),
            GoRoute(
              path: '/habits',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HabitsScreen(),
              ),
            ),
            GoRoute(
              path: '/focus',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: FocusScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// App shell with adaptive bottom tab bar.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  static const _routes = ['/tasks', '/habits', '/focus', '/settings'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _routes.indexOf(location).clamp(0, 3);

    return Scaffold(
      body: child,
      bottomNavigationBar: AdaptiveTabBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_routes[index]),
      ),
    );
  }
}
