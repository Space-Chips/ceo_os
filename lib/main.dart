import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/habit_provider.dart';
import 'core/providers/focus_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.systemBackground,
    ),
  );

  // Initialize Supabase
  // Note: This relies on placeholders in SupabaseConfig being filled
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
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
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(context);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveApp.router(
      title: 'CEOOS',
      themeMode: ThemeMode.dark,
      cupertinoDarkTheme: AppTheme.cupertino,
      materialDarkTheme: AppTheme.materialFallback,
      routerConfig: _router,
    );
  }
}
