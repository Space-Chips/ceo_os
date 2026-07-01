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
import 'apple_sign_in_button.dart';
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
    final language = context.read<LanguageProvider>();
    await showAuthDialog(
      context,
      title: language.t('auth_error_title'),
      message: humanizeAuthError(error, language: language),
    );
  }

  bool get _isFr =>
      context.read<LanguageProvider>().languageCode.toLowerCase().startsWith(
        'fr',
      );

  /// Age gate (RGPD art.8 / COPPA). Runs before any account is created. If the
  /// device already cleared the gate we let the flow through immediately;
  /// otherwise we show a date-of-birth picker, compute the age, and either
  /// persist the verification (>= 13) or show a blocking message (< 13).
  ///
  /// Returns `true` when account creation may proceed.
  Future<bool> _ensureAgeVerified() async {
    final auth = context.read<AuthProvider>();
    if (await auth.isAgeVerified()) return true;
    if (!mounted) return false;

    final isFr = _isFr;
    final now = DateTime.now();
    // Default the picker to a plausible adult DOB so the common case is one tap.
    DateTime selected = DateTime(now.year - 18, now.month, now.day);

    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (popupContext) {
        return Container(
          height: 320,
          color: AppColors.background,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        isFr ? 'Quelle est ta date de naissance ?' : 'When were you born?',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFr
                            ? 'Tu dois avoir au moins 13 ans pour utiliser WakeApp.'
                            : 'You must be at least 13 to use WakeApp.',
                        textAlign: TextAlign.center,
                        style: AppTypography.footnote.copyWith(
                          fontSize: 12,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selected,
                    minimumYear: 1900,
                    maximumDate: now,
                    onDateTimeChanged: (value) => selected = value,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () => Navigator.of(popupContext).pop(true),
                      child: Text(isFr ? 'Confirmer' : 'Confirm'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return false;
    if (!mounted) return false;

    final age = _ageFrom(selected, now);
    if (age < AuthProvider.minimumSignupAge) {
      await _showAgeBlocked();
      return false;
    }

    await auth.setAgeVerified();
    return true;
  }

  /// Whole years between [dob] and [asOf], without counting a birthday that
  /// hasn't happened yet this year.
  int _ageFrom(DateTime dob, DateTime asOf) {
    var age = asOf.year - dob.year;
    final hadBirthday =
        asOf.month > dob.month ||
        (asOf.month == dob.month && asOf.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  Future<void> _showAgeBlocked() async {
    if (!mounted) return;
    final isFr = _isFr;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(isFr ? 'Accès non autorisé' : 'Access not allowed'),
        content: Text(
          isFr
              ? 'WakeApp nécessite d\'avoir au moins 13 ans. Nous ne pouvons pas créer de compte pour le moment.'
              : 'WakeApp requires you to be at least 13 years old. We can\'t create an account right now.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isFr ? 'OK' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      return;
    }
    // Age gate must pass before we create any account (shown once per device).
    if (!await _ensureAgeVerified()) return;
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final result = await context.read<AuthProvider>().signup(
        _nameCtrl.text,
        email,
        _passCtrl.text,
      );
      if (!mounted) return;
      if (_setupData != null) {
        context.read<ThemeProvider>().setPendingOnboardingSetup(_setupData!);
      }
      await context.read<ThemeProvider>().persistPendingOnboardingSetup();
      if (!mounted) return;
      // When confirmation is required (normal prod path) we navigate to a
      // dedicated screen instead of showing a transient dialog so the user
      // has a clear next step and a place to land while they wait for the
      // email. When confirmation is NOT required, the AuthState listener
      // will route the app forward on its own.
      if (result.requiresEmailConfirmation) {
        context.go('/signup-email-sent', extra: email);
      }
      // Otherwise the AuthState listener + router redirect will route the
      // user forward (no email confirmation needed = session live already).
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
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
                          GlassInputField(
                            placeholder: language.languageCode
                                    .toLowerCase()
                                    .startsWith('fr')
                                ? 'Nom'
                                : 'Name',
                            controller: _nameCtrl,
                            prefix: Icon(
                              CupertinoIcons.person,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GlassInputField(
                            placeholder: language.t('auth_email'),
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefix: Icon(
                              CupertinoIcons.mail,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GlassInputField(
                            placeholder: language.t('auth_password'),
                            controller: _passCtrl,
                            obscureText: true,
                            prefix: Icon(
                              CupertinoIcons.lock,
                              size: 16,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GlassInputField(
                            placeholder: language.t(
                              'auth_confirm_password_placeholder',
                            ),
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
                          const SizedBox(height: 28),
                          LiquidButton(
                            label: language.t('auth_create_account'),
                            fullWidth: true,
                            isLoading: _loading,
                            onPressed: _signup,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    // Sign in with Apple — Apple Guideline 4.8 requires this
                    // to be offered when a third-party login is offered.
                    //
                    // The age gate must also intercept this OAuth path. We do
                    // it without touching the Apple flow itself: while the
                    // gate is unverified we overlay an absorbing tap target
                    // that runs `_ensureAgeVerified()`; once it clears we
                    // rebuild and let the real button handle the tap.
                    _AgeGatedAppleButton(ensureAgeVerified: _ensureAgeVerified),
                    const SizedBox(height: 24),

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

/// Wraps [AppleSignInButton] so the age gate is enforced before the Apple
/// OAuth flow starts, without modifying the Apple flow itself.
///
/// While the gate is not yet cleared we render the Apple button behind a
/// transparent absorbing overlay: a tap runs [ensureAgeVerified] and, if it
/// passes, immediately triggers the real Apple sign-in via the button's
/// success-agnostic re-tap (we simply rebuild and let the user tap again, or
/// — for a one-tap feel — drop the overlay so the next press goes through).
class _AgeGatedAppleButton extends StatefulWidget {
  final Future<bool> Function() ensureAgeVerified;

  const _AgeGatedAppleButton({required this.ensureAgeVerified});

  @override
  State<_AgeGatedAppleButton> createState() => _AgeGatedAppleButtonState();
}

class _AgeGatedAppleButtonState extends State<_AgeGatedAppleButton> {
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _hydrateVerified();
  }

  Future<void> _hydrateVerified() async {
    final verified = await context.read<AuthProvider>().isAgeVerified();
    if (!mounted) return;
    if (verified != _verified) setState(() => _verified = verified);
  }

  Future<void> _onGateTap() async {
    final passed = await widget.ensureAgeVerified();
    if (!mounted) return;
    if (passed) setState(() => _verified = true);
  }

  @override
  Widget build(BuildContext context) {
    // Once the gate is cleared the real button owns its taps. Until then we
    // overlay an absorbing layer that runs the gate first.
    if (_verified) return const AppleSignInButton();
    return Stack(
      children: [
        const IgnorePointer(child: AppleSignInButton()),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onGateTap,
          ),
        ),
      ],
    );
  }
}
