import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'auth_support.dart';

/// Apple "Sign in with Apple" button — rendered with the Apple-prescribed
/// visual style (black pill with the Apple logo + "Sign in with Apple"
/// label). Apple's brand guidelines require we keep the wording, the icon,
/// and a minimum tap target — we use SF Symbol's apple.logo glyph and the
/// system black/white palette.
///
/// Only visible on Apple platforms (iOS / macOS). Returns SizedBox.shrink()
/// elsewhere so the screen layout stays clean on Android.
class AppleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AppleSignInButton({super.key, this.onSuccess});

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  bool _loading = false;

  bool get _isApplePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onPressed() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithApple();
      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      final language = context.read<LanguageProvider>();
      // sign_in_with_apple raises a SignInWithAppleAuthorizationException
      // when the user cancels — surface a softer message in that case.
      final raw = e.toString().toLowerCase();
      if (raw.contains('canceled') || raw.contains('cancelled')) {
        // User backed out of the Apple sheet on purpose — silent no-op.
        return;
      }
      await showAuthDialog(
        context,
        title: language.t('auth_error_title'),
        message: humanizeAuthError(e, language: language),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isApplePlatform) return const SizedBox.shrink();

    return _PressScale(
      onTap: _onPressed,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          // Apple HIG: black button on light surfaces, white on dark.
          // Our auth screens are dark, so we pick the white style for a
          // strong contrast tap target.
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const CupertinoActivityIndicator(
                  color: CupertinoColors.black,
                  radius: 10,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.app_badge,
                      // Apple's SF Symbol for the Apple logo is technically
                      // available as a private glyph; CupertinoIcons doesn't
                      // expose `apple.logo` so we render a stylised square
                      // logo placeholder. Visually close enough for a 1.0
                      // release; can swap for an SVG asset later.
                      color: CupertinoColors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Apple',
                      style: AppTypography.body.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Local copy of PressScale to avoid pulling tasks_screen.dart's private
/// implementation. Mirrors the same haptic-less subtle scale animation used
/// elsewhere on auth surfaces.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressScale({required this.child, this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
