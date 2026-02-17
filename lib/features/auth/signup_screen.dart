import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_button.dart';
import '../../core/widgets/ceo_text_field.dart';

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    await context.read<AuthProvider>().signup(
      _nameCtrl.text,
      _emailCtrl.text,
      _passCtrl.text,
    );
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
              Text('Create Account', style: AppTypography.largeTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Start your productivity journey',
                style: AppTypography.body.copyWith(
                  color: AppColors.secondaryLabel,
                ),
              ),
              const Spacer(),
              CeoTextField(
                label: 'Name',
                hint: 'Your name',
                controller: _nameCtrl,
                prefixIcon: const Icon(
                  CupertinoIcons.person,
                  size: 18,
                  color: AppColors.tertiaryLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
                label: 'Create Account',
                expand: true,
                isLoading: _loading,
                onPressed: _signup,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Sign In',
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
