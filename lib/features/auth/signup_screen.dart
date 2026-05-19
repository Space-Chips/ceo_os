import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/models/onboarding_models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'auth_support.dart';
import '../../components/glass_card.dart';
import '../../components/glass_input_field.dart';
import '../../components/liquid_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  OnboardingSetupData? _setupData;
  bool _didHydrateSetup = false;

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
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
          title: Text(
            'AUTH ERROR',
            style: AppTypography.mono.copyWith(fontSize: 16),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(error.toString(), style: AppTypography.caption1),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'DISMISS',
                style: TextStyle(color: AppColors.primaryOrange),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
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
    final language = context.watch<LanguageProvider>();
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            onPressed: _showLanguagePicker,
                            child: Text(
                              _languageDisplayLabel(language.languageCode),
                              style: AppTypography.footnote.copyWith(
                                fontSize: 12,
                                color: AppColors.tertiaryLabel,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          language.t('auth_create_account_title'),
                          style: AppTypography.largeTitle.copyWith(
                            fontSize: 31,
                            fontWeight: FontWeight.w700,
                            color: AppColors.label,
                            letterSpacing: -0.95,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.t('auth_create_account_subtitle'),
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            fontSize: 15,
                            color: AppColors.secondaryLabel,
                            height: 1.42,
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
                            prefix: Icon(
                              CupertinoIcons.person,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'EMAIL_ADDRESS',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
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
                            prefix: Icon(
                              CupertinoIcons.lock,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassInputField(
                            placeholder: 'CONFIRM_ACCESS_KEY',
                            controller: _confirmPassCtrl,
                            obscureText: true,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            prefix: Icon(
                              CupertinoIcons.lock_shield,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
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
                    const AuthTrustFooter(),
                    const SizedBox(height: 20),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          language.t('auth_already_registered'),
                          style: AppTypography.footnote.copyWith(
                            fontSize: 12,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            language.t('auth_sign_in'),
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

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.footnote.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLabel,
      ),
    );
  }
}
