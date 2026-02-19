import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

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
              child: const Text('DISMISS', style: TextStyle(color: AppColors.primaryOrange)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(_emailCtrl.text, _passCtrl.text);
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
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
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
                        const NeoMonoText(
                          'CEO OS',
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
                            prefix: const Icon(CupertinoIcons.mail, size: 16, color: AppColors.secondaryLabel),
                          ),
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'ACCESS_KEY',
                            controller: _passCtrl,
                            obscureText: true,
                            prefix: const Icon(CupertinoIcons.lock, size: 16, color: AppColors.secondaryLabel),
                          ),
                          const SizedBox(height: 32),
                          LiquidButton(
                            label: 'AUTHENTICATE',
                            fullWidth: true,
                            isLoading: _loading,
                            onPressed: _login,
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