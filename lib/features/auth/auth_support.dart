import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  await showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title, style: AppTypography.mono.copyWith(fontSize: 16)),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message, style: AppTypography.caption1),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'OK',
            style: AppTypography.mono.copyWith(color: AppColors.primaryOrange),
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
    return Column(
      children: [
        Text(
          'By continuing, you agree to the Terms of Use and Privacy Policy.',
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
              label: 'TERMS',
              onTap: () => showAuthLegalDialog(
                context,
                title: 'TERMS OF USE',
                body:
                    'WakeApp provides productivity, planning, and focus tools. Premium subscriptions may renew automatically unless canceled in your Apple App Store or Google Play subscription settings.',
              ),
            ),
            _AuthInlineLink(
              label: 'PRIVACY',
              onTap: () => showAuthLegalDialog(
                context,
                title: 'PRIVACY POLICY',
                body:
                    'WakeApp uses Supabase for account and cloud sync infrastructure, Google Sign-In when selected by the user, RevenueCat plus Apple or Google Play for purchases, and platform system APIs for blocking, notifications, widgets, and scheduling.',
              ),
            ),
            _AuthInlineLink(
              label: 'SUPPORT',
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
        style: AppTypography.mono.copyWith(
          fontSize: 11,
          color: AppColors.primaryOrange,
          letterSpacing: 1.2,
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
  await showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title, style: AppTypography.mono.copyWith(fontSize: 16)),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(body, style: AppTypography.caption1),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: AppTypography.mono.copyWith(color: AppColors.primaryOrange),
          ),
        ),
      ],
    ),
  );
}

Future<void> copySupportEmail(BuildContext context) async {
  const supportEmail = 'timofrmac@gmail.com';
  await Clipboard.setData(const ClipboardData(text: supportEmail));
  if (!context.mounted) return;
  await showAuthDialog(
    context,
    title: 'SUPPORT',
    message:
        'Support email copied: $supportEmail. Include your device, app version, and the steps that caused the issue.',
  );
}
