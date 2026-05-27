import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Maps a raw Supabase auth error (or anything else) to a friendly, localized
/// message kids could understand. The optional [language] enables i18n; if
/// omitted, English defaults are used (used in places that don't have access
/// to a BuildContext, e.g. callbacks).
String humanizeAuthError(Object error, {LanguageProvider? language}) {
  String t(String key, String fallback) {
    if (language == null) return fallback;
    final translated = language.t(key);
    // language.t() returns the key itself if not found; in that case use fallback.
    return translated == key ? fallback : translated;
  }

  final raw = error.toString();
  final lower = raw.toLowerCase();

  // 1. Rate limit — extract the seconds from messages like
  //    "For security purposes, you can only request this after 54 seconds"
  //    or codes `over_email_send_rate_limit` / `over_request_rate_limit`.
  if (lower.contains('over_email_send_rate_limit') ||
      lower.contains('over_request_rate_limit') ||
      lower.contains('you can only request this after') ||
      (error is AuthException && error.statusCode == '429')) {
    final secondsMatch =
        RegExp(r'(\d+)\s*seconds?').firstMatch(raw) ??
            RegExp(r'after\s+(\d+)').firstMatch(raw);
    final seconds = secondsMatch?.group(1) ?? '60';
    return t(
      'auth_error_rate_limit_seconds',
      'You just asked for an email. Please wait $seconds seconds before trying again.',
    ).replaceAll('{seconds}', seconds);
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return t(
        'auth_error_invalid_credentials',
        'The email or password is incorrect. Please try again.',
      );
    }
    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed')) {
      return t(
        'auth_error_email_not_confirmed',
        'You need to confirm your email first. Check your inbox for the confirmation link.',
      );
    }
    if (message.contains('user already registered') ||
        message.contains('already exists') ||
        message.contains('user_already_exists')) {
      return t(
        'auth_error_user_already_exists',
        'An account with this email already exists. Try signing in instead.',
      );
    }
    if (message.contains('invalid email') ||
        message.contains('invalid_email')) {
      return t(
        'auth_error_invalid_email',
        'This email address looks invalid. Please check it and try again.',
      );
    }
    if (message.contains('password') &&
        (message.contains('short') ||
            message.contains('weak') ||
            message.contains('6 characters'))) {
      return t(
        'auth_error_weak_password',
        'Your password is too short. Use at least 8 characters.',
      );
    }
  }

  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable')) {
    return t(
      'auth_error_network',
      'Cannot reach the server. Check your internet connection and try again.',
    );
  }

  return t(
    'auth_error_unknown',
    'Something went wrong. Please try again in a moment.',
  );
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
