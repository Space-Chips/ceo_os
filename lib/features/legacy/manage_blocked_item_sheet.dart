import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../../components/blocked_token_views.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Bottom sheet shown when the user taps a blocked app or website tile,
/// OR opened automatically right after the user adds a new entry (so they
/// pick the daily duration immediately — see [isInitialSetup]).
///
/// Design intent (per UX brief):
///   * Tightening the daily limit (smaller value) = zero friction. Being
///     stricter with yourself is always cheap.
///   * Loosening the daily limit (bigger value) = **20-second hold-to-
///     confirm countdown** + an explicit destructive confirmation.
///     Loosening usually happens in moments of weakness; the friction is
///     here to give the user time to reconsider.
///   * Removing the entry from the block list entirely = same friction.
///   * On the very first save right after the user adds the entry
///     ([isInitialSetup] = true) there is **no friction** in either
///     direction — the user is literally choosing the starting value, not
///     undoing a past commitment to themselves.
class ManageBlockedItemSheet extends StatefulWidget {
  final String itemId;
  final String fallbackTitle;
  final String? nativePayload; // null on Android or for legacy entries
  final int currentDailyLimitMinutes; // 0 = always blocked
  final bool isWebsite;
  final bool isInitialSetup; // true → auto-opened right after add, skip friction
  final Future<void> Function(int minutes)? onSetDailyLimit;
  final Future<void> Function() onRemove;

  /// Optional async resolver injected by the caller. When provided, the
  /// sheet calls it once in `initState` to fetch the *real* Family Controls
  /// display name (e.g. "Among Us", "youtube.com") via the host's
  /// MethodChannel and shows it in the header as plain text. This
  /// deliberately avoids embedding a SwiftUI `Label(token)` PlatformView in
  /// the sheet — the PlatformView's hosting `UIView` was the recurring
  /// source of a residual dark/gray rectangle artifact bleeding onto the
  /// daily-limit card border below, because the UIView's empty area
  /// (outside the rendered SwiftUI glyphs) renders with opaque
  /// surface-default tint regardless of `backgroundColor = .clear`. Using
  /// MethodChannel + plain `Text` eliminates the PlatformView entirely
  /// from the sheet, so the artifact cannot recur.
  final Future<String?> Function(String payload)? resolveDisplayName;

  const ManageBlockedItemSheet({
    super.key,
    required this.itemId,
    required this.fallbackTitle,
    required this.nativePayload,
    required this.currentDailyLimitMinutes,
    required this.isWebsite,
    required this.onSetDailyLimit,
    required this.onRemove,
    this.isInitialSetup = false,
    this.resolveDisplayName,
  });

  @override
  State<ManageBlockedItemSheet> createState() => _ManageBlockedItemSheetState();
}

class _ManageBlockedItemSheetState extends State<ManageBlockedItemSheet> {
  late int _draftLimitMinutes;
  String? _resolvedDisplayName;

  @override
  void initState() {
    super.initState();
    // On the initial-setup auto-open, start at a sensible value (60 min)
    // rather than 0 = "always blocked", so the slider is somewhere
    // discoverable. The user can still drag back to 0 if they really do
    // want a full block.
    _draftLimitMinutes = widget.isInitialSetup &&
            widget.currentDailyLimitMinutes == 0
        ? 60
        : widget.currentDailyLimitMinutes;
    _kickOffNameResolution();
  }

  void _kickOffNameResolution() {
    final resolver = widget.resolveDisplayName;
    final payload = widget.nativePayload;
    if (resolver == null || payload == null || payload.isEmpty) return;
    // Fire and forget. If it fails or returns empty we just keep
    // `fallbackTitle` — never crash, never block the UI.
    () async {
      try {
        final resolved = await resolver(payload);
        if (!mounted) return;
        final trimmed = resolved?.trim();
        // Only adopt the resolved name when it is a real, non-generic label.
        // Otherwise we keep `fallbackTitle`, which the caller already
        // computed from the same source the list row displays — never let a
        // placeholder like "blocked app" override a good name.
        if (trimmed != null &&
            trimmed.isNotEmpty &&
            !_isGenericName(trimmed)) {
          setState(() => _resolvedDisplayName = trimmed);
        }
      } catch (_) {
        // Swallow — fallback title stays.
      }
    }();
  }

  /// `true` when the user is making the daily limit MORE permissive (the
  /// "relapse" direction). This is what triggers the 20-second hold. We
  /// treat 0 = always blocked as the strictest setting, so any positive
  /// value above the current one (or any move from 0 to a non-zero number,
  /// outside of [widget.isInitialSetup]) is a loosening.
  bool get _draftIsLoosening {
    if (widget.isInitialSetup) return false;
    if (widget.currentDailyLimitMinutes == _draftLimitMinutes) return false;
    // current = 0 means "always blocked" (the strictest). Any positive draft
    // is therefore a loosening.
    if (widget.currentDailyLimitMinutes == 0 && _draftLimitMinutes > 0) {
      return true;
    }
    // draft = 0 means the user is going all-the-way back to "always blocked"
    // — that is a tightening, never a loosening.
    if (_draftLimitMinutes == 0) return false;
    return _draftLimitMinutes > widget.currentDailyLimitMinutes;
  }

  Future<void> _saveDailyLimit() async {
    final fn = widget.onSetDailyLimit;
    if (fn == null) return;
    if (_draftLimitMinutes == widget.currentDailyLimitMinutes) {
      Navigator.of(context).pop();
      return;
    }
    if (_draftIsLoosening) {
      final approved = await _runFrictionFlow(
        introTitle: 'Increase daily limit?',
        introBody:
            'You are loosening the daily limit on "${widget.fallbackTitle}" '
            'from ${_humanMinutes(widget.currentDailyLimitMinutes)} to '
            '${_humanMinutes(_draftLimitMinutes)}.\n\n'
            'Loosening usually happens in moments of weakness. The '
            '20-second hold below is here so you have time to reconsider.',
        confirmLabel: 'Hold to increase',
        finalTitle: 'Increase now?',
        finalBody:
            'New daily limit: ${_humanMinutes(_draftLimitMinutes)}.\n'
            'You can always tighten it back down later — no friction the '
            'other way.',
        finalConfirmLabel: 'Increase',
      );
      if (!approved || !mounted) return;
    }
    await fn(_draftLimitMinutes);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleRemove() async {
    final approved = await _runFrictionFlow(
      introTitle: 'Remove from block list?',
      introBody:
          'You are about to fully unblock "${widget.fallbackTitle}". '
          'This is the easy path back to a bad habit — and the reason this '
          'screen has friction. Hold the button below for 20 seconds to '
          'confirm you really want to do this.',
      confirmLabel: 'Hold to unblock',
      finalTitle: 'Unblock for real?',
      finalBody:
          '"${widget.fallbackTitle}" will be removed from your block list '
          'immediately. You can re-add it later if you change your mind.',
      finalConfirmLabel: 'Unblock',
    );
    if (!approved || !mounted) return;
    await widget.onRemove();
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _runFrictionFlow({
    required String introTitle,
    required String introBody,
    required String confirmLabel,
    required String finalTitle,
    required String finalBody,
    required String finalConfirmLabel,
  }) async {
    final held = await _showHoldCountdownDialog(
      title: introTitle,
      body: introBody,
      ctaLabel: confirmLabel,
    );
    if (!held || !mounted) return false;
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(finalTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(finalBody, style: const TextStyle(height: 1.35)),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Keep blocked'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(finalConfirmLabel),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _showHoldCountdownDialog({
    required String title,
    required String body,
    required String ctaLabel,
  }) async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) =>
              _HoldCountdownDialog(title: title, body: body, ctaLabel: ctaLabel),
        ) ==
        true;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: AppColors.glassBorder.withValues(alpha: 0.30),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dragHandle(),
                const SizedBox(height: 16),
                _header(),
                const SizedBox(height: 24),
                if (widget.onSetDailyLimit != null) ...[
                  _dailyLimitSection(),
                  const SizedBox(height: 18),
                ],
                _settingsSection(),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: AppTypography.callout.copyWith(
                      color: AppColors.secondaryLabel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.glassBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header() {
    final payload = widget.nativePayload?.trim();
    // Apple only resolves a Family Controls token's real name inside a live,
    // on-screen `Label(token)` view (off-screen text/image extraction returns
    // nothing). So the header renders that native label (title only) to show
    // the real app/website name. Falls back to plain text on Android / when no
    // payload is available.
    if (Platform.isIOS && payload != null && payload.isNotEmpty) {
      final label = widget.isWebsite
          ? BlockedWebsiteTokenLabel(
              payload: payload,
              fallbackTitle: widget.fallbackTitle,
              isDarkTheme: true,
              showIcon: false,
              height: 26,
            )
          : BlockedAppTokenLabel(
              payload: payload,
              fallbackTitle: widget.fallbackTitle,
              isDarkTheme: true,
              showIcon: false,
              height: 26,
            );
      return Align(alignment: Alignment.centerLeft, child: label);
    }
    return Text(
      _resolvedDisplayName ?? widget.fallbackTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.title2.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.label,
      ),
    );
  }

  Widget _dailyLimitSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _draftLimitMinutes == 0
                    ? 'Always blocked'
                    : _humanMinutes(_draftLimitMinutes),
                style: AppTypography.title2.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label,
                ),
              ),
              const SizedBox(width: 8),
              if (_draftLimitMinutes > 0)
                Text(
                  '/ day',
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.tertiaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoSlider(
            value: _draftLimitMinutes.toDouble(),
            min: 0,
            max: 240,
            divisions: 48, // 5-minute steps (0, 5, 10 … 240)
            onChanged: (v) =>
                setState(() => _draftLimitMinutes = v.round()),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '4 h',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.tertiaryLabel,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              // On initial setup we always enable Save so the user can
              // confirm whatever they pick (including the default 60 min
              // we pre-selected, or 0 = always blocked).
              onPressed: (!widget.isInitialSetup &&
                      _draftLimitMinutes == widget.currentDailyLimitMinutes)
                  ? null
                  : _saveDailyLimit,
              child: Text(
                widget.isInitialSetup
                    ? 'Set daily limit'
                    : (_draftIsLoosening
                        ? 'Hold to increase'
                        : 'Save daily limit'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              color: AppColors.tertiaryLabel,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Increasing the daily limit and removing an entry from the '
            'block list are intentionally slow: each requires a 20-second '
            'hold plus a final confirmation. Tightening the limit is free.',
            style: AppTypography.footnote.copyWith(
              color: AppColors.secondaryLabel,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.primaryOrange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              onPressed: _handleRemove,
              child: Text(
                'Remove from block list',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Guards against generic placeholder labels (e.g. the "screen time
  /// blocked app" / "blocked app" strings that some resolvers may return)
  /// so the header never shows a placeholder when a real name exists.
  bool _isGenericName(String value) {
    final n = value.trim().toLowerCase();
    return n.isEmpty ||
        n == 'blocked app' ||
        n == 'screen time blocked app' ||
        n == 'unknown app' ||
        n == 'screen time unknown app' ||
        n == 'selected app' ||
        n.startsWith('selected app ');
  }

  String _humanMinutes(int minutes) {
    if (minutes <= 0) return 'No limit';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining.toString().padLeft(2, '0')}';
  }
}

/// 20-second hold-to-confirm dialog used as the friction gate before any
/// destructive action (reduce daily limit, remove from block list).
class _HoldCountdownDialog extends StatefulWidget {
  final String title;
  final String body;
  final String ctaLabel;
  const _HoldCountdownDialog({
    required this.title,
    required this.body,
    required this.ctaLabel,
  });

  @override
  State<_HoldCountdownDialog> createState() => _HoldCountdownDialogState();
}

class _HoldCountdownDialogState extends State<_HoldCountdownDialog> {
  static const int _holdSeconds = 20;
  Timer? _timer;
  int _secondsLeft = _holdSeconds;
  bool _isHolding = false;

  void _startHold() {
    if (_isHolding) return;
    setState(() => _isHolding = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) Navigator.of(context).pop(true);
      }
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    setState(() {
      _isHolding = false;
      _secondsLeft = _holdSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_holdSeconds - _secondsLeft) / _holdSeconds;
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.body, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: (_) => _startHold(),
              onTapUp: (_) => _cancelHold(),
              onTapCancel: _cancelHold,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primaryOrange.withValues(
                    alpha: _isHolding ? 0.35 : 0.18,
                  ),
                  border: Border.all(
                    color: AppColors.primaryOrange.withValues(alpha: 0.55),
                    width: 0.6,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              color:
                                  AppColors.primaryOrange.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _isHolding
                          ? 'Hold… $_secondsLeft s'
                          : widget.ctaLabel,
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isHolding
                  ? 'Release to cancel.'
                  : 'Press and hold the button for 20 seconds.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.tertiaryLabel,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () {
            _cancelHold();
            Navigator.of(context).pop(false);
          },
        ),
      ],
    );
  }
}
