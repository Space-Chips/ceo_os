import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/habit_provider.dart';
import 'core/providers/focus_provider.dart';
import 'core/providers/countdown_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.systemBackground,
    ),
  );
  runApp(const CeoOsApp());
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
    _router = AppRouter.create();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => CountdownProvider()),
      ],
      child: CupertinoApp.router(
        title: 'CEOOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertino,
        routerConfig: _router,
        builder: (context, child) {
          return Theme(
            data: AppTheme.materialFallback,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
