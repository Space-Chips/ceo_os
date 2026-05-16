import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ScreenTimeScreen extends StatefulWidget {
  final String? initialSection;

  const ScreenTimeScreen({super.key, this.initialSection});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  static const List<String> _websiteSuggestions = [
    'youtube.com',
    'tiktok.com',
    'instagram.com',
    'facebook.com',
    'x.com',
    'twitter.com',
    'reddit.com',
    'twitch.tv',
    'netflix.com',
    'primevideo.com',
    'discord.com',
    'snapchat.com',
    'pinterest.com',
    'linkedin.com',
    'news.ycombinator.com',
    'google.com',
    'bing.com',
    'duckduckgo.com',
  ];
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
          child: Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: NeoMonoText(
          'SCREEN_TIME',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? Center(child: CupertinoActivityIndicator(color: AppColors.primaryOrange))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                children: [
                  _glowSurface(
                    glowColor: AppColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: 16,
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.22),
                        width: 0.7,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.device_phone_portrait,
                            size: 16,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Raw usage logs from the last 14 days.',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: AppColors.secondaryLabel,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: _load,
                            child: Icon(
                              CupertinoIcons.refresh,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            border: Border.all(
                              color: AppColors.glassBorder,
                              width: 0.5,
                            ),
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
                                    fontWeight: FontWeight.bold,
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

  Widget _glowSurface({
    required Widget child,
    required Color glowColor,
    double borderRadius = 16,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 28, spreadRadius: 1),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
