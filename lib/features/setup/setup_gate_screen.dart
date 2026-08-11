import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/ambient_backdrop.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'setup_flow_controller.dart';

class SetupGateScreen extends StatefulWidget {
  const SetupGateScreen({super.key});

  @override
  State<SetupGateScreen> createState() => _SetupGateScreenState();
}

class _SetupGateScreenState extends State<SetupGateScreen> {
  bool _didRoute = false;

  @override
  void initState() {
    super.initState();
    _kickoff();
  }

  Future<void> _kickoff() async {
    final controller = context.read<SetupFlowController>();
    await controller.initialize();
    if (!mounted || _didRoute) return;
    _didRoute = true;
    if (controller.isSetupRequired) {
      context.go('/setup');
    } else {
      await controller.markSetupComplete();
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.glassSurfaceStrong,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Preparing Screen Time',
                    style: AppTypography.title2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Checking your protection setup.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
