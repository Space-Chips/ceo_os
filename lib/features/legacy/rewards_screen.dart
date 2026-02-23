import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final FeatureRepository _repo = FeatureRepository();
  final TextEditingController _reward = TextEditingController();
  final TextEditingController _sanction = TextEditingController();
  int _threshold = 90;
  bool _committed = false;
  WeeklyContract? _contract;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contract = await _repo.getCurrentWeeklyContract();
    if (!mounted) return;
    setState(() {
      _contract = contract;
      _reward.text = contract?.rewardText ?? '';
      _sanction.text = contract?.sanctionText ?? '';
      _threshold = contract?.successThresholdPercentage ?? 90;
      _committed = contract?.committed ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _repo.upsertCurrentWeeklyContract(
      reward: _reward.text.trim(),
      sanction: _sanction.text.trim(),
      threshold: _threshold,
      committed: _committed,
    );
    await _load();
  }

  @override
  void dispose() {
    _reward.dispose();
    _sanction.dispose();
    super.dispose();
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
          'REWARDS',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: Text(
            'SAVE',
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.primaryOrange,
            ),
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEEKLY COMMITMENT',
                          style: AppTypography.mono.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassInputField(
                          controller: _reward,
                          placeholder: 'Reward if successful',
                        ),
                        const SizedBox(height: 10),
                        GlassInputField(
                          controller: _sanction,
                          placeholder: 'Sanction if failed',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Threshold: $_threshold%',
                              style: AppTypography.mono.copyWith(fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CupertinoSlider(
                                value: _threshold.toDouble(),
                                min: 60,
                                max: 100,
                                divisions: 8,
                                activeColor: AppColors.primaryOrange,
                                onChanged: (v) =>
                                    setState(() => _threshold = v.round()),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Committed',
                              style: AppTypography.mono.copyWith(fontSize: 11),
                            ),
                            CupertinoSwitch(
                              value: _committed,
                              activeTrackColor: AppColors.primaryOrange,
                              onChanged: (v) => setState(() => _committed = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_contract != null)
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 14,
                      child: Text(
                        'Current week: ${_contract!.weekStartDate} → ${_contract!.weekEndDate}\nOutcome: ${_contract!.outcomeGrade.toUpperCase()}',
                        style: AppTypography.mono.copyWith(
                          fontSize: 10,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
