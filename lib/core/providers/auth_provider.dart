import 'package:flutter/material.dart';

/// Auth state management — scaffold only, no real auth backend.
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;
  String? _userName;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  /// Stub login — always succeeds.
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _isAuthenticated = true;
    _userEmail = email;
    _userName = email.split('@').first;
    notifyListeners();
  }

  /// Stub signup — always succeeds.
  Future<void> signup(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _isAuthenticated = true;
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
