import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Screen shown right after a successful sign-up to tell the user a
/// confirmation email has been sent. The user lands here automatically from
/// the signup flow and from here can either go back to the login screen or
/// wait until they tap the confirmation link in their inbox (which deep-links
/// straight into the app via [`/auth/callback`]).
class EmailSentScreen extends StatelessWidget {
  final String email;

  const EmailSentScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();

    final messageTemplate = language.t('auth_email_sent_message');
    final message = messageTemplate.contains('{email}')
        ? messageTemplate.replaceAll('{email}', email)
        : '$messageTemplate\n\n$email';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Background glow — same accent as the rest of the auth flow.
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
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.18,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.envelope_open,
                          size: 40,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      language.t('auth_email_sent_title'),
                      textAlign: TextAlign.center,
                      style: AppTypography.largeTitle.copyWith(
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                        letterSpacing: -0.95,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        color: AppColors.secondaryLabel,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 36),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.t('auth_email_sent_tip_title'),
                              style: AppTypography.footnote.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tertiaryLabel,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              language.t('auth_email_sent_tip_body'),
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                color: AppColors.secondaryLabel,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    LiquidButton(
                      onPressed: () => context.go('/login'),
                      label: language.t('auth_email_sent_back_to_login'),
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
