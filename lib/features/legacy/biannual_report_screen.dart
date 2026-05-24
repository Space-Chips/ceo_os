import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/components.dart';
import '../../core/models/premium_models.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/glass_card.dart';
import '../../components/neo_mono_text.dart';

class BiannualReportScreen extends StatefulWidget {
  const BiannualReportScreen({super.key});

  @override
  State<BiannualReportScreen> createState() => _BiannualReportScreenState();
}

class _BiannualReportScreenState extends State<BiannualReportScreen> {
  final PremiumRepository _premiumRepository = PremiumRepository();
  bool _loading = true;
  int _completedTasks = 0;
  int _focusMinutes = 0;
  int _habitCompletions = 0;
  String _dominant = 'Gathering data...';
  PremiumCheckResult? _premiumBlock;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final premiumCheck = await _premiumRepository.canAccessReports();
    if (!premiumCheck.allowed) {
      if (!mounted) return;
      setState(() {
        _premiumBlock = premiumCheck;
        _loading = false;
      });
      return;
    }

    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    final since = DateTime.now()
        .subtract(const Duration(days: 180))
        .toIso8601String();
    final sinceDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 180)));

    final tasks = await client
        .from('pareto_tasks')
        .select('id')
        .eq('created_by', uid)
        .eq('completed', true)
        .gte('completed_date', since);

    final focus = await client
        .from('focus_sessions')
        .select('duration_minutes')
        .eq('created_by', uid)
        .eq('completed', true)
        .gte('start_time', since);

    final habits = await client
        .from('habit_completions')
        .select('id')
        .eq('created_by', uid)
        .eq('completed', true)
        .gte('date', sinceDate);

    final completedTasks = (tasks as List).length;
    final habitCompletions = (habits as List).length;
    final focusMinutes = (focus as List).fold<int>(
      0,
      (sum, row) => sum + ((row['duration_minutes'] as num?)?.toInt() ?? 0),
    );

    final dominant = _dominantInsight(
      completedTasks,
      habitCompletions,
      focusMinutes,
    );

    if (!mounted) return;
    setState(() {
      _premiumBlock = null;
      _completedTasks = completedTasks;
      _habitCompletions = habitCompletions;
      _focusMinutes = focusMinutes;
      _dominant = dominant;
      _loading = false;
    });
  }

  String _dominantInsight(int tasks, int habits, int focus) {
    if (focus < 900) {
      return 'Deep work volume is low over 6 months. Protect fixed focus blocks.';
    }
    if (habits < 120) {
      return 'Habit consistency is the largest gap. Reduce scope and increase repeatability.';
    }
    if (tasks < 60) {
      return 'Execution throughput is low. Increase weekly shipping cadence.';
    }
    return 'Execution, habits, and focus are balanced. Continue compounding this system.';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: Icon(CupertinoIcons.back, color: AppColors.primaryOrange),
        ),
        middle: const NeoMonoText(
          'BIANNUAL_REPORT',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _load,
          child: Icon(
            CupertinoIcons.refresh,
            size: 18,
            color: AppColors.primaryOrange,
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _glowSurface(
                    glowColor: AppColors.primaryOrange.withValues(alpha: 0.14),
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
                            CupertinoIcons.chart_bar_alt_fill,
                            size: 16,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rolling 180-day performance synthesis.',
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                color: AppColors.secondaryLabel,
                              ),
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
                        _metric('COMPLETED_TASKS', '$_completedTasks'),
                        _metric('HABIT_CHECKINS', '$_habitCompletions'),
                        _metric(
                          'FOCUS_HOURS',
                          (_focusMinutes / 60).toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    border: Border.all(
                      color: AppColors.primaryOrange.withValues(alpha: 0.22),
                      width: 0.55,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dominant insight',
                          style: AppTypography.mono.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dominant,
                          style: AppTypography.mono.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPremiumLockedCard(PremiumCheckResult check) {
    final message = premiumMessageForReason(check.reason);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      border: Border.all(
        color: AppColors.primaryOrange.withValues(alpha: 0.28),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield_fill,
                size: 16,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.title.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.label,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.description,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.secondaryLabel,
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

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 8,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
