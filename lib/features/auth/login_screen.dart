import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_button.dart';
import '../../core/widgets/ceo_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    await context.read<AuthProvider>().login(_emailCtrl.text, _passCtrl.text);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              // Logo area
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.accentGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.systemBlue.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.bolt,
                  color: CupertinoColors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('CEO OS', style: AppTypography.largeTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your AI productivity operating system',
                style: AppTypography.body.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
              const Spacer(),
              // Form
              CeoTextField(
                label: 'Email',
                hint: 'you@company.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(
                  CupertinoIcons.mail,
                  size: 18,
                  color: AppColors.tertiaryLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CeoTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passCtrl,
                obscureText: true,
                prefixIcon: const Icon(
                  CupertinoIcons.lock,
                  size: 18,
                  color: AppColors.tertiaryLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CeoButton(
                label: 'Sign In',
                expand: true,
                isLoading: _loading,
                onPressed: _login,
              ),
              const SizedBox(height: AppSpacing.md),
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Container(height: 0.5, color: AppColors.separator),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      'or',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 0.5, color: AppColors.separator),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Social buttons
              Row(
                children: [
                  Expanded(
                    child: CeoButton(
                      label: 'Apple',
                      icon: CupertinoIcons.device_phone_portrait,
                      variant: CeoButtonVariant.secondary,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CeoButton(
                      label: 'Google',
                      icon: CupertinoIcons.globe,
                      variant: CeoButtonVariant.secondary,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Text(
                      'Sign Up',
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.systemBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
