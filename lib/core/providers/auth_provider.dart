import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../repositories/user_repository.dart';
import '../services/write_queue.dart';

class AuthSignupResult {
  final bool requiresEmailConfirmation;

  const AuthSignupResult({required this.requiresEmailConfirmation});
}

/// Auth state management using Supabase.
class AuthProvider extends ChangeNotifier {
  // Must mirror `ControlCenterSetupStore._keyCompleted`. We duplicate it here
  // instead of importing the store to avoid pulling a screen-level dependency
  // into a core provider. The key format is `<base>::<userId>`.
  static const _setupCompletedKey = 'control_center.setup_completed.v1';

  // Age gate (RGPD art.8 / COPPA). Device-scoped flag so the 13+ check is only
  // shown once per device, before the very first account is created. We store
  // the boolean result, not the date of birth, to keep the footprint minimal.
  static const _ageVerifiedKey = 'auth.age_verified.v1';

  /// Minimum age required to create an account. 13 is the global floor
  /// (COPPA / Apple / Google). Can be raised later without touching callers.
  static const int minimumSignupAge = 13;

  final _supabase = Supabase.instance.client;
  User? _user;
  bool _hasCompletedOnboarding = false;
  bool _hasCompletedSetup = false;
  DateTime? _pendingDeletionDate;
  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider() {
    _user = _supabase.auth.currentUser;
    _listenToAuthChanges();
    if (_user != null) {
      unawaited(_refreshSetupCompletedFlag().then((_) => notifyListeners()));
    }
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// `true` when this device has already walked the current user through
  /// `/control-center-setup` at least once. Read synchronously from
  /// SharedPreferences and kept fresh via the auth-change listener.
  ///
  /// The router uses this to send returning users straight to `/home` when
  /// they sign in via Apple/Google on the `/signup` screen (which would
  /// otherwise be treated as a brand-new signup).
  bool get hasCompletedSetup => _hasCompletedSetup;

  /// `true` when the signed-in user's profile carries a future
  /// `deletion_scheduled_at`, i.e. they previously requested a soft account
  /// deletion that has not yet been purged. Post-login UI uses this to offer a
  /// "cancel deletion" dialog so the user can recover their account.
  bool get hasPendingDeletion => _pendingDeletionDate != null;

  /// The date the account is scheduled to be permanently deleted, or `null`
  /// when no deletion is pending. Resolved from `profiles.deletion_scheduled_at`
  /// on each auth refresh.
  DateTime? get pendingDeletionDate => _pendingDeletionDate;

  String? get userName =>
      _user?.userMetadata?['full_name'] ?? _user?.email?.split('@').first;
  String? get userEmail => _user?.email;

  /// `true` once the user has passed the 13+ age gate on this device. Read
  /// from SharedPreferences. The gate is intentionally device-scoped (not
  /// user-scoped) since it runs before any account exists.
  Future<bool> isAgeVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_ageVerifiedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Persist that the age gate has been cleared, so we never ask again on
  /// this device.
  Future<void> setAgeVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ageVerifiedKey, true);
    } catch (_) {
      // Best effort — if persistence fails the gate simply shows again next
      // time, which is the safe direction.
    }
  }

  Future<void> _refreshSetupCompletedFlag() async {
    final userId = _user?.id;
    if (userId == null) {
      _hasCompletedSetup = false;
      _pendingDeletionDate = null;
      return;
    }

    // Local (offline) value first: read synchronously-cached SharedPreferences
    // so we always have a fallback even if the network read below fails.
    var localCompleted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      localCompleted = prefs.getBool('$_setupCompletedKey::$userId') ?? false;
    } catch (_) {
      localCompleted = false;
    }
    _hasCompletedSetup = localCompleted;

    // Then consult the server: an existing user reinstalling on a new device
    // has no local flag yet, but `profiles.setup_completed` survives. If the
    // server says setup is done, trust it and refresh the local cache for
    // offline. On any network failure, keep the local value resolved above.
    try {
      final profile = await UserRepository().getProfile();
      if (profile != null && profile.setupCompleted) {
        _hasCompletedSetup = true;
        if (!localCompleted) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('$_setupCompletedKey::$userId', true);
          } catch (_) {
            // Best effort — the server remains the source of truth.
          }
        }
      }

      // Surface a pending soft-deletion so post-login UI can offer to cancel it.
      // Only treat a deletion scheduled in the FUTURE as recoverable; a past
      // timestamp means the cron is about to purge (or has purged) the account.
      final scheduledAt = profile?.deletionScheduledAt;
      _pendingDeletionDate =
          (scheduledAt != null &&
              scheduledAt.isAfter(DateTime.now().toUtc()))
          ? scheduledAt
          : null;
    } catch (_) {
      // Network read failed — fall back to the local value already set.
    }
  }

  /// Cancel a pending soft-deletion (clears `deletion_scheduled_at` /
  /// `deletion_reason` on the user's profile) and drop the local flag so the
  /// UI stops prompting. Safe to call even when nothing is pending.
  Future<void> cancelScheduledDeletion() async {
    await UserRepository().cancelScheduledDeletion();
    _pendingDeletionDate = null;
    notifyListeners();
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      // Only clear _user on explicit sign-out. Token refresh failures (e.g.
      // when offline) emit a null session that would otherwise log the user
      // out — instead we keep their cached session active until they regain
      // network and either refresh or hit an explicit signedOut event.
      if (data.event == AuthChangeEvent.signedOut) {
        _user = null;
        _hasCompletedSetup = false;
      } else {
        final session = data.session;
        if (session != null) {
          _user = session.user;
          // Refresh the flag BEFORE notifying listeners so the router's
          // redirect callback (driven by AuthProvider as its refreshListenable)
          // sees up-to-date `hasCompletedSetup`. Otherwise a returning user
          // signing in via Apple on the /signup screen would be sent through
          // /control-center-setup again.
          await _refreshSetupCompletedFlag();
        }
      }
      notifyListeners();
    });
  }

  /// Real login with Supabase.
  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      _hasCompletedOnboarding = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Real signup with Supabase.
  Future<AuthSignupResult> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      _hasCompletedOnboarding = true;
      return AuthSignupResult(
        requiresEmailConfirmation: response.session == null,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      rethrow;
    }
  }

  /// Google Sign-In integration.
  Future<void> signInWithGoogle() async {
    try {
      // 1. Web and Desktop handled differently by Supabase,
      // but for Mobile we use google_sign_in package.
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android)) {
        if (!SupabaseConfig.hasGoogleMobileClientConfig) {
          throw StateError(
            'Google Sign-In mobile is not configured. Provide GOOGLE_WEB_CLIENT_ID and GOOGLE_IOS_CLIENT_ID via --dart-define before shipping.',
          );
        }

        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? SupabaseConfig.googleIosClientId
              : null,
          serverClientId: SupabaseConfig.googleWebClientId,
        );
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw StateError('Google Sign-In was cancelled.');
        }
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (accessToken == null || idToken == null) {
          throw 'Google Sign-In was cancelled or failed.';
        }

        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        _hasCompletedOnboarding = true;
      } else {
        // Fallback for Web/Desktop
        await _supabase.auth.signInWithOAuth(OAuthProvider.google);
        _hasCompletedOnboarding = true;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Apple Sign-In integration (native iOS flow).
  ///
  /// We follow Supabase's recommended pattern for native id-token sign-in:
  ///   1. Generate a high-entropy raw nonce locally.
  ///   2. Send the SHA-256 hash to Apple (the id_token Apple returns includes
  ///      that hashed nonce, so we know later that the token is bound to us).
  ///   3. Hand Supabase the identity token + the original raw nonce so it
  ///      can recompute the hash and verify the binding before issuing a
  ///      Supabase session.
  ///
  /// On first sign-in only, Apple returns the user's full name. We forward it
  /// to Supabase as `full_name` metadata so the rest of the app picks it up.
  Future<void> signInWithApple() async {
    try {
      // Only iOS/macOS support native Sign in with Apple. Apple does not
      // publish a credential flow for Android/Web from this package.
      final isApplePlatform =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
      if (!isApplePlatform) {
        throw StateError('Sign in with Apple is only available on Apple devices.');
      }

      final rawNonce = _generateRawNonce();
      final hashedNonce = sha256
          .convert(utf8.encode(rawNonce))
          .toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw StateError('Apple did not return an identity token.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Apple only ships givenName/familyName on the FIRST sign-in. If we
      // got them, push them into Supabase user metadata so the rest of the
      // app can render a personalised greeting on subsequent launches.
      final given = credential.givenName?.trim();
      final family = credential.familyName?.trim();
      final fullName = [
        if (given != null && given.isNotEmpty) given,
        if (family != null && family.isNotEmpty) family,
      ].join(' ').trim();
      if (fullName.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
      }

      _hasCompletedOnboarding = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Cryptographically-strong random nonce — 32 url-safe characters.
  /// Used as the binding between our request to Apple and Supabase's later
  /// verification of the returned identity token.
  String _generateRawNonce([int length = 32]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> logout() async {
    // Clear queued offline writes before signing out so they don't flush
    // under a different account on next sign-in.
    try {
      await WriteQueue.clear();
    } catch (_) {
      // Best effort.
    }
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
