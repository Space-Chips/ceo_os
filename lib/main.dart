import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/sync_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/habit_provider.dart';
import 'core/providers/focus_provider.dart';
import 'core/providers/ceo_mode_provider.dart';
import 'core/providers/launcher_provider.dart';
import 'core/providers/language_provider.dart';
import 'features/setup/setup_flow_controller.dart';
import 'features/screen_time_setup/screen_time_setup_controller.dart';
import 'core/router/app_router.dart';
import 'core/services/home_widget_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_catalog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.systemBackground,
    ),
  );

  if (!SupabaseConfig.hasRequiredConfiguration) {
    runApp(
      StartupConfigurationErrorApp(
        missingKeys: SupabaseConfig.missingRequiredKeys,
      ),
    );
    return;
  }
  // Surface, in debug only, when a build forgot to inject --dart-define values
  // and silently fell back to the embedded production keys.
  assert(() {
    if (!SupabaseConfig.isConfiguredFromEnvironment) {
      debugPrint(
        '[SupabaseConfig] No --dart-define provided; using embedded fallback values. '
        'Production builds must pass SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return true;
  }());
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider()..initialize(),
        ),
        ProxyProvider<ConnectivityProvider, SyncService>(
          lazy: false,
          update: (_, conn, prev) => prev ?? SyncService(connectivity: conn),
          dispose: (_, sync) => sync.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => CeoModeProvider()),
        ChangeNotifierProvider(create: (_) => LauncherProvider()),
        ChangeNotifierProvider(create: (_) => SetupFlowController()),
        ChangeNotifierProvider(create: (_) => ScreenTimeSetupController()),
      ],
      child: const CeoOsApp(),
    ),
  );
}

class CeoOsApp extends StatefulWidget {
  const CeoOsApp({super.key});

  @override
  State<CeoOsApp> createState() => _CeoOsAppState();
}

class _CeoOsAppState extends State<CeoOsApp> {
  late GoRouter _router;
  StreamSubscription<Uri?>? _homeWidgetClicks;
  StreamSubscription<Uri>? _appLinksSub;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(context);
    unawaited(_initHomeWidgetLinks());
    unawaited(_initAppLinks());
  }

  Future<void> _initHomeWidgetLinks() async {
    try {
      await CeoHomeWidgetService.ensureInitialized();
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _handleHomeWidgetUri(initial);
      _homeWidgetClicks = HomeWidget.widgetClicked.listen(_handleHomeWidgetUri);
    } on MissingPluginException {
      // Desktop targets do not provide the HomeWidget plugin.
    }
  }

  // Routes a deep link (or a home widget tap) is allowed to land on.
  // Mirrors AppRouter — explicit allowlist prevents external links from
  // navigating into auth / setup / debug screens that should only be reached
  // by the in-app flow.
  static const Set<String> _allowedExternalNavPaths = {
    '/home',
    '/tasks',
    '/habits',
    '/habits/complete',
    '/calendar',
    '/focus',
    '/ceo-mode',
    '/stats',
    '/dashboard',
    '/profile',
    '/rank',
    '/leaderboard',
    '/notes',
    '/upgrade',
    '/win-streak',
    '/rewards',
    '/screen-time',
    '/screen-time-manager',
    '/screen-time-manager/blocking',
    '/family-time',
    '/event-types',
    '/biannual-report',
    '/app-modules',
    '/widget-configuration',
  };

  bool _isAllowedNavPath(String path) {
    if (path.isEmpty) return false;
    return _allowedExternalNavPaths.contains(path);
  }

  void _handleHomeWidgetUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme.isNotEmpty && uri.scheme.toLowerCase() != 'ceoos') return;
    final path = uri.path;
    if (!_isAllowedNavPath(path)) return;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    _router.go('$path$query');
  }

  Future<void> _initAppLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      _handleDeepLink(initial);
      _appLinksSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    } catch (_) {
      // Best effort only: HomeWidget taps still work through the plugin stream.
    }
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme.toLowerCase() != 'ceoos') return;

    // Supabase auth callbacks (email confirmation, OAuth) arrive as
    // ceoos://auth/callback?code=... — supabase_flutter listens to incoming
    // app_links itself and exchanges the code via getSessionFromUrl, then
    // emits onAuthStateChange which the GoRouter redirect picks up to send
    // the user to /control-center-setup. We intentionally do NOT call
    // getSessionFromUrl here ourselves: doing it twice burns the single-use
    // code and surfaces "otp_expired" on the second call.
    final isAuthCallback =
        (uri.host == 'auth' && uri.pathSegments.contains('callback')) ||
        uri.path == '/auth/callback' ||
        uri.path.startsWith('/auth/callback');
    if (isAuthCallback) return;

    final path = uri.path;
    if (!_isAllowedNavPath(path)) return;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    _router.go('$path$query');
  }

  @override
  void dispose() {
    _homeWidgetClicks?.cancel();
    _appLinksSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, theme, language, _) {
        final overlayStyle = SystemUiOverlayStyle(
          statusBarBrightness: theme.currentPreset.isDark
              ? Brightness.dark
              : Brightness.light,
          statusBarIconBrightness: theme.currentPreset.isDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: AppColors.systemBackground,
          systemNavigationBarIconBrightness: theme.currentPreset.isDark
              ? Brightness.light
              : Brightness.dark,
        );
        SystemChrome.setSystemUIOverlayStyle(overlayStyle);
        final lightTone = AppThemeTone.light;
        final darkTone = AppThemeTone.dark;
        return AdaptiveApp.router(
          title: language.t('app_name'),
          themeMode: theme.themeMode,
          cupertinoLightTheme: AppTheme.cupertinoForTone(lightTone),
          cupertinoDarkTheme: AppTheme.cupertinoForTone(darkTone),
          materialLightTheme: AppTheme.materialForTone(lightTone),
          materialDarkTheme: AppTheme.materialForTone(darkTone),
          routerConfig: _router,
        );
      },
    );
  }
}

class StartupConfigurationErrorApp extends StatelessWidget {
  final List<String> missingKeys;

  const StartupConfigurationErrorApp({super.key, required this.missingKeys});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF09111A);
    const panel = Color(0xFF101B28);
    const border = Color(0xFF223246);
    const accent = Color(0xFF7DD3FC);
    const textPrimary = Color(0xFFF4F8FC);
    const textSecondary = Color(0xFF9CB3C9);
    const codeBackground = Color(0xFF0B1420);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Startup blocked',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'WakeApp needs Supabase credentials before it can start.',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Missing values: ${missingKeys.join(', ')}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: codeBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: border.withValues(alpha: 0.9),
                          ),
                        ),
                        child: const SelectableText(
                          'flutter run \\\n'
                          '  --dart-define=SUPABASE_URL=https://your-project.supabase.co \\\n'
                          '  --dart-define=SUPABASE_ANON_KEY=your-anon-key',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            height: 1.45,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'If you launch from VS Code, the workspace now prompts for these values automatically on the next run.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          height: 1.45,
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
    );
  }
}
