import 'dart:async';
import 'package:flutter/material.dart';

/// Focus/Pomodoro session state.
enum FocusState { idle, focusing, shortBreak, longBreak }

/// A blocked app entry (mock).
class BlockedApp {
  final String name;
  final IconData icon;
  bool isBlocked;

  BlockedApp({
    required this.name,
    required this.icon,
    this.isBlocked = true,
  });
}

/// Pomodoro + Focus mode state manager.
class FocusProvider extends ChangeNotifier {
  // ── Pomodoro Settings ──
  int focusDurationMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;

  // ── Timer State ──
  FocusState _state = FocusState.idle;
  int _remainingSeconds = 25 * 60;
  int _completedSessions = 0;
  Timer? _timer;

  // ── Focus Mode (Opal-like) ──
  bool _isFocusModeActive = false;
  final List<BlockedApp> _blockedApps = [];

  // ── Daily Stats ──
  int _totalFocusMinutesToday = 0;
  final List<double> _hourlyUsage = List.filled(24, 0); // mock screen time data

  // ── Getters ──
  FocusState get state => _state;
  int get remainingSeconds => _remainingSeconds;
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

  String get stateLabel {
    switch (_state) {
      case FocusState.idle:
        return 'Ready to Focus';
      case FocusState.focusing:
        return 'Deep Focus';
      case FocusState.shortBreak:
        return 'Short Break';
      case FocusState.longBreak:
        return 'Long Break';
    }
  }

  // ── Pomodoro Controls ──
  void startFocus() {
    _state = FocusState.focusing;
    _remainingSeconds = focusDurationMinutes * 60;
    _startTimer();
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
    _state = FocusState.idle;
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
        if (_state == FocusState.focusing) {
          // Track elapsed focus time
        }
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
      // Start break
      if (_completedSessions % sessionsBeforeLongBreak == 0) {
        _state = FocusState.longBreak;
        _remainingSeconds = longBreakMinutes * 60;
      } else {
        _state = FocusState.shortBreak;
        _remainingSeconds = shortBreakMinutes * 60;
      }
      _startTimer();
    } else {
      // Break is over, back to focus
      _state = FocusState.focusing;
      _remainingSeconds = focusDurationMinutes * 60;
      _startTimer();
    }
    notifyListeners();
  }

  // ── Focus Mode (Opal-like) ──
  void toggleFocusMode() {
    _isFocusModeActive = !_isFocusModeActive;
    notifyListeners();
  }

  void toggleBlockedApp(int index) {
    _blockedApps[index].isBlocked = !_blockedApps[index].isBlocked;
    notifyListeners();
  }

  void loadSampleData() {
    if (_blockedApps.isNotEmpty) return;
    _blockedApps.addAll([
      BlockedApp(name: 'Twitter / X', icon: Icons.chat_bubble_outline),
      BlockedApp(name: 'Instagram', icon: Icons.camera_alt_outlined),
      BlockedApp(name: 'TikTok', icon: Icons.play_circle_outline),
      BlockedApp(name: 'YouTube', icon: Icons.ondemand_video),
      BlockedApp(name: 'Reddit', icon: Icons.forum_outlined),
      BlockedApp(name: 'Discord', icon: Icons.headset_mic_outlined, isBlocked: false),
    ]);
    // Mock hourly usage data
    final mockData = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 1.2, 2.5, 1.8, 0.8, 1.5,
                      2.0, 1.0, 0.5, 1.8, 3.2, 2.5, 1.5, 0.8, 0.3, 0.1, 0.0, 0.0];
    for (int i = 0; i < 24 && i < mockData.length; i++) {
      _hourlyUsage[i] = mockData[i];
    }
    _totalFocusMinutesToday = 95;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
