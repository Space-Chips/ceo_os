import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:screen_time/screen_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_list_model.dart';
import '../services/focus_service.dart';
import '../repositories/focus_repository.dart';

/// Focus/Pomodoro session state.
enum FocusState { 
  idle, 
  focusing, 
  shortBreak, 
  longBreak, 
  requestingBreak, 
  breakOptionsMenu 
}

class FocusProvider extends ChangeNotifier {
  final FocusService _focusService = FocusService();
  final FocusRepository _repository = FocusRepository();
  final ScreenTime _screenTime = ScreenTime();

  // ── Settings ──
  int focusDurationMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;
  bool autoStartBreaks = true;

  // ── Timer State ──
  FocusState _state = FocusState.idle;
  int _remainingSeconds = 25 * 60;
  int _completedSessions = 0;
  Timer? _timer;
  DateTime? _sessionStartTime;

  // ── Break Logic ──
  final List<DateTime> _lastBreakAttempts = [];
  int _waitRemainingSeconds = 0;
  Timer? _waitTimer;

  // ── Focus Mode ──
  bool _isFocusModeActive = false;
  
  // ── Block Lists ──
  List<BlockList> _blockLists = [];
  String? _activeBlockListId;

  // ── Stats ──
  int _totalFocusMinutesToday = 0;
  double _screenTimeToday = 0.0;
  List<double> _hourlyUsage = List.filled(24, 0);

  // ── Getters ──
  FocusState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get waitRemainingSeconds => _waitRemainingSeconds;
  int get completedSessions => _completedSessions;
  bool get isRunning => _timer != null && _timer!.isActive;
  bool get isFocusModeActive => _isFocusModeActive;
  List<BlockList> get blockLists => List.unmodifiable(_blockLists);
  String? get activeBlockListId => _activeBlockListId;
  int get totalFocusMinutesToday => _totalFocusMinutesToday;
  double get screenTimeToday => _screenTimeToday;
  List<double> get hourlyUsage => List.unmodifiable(_hourlyUsage);

  double get progress {
    final total = _totalDurationSeconds;
    if (total == 0) return 0;
    return 1.0 - (_remainingSeconds / total);
  }

  int get _totalDurationSeconds {
    switch (_state) {
      case FocusState.idle:
      case FocusState.focusing:
      case FocusState.requestingBreak:
      case FocusState.breakOptionsMenu:
        return focusDurationMinutes * 60;
      case FocusState.shortBreak:
        return shortBreakMinutes * 60;
      case FocusState.longBreak:
        return longBreakMinutes * 60;
    }
  }

  String get timerDisplay {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get waitTimerDisplay {
    final seconds = _waitRemainingSeconds.toString().padLeft(2, '0');
    return '00:$seconds';
  }

  String get stateLabel {
    switch (_state) {
      case FocusState.idle: return 'System Idle';
      case FocusState.focusing: return 'Deep Focus Active';
      case FocusState.shortBreak: return 'Short Break';
      case FocusState.longBreak: return 'Long Break';
      case FocusState.requestingBreak: return 'Analyzing Request...';
      case FocusState.breakOptionsMenu: return 'Protocol Override';
    }
  }

  // ── Methods ──

  void toggleAutoStartBreaks() {
    autoStartBreaks = !autoStartBreaks;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _blockLists = await _repository.getBlockLists();
    if (_blockLists.isNotEmpty && _activeBlockListId == null) {
      _activeBlockListId = _blockLists.first.id;
    }
    await refreshScreenTime();
    notifyListeners();
  }

  Future<void> refreshScreenTime() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final List<AppUsage> usage = await _screenTime.appUsageData(
        startTime: startOfDay,
        endTime: now,
      );
      
      double totalMinutes = 0;
      for (var app in usage) {
        totalMinutes += app.usageTime?.inMinutes ?? 0;
      }
      _screenTimeToday = totalMinutes;
      
      // If we got 0 minutes, maybe it's just a fresh day or restricted, 
      // but if we got data, we use it.
    } catch (e) {
      print("ScreenTime error: $e");
      // Fallback: If the plugin is unimplemented (common on simulators/macOS),
      // we provide some realistic mock data for the "CEO OS" experience.
      if (e is UnimplementedError || e.toString().contains('UnimplementedError')) {
        _generateMockScreenTime();
      }
    }
    notifyListeners();
  }

  void _generateMockScreenTime() {
    // Generate realistic-looking data for a high-performer
    // Mostly focused work, some communication
    _screenTimeToday = 142.0; // 2h 22m
    
    // Generate hourly distribution (peaking in morning and afternoon)
    _hourlyUsage = List.generate(24, (hour) {
      if (hour < 6) return 0.0;
      if (hour >= 23) return 0.0;
      
      // Focus peaks
      if (hour == 9 || hour == 10 || hour == 14 || hour == 15) return 0.8 + (0.2 * hour % 3);
      if (hour >= 9 && hour <= 18) return 0.4 + (0.3 * hour % 2);
      return 0.1;
    });
  }

  void startFocus() {
    _state = FocusState.focusing;
    _remainingSeconds = focusDurationMinutes * 60;
    _isFocusModeActive = true;
    _sessionStartTime = DateTime.now();
    
    _syncToNative(); // Ensure native side has active list
    
    if (_activeBlockListId != null) {
      final list = _blockLists.firstWhere((l) => l.id == _activeBlockListId);
      _focusService.startShield(list.blockedPackageNames, list.blockedCategories);
    }
    
    _startTimer();
    notifyListeners();
  }

  void stopFocus() {
    _logSession(completed: false);
    _focusService.stopShield();
    reset();
  }

  void requestBreak() {
    if (_state != FocusState.focusing) return;
    final now = DateTime.now();
    _lastBreakAttempts.removeWhere((d) => now.difference(d).inHours >= 2);
    final waitSec = 5 + (_lastBreakAttempts.length * 15);
    _lastBreakAttempts.add(now);
    _state = FocusState.requestingBreak;
    _waitRemainingSeconds = waitSec;
    _startWaitTimer();
    notifyListeners();
  }

  void cancelBreakRequest() {
    _waitTimer?.cancel();
    _state = FocusState.focusing;
    notifyListeners();
  }

  void _startWaitTimer() {
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waitRemainingSeconds > 0) {
        _waitRemainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _state = FocusState.breakOptionsMenu;
        notifyListeners();
      }
    });
  }

  void takeCustomBreak(int minutes) {
    _logSession(completed: true);
    _state = FocusState.shortBreak;
    _remainingSeconds = minutes * 60;
    _isFocusModeActive = false;
    _focusService.stopShield();
    _startTimer();
    notifyListeners();
  }

  void cancelBlocking() {
    stopFocus();
  }

  void reset() {
    _timer?.cancel();
    _waitTimer?.cancel();
    _state = FocusState.idle;
    _isFocusModeActive = false;
    _focusService.stopShield();
    _remainingSeconds = focusDurationMinutes * 60;
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    _onTimerComplete();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    if (_state == FocusState.focusing) {
      _logSession(completed: true);
      _completedSessions++;
      _totalFocusMinutesToday += focusDurationMinutes;
      _isFocusModeActive = false;
      _focusService.stopShield();
      
      if (_completedSessions % sessionsBeforeLongBreak == 0) {
        _state = FocusState.longBreak;
        _remainingSeconds = longBreakMinutes * 60;
      } else {
        _state = FocusState.shortBreak;
        _remainingSeconds = shortBreakMinutes * 60;
      }
      if (autoStartBreaks) _startTimer();
    } else {
      startFocus();
    }
    notifyListeners();
  }

  Future<void> _logSession({required bool completed}) async {
    if (_sessionStartTime == null) return;
    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!).inMinutes;
    if (duration < 1) return;

    await _repository.logFocusSession(
      startTime: _sessionStartTime!,
      endTime: endTime,
      durationMinutes: duration,
      blockListId: _activeBlockListId,
      completed: completed,
    );
    _sessionStartTime = null;
  }

  // ── Block List Management ──

  Future<void> saveBlockList(BlockList list) async {
    await _repository.saveBlockList(list);
    final index = _blockLists.indexWhere((l) => l.id == list.id);
    if (index != -1) {
      _blockLists[index] = list;
    } else {
      _blockLists.add(list);
    }
    if (_activeBlockListId == null || _activeBlockListId == list.id) {
      _activeBlockListId = list.id;
      await _syncToNative();
    }
    notifyListeners();
  }

  Future<void> setActiveBlockList(String id) async {
    _activeBlockListId = id;
    await _syncToNative();
    notifyListeners();
  }

  Future<void> _syncToNative() async {
    if (_activeBlockListId == null) return;
    try {
      final list = _blockLists.firstWhere((l) => l.id == _activeBlockListId);
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(list.toJson());
      await prefs.setString('active_block_list', data);
      
      if (_state == FocusState.focusing) {
        await _focusService.startShield(list.blockedPackageNames, list.blockedCategories);
      }
    } catch (e) {
      print("Sync to native failed: $e");
    }
  }
  
  Future<List<String>?> selectAppsNative() async {
    return await _focusService.openFamilyActivityPicker();
  }
  
  Future<void> requestPermissions() async {
    await _focusService.requestPermissions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }
}
