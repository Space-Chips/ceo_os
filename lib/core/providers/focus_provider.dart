import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_list_model.dart';
import '../models/premium_models.dart';
import '../models/task_models.dart';
import '../repositories/feature_repository.dart';
import '../repositories/premium_repository.dart';
import '../services/classic_blocking_coordinator.dart';
import '../services/classic_blocking_local_store.dart';
import '../services/focus_service.dart';
import '../repositories/focus_repository.dart';
import '../services/stats_engine.dart';
import '../utils/app_logger.dart';
import '../utils/domain_utils.dart';

/// Focus/Pomodoro session state.
enum FocusState {
  idle,
  focusing,
  exitPending,
  shortBreak,
  longBreak,
  requestingBreak,
  breakOptionsMenu,
}

class _FocusShieldSnapshot {
  final List<String> selectors;
  final List<String> websiteDomains;
  final int blockedAppCount;
  final int blockedWebsiteCount;

  const _FocusShieldSnapshot({
    required this.selectors,
    required this.websiteDomains,
    required this.blockedAppCount,
    required this.blockedWebsiteCount,
  });

  bool get hasAnyTarget => blockedAppCount > 0 || blockedWebsiteCount > 0;
}

class FocusProvider extends ChangeNotifier {
  final FocusService _focusService = FocusService();
  final FocusRepository _repository = FocusRepository();
  final FeatureRepository _featureRepository = FeatureRepository();
  final PremiumRepository _premiumRepository = PremiumRepository();
  final ClassicBlockingLocalStore _classicLocalStore =
      ClassicBlockingLocalStore();
  final ClassicBlockingCoordinator _classicCoordinator =
      ClassicBlockingCoordinator();
  final StatsEngine _statsEngine = StatsEngine();

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
  DateTime? _focusExitReadyAt;
  DateTime? _breakRequestReadyAt;
  bool _focusShieldOverrideActive = false;
  bool _endingSession = false;
  String _focusPreparationStatus = 'not_seen';

  // ── Focus Mode ──
  bool _isFocusModeActive = false;
  bool _isAuthorized = false;
  FocusProtectionStatus _protectionStatus = FocusProtectionStatus.unknown;

  // ── Session Context ──
  String? sessionTitle;
  String? linkedTaskId;
  static const int _focusExitCountdownSeconds = 100;

  // ── Block Lists ──
  List<BlockList> _blockLists = [];
  String? _activeBlockListId;

  // ── Stats ──
  int _totalFocusMinutesToday = 0;
  double _screenTimeToday = 0.0;
  List<double> _hourlyUsage = List.filled(24, 0);
  PremiumCheckResult? _lastPremiumCheck;
  int _configuredBlockedAppCount = 0;
  int _configuredBlockedWebsiteCount = 0;
  String? _lastBlockingSyncError;

  // ── Getters ──
  FocusState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get completedSessions => _completedSessions;
  bool get isRunning => _timer != null && _timer!.isActive;
  bool get isFocusModeActive => _isFocusModeActive;
  bool get isAuthorized => _isAuthorized;
  FocusProtectionStatus get protectionStatus => _protectionStatus;
  List<BlockList> get blockLists => List.unmodifiable(_blockLists);
  String? get activeBlockListId => _activeBlockListId;
  int get totalFocusMinutesToday => _totalFocusMinutesToday;
  double get screenTimeToday => _screenTimeToday;
  List<double> get hourlyUsage => List.unmodifiable(_hourlyUsage);
  PremiumCheckResult? get lastPremiumCheck => _lastPremiumCheck;
  int get configuredBlockedAppCount => _configuredBlockedAppCount;
  int get configuredBlockedWebsiteCount => _configuredBlockedWebsiteCount;
  bool get hasConfiguredBlockingTargets =>
      configuredBlockedAppCount > 0 || configuredBlockedWebsiteCount > 0;
  String? get lastBlockingSyncError => _lastBlockingSyncError;
  bool get shouldShowPreparationFlowBeforeFocus =>
      _focusPreparationStatus == 'not_seen';
  String get waitTimerDisplay {
    final seconds = _breakRequestReadyAt == null
        ? 0
        : _breakRequestReadyAt!
              .difference(DateTime.now())
              .inSeconds
              .clamp(0, 999);
    return '${seconds.toString().padLeft(2, '0')}s';
  }

  int get exitCountdownRemainingSeconds {
    if (_state != FocusState.exitPending || _focusExitReadyAt == null) return 0;
    return _focusExitReadyAt!
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, _focusExitCountdownSeconds);
  }

  bool get canFinalizeEarlyExit =>
      _state == FocusState.exitPending && exitCountdownRemainingSeconds == 0;
  String get exitCountdownLabel {
    final seconds = exitCountdownRemainingSeconds.clamp(0, 999).toString();
    return '${seconds.padLeft(2, '0')}s';
  }

  double get progress {
    final total = _totalDurationSeconds;
    if (total == 0) return 0;
    return 1.0 - (_remainingSeconds / total);
  }

  int get _totalDurationSeconds {
    switch (_state) {
      case FocusState.idle:
      case FocusState.focusing:
      case FocusState.exitPending:
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

  String get stateLabel {
    switch (_state) {
      case FocusState.idle:
        return 'System Idle';
      case FocusState.focusing:
        return 'Deep Focus Active';
      case FocusState.exitPending:
        return 'Exit Countdown';
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

  // ── Methods ──

  void toggleAutoStartBreaks() {
    autoStartBreaks = !autoStartBreaks;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _blockLists = await _repository.getBlockLists();
    try {
      final prefs = await SharedPreferences.getInstance();
      _focusPreparationStatus =
          prefs.getString('focus_preparation_status_v1') ?? 'not_seen';
    } catch (_) {}
    await _refreshProtectionStatus();
    await _syncClassicBaselineFromBlockedAppsSites();
    await _refreshBlockingSummary();

    notifyListeners();
  }

  Future<void> refreshScreenTime() async {
    _screenTimeToday = 0;
    _hourlyUsage = List.filled(24, 0);
    notifyListeners();
  }

  Future<bool> startFocus() async {
    final premiumCheck = await _premiumRepository.canStartFocusSession(
      focusDurationMinutes,
    );
    _lastPremiumCheck = premiumCheck;
    if (!premiumCheck.allowed) {
      notifyListeners();
      return false;
    }

    // Check for authorization first
    await _refreshProtectionStatus();
    if (!_isAuthorized) {
      notifyListeners();
      // Continue even if unauthorized to allow the internal timer to run.
    }

    _state = FocusState.focusing;
    _remainingSeconds = focusDurationMinutes * 60;
    _isFocusModeActive = true;
    _sessionStartTime = DateTime.now();
    _focusExitReadyAt = null;
    await _applyFocusShieldOverrideFromBlockedAppsSites();

    _startTimer();
    unawaited(
      _statsEngine.recordFocusSessionStarted(
        plannedDurationMinutes: focusDurationMinutes,
        linkedTaskId: linkedTaskId,
      ),
    );
    notifyListeners();
    return true;
  }

  void stopFocus() {
    unawaited(_endSessionEarly());
  }

  Future<void> _endSessionEarly() async {
    if (_endingSession) return;
    _endingSession = true;
    _timer?.cancel();
    try {
      if (_sessionStartTime != null) {
        final elapsed = DateTime.now().difference(_sessionStartTime!).inMinutes;
        if (elapsed > 0) {
          unawaited(
            _statsEngine.recordFocusSessionBroken(elapsedMinutes: elapsed),
          );
        }
      }
      await _logSession(completed: false);
      await _resetAfterSession();
      notifyListeners();
    } finally {
      _endingSession = false;
    }
  }

  void requestEarlyExit() {
    if (_state != FocusState.focusing) return;
    _state = FocusState.exitPending;
    _focusExitReadyAt = DateTime.now().add(
      const Duration(seconds: _focusExitCountdownSeconds),
    );
    notifyListeners();
  }

  void returnToSession() {
    if (_state != FocusState.exitPending) return;
    _state = FocusState.focusing;
    _focusExitReadyAt = null;
    notifyListeners();
  }

  void requestBreak() {
    if (_state != FocusState.focusing) return;
    _state = FocusState.requestingBreak;
    _breakRequestReadyAt = DateTime.now().add(const Duration(seconds: 10));
    notifyListeners();
  }

  void cancelBreakRequest() {
    if (_state != FocusState.requestingBreak) return;
    _state = FocusState.focusing;
    _breakRequestReadyAt = null;
    notifyListeners();
  }

  void takeCustomBreak(int minutes) {
    if (_state != FocusState.requestingBreak &&
        _state != FocusState.breakOptionsMenu) {
      return;
    }
    _breakRequestReadyAt = null;
    _state = minutes >= longBreakMinutes
        ? FocusState.longBreak
        : FocusState.shortBreak;
    _remainingSeconds = minutes.clamp(1, 180) * 60;
    _startTimer();
    notifyListeners();
  }

  Future<void> persistPreparationOutcome(Object outcome) async {
    final serialized = outcome.toString().endsWith('.completed')
        ? 'completed'
        : 'skipped';
    if (_focusPreparationStatus == serialized) return;
    _focusPreparationStatus = serialized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('focus_preparation_status_v1', serialized);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> finalizeEarlyExit() async {
    if (!canFinalizeEarlyExit) return;
    await _endSessionEarly();
  }

  void cancelBlocking() {
    requestEarlyExit();
  }

  void reset() {
    _timer?.cancel();
    _state = FocusState.idle;
    _isFocusModeActive = false;
    _focusExitReadyAt = null;
    _remainingSeconds = focusDurationMinutes * 60;
    if (_focusShieldOverrideActive) {
      unawaited(_syncClassicBaselineFromBlockedAppsSites());
      _focusShieldOverrideActive = false;
    }
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    unawaited(_onTimerComplete());
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        unawaited(_onTimerComplete());
      }
    });
  }

  Future<void> _onTimerComplete() async {
    if (_endingSession) return;
    _endingSession = true;
    try {
      if (_state == FocusState.focusing || _state == FocusState.exitPending) {
        await _logSession(completed: true);
        _completedSessions++;
        _totalFocusMinutesToday += focusDurationMinutes;
        unawaited(
          _statsEngine.recordFocusSessionCompleted(
            durationMinutes: focusDurationMinutes,
            linkedTaskId: linkedTaskId,
          ),
        );
        unawaited(
          _statsEngine.recordProductiveTime(minutes: focusDurationMinutes),
        );
        await _resetAfterSession();
      } else {
        await _resetAfterSession();
      }
      notifyListeners();
    } finally {
      _endingSession = false;
    }
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
      blockListId: null,
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
      await setActiveBlockList(list.id);
    }
    notifyListeners();
  }

  Future<void> setActiveBlockList(String id) async {
    _activeBlockListId = id;
    await _repository.updateActiveBlockList(id);
    notifyListeners();
  }

  Future<List<String>?> selectAppsNative() async {
    return await _focusService.openFamilyActivityPicker();
  }

  Future<_FocusShieldSnapshot> _buildFocusShieldSnapshot() async {
    final blockedApps = await _featureRepository.getBlockedApps();
    final blockedWebsites = await _featureRepository.getBlockedWebsites();
    final appBindings = await _classicLocalStore.loadAppBindings();
    final websiteBindings = await _classicLocalStore.loadWebsiteBindings();

    final selectors = <String>{};
    final websiteDomains = <String>{};
    final unresolvedBlockedApps = <String>[];
    var appCount = 0;
    var websiteCount = 0;

    final legacyFallbackPackageIds = <String>{
      for (final list in _blockLists)
        if ((_activeBlockListId != null && list.id == _activeBlockListId) ||
            (_activeBlockListId == null && list.isActive))
          ...list.blockedPackageNames
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty),
    };

    for (final app in blockedApps) {
      final binding = appBindings[app.id];

      if (Platform.isIOS) {
        var payload = binding?.nativePayload?.trim();
        final bundleId = binding?.nativeIdentifier?.trim();
        if ((payload == null || payload.isEmpty) &&
            bundleId != null &&
            bundleId.isNotEmpty) {
          payload = await _focusService.encodeApplicationBundleSelection(
            bundleId,
          );
          if (payload != null && payload.trim().isNotEmpty) {
            payload = payload.trim();
            await _classicLocalStore.saveAppBinding(
              rowId: app.id,
              nativeIdentifier: bundleId,
              nativePayload: payload,
            );
          }
        }
        if (payload != null && payload.isNotEmpty) {
          selectors.add(payload);
          appCount++;
        } else {
          unresolvedBlockedApps.add(app.appName ?? 'Unknown app');
        }
      } else {
        final packageName = binding?.nativeIdentifier?.trim();
        if (packageName != null && packageName.isNotEmpty) {
          selectors.add(packageName);
          appCount++;
        } else {
          unresolvedBlockedApps.add(app.appName ?? 'Unknown app');
        }
      }
    }

    for (final packageId in legacyFallbackPackageIds) {
      if (Platform.isIOS) {
        final payload = await _focusService.encodeApplicationBundleSelection(
          packageId,
        );
        final cleaned = payload?.trim();
        if (cleaned != null && cleaned.isNotEmpty) {
          if (selectors.add(cleaned)) {
            appCount++;
          }
        }
      } else {
        if (selectors.add(packageId)) {
          appCount++;
        }
      }
    }

    if (unresolvedBlockedApps.isNotEmpty) {
      AppLogger.warning(
        'Focus shield could not resolve native identifiers for some restricted apps: '
        '${unresolvedBlockedApps.join(', ')}',
      );
    }

    for (final website in blockedWebsites) {
      final rawDomain = website.urlDomain?.trim();
      if (rawDomain == FeatureRepository.adultContentShieldMarker) {
        continue;
      }

      final binding = websiteBindings[website.id];
      final bindingDomain = binding?.nativeIdentifier?.trim();
      final normalizedDomain = normalizeDomainInput(
        bindingDomain?.isNotEmpty == true ? bindingDomain! : rawDomain,
      );
      final domain = normalizedDomain?.trim().toLowerCase();
      if (domain != null && domain.isNotEmpty) {
        websiteDomains.add(domain);
      }

      if (Platform.isIOS) {
        var payload = binding?.nativePayload?.trim();
        if ((payload == null || payload.isEmpty) &&
            domain != null &&
            domain.isNotEmpty) {
          payload = await _focusService.encodeWebsiteDomainSelection(domain);
          if (payload != null && payload.trim().isNotEmpty) {
            payload = payload.trim();
            await _classicLocalStore.saveWebsiteBinding(
              rowId: website.id,
              nativeIdentifier: domain,
              nativePayload: payload,
            );
          }
        }
        if (payload != null && payload.isNotEmpty) {
          selectors.add(payload);
        }
      }

      final enforceable = (Platform.isIOS)
          ? ((domain != null && domain.isNotEmpty) ||
                ((binding?.nativePayload?.trim().isNotEmpty ?? false)))
          : (domain != null && domain.isNotEmpty);
      if (enforceable) {
        websiteCount++;
      }
    }

    return _FocusShieldSnapshot(
      selectors: selectors.toList(growable: false),
      websiteDomains: websiteDomains.toList(growable: false),
      blockedAppCount: appCount,
      blockedWebsiteCount: websiteCount,
    );
  }

  Future<void> _refreshBlockingSummary() async {
    final snapshot = await _buildFocusShieldSnapshot();
    _configuredBlockedAppCount = snapshot.blockedAppCount;
    _configuredBlockedWebsiteCount = snapshot.blockedWebsiteCount;
  }

  Future<void> _applyFocusShieldOverrideFromBlockedAppsSites() async {
    try {
      final snapshot = await _buildFocusShieldSnapshot();
      _configuredBlockedAppCount = snapshot.blockedAppCount;
      _configuredBlockedWebsiteCount = snapshot.blockedWebsiteCount;
      if (!snapshot.hasAnyTarget) {
        _focusShieldOverrideActive = false;
        return;
      }
      await _focusService.syncClassicShieldConfig(
        snapshot.selectors,
        const [],
        websiteDomains: snapshot.websiteDomains,
      );
      await _focusService.setClassicShieldEnabled(true);
      _focusShieldOverrideActive = true;
    } catch (error) {
      _focusShieldOverrideActive = false;
      AppLogger.error('Failed to apply Focus Mode shield override.', error);
    }
  }

  Future<void> _syncClassicBaselineFromBlockedAppsSites() async {
    try {
      final apps = await _featureRepository.getBlockedApps();
      final websites = await _featureRepository.getBlockedWebsites();
      final filteredWebsites = websites
          .where(
            (site) =>
                (site.urlDomain ?? '').trim() !=
                FeatureRepository.adultContentShieldMarker,
          )
          .toList(growable: false);
      final restPeriods = await _featureRepository.getRestPeriods();
      await _classicCoordinator.syncNativeState(
        apps: apps,
        websites: filteredWebsites,
        restPeriods: restPeriods,
      );
    } catch (error) {
      AppLogger.error('Failed to restore baseline classic shielding.', error);
    }
  }

  Future<void> _resetAfterSession() async {
    _timer?.cancel();
    _state = FocusState.idle;
    _isFocusModeActive = false;
    _focusExitReadyAt = null;
    _remainingSeconds = focusDurationMinutes * 60;

    if (_focusShieldOverrideActive) {
      await _syncClassicBaselineFromBlockedAppsSites();
      _focusShieldOverrideActive = false;
    } else {
      await _refreshBlockingSummary();
    }
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

  Future<AndroidProtectionStep> getNextAndroidProtectionStep() {
    return _focusService.getNextAndroidProtectionStep();
  }

  Future<bool> openSystemSettings() async {
    return _focusService.openSystemSettings();
  }

  Future<void> _refreshProtectionStatus() async {
    _protectionStatus = await _focusService.getProtectionStatus();
    _isAuthorized = _protectionStatus.isAuthorized;
  }

  Future<void> syncPlannedFocusSessions(List<CalendarEvent> events) async {
    final deduped = <String, CalendarEvent>{};
    for (final event in events) {
      if ((event.sourceType ?? '').toLowerCase() != 'focus_plan') continue;
      if (event.eventDate == null || event.eventTime == null) continue;
      final rootId = event.id.split('::').first;
      final existing = deduped[rootId];
      if (existing == null) {
        deduped[rootId] = event;
        continue;
      }
      final existingDate = DateTime.tryParse(existing.eventDate ?? '');
      final newDate = DateTime.tryParse(event.eventDate ?? '');
      if (existingDate == null ||
          (newDate != null && newDate.isBefore(existingDate))) {
        deduped[rootId] = event;
      }
    }

    final payload = deduped.entries
        .map((entry) {
          final event = entry.value;
          return <String, dynamic>{
            'id': entry.key,
            'date': event.eventDate,
            'time': event.eventTime,
            'durationMinutes': event.durationMinutes ?? 45,
            'weekly': (event.recurrenceRule ?? '').toLowerCase().contains(
              'week',
            ),
            'title': event.title,
          };
        })
        .toList(growable: false);
    await _focusService.syncPlannedSessions(payload);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
