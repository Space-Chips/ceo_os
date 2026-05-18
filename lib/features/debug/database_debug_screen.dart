import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../components/components.dart';
import '../../core/services/database_debug_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/glass_card.dart';
import '../../components/liquid_button.dart';

class DatabaseDebugScreen extends StatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  State<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  final DatabaseDebugService _service = DatabaseDebugService();
  late List<DatabaseDebugTestResult> _results;
  bool _isRunning = false;
  DateTime? _startedAt;
  DateTime? _finishedAt;

  @override
  void initState() {
    super.initState();
    _results = _service.testCases.map(_service.pendingResult).toList();
  }

  Future<void> _runAll() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _startedAt = DateTime.now();
      _finishedAt = null;
      _results = _service.testCases.map(_service.pendingResult).toList();
    });

    for (var i = 0; i < _service.testCases.length; i++) {
      final testCase = _service.testCases[i];
      setState(() {
        _results[i] = _results[i].copyWith(
          status: DatabaseDebugTestStatus.running,
          message: 'Running…',
        );
      });
      final result = await _service.runTestCase(testCase.id);
      if (!mounted) return;
      setState(() {
        _results[i] = result;
      });
    }

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _finishedAt = DateTime.now();
    });
  }

  Future<void> _copyReport() async {
    final passed = _results
        .where((item) => item.status == DatabaseDebugTestStatus.passed)
        .length;
    final failed = _results
        .where((item) => item.status == DatabaseDebugTestStatus.failed)
        .length;
    final lines = <String>[
      'Database Debug Report',
      'Started: ${_startedAt?.toIso8601String() ?? '-'}',
      'Finished: ${_finishedAt?.toIso8601String() ?? '-'}',
      'Passed: $passed',
      'Failed: $failed',
      '',
      for (final result in _results)
        '- ${result.title}: ${result.status.name.toUpperCase()} (${result.duration.inMilliseconds}ms) — ${result.message}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Report copied', style: AppTypography.body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: AppTypography.body.copyWith(color: AppColors.systemBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results
        .where((item) => item.status == DatabaseDebugTestStatus.passed)
        .length;
    final failed = _results
        .where((item) => item.status == DatabaseDebugTestStatus.failed)
        .length;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground.withValues(alpha: 0.9),
        border: const Border(),
        middle: Text('Database Debug', style: AppTypography.title3),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automated Supabase write checks',
                    style: AppTypography.title3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each test writes prefixed debug data, verifies read-back, then cleans up. Failures usually point to missing migrations, RLS issues, or schema drift.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _summaryChip('Passed', passed, AppColors.success),
                      const SizedBox(width: 10),
                      _summaryChip('Failed', failed, AppColors.error),
                      const SizedBox(width: 10),
                      _summaryChip(
                        'Total',
                        _results.length,
                        AppColors.systemBlue,
                      ),
                    ],
                  ),
                  if (_startedAt != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      "Last run: ${_finishedAt?.toLocal().toString().substring(0, 19) ?? 'in progress"}',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            LiquidButton(
              label: _isRunning ? 'Running checks…' : 'Run all database checks',
              fullWidth: true,
              onPressed: _isRunning ? null : _runAll,
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: AppColors.glassBase.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              onPressed: _results.every(
                (item) => item.status == DatabaseDebugTestStatus.pending,
              )
                  ? null
                  : _copyReport,
              child: Text(
                'Copy report',
                style: AppTypography.body.copyWith(
                  color: AppColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (final result in _results) ...[
              _resultCard(result),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label $value',
        style: AppTypography.caption1.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _resultCard(DatabaseDebugTestResult result) {
    final color = switch (result.status) {
      DatabaseDebugTestStatus.passed => AppColors.success,
      DatabaseDebugTestStatus.failed => AppColors.error,
      DatabaseDebugTestStatus.running => AppColors.systemBlue,
      DatabaseDebugTestStatus.skipped => AppColors.warning,
      DatabaseDebugTestStatus.pending => AppColors.tertiaryLabel,
    };

    final statusText = switch (result.status) {
      DatabaseDebugTestStatus.passed => 'PASSED',
      DatabaseDebugTestStatus.failed => 'FAILED',
      DatabaseDebugTestStatus.running => 'RUNNING',
      DatabaseDebugTestStatus.skipped => 'SKIPPED',
      DatabaseDebugTestStatus.pending => 'PENDING',
    };

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.caption2.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: AppTypography.footnote.copyWith(
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${result.duration.inMilliseconds} ms',
            style: AppTypography.caption2.copyWith(
              color: AppColors.tertiaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
