import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'auth_support.dart';

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

  Future<void> _showError(dynamic error) async {
    if (!mounted) return;
    final language = context.read<LanguageProvider>();
    await showAuthDialog(
      context,
      title: language.t('auth_error_title'),
      message: humanizeAuthError(error, language: language),
    );
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (!isValidEmail(email)) {
      await showAuthDialog(
        context,
        title: 'INVALID EMAIL',
        message: 'Please enter a valid email address.',
      );
      return;
    }
    if (password.isEmpty) {
      await showAuthDialog(
        context,
        title: 'PASSWORD REQUIRED',
        message: 'Please enter your password to continue.',
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(email, password);
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (!isValidEmail(email)) {
      await showAuthDialog(
        context,
        title: 'RESET PASSWORD',
        message: 'Enter your account email first, then try again.',
      );
      return;
    }

    try {
      await context.read<AuthProvider>().resetPassword(email);
      if (!mounted) return;
      await showAuthDialog(
        context,
        title: 'CHECK YOUR EMAIL',
        message:
            'If an account exists for $email, a password reset email has been sent.',
      );
    } catch (e) {
      await _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -50,
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
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: AppTypography.largeTitle.copyWith(
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                        letterSpacing: -0.95,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Auth Form
                    GlassCard(
                      blur: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassInputField(
                            placeholder: 'Email',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            prefix: Icon(
                              CupertinoIcons.mail,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GlassInputField(
                            placeholder: 'Password',
                            controller: _passCtrl,
                            obscureText: true,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            prefix: Icon(
                              CupertinoIcons.lock,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 28),
                          LiquidButton(
                            label: 'Sign in',
                            fullWidth: true,
                            isLoading: _loading,
                            onPressed: _login,
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: _loading ? null : _resetPassword,
                              child: Text(
                                'Forgot password?',
                                style: AppTypography.footnote.copyWith(
                                  fontSize: 13,
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New user? ',
                          style: AppTypography.footnote.copyWith(
                            fontSize: 12,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: Text(
                            'Sign up',
                            style: AppTypography.footnote.copyWith(
                              fontSize: 12,
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w700,
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
