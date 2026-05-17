import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/supabase_config.dart';
import '../repositories/premium_repository.dart';

class AuthSignupResult {
  final bool requiresEmailConfirmation;

  const AuthSignupResult({required this.requiresEmailConfirmation});
}

/// Auth state management using Supabase.
class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  bool _hasCompletedOnboarding = false;
  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider() {
    _user = _supabase.auth.currentUser;
    _listenToAuthChanges();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get userName =>
      _user?.userMetadata?['full_name'] ?? _user?.email?.split('@').first;
  String? get userEmail => _user?.email;

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
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

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
