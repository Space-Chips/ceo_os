import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/premium_models.dart';
import '../repositories/ceo_mode_repository.dart';
import '../repositories/premium_repository.dart';
import '../services/focus_service.dart';
import '../services/live_activity_service.dart';
import '../services/stats_engine.dart';
import '../../features/ceo_mode/blackout_preparation/blackout_preparation_models.dart';
import 'package:flutter/widgets.dart';

enum CeoModeState { idle, active, exitPending }

class CeoModeProvider extends ChangeNotifier with WidgetsBindingObserver {
  CeoModeProvider({
    CeoModeRepository? ceoModeRepository,
    FocusService? focusService,
    PremiumRepository? premiumRepository,
  }) : _ceoModeRepository = ceoModeRepository ?? CeoModeRepository(),
       _focusService = focusService ?? FocusService(),
       _premiumRepository = premiumRepository ?? PremiumRepository() {
    Future.microtask(initialize);
  }

  final CeoModeRepository _ceoModeRepository;
  final FocusService _focusService;
  final PremiumRepository _premiumRepository;
  final StatsEngine _statsEngine = StatsEngine();

  static const List<String> approvedApps = [];
  static const int _defaultDurationMinutes = 30;
  static const int _exitDelayMinutes = 10;

  static const String _prefsState = 'ceo_mode_state';
  static const String _prefsSessionId = 'ceo_mode_session_id';
  static const String _prefsSelectedDuration = 'ceo_mode_selected_duration';
  static const String _prefsStartAtMs = 'ceo_mode_start_at_ms';
  static const String _prefsEndAtMs = 'ceo_mode_end_at_ms';
  static const String _prefsExitReadyAtMs = 'ceo_mode_exit_ready_at_ms';
  static const String _prefsPreparationStatus = 'ceo_mode_preparation_status';

  Timer? _ticker;
  bool _initialized = false;
  bool _busy = false;
  bool _ending = false;
  bool _isAuthorized = false;
  FocusProtectionStatus _protectionStatus = FocusProtectionStatus.unknown;

  CeoModeState _state = CeoModeState.idle;
  int _selectedDurationMinutes = _defaultDurationMinutes;
  DateTime? _sessionStartAt;
  DateTime? _sessionEndAt;
  DateTime? _exitReadyAt;
  String? _sessionId;
  PremiumCheckResult? _lastPremiumCheck;
  String? _lastStartIssue;
  BlackoutPreparationStatus _preparationStatus =
      BlackoutPreparationStatus.notSeen;

  CeoModeState get state => _state;
  bool get isBusy => _busy;
  bool get isInitialized => _initialized;
  bool get isAuthorized => _isAuthorized;
  FocusProtectionStatus get protectionStatus => _protectionStatus;
  bool get isSessionActive => _state != CeoModeState.idle;
  bool get isExitPending => _state == CeoModeState.exitPending;
  int get selectedDurationMinutes => _selectedDurationMinutes;
  PremiumCheckResult? get lastPremiumCheck => _lastPremiumCheck;
  String? get lastStartIssue => _lastStartIssue;
  BlackoutPreparationStatus get preparationStatus => _preparationStatus;
  bool get shouldShowPreparationFlowBeforeBlackout =>
      _preparationStatus == BlackoutPreparationStatus.notSeen;

  int get sessionRemainingSeconds {
    if (_sessionEndAt == null) return 0;
    return _sessionEndAt!.difference(DateTime.now()).inSeconds.clamp(0, 86400);
  }

  int get exitCountdownRemainingSeconds {
    if (_state != CeoModeState.exitPending || _exitReadyAt == null) return 0;
    return _exitReadyAt!.difference(DateTime.now()).inSeconds.clamp(0, 36000);
  }

  bool get canFinalizeExit =>
      _state == CeoModeState.exitPending && exitCountdownRemainingSeconds == 0;

  String get sessionTimerLabel => _formatClock(sessionRemainingSeconds);
  String get exitCountdownLabel => _formatClock(exitCountdownRemainingSeconds);

  String get homeCardLabel {
    if (_state == CeoModeState.exitPending) {
      return 'EXIT WINDOW ${_formatClock(exitCountdownRemainingSeconds)}';
    }
    if (_state == CeoModeState.active) {
      return 'IN SESSION ${_formatClock(sessionRemainingSeconds)}';
    }
    return 'MAXIMUM FOCUS';
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    await _restoreFromPrefs();
    await _refreshProtectionStatus();
    _ensureTicker();
    notifyListeners();
  }

  void setDuration(int minutes) {
    if (_state != CeoModeState.idle) return;
    if (minutes <= 0) return;
    _selectedDurationMinutes = minutes;
    unawaited(_persistState());
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    await _focusService.requestPermissions();
    await _refreshProtectionStatus();
    notifyListeners();
    return _isAuthorized;
  }

  Future<void> refreshProtectionStatus() async {
    await _refreshProtectionStatus();
    notifyListeners();
  }

  Future<void> persistPreparationOutcome(
    BlackoutPreparationFlowOutcome outcome,
  ) async {
    final next = outcome == BlackoutPreparationFlowOutcome.completed
        ? BlackoutPreparationStatus.completed
        : BlackoutPreparationStatus.skipped;
    if (_preparationStatus == next) return;
    _preparationStatus = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPreparationStatus, next.storageValue);
    notifyListeners();
  }

  Future<AndroidProtectionStep> getNextAndroidProtectionStep() {
    return _focusService.getNextAndroidProtectionStep();
  }

  Future<bool> openSystemSettings() async {
    return _focusService.openSystemSettings();
  }

  Future<bool> startSession() async {
    if (_state != CeoModeState.idle || _busy) return false;

    _busy = true;
    _lastStartIssue = null;
    notifyListeners();

    try {
      final premiumCheck = await _premiumRepository.canStartCeoSession(
        _selectedDurationMinutes,
      );
      _lastPremiumCheck = premiumCheck;
      if (!premiumCheck.allowed) {
        return false;
      }

      await _refreshProtectionStatus();
      if (!_isAuthorized) {
        await requestPermissions();
      }
      if (!_isAuthorized) {
        _lastStartIssue = _protectionStatus.isSupported
            ? (_protectionStatus.shouldOpenSettings
                  ? 'permissions_denied'
                  : 'permissions')
            : 'unsupported';
        return false;
      }

      final now = DateTime.now();
      _sessionStartAt = now;
      _sessionEndAt = now.add(Duration(minutes: _selectedDurationMinutes));
      _exitReadyAt = null;
      _state = CeoModeState.active;

      final shieldingApplied = await _activateShielding();
      if (!shieldingApplied) {
        _lastStartIssue = 'activation_failed';
        _state = CeoModeState.idle;
        _sessionStartAt = null;
        _sessionEndAt = null;
        _exitReadyAt = null;
        return false;
      }

      _sessionId = await _ceoModeRepository.createSession(
        startTime: now,
        durationMinutes: _selectedDurationMinutes,
        approvedAppsCount: approvedApps.length,
      );
      unawaited(
        _statsEngine.recordCeoSessionStarted(
          plannedDurationMinutes: _selectedDurationMinutes,
        ),
      );

      await _persistState();
      _ensureTicker();
      unawaited(
        LiveActivityService.instance.start(
          session: LiveActivitySession.blackout,
          title: 'Blackout',
          startAt: now,
          endAt: _sessionEndAt!,
        ),
      );
      return true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void requestExit() {
    if (_state == CeoModeState.idle) return;
    _state = CeoModeState.exitPending;
    _exitReadyAt = DateTime.now().add(
      const Duration(minutes: _exitDelayMinutes),
    );
    unawaited(_persistState());
    notifyListeners();
  }

  void returnToSession() {
    if (_state != CeoModeState.exitPending) return;
    _state = CeoModeState.active;
    _exitReadyAt = null;
    unawaited(_persistState());
    notifyListeners();
  }

  Future<bool> finalizeExit() async {
    if (!canFinalizeExit || _ending) return false;
    await _endSession(completed: false);
    return true;
  }

  Future<bool> _activateShielding() async {
    return _focusService.startCeoShield();
  }

  Future<void> _refreshProtectionStatus() async {
    _protectionStatus = await _focusService.getProtectionStatus();
    _isAuthorized = _protectionStatus.isAuthorized;
  }

  void _ensureTicker() {
    _ticker?.cancel();
    if (!isSessionActive) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
  }

  void _onTick() {
    if (!isSessionActive) {
      _ticker?.cancel();
      return;
    }

    if (sessionRemainingSeconds <= 0) {
      unawaited(_endSession(completed: true));
      return;
    }
    notifyListeners();
  }

  Future<void> _endSession({required bool completed}) async {
    if (_ending) return;
    _ending = true;
    final endedAt = DateTime.now();
    final sessionId = _sessionId;

    try {
      await _focusService.stopShield();

      if (sessionId != null) {
        await _ceoModeRepository.endSession(
          sessionId: sessionId,
          endTime: endedAt,
        );
      }
      final startedAt = _sessionStartAt;
      if (startedAt != null) {
        final elapsed = endedAt
            .difference(startedAt)
            .inMinutes
            .clamp(0, 24 * 60);
        if (completed) {
          unawaited(
            _statsEngine.recordCeoSessionCompleted(durationMinutes: elapsed),
          );
          unawaited(_statsEngine.recordProductiveTime(minutes: elapsed));
        } else {
          unawaited(
            _statsEngine.recordCeoSessionBroken(elapsedMinutes: elapsed),
          );
        }
      }

      _state = CeoModeState.idle;
      _sessionStartAt = null;
      _sessionEndAt = null;
      _exitReadyAt = null;
      _sessionId = null;
      _ticker?.cancel();
      unawaited(
        LiveActivityService.instance.end(LiveActivitySession.blackout),
      );
      _ticker = null;
      await _clearPersistedState();
    } finally {
      _ending = false;
      notifyListeners();
    }
  }

  Future<void> _restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedDurationMinutes =
        prefs.getInt(_prefsSelectedDuration) ?? _defaultDurationMinutes;
    _preparationStatus = BlackoutPreparationStatus.fromStorage(
      prefs.getString(_prefsPreparationStatus),
    );

    final rawState = prefs.getString(_prefsState);
    final startAtMs = prefs.getInt(_prefsStartAtMs);
    final endAtMs = prefs.getInt(_prefsEndAtMs);
    final exitReadyAtMs = prefs.getInt(_prefsExitReadyAtMs);
    final sessionId = prefs.getString(_prefsSessionId);

    if (rawState == null || rawState == CeoModeState.idle.name) {
      return;
    }

    final restoredStart = startAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(startAtMs);
    final restoredEnd = endAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(endAtMs);
    final restoredExitReadyAt = exitReadyAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(exitReadyAtMs);

    if (restoredStart == null || restoredEnd == null) {
      await _clearPersistedState();
      return;
    }

    final now = DateTime.now();
    if (!restoredEnd.isAfter(now)) {
      if (sessionId != null) {
        await _ceoModeRepository.endSession(
          sessionId: sessionId,
          endTime: restoredEnd,
        );
      }
      await _clearPersistedState();
      return;
    }

    _state = rawState == CeoModeState.exitPending.name
        ? CeoModeState.exitPending
        : CeoModeState.active;
    _sessionStartAt = restoredStart;
    _sessionEndAt = restoredEnd;
    _exitReadyAt = _state == CeoModeState.exitPending
        ? (restoredExitReadyAt ??
              now.add(const Duration(minutes: _exitDelayMinutes)))
        : null;
    _sessionId = sessionId;
    unawaited(
      LiveActivityService.instance.start(
        session: LiveActivitySession.blackout,
        title: 'Blackout',
        startAt: restoredStart,
        endAt: restoredEnd,
      ),
    );
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsSelectedDuration, _selectedDurationMinutes);
    await prefs.setString(_prefsState, _state.name);

    if (_sessionId != null) {
      await prefs.setString(_prefsSessionId, _sessionId!);
    } else {
      await prefs.remove(_prefsSessionId);
    }

    if (_sessionStartAt != null) {
      await prefs.setInt(
        _prefsStartAtMs,
        _sessionStartAt!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_prefsStartAtMs);
    }

    if (_sessionEndAt != null) {
      await prefs.setInt(_prefsEndAtMs, _sessionEndAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_prefsEndAtMs);
    }

    if (_exitReadyAt != null) {
      await prefs.setInt(
        _prefsExitReadyAtMs,
        _exitReadyAt!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_prefsExitReadyAtMs);
    }
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsSelectedDuration, _selectedDurationMinutes);
    await prefs.setString(_prefsState, CeoModeState.idle.name);
    await prefs.remove(_prefsSessionId);
    await prefs.remove(_prefsStartAtMs);
    await prefs.remove(_prefsEndAtMs);
    await prefs.remove(_prefsExitReadyAtMs);
  }

  String _formatClock(int totalSeconds) {
    final secs = totalSeconds.clamp(0, 99 * 3600);
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isSessionActive) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_state == CeoModeState.exitPending) {
        _exitReadyAt = DateTime.now().add(
          const Duration(minutes: _exitDelayMinutes),
        );
        unawaited(_persistState());
        notifyListeners();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(refreshProtectionStatus());
      if (sessionRemainingSeconds <= 0) {
        unawaited(_endSession(completed: true));
      } else {
        _ensureTicker();
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}
