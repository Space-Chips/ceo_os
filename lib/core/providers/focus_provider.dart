import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_time/screen_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/block_list_model.dart';
import '../models/premium_models.dart';
import '../repositories/focus_repository.dart';
import '../repositories/premium_repository.dart';
import '../services/focus_service.dart';

enum FocusState {
  idle,
  focusing,
  shortBreak,
  longBreak,
  requestingBreak,
  breakOptionsMenu,
}

class FocusProvider extends ChangeNotifier {
  final FocusService _focusService = FocusService();
  final FocusRepository _repository = FocusRepository();
  final PremiumRepository _premiumRepository = PremiumRepository();
  final ScreenTime _screenTime = ScreenTime();

  int focusDurationMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;
  bool autoStartBreaks = true;

  FocusState _state = FocusState.idle;
  int _remainingSeconds = 25 * 60;
  int _completedSessions = 0;
  int _waitRemainingSeconds = 0;
  Timer? _timer;
  Timer? _waitTimer;
  DateTime? _sessionStartTime;

  bool _isFocusModeActive = false;
  bool _isAuthorized = false;
  FocusProtectionStatus _protectionStatus = FocusProtectionStatus.unknown;
  String? _lastBlockingSyncError;

  String? sessionTitle;
  String? linkedTaskId;

  List<BlockList> _blockLists = [];
  String? _activeBlockListId;

  int _totalFocusMinutesToday = 0;
  double _screenTimeToday = 0;
  final List<double> _hourlyUsage = List.filled(24, 0);
  PremiumCheckResult? _lastPremiumCheck;

  FocusState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get completedSessions => _completedSessions;
  bool get isRunning => _timer?.isActive == true;
  bool get isFocusModeActive => _isFocusModeActive;
  bool get isAuthorized => _isAuthorized;
  FocusProtectionStatus get protectionStatus => _protectionStatus;
  List<BlockList> get blockLists => List.unmodifiable(_blockLists);
  String? get activeBlockListId => _activeBlockListId;
  int get totalFocusMinutesToday => _totalFocusMinutesToday;
  double get screenTimeToday => _screenTimeToday;
  List<double> get hourlyUsage => List.unmodifiable(_hourlyUsage);
  PremiumCheckResult? get lastPremiumCheck => _lastPremiumCheck;
  String? get lastBlockingSyncError => _lastBlockingSyncError;
  bool get hasConfiguredBlockingTargets =>
      configuredBlockedAppCount + configuredBlockedWebsiteCount > 0;

  int get configuredBlockedAppCount {
    final active = _activeBlockList;
    if (active == null) return 0;
    return active.blockedPackageNames.length + active.blockedCategories.length;
  }

  int get configuredBlockedWebsiteCount => _activeBlockList?.adultBlocking == true ? 1 : 0;

  bool get shouldShowPreparationFlowBeforeFocus => false;

  double get progress {
    final total = _totalDurationSeconds;
    if (total <= 0) return 0;
    return 1 - (_remainingSeconds / total);
  }

  String get timerDisplay => _formatClock(_remainingSeconds);
  String get waitTimerDisplay => _formatClock(_waitRemainingSeconds);

  String get stateLabel {
    switch (_state) {
      case FocusState.idle:
        return 'System Idle';
      case FocusState.focusing:
        return 'Deep Focus Active';
      case FocusState.shortBreak:
        return 'Short Break';
      case FocusState.longBreak:
        return 'Long Break';
      case FocusState.requestingBreak:
        return 'Analyzing Request';
      case FocusState.breakOptionsMenu:
        return 'Break Options';
    }
  }

  int get _totalDurationSeconds {
    switch (_state) {
      case FocusState.shortBreak:
        return shortBreakMinutes * 60;
      case FocusState.longBreak:
        return longBreakMinutes * 60;
      case FocusState.idle:
      case FocusState.focusing:
      case FocusState.requestingBreak:
      case FocusState.breakOptionsMenu:
        return focusDurationMinutes * 60;
    }
  }

  BlockList? get _activeBlockList {
    if (_blockLists.isEmpty) return null;
    return _blockLists.firstWhere(
      (list) => list.id == _activeBlockListId,
      orElse: () => _blockLists.first,
    );
  }

  void toggleAutoStartBreaks() {
    autoStartBreaks = !autoStartBreaks;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _blockLists = await _repository.getBlockLists();
    final activeInDb = _blockLists.where((list) => list.isActive).toList();
    if (activeInDb.isNotEmpty) {
      _activeBlockListId = activeInDb.first.id;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _activeBlockListId = prefs.getString('active_block_list_id');
    }
    if (_blockLists.isNotEmpty &&
        (_activeBlockListId == null ||
            !_blockLists.any((list) => list.id == _activeBlockListId))) {
      _activeBlockListId = _blockLists.first.id;
    }
    await refreshProtectionStatus();
    await refreshScreenTime();
    notifyListeners();
  }

  Future<void> refreshProtectionStatus() async {
    _protectionStatus = await _focusService.getProtectionStatus();
    _isAuthorized = _protectionStatus.isAuthorized;
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    final granted = await _focusService.requestPermissions();
    await refreshProtectionStatus();
    if (granted) _isAuthorized = true;
    notifyListeners();
    return _isAuthorized || granted;
  }

  Future<AndroidProtectionStep> getNextAndroidProtectionStep() {
    return _focusService.getNextAndroidProtectionStep();
  }

  Future<bool> openSystemSettings() => _focusService.openSystemSettings();

  Future<void> persistPreparationOutcome(dynamic outcome) async {}

  Future<void> refreshScreenTime() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final usage = await _screenTime.appUsageData(
        startTime: startOfDay,
        endTime: now,
      );
      _screenTimeToday = usage.fold<double>(
        0,
        (sum, app) => sum + (app.usageTime?.inMinutes ?? 0),
      );
    } on MissingPluginException {
      _screenTimeToday = 0;
    } catch (_) {
      _screenTimeToday = 0;
    }
    notifyListeners();
  }

  Future<bool> startFocus() async {
    final premiumCheck =
        await _premiumRepository.canStartFocusSession(focusDurationMinutes);
    _lastPremiumCheck = premiumCheck;
    if (!premiumCheck.allowed) {
      notifyListeners();
      return false;
    }

    _state = FocusState.focusing;
    _remainingSeconds = focusDurationMinutes * 60;
    _sessionStartTime = DateTime.now();
    _isFocusModeActive = true;
    _lastBlockingSyncError = null;
    await _syncToNative();
    _startTimer();
    notifyListeners();
    return true;
  }

  void stopFocus() {
    if (_state == FocusState.focusing && _sessionStartTime != null) {
      final minutes = DateTime.now().difference(_sessionStartTime!).inMinutes;
      _totalFocusMinutesToday += minutes.clamp(0, focusDurationMinutes);
    }
    reset();
  }

  void requestBreak() {
    if (_state != FocusState.focusing) return;
    _state = FocusState.requestingBreak;
    _waitRemainingSeconds = 10;
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _waitRemainingSeconds -= 1;
      if (_waitRemainingSeconds <= 0) {
        timer.cancel();
        _state = FocusState.breakOptionsMenu;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelBreakRequest() {
    _waitTimer?.cancel();
    _waitRemainingSeconds = 0;
    if (_state == FocusState.requestingBreak) _state = FocusState.focusing;
    notifyListeners();
  }

  void takeCustomBreak(int minutes) {
    _waitTimer?.cancel();
    _state = FocusState.shortBreak;
    _remainingSeconds = minutes * 60;
    _startTimer();
    notifyListeners();
  }

  void skip() {
    _state = FocusState.focusing;
    _remainingSeconds = focusDurationMinutes * 60;
    _startTimer();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _waitTimer?.cancel();
    _timer = null;
    _waitTimer = null;
    _state = FocusState.idle;
    _remainingSeconds = focusDurationMinutes * 60;
    _waitRemainingSeconds = 0;
    _isFocusModeActive = false;
    _sessionStartTime = null;
    unawaited(_focusService.stopShield());
    notifyListeners();
  }

  Future<void> saveBlockList(BlockList list) async {
    await _repository.saveBlockList(list);
    final index = _blockLists.indexWhere((entry) => entry.id == list.id);
    if (index >= 0) {
      _blockLists[index] = list;
    } else {
      _blockLists.add(list);
    }
    if (_activeBlockListId == null || list.isActive) {
      await setActiveBlockList(list.id);
    }
    notifyListeners();
  }

  Future<void> setActiveBlockList(String id) async {
    _activeBlockListId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_block_list_id', id);
    _blockLists = _blockLists
        .map(
          (list) => BlockList(
            id: list.id,
            name: list.name,
            adultBlocking: list.adultBlocking,
            blockedPackageNames: list.blockedPackageNames,
            blockedCategories: list.blockedCategories,
            isActive: list.id == id,
          ),
        )
        .toList();
    await _syncToNative();
    notifyListeners();
  }

  Future<void> deleteBlockList(String id) async {
    await _repository.deleteBlockList(id);
    _blockLists.removeWhere((list) => list.id == id);
    if (_activeBlockListId == id) {
      _activeBlockListId = _blockLists.isEmpty ? null : _blockLists.first.id;
    }
    notifyListeners();
  }

  Future<void> syncPlannedFocusSessions(
    List<Map<String, dynamic>> sessions,
  ) async {
    await _focusService.syncPlannedSessions(sessions);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds -= 1;
      } else {
        timer.cancel();
        _onTimerComplete();
      }
      notifyListeners();
    });
  }

  void _onTimerComplete() {
    if (_state == FocusState.focusing) {
      _completedSessions += 1;
      _totalFocusMinutesToday += focusDurationMinutes;
      if (autoStartBreaks) {
        _state = _completedSessions % sessionsBeforeLongBreak == 0
            ? FocusState.longBreak
            : FocusState.shortBreak;
        _remainingSeconds =
            (_state == FocusState.longBreak ? longBreakMinutes : shortBreakMinutes) *
                60;
        _startTimer();
      } else {
        reset();
      }
    } else {
      _state = FocusState.idle;
      _remainingSeconds = focusDurationMinutes * 60;
      _isFocusModeActive = false;
    }
  }

  Future<void> _syncToNative() async {
    final active = _activeBlockList;
    if (active == null) return;
    try {
      await _focusService.startShield(
        active.blockedPackageNames,
        active.blockedCategories,
      );
    } catch (error) {
      _lastBlockingSyncError = error.toString();
    }
  }

  String _formatClock(int seconds) {
    final clamped = seconds.clamp(0, 24 * 60 * 60);
    final minutes = (clamped ~/ 60).toString().padLeft(2, '0');
    final secs = (clamped % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
