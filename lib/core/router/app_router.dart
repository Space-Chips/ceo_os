import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/countdowns/countdown_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../theme/app_colors.dart';

/// App router — CupertinoApp.router with CNTabBar shell.
class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/tasks',
      debugLogDiagnostics: false,
      routes: [
        // ── Onboarding ──
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
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TasksScreen()),
            ),
            GoRoute(
              path: '/habits',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HabitsScreen()),
            ),
            GoRoute(
              path: '/focus',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FocusScreen()),
            ),
            GoRoute(
              path: '/countdowns',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CountdownScreen()),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

/// App shell with CNTabBar from cupertino_native.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  static const _routes = [
    '/tasks',
    '/habits',
    '/focus',
    '/countdowns',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _routes.indexOf(location).clamp(0, 4);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground,
      child: Column(
        children: [
          Expanded(child: child),
          CNTabBar(
            items: const [
              CNTabBarItem(
                label: 'Tasks',
                icon: CNSymbol('checkmark.circle.fill'),
              ),
              CNTabBarItem(label: 'Habits', icon: CNSymbol('flame.fill')),
              CNTabBarItem(label: 'Focus', icon: CNSymbol('shield.fill')),
              CNTabBarItem(label: 'Countdowns', icon: CNSymbol('timer')),
              CNTabBarItem(label: 'Settings', icon: CNSymbol('gearshape.fill')),
            ],
            currentIndex: currentIndex,
            onTap: (index) => context.go(_routes[index]),
          ),
        ],
      ),
    );
  }
}
