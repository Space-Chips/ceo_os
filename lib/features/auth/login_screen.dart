import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'auth_support.dart';
import '../../components/glass_card.dart';
import '../../components/glass_input_field.dart';
import '../../components/liquid_button.dart';
import '../../components/neo_mono_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  String _t(String key) => context.read<LanguageProvider>().t(key);
  static const List<(String code, String nativeLabel)> _languages = [
    ('en', 'English'),
    ('fr', 'Français'),
    ('zh', '中文'),
    ('hi', 'हिन्दी'),
    ('es', 'Español'),
    ('ar', 'العربية'),
    ('id', 'Bahasa Indonesia'),
    ('ru', 'Русский'),
    ('pt', 'Português'),
  ];

  String _languageDisplayLabel(String code) {
    final normalized = code.toLowerCase();
    for (final option in _languages) {
      if (option.$1 == normalized) return option.$2;
    }
    return 'English';
  }

  Future<void> _showLanguagePicker() async {
    final languageProvider = context.read<LanguageProvider>();
    final current = languageProvider.languageCode.toLowerCase();
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (popupContext) {
        return CupertinoActionSheet(
          title: Text(_t('language')),
          message: Text(_t('language_picker_subtitle')),
          actions: [
            for (final option in _languages)
              CupertinoActionSheetAction(
                isDefaultAction: option.$1 == current,
                onPressed: () => Navigator.of(popupContext).pop(option.$1),
                child: Text(option.$2),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(popupContext).pop(),
            child: Text(_t('cancel')),
          ),
        );
      },
    );

    if (selected == null || selected == current) return;
    await languageProvider.setLanguage(selected, persistToCloud: true);
  }

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
              child: Text('DISMISS', style: TextStyle(color: AppColors.primaryOrange)),
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
    final language = context.watch<LanguageProvider>();
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