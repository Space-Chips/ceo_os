import 'dart:async';
import 'package:flutter/material.dart';

/// Focus/Pomodoro session state.
enum FocusState { 
  idle, 
  focusing, 
  shortBreak, 
  longBreak, 
  requestingBreak, // Waiting period before break options
  breakOptionsMenu // The menu with 5-15 min break or cancel blocking
}

/// A blocked app entry (mock).
class BlockedApp {
  final String name;
  final IconData icon;
  bool isBlocked;

  BlockedApp({required this.name, required this.icon, this.isBlocked = true});
}

/// Pomodoro + Focus mode state manager.
class FocusProvider extends ChangeNotifier {
  // ── Pomodoro Settings ──
  int focusDurationMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;
  bool autoStartBreaks = true;

  void toggleAutoStartBreaks() {
    autoStartBreaks = !autoStartBreaks;
    notifyListeners();
  }

  // ── Timer State ──
  FocusState _state = FocusState.idle;
  int _remainingSeconds = 25 * 60;
  int _completedSessions = 0;
  Timer? _timer;

  // ── Break Request Logic ──
  final List<DateTime> _lastBreakAttempts = [];
  int _waitRemainingSeconds = 0;
  Timer? _waitTimer;

  // ── Focus Mode (Opal-like) ──
  bool _isFocusModeActive = false;
  final List<BlockedApp> _blockedApps = [];

  // ── Daily Stats ──
  int _totalFocusMinutesToday = 0;
  final List<double> _hourlyUsage = List.filled(24, 0); // mock screen time data

  // ── Getters ──
  FocusState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get waitRemainingSeconds => _waitRemainingSeconds;
  int get completedSessions => _completedSessions;
  bool get isRunning => _timer != null && _timer!.isActive;
  bool get isFocusModeActive => _isFocusModeActive;
  List<BlockedApp> get blockedApps => List.unmodifiable(_blockedApps);
  int get totalFocusMinutesToday => _totalFocusMinutesToday;
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
      case FocusState.idle:
        return 'System Idle';
      case FocusState.focusing:
        return 'Deep Focus Active';
      case FocusState.shortBreak:
        return 'Short Break';
      case FocusState.longBreak:
        return 'Long Break';
      case FocusState.requestingBreak:
        return 'Analyzing Request...';
      case FocusState.breakOptionsMenu:
        return 'Protocol Override';
    }
  }

  // ── Pomodoro Controls ──
  void startFocus() {
    _state = FocusState.focusing;
    _remainingSeconds = focusDurationMinutes * 60;
    _isFocusModeActive = true;
    _startTimer();
    notifyListeners();
  }

  // ── Break Request Logic (Opal style) ──
  void requestBreak() {
    if (_state != FocusState.focusing) return;
    
    // Calculate wait time based on attempts in last 2 hours
    final now = DateTime.now();
    
    // Defensive check for hot-reload initialization issues in Web
    try {
      _lastBreakAttempts.removeWhere((d) => now.difference(d).inHours >= 2);
    } catch (_) {
      // If it's undefined/null due to hot reload, re-initialize
    }
    
    // Formula: 5s base + 15s per previous attempt in last 2h
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
    _state = FocusState.shortBreak;
    _remainingSeconds = minutes * 60;
    _isFocusModeActive = false;
    _startTimer();
    notifyListeners();
  }

  void cancelBlocking() {
    _state = FocusState.idle;
    _isFocusModeActive = false;
    _timer?.cancel();
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_state != FocusState.idle) {
      _startTimer();
      notifyListeners();
    }
  }

  void reset() {
    _timer?.cancel();
    _waitTimer?.cancel();
    _state = FocusState.idle;
    _isFocusModeActive = false;
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
      _completedSessions++;
      _totalFocusMinutesToday += focusDurationMinutes;
      _isFocusModeActive = false;
      if (_completedSessions % sessionsBeforeLongBreak == 0) {
        _state = FocusState.longBreak;
        _remainingSeconds = longBreakMinutes * 60;
      } else {
        _state = FocusState.shortBreak;
        _remainingSeconds = shortBreakMinutes * 60;
      }
      if (autoStartBreaks) _startTimer();
    } else {
      _state = FocusState.focusing;
      _remainingSeconds = focusDurationMinutes * 60;
      _isFocusModeActive = true;
      _startTimer();
    }
    notifyListeners();
  }

  void toggleFocusMode() {
    if (_state == FocusState.idle) {
      _isFocusModeActive = !_isFocusModeActive;
    }
    notifyListeners();
  }

  void toggleBlockedApp(int index) {
    _blockedApps[index].isBlocked = !_blockedApps[index].isBlocked;
    notifyListeners();
  }

  void loadSampleData() {
    if (_blockedApps.isNotEmpty) return;
    _blockedApps.addAll([
      BlockedApp(name: 'TWITTER / X', icon: Icons.chat_bubble_outline),
      BlockedApp(name: 'INSTAGRAM', icon: Icons.camera_alt_outlined),
      BlockedApp(name: 'TIKTOK', icon: Icons.play_circle_outline),
      BlockedApp(name: 'YOUTUBE', icon: Icons.ondemand_video),
      BlockedApp(name: 'REDDIT', icon: Icons.forum_outlined),
      BlockedApp(name: 'DISCORD', icon: Icons.headset_mic_outlined, isBlocked: false),
    ]);
    final mockData = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 1.2, 2.5, 1.8, 0.8, 1.5, 2.0, 1.0, 0.5, 1.8, 3.2, 2.5, 1.5, 0.8, 0.3, 0.1, 0.0, 0.0];
    for (int i = 0; i < 24 && i < mockData.length; i++) {
      _hourlyUsage[i] = mockData[i];
    }
    _totalFocusMinutesToday = 95;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }
}