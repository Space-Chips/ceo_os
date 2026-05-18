import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/providers/auth_provider.dart';
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
    await showAuthDialog(
      context,
      title: 'AUTH ERROR',
      message: humanizeAuthError(error),
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
                    Column(
                      children: [
                        NeoMonoText(
                          'WakeApp',
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: AppColors.label,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SYSTEM INITIALIZING...',
                          style: AppTypography.mono.copyWith(
                            color: AppColors.primaryOrange,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),

                    // Auth Form
                    GlassCard(
                      blur: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CREDENTIALS',
                            style: AppTypography.mono.copyWith(
                              fontSize: 11,
                              color: AppColors.tertiaryLabel,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'EMAIL_ADDRESS',
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
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'ACCESS_KEY',
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
                          const SizedBox(height: 32),
                          LiquidButton(
                            label: 'AUTHENTICATE',
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
                                'FORGOT_PASSWORD',
                                style: AppTypography.mono.copyWith(
                                  fontSize: 11,
                                  color: AppColors.primaryOrange,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const AuthTrustFooter(),
                    const SizedBox(height: 20),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "NEW_OPERATOR? ",
                          style: AppTypography.mono.copyWith(
                            fontSize: 12,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: Text(
                            'SIGN_UP',
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
