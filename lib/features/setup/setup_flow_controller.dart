import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/focus_service.dart';

enum SetupStep {
  welcome,
  usageAccess,
  accessibility,
  overlay,
  success,
}

class SetupFlowController extends ChangeNotifier {
  static const _prefSetupComplete = 'screen_time_setup_complete';
  static const _prefSetupHasRun = 'screen_time_setup_has_run';
  static const _prefSetupStep = 'screen_time_setup_step';
  final FocusService _focusService;
  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _isLoading = true;
  bool _setupComplete = false;
  bool _setupHasRun = false;
  SetupStep _currentStep = SetupStep.welcome;
  FocusPermissionState _overlayState = FocusPermissionState.unknown;
  FocusPermissionState _usageState = FocusPermissionState.unknown;
  FocusPermissionState _accessibilityState = FocusPermissionState.unknown;

  SetupFlowController({FocusService? focusService})
    : _focusService = focusService ?? FocusService();

  bool get isLoading => _isLoading;
  bool get isSetupComplete => _setupComplete;
  bool get isSetupRequired => _requiresAndroidSetup && !allPermissionsGranted;
  bool get hasRunBefore => _setupHasRun;
  SetupStep get currentStep => _currentStep;
  bool get overlayGranted => _overlayState == FocusPermissionState.approved;
  bool get usageGranted => _usageState == FocusPermissionState.approved;
  bool get accessibilityGranted =>
      _accessibilityState == FocusPermissionState.approved;

  bool get allPermissionsGranted =>
      overlayGranted && usageGranted && accessibilityGranted;

  bool get _requiresAndroidSetup => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!_requiresAndroidSetup) {
      _setupComplete = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    _setupComplete = _prefs?.getBool(_prefSetupComplete) ?? false;
    _setupHasRun = _prefs?.getBool(_prefSetupHasRun) ?? false;
    await refreshPermissionStates();

    if (allPermissionsGranted) {
      _setupComplete = true;
      await _prefs?.setBool(_prefSetupComplete, true);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _setupComplete = false;
    await _prefs?.setBool(_prefSetupComplete, false);

    final savedStep = _stepFromName(_prefs?.getString(_prefSetupStep));
    _currentStep = _resolveInitialStep(savedStep);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> openOverlaySettings() async {
    await _focusService.setPendingPermissionReturn(AndroidProtectionStep.overlay);
    await _focusService.openOverlaySettings();
  }

  Future<void> openUsageAccessSettings() async {
    await _focusService.setPendingPermissionReturn(AndroidProtectionStep.usageAccess);
    await _focusService.openUsageAccessSettings();
  }

  Future<void> openAccessibilitySettings() async {
    await _focusService.setPendingPermissionReturn(AndroidProtectionStep.accessibility);
    await _focusService.openAccessibilitySettings();
  }

  Future<void> clearPendingPermissionReturn() async {
    await _focusService.clearPendingPermissionReturn();
  }





  Future<void> refreshPermissionStates() async {
    if (!_requiresAndroidSetup) {
      _overlayState = FocusPermissionState.approved;
      _usageState = FocusPermissionState.approved;
      _accessibilityState = FocusPermissionState.approved;
      return;
    }

    _overlayState = await _focusService.getOverlayPermissionState();
    _usageState = await _focusService.getUsageAccessPermissionState();
    _accessibilityState = await _focusService.getAccessibilityPermissionState();
  }

  Future<void> advance() async {
    await _markHasRun();
    _currentStep = _nextStepAfter(_currentStep);
    await _persistStep();
    notifyListeners();
  }

  Future<void> jumpTo(SetupStep step) async {
    _currentStep = step;
    await _persistStep();
    notifyListeners();
  }

  Future<void> markSetupComplete() async {
    _setupComplete = true;
    await _prefs?.setBool(_prefSetupComplete, true);
    await _persistStep(stepOverride: SetupStep.success);
    notifyListeners();
  }

  bool isPermissionStep(SetupStep step) {
    return step == SetupStep.overlay ||
        step == SetupStep.usageAccess ||
        step == SetupStep.accessibility;
  }

  bool isPermissionGrantedFor(SetupStep step) {
    switch (step) {
      case SetupStep.overlay:
        return overlayGranted;
      case SetupStep.usageAccess:
        return usageGranted;
      case SetupStep.accessibility:
        return accessibilityGranted;
      default:
        return false;
    }
  }

  SetupStep firstMissingPermissionStep() {
    if (!accessibilityGranted) return SetupStep.accessibility;
    if (!usageGranted) return SetupStep.usageAccess;
    if (!overlayGranted) return SetupStep.overlay;
    return SetupStep.success;
  }

  SetupStep _resolveInitialStep(SetupStep? savedStep) {
    if (!_setupHasRun) return SetupStep.welcome;
    if (allPermissionsGranted) return SetupStep.success;
    if (savedStep != null &&
        isPermissionStep(savedStep) &&
        !isPermissionGrantedFor(savedStep)) {
      return savedStep;
    }
    return firstMissingPermissionStep();
  }

  Future<void> _markHasRun() async {
    if (_setupHasRun) return;
    _setupHasRun = true;
    await _prefs?.setBool(_prefSetupHasRun, true);
  }

  Future<void> _persistStep({SetupStep? stepOverride}) async {
    final step = stepOverride ?? _currentStep;
    await _prefs?.setString(_prefSetupStep, step.name);
  }

  SetupStep _nextStepAfter(SetupStep step) {
    final order = _orderedSteps;
    final index = order.indexOf(step);
    if (index == -1) return SetupStep.welcome;
    if (index >= order.length - 1) return step;
    return order[index + 1];
  }

  SetupStep? _stepFromName(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'reflection':
      case 'loading':
      case 'insight':
      case 'overview':
        return SetupStep.welcome;
    }
    for (final step in SetupStep.values) {
      if (step.name == raw) return step;
    }
    return null;
  }

  List<SetupStep> get _orderedSteps => const [
    SetupStep.welcome,
    SetupStep.accessibility,
    SetupStep.usageAccess,
    SetupStep.overlay,
    SetupStep.success,
  ];
}
