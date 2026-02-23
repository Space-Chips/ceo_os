import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserRepository _repository = UserRepository();
  List<_RankedEntry> _entries = [];
  String? _myUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _computeScore(LeaderboardEntry e) {
    final rankLevel = (e.rankLevel ?? 1).clamp(1, 10);
    final streak = (e.winStreak ?? 0).clamp(0, 365);
    final percentile = (e.percentile ?? 0).clamp(0, 100);
    final screen = (e.screenTimeAvgMinutes ?? 0).clamp(0, 6000);

    // Lower screen time is better after 90m baseline.
    final focusDiscipline = (160 - (screen / 20)).clamp(20, 160).round();
    final progression = rankLevel * 120;
    final consistency = streak * 14;
    final standing = percentile * 6;

    return progression + consistency + standing + focusDiscipline;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _repository.refreshLeaderboardForMe();

    final entries = await _repository.getLeaderboard();
    final me = await _repository
        .getProfile()
        .then((value) => value?.id)
        .catchError((_) => null);

    final ranked =
        entries
            .where((e) => e.optedIn)
            .map((e) => _RankedEntry(entry: e, score: _computeScore(e)))
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    if (!mounted) return;
    setState(() {
      _entries = ranked;
      _myUserId = me;
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
          onPressed: () => context.go('/profile'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: const NeoMonoText(
          'LEADERBOARD',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _load,
          child: const Icon(
            CupertinoIcons.refresh,
            color: AppColors.primaryOrange,
            size: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _loading
          ? const Center(
              child: CupertinoActivityIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: _entries.isEmpty
                  ? Center(
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Text(
                          'No leaderboard data yet. Complete habits/tasks/focus to generate rankings.',
                          textAlign: TextAlign.center,
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final row = _entries[index];
                        final entry = row.entry;
                        final rank = index + 1;
                        final mine =
                            _myUserId != null && entry.createdBy == _myUserId;
                        return GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          borderRadius: 16,
                          border: mine
                              ? Border.all(
                                  color: AppColors.primaryOrange.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 0.8,
                                )
                              : Border.all(
                                  color: rank == 1
                                      ? const Color(
                                          0xFFFFD54F,
                                        ).withValues(alpha: 0.35)
                                      : rank == 2
                                      ? const Color(
                                          0xFFB0BEC5,
                                        ).withValues(alpha: 0.3)
                                      : rank == 3
                                      ? const Color(
                                          0xFFB87333,
                                        ).withValues(alpha: 0.3)
                                      : AppColors.glassBorder,
                                  width: 0.6,
                                ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 42,
                                child: Text(
                                  rank == 1
                                      ? '🥇'
                                      : rank == 2
                                      ? '🥈'
                                      : rank == 3
                                      ? '🥉'
                                      : '#$rank',
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: rank <= 3
                                        ? AppColors.label
                                        : AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.rankName ?? 'Starter',
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      mine
                                          ? 'YOU'
                                          : entry.createdBy.substring(0, 8),
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 10,
                                        color: AppColors.tertiaryLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _pill('IDX ${row.score}'),
                              const SizedBox(width: 6),
                              _pill('L${entry.rankLevel ?? 1}'),
                              const SizedBox(width: 6),
                              _pill('${entry.winStreak ?? 0}d'),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _pill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: AppTypography.mono.copyWith(
          fontSize: 10,
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RankedEntry {
  final LeaderboardEntry entry;
  final int score;

  const _RankedEntry({required this.entry, required this.score});
}
