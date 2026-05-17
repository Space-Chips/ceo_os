import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

String humanizeAuthError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'The email or password is incorrect.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (message.contains('user already registered')) {
      return 'An account already exists for this email address.';
    }
    if (message.contains('password')) {
      return error.message;
    }
    return error.message;
  }

  final raw = error.toString();
  if (raw.contains('SocketException')) {
    return 'Network connection failed. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}

bool isValidEmail(String value) {
  final email = value.trim();
  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  return emailRegex.hasMatch(email);
}

Future<void> showAuthDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final language = context.read<LanguageProvider>();
  await showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(
        title,
        style: AppTypography.headline.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: AppTypography.callout.copyWith(
            fontSize: 14,
            color: AppColors.secondaryLabel,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            language.t('ok'),
            style: AppTypography.callout.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthTrustFooter extends StatelessWidget {
  const AuthTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return Column(
      children: [
        Text(
          language.t('auth_trust_footer'),
          textAlign: TextAlign.center,
          style: AppTypography.caption1.copyWith(
            color: AppColors.tertiaryLabel,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _AuthInlineLink(
              label: language.t('terms_short'),
              onTap: () => showAuthLegalDialog(
                context,
                title: language.t('terms_of_use'),
                body: language.t('auth_terms_body'),
              ),
            ),
            _AuthInlineLink(
              label: language.t('privacy_short'),
              onTap: () => showAuthLegalDialog(
                context,
                title: language.t('privacy_policy'),
                body: language.t('auth_privacy_body'),
              ),
            ),
            _AuthInlineLink(
              label: language.t('support_short'),
              onTap: () => copySupportEmail(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthInlineLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AuthInlineLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Text(
        label,
        style: AppTypography.footnote.copyWith(
          fontSize: 12,
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Future<void> showAuthLegalDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final language = context.read<LanguageProvider>();
  await showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(
        title,
        style: AppTypography.headline.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          body,
          style: AppTypography.callout.copyWith(
            fontSize: 14,
            color: AppColors.secondaryLabel,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            language.t('close'),
            style: AppTypography.callout.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> copySupportEmail(BuildContext context) async {
  const supportEmail = 'timofrmac@gmail.com';
  final language = context.read<LanguageProvider>();
  await Clipboard.setData(const ClipboardData(text: supportEmail));
  if (!context.mounted) return;
  await showAuthDialog(
    context,
    title: language.t('contact_support'),
    message: language
        .t('support_email_copied')
        .replaceAll('timofrmac@gmail.com', supportEmail),
  );
}
