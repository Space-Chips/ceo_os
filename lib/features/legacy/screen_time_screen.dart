import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  final FeatureRepository _repo = FeatureRepository();
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _repo.getScreenTimeLogs(days: 14);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = _logs.fold<int>(
      0,
      (sum, log) => sum + ((log['duration_seconds'] as num?)?.toInt() ?? 0),
    );
    final totalHours = (totalSeconds / 3600).toStringAsFixed(1);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: const NeoMonoText(
          'SCREEN_TIME',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? const Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 16,
                    child: Row(
                      children: [
                        _metric('LOGS', '${_logs.length}'),
                        _metric('HOURS', totalHours),
                        _metric(
                          'AVG/LOG',
                          _logs.isEmpty
                              ? '0m'
                              : '${(totalSeconds / _logs.length / 60).round()}m',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._logs
                      .take(30)
                      .map(
                        (log) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            borderRadius: 14,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (log['entity_name']?.toString() ??
                                            'Unknown')
                                        .toUpperCase(),
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${((log['duration_seconds'] as num?)?.toInt() ?? 0) ~/ 60}m',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 11,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
