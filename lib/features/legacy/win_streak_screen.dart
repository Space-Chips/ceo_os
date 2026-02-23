import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/models/user_models.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class WinStreakScreen extends StatefulWidget {
  const WinStreakScreen({super.key});

  @override
  State<WinStreakScreen> createState() => _WinStreakScreenState();
}

class _WinStreakScreenState extends State<WinStreakScreen> {
  final FeatureRepository _repo = FeatureRepository();
  WinStreak? _streak;
  List<WeeklyHabitScore> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final streak = await _repo.getWinStreak();
    final scores = await _repo.getWeeklyHabitScores(limit: 10);
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _scores = scores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'WIN_STREAK',
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
                    padding: const EdgeInsets.all(20),
                    borderRadius: 18,
                    child: Row(
                      children: [
                        _metric('CURRENT', '${_streak?.currentStreak ?? 0}d'),
                        _metric('LONGEST', '${_streak?.longestStreak ?? 0}d'),
                        _metric(
                          'SESSIONS',
                          '${_streak?.totalCompletedSessions ?? 0}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Weekly Habit Scores',
                    style: AppTypography.mono.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_scores.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No weekly scores yet.',
                        style: AppTypography.mono.copyWith(
                          fontSize: 11,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    )
                  else
                    ..._scores.map(
                      (score) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          borderRadius: 14,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${score.weekStartDate ?? '-'} → ${score.weekEndDate ?? '-'}',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 10,
                                    color: AppColors.secondaryLabel,
                                  ),
                                ),
                              ),
                              Text(
                                '${score.successPercentage ?? 0}%',
                                style: AppTypography.mono.copyWith(
                                  fontSize: 13,
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
