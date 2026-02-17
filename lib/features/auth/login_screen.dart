import 'package:flutter/material.dart';
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
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    await context.read<AuthProvider>().login(_emailCtrl.text, _passCtrl.text);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            const Spacer(),
            // Logo area
            Container(width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.accentGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))]),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 36)),
            const SizedBox(height: AppSpacing.lg),
            Text('CEO OS', style: AppTypography.displayLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('Your AI productivity operating system',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            // Form
            CeoTextField(label: 'Email', hint: 'you@company.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textTertiary)),
            const SizedBox(height: AppSpacing.md),
            CeoTextField(label: 'Password', hint: '••••••••', controller: _passCtrl, obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary)),
            const SizedBox(height: AppSpacing.lg),
            CeoButton(label: 'Sign In', expand: true, isLoading: _loading, onPressed: _login),
            const SizedBox(height: AppSpacing.md),
            // Divider
            Row(children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('or', style: AppTypography.caption)),
              const Expanded(child: Divider(color: AppColors.border)),
            ]),
            const SizedBox(height: AppSpacing.md),
            // Social buttons
            Row(children: [
              Expanded(child: CeoButton(label: 'Apple', icon: Icons.apple, variant: CeoButtonVariant.secondary, onPressed: () {})),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: CeoButton(label: 'Google', icon: Icons.g_mobiledata, variant: CeoButtonVariant.secondary, onPressed: () {})),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Don't have an account? ", style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => context.go('/signup'),
                child: Text('Sign Up', style: AppTypography.bodySmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: AppSpacing.md),
          ]),
        ),
      ),
    );
  }
}
