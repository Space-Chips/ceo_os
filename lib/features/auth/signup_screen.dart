import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/models/onboarding_models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  OnboardingSetupData? _setupData;
  bool _didHydrateSetup = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateSetup) return;
    final state = GoRouterState.of(context);
    final extra = state.extra;
    if (extra is OnboardingSetupData) {
      _setupData = extra;
      context.read<ThemeProvider>().setPendingOnboardingSetup(extra);
    }
    _didHydrateSetup = true;
  }

  Future<void> _showError(dynamic error) async {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: CupertinoAlertDialog(
          title: Text('AUTH ERROR', style: AppTypography.mono.copyWith(fontSize: 16)),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(error.toString(), style: AppTypography.caption1),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('DISMISS', style: TextStyle(color: AppColors.primaryOrange)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signup(
            _nameCtrl.text,
            _emailCtrl.text,
            _passCtrl.text,
          );
      if (!mounted) return;
      if (_setupData != null) {
        context.read<ThemeProvider>().setPendingOnboardingSetup(_setupData!);
      }
      await context.read<ThemeProvider>().persistPendingOnboardingSetup();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: CupertinoColors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Column(
                      children: [
                        NeoMonoText(
                          'REGISTER',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.label,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NEW OPERATOR PROTOCOL',
                          style: AppTypography.mono.copyWith(
                            color: AppColors.primaryOrange,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Auth Form
                    GlassCard(
                      blur: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IDENTIFICATION',
                            style: AppTypography.mono.copyWith(
                              fontSize: 11,
                              color: AppColors.tertiaryLabel,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'FULL_NAME',
                            controller: _nameCtrl,
                            prefix: Icon(CupertinoIcons.person, size: 16, color: AppColors.secondaryLabel),
                          ),
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'EMAIL_ADDRESS',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefix: Icon(CupertinoIcons.mail, size: 16, color: AppColors.secondaryLabel),
                          ),
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'ACCESS_KEY',
                            controller: _passCtrl,
                            obscureText: true,
                            prefix: Icon(CupertinoIcons.lock, size: 16, color: AppColors.secondaryLabel),
                          ),
                          const SizedBox(height: 32),
                          LiquidButton(
                            label: 'CREATE_ACCOUNT',
                            fullWidth: true,
                            isLoading: _loading,
                            onPressed: _signup,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "ALREADY_REGISTERED? ",
                          style: AppTypography.mono.copyWith(
                            fontSize: 12,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'SIGN_IN',
                            style: AppTypography.mono.copyWith(
                              fontSize: 12,
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}