import 'package:ceo_os/features/auth/auth_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('isValidEmail', () {
    test('accepts a standard email address', () {
      expect(isValidEmail('founder@example.com'), isTrue);
    });

    test('rejects malformed email addresses', () {
      expect(isValidEmail('founderexample.com'), isFalse);
      expect(isValidEmail('founder@'), isFalse);
      expect(isValidEmail(''), isFalse);
    });
  });

  group('humanizeAuthError', () {
    test('maps invalid credentials to a human-readable message', () {
      final error = AuthException('Invalid login credentials');

      expect(
        humanizeAuthError(error),
        'The email or password is incorrect.',
      );
    });

    test('maps email confirmation errors to a reviewer-friendly message', () {
      final error = AuthException('Email not confirmed');

      expect(
        humanizeAuthError(error),
        'Please confirm your email address before signing in.',
      );
    });

    test('falls back to a safe generic message for unknown failures', () {
      expect(
        humanizeAuthError(Exception('Unexpected failure')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
