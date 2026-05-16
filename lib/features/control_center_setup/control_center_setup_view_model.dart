import 'package:flutter/foundation.dart';

import 'control_center_setup_models.dart';
import 'control_center_setup_store.dart';

class ControlCenterSetupViewModel extends ChangeNotifier {
  ControlCenterSetupStore? _store;

  ControlCenterSetupState _state = ControlCenterSetupState.initial();
  bool _initialized = false;
  bool _isPersisting = false;

  ControlCenterSetupViewModel({ControlCenterSetupStore? store})
    : _store = store;

  ControlCenterSetupState get uiState => _state;
  bool get isInitialized => _initialized;
  bool get isPersisting => _isPersisting;

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _store ??= await ControlCenterSetupStore.create();
    final config = await _store!.load();
    _state = config.toState(startStep: SetupStep.emptyCenter).copyWith(
      currentStep: SetupStep.emptyCenter,
      hasCompletedSetup: config.setupCompleted,
    );
    _initialized = true;
    notifyListeners();
  }

  void addModule(MainModule module) {
    if (!_initialized) return;
    final item = ControlCenterModuleItem(module);
    if (_state.containsItemId(item.id)) return;
    if (_state.remainingSlots <= 0) return;

    final nextModules = [..._state.selectedModules, item];
    _state = _state.copyWith(selectedModules: nextModules);
    notifyListeners();
  }

  void addShortcut(ControlShortcut shortcut) {
    if (!_initialized) return;
    final item = ControlCenterShortcutItem(shortcut);
    if (_state.containsItemId(item.id)) return;
    if (_state.remainingSlots <= 0) return;

    final nextShortcuts = [..._state.selectedShortcuts, item];
    _state = _state.copyWith(selectedShortcuts: nextShortcuts);
    notifyListeners();
  }

  void removeItem(String itemId) {
    if (!_initialized) return;
    final nextModules = _state.selectedModules
        .where((item) => item.id != itemId)
        .toList(growable: false);
    final nextShortcuts = _state.selectedShortcuts
        .where((item) => item.id != itemId)
        .toList(growable: false);
    if (nextModules.length == _state.selectedModules.length &&
        nextShortcuts.length == _state.selectedShortcuts.length) {
      return;
    }
    _state = _state.copyWith(
      selectedModules: nextModules,
      selectedShortcuts: nextShortcuts,
    );
    notifyListeners();
  }

  void toggleDashboardWidget(DashboardWidget widget) {
    if (!_initialized) return;
    final next = Set<DashboardWidget>.from(_state.enabledDashboardWidgets);
    if (next.contains(widget)) {
      next.remove(widget);
    } else {
      next.add(widget);
    }
    _state = _state.copyWith(enabledDashboardWidgets: next);
    notifyListeners();
  }

  void goBack() {
    if (!_initialized) return;
    final step = _state.currentStep;
    final previous = _previousStep(step);
    _state = _state.copyWith(currentStep: previous);
    notifyListeners();
  }

  void goNext() {
    if (!_initialized) return;
    final step = _state.currentStep;
    final next = _nextStep(step);
    _state = _state.copyWith(currentStep: next);
    notifyListeners();
  }

  Future<void> completeSetup() async {
    if (!_initialized) return;
    if (_isPersisting) return;
    _isPersisting = true;
    notifyListeners();
    try {
      _state = _state.copyWith(hasCompletedSetup: true);
      final config = ControlCenterConfiguration.fromState(_state);
      await _store!.save(config);
    } finally {
      _isPersisting = false;
      notifyListeners();
    }
  }

  SetupStep _nextStep(SetupStep step) {
    switch (step) {
      case SetupStep.emptyCenter:
        return SetupStep.modulePicker;
      case SetupStep.modulePicker:
        return SetupStep.moduleConfirmation;
      case SetupStep.moduleConfirmation:
        return _state.remainingSlots > 0
            ? SetupStep.shortcutPicker
            : SetupStep.dashboardIntro;
      case SetupStep.shortcutPicker:
        return SetupStep.dashboardIntro;
      case SetupStep.dashboardIntro:
        return SetupStep.dashboardWidgets;
      case SetupStep.dashboardWidgets:
        return SetupStep.finalPreview;
      case SetupStep.finalPreview:
        return SetupStep.permissions;
      case SetupStep.permissions:
        return SetupStep.permissions;
    }
  }

  SetupStep _previousStep(SetupStep step) {
    switch (step) {
      case SetupStep.emptyCenter:
        return SetupStep.emptyCenter;
      case SetupStep.modulePicker:
        return SetupStep.emptyCenter;
      case SetupStep.moduleConfirmation:
        return SetupStep.modulePicker;
      case SetupStep.shortcutPicker:
        return SetupStep.moduleConfirmation;
      case SetupStep.dashboardIntro:
        return _state.remainingSlots > 0
            ? SetupStep.shortcutPicker
            : SetupStep.moduleConfirmation;
      case SetupStep.dashboardWidgets:
        return SetupStep.dashboardIntro;
      case SetupStep.finalPreview:
        return SetupStep.dashboardWidgets;
      case SetupStep.permissions:
        return SetupStep.finalPreview;
    }
  }
}
