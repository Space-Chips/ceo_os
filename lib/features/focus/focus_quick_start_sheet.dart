import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/repositories/focus_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class FocusQuickStartSheet extends StatefulWidget {
  const FocusQuickStartSheet({super.key});

  @override
  State<FocusQuickStartSheet> createState() => _FocusQuickStartSheetState();
}

class _FocusQuickStartSheetState extends State<FocusQuickStartSheet> {
  static const List<int> _defaults = [25, 45, 60, 90, 120, 180];

  final FocusRepository _focusRepository = FocusRepository();
  List<int> _durations = const [];
  int? _selected;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final seen = <int>{};
    final unique = <int>[];
    try {
      final sessions = await _focusRepository.getRecentSessions();
      for (final s in sessions) {
        final d = (s['duration_minutes'] as num?)?.toInt();
        if (d != null && d > 0 && seen.add(d)) {
          unique.add(d);
          if (unique.length >= 6) break;
        }
      }
    } catch (_) {}
    for (final d in _defaults) {
      if (unique.length >= 6) break;
      if (seen.add(d)) unique.add(d);
    }
    if (!mounted) return;
    setState(() {
      _durations = unique.take(6).toList(growable: false);
      _selected = _durations.isNotEmpty
          ? _durations.first
          : context.read<FocusProvider>().focusDurationMinutes;
      _loading = false;
    });
  }

  String _label(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}';
  }

  Future<void> _start() async {
    if (_starting) return;
    final focusProv = context.read<FocusProvider>();
    final duration = _selected;
    if (duration != null) {
      focusProv.focusDurationMinutes = duration;
    }
    setState(() => _starting = true);
    final success = await focusProv.startFocus();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      context.push('/focus');
      return;
    }
    setState(() => _starting = false);
    final block = focusProv.lastPremiumCheck;
    if (block != null && !block.allowed) {
      await showPremiumGateDialog(context, block);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: AppColors.border.withValues(alpha: 0.30),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.bolt_fill,
                      size: 18,
                      color: AppColors.secondaryLabel,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Start',
                      style: AppTypography.title2.copyWith(
                        fontSize: 22,
                        color: AppColors.label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: CupertinoActivityIndicator(
                      color: AppColors.secondaryLabel,
                    ),
                  )
                else
                  _grid(),
                const SizedBox(height: 18),
                _startButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: 10),
                Expanded(child: _durationCard(row * 3 + col)),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _durationCard(int index) {
    if (index >= _durations.length) {
      return const SizedBox(height: 64);
    }
    final minutes = _durations[index];
    final active = _selected == minutes;
    return GestureDetector(
      onTap: () => setState(() => _selected = minutes),
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [
                    AppColors.label.withValues(alpha: 0.18),
                    AppColors.label.withValues(alpha: 0.08),
                  ]
                : [
                    AppColors.cardBackgroundStrong.withValues(alpha: 0.60),
                    AppColors.background.withValues(alpha: 0.42),
                  ],
          ),
          border: Border.all(
            color: AppColors.border.withValues(alpha: active ? 0.55 : 0.30),
            width: 0.5,
          ),
        ),
        child: Text(
          _label(minutes),
          style: AppTypography.title3.copyWith(
            fontSize: 20,
            color: AppColors.label,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _startButton() {
    return GestureDetector(
      onTap: _starting ? null : _start,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: _starting ? 0.85 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.label.withValues(alpha: 0.92),
                AppColors.secondaryLabel.withValues(alpha: 0.84),
              ],
            ),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.40),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -8,
              ),
            ],
          ),
          child: _starting
              ? CupertinoActivityIndicator(color: AppColors.background)
              : Text(
                  'Start Session',
                  style: AppTypography.callout.copyWith(
                    fontSize: 17,
                    color: AppColors.background,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
