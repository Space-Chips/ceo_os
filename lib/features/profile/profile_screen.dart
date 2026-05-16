import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rank_art.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<_LanguageOption> _languages = [
    _LanguageOption(code: 'en', label: 'English', nativeLabel: 'English'),
    _LanguageOption(code: 'fr', label: 'French', nativeLabel: 'Français'),
    _LanguageOption(code: 'zh', label: 'Chinese', nativeLabel: '中文'),
    _LanguageOption(code: 'hi', label: 'Hindi', nativeLabel: 'हिन्दी'),
    _LanguageOption(code: 'es', label: 'Spanish', nativeLabel: 'Español'),
    _LanguageOption(code: 'ar', label: 'Arabic', nativeLabel: 'العربية'),
    _LanguageOption(
      code: 'id',
      label: 'Indonesian',
      nativeLabel: 'Bahasa Indonesia',
    ),
    _LanguageOption(code: 'ru', label: 'Russian', nativeLabel: 'Русский'),
    _LanguageOption(code: 'pt', label: 'Portuguese', nativeLabel: 'Português'),
  ];

  final UserRepository _userRepository = UserRepository();
  final TextEditingController _nameCtrl = TextEditingController();

  Profile? _profile;
  UserRank? _rank;
  WinStreak? _streak;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userRepository.getProfile();
      final rank = await _userRepository.getUserRank();
      final streak = await _userRepository.getWinStreak();
      _nameCtrl.text = profile?.fullName ?? '';
      if (mounted) {
        setState(() {
          _profile = profile;
          _rank = rank;
          _streak = streak;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _userRepository.updateProfile(fullName: _nameCtrl.text.trim());
    await _load();
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: Icon(CupertinoIcons.back, color: AppColors.primaryOrange),
        ),
        middle: NeoMonoText(
          language.t('profile'),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: Text(
            _isSaving ? 'SAVING' : 'SAVE',
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
      ),
      child: _isLoading
          ? Center(child: CupertinoActivityIndicator(color: AppColors.primaryOrange))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISPLAY_NAME',
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassInputField(
                          controller: _nameCtrl,
                          placeholder: 'Your name',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile?.email ?? '-',
                          style: AppTypography.mono.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 18,
                    child: Row(
                      children: [
                        _metric(
                          'RANK',
                          RankArt.displayName(_rank?.rankName ?? 'Asleep'),
                        ),
                        _metric('LEVEL', '${_rank?.rankLevel ?? 1}'),
                        _metric('POINTS', '${_rank?.totalRankPoints ?? 0}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 18,
                    child: Row(
                      children: [
                        _metric('STREAK', '${_streak?.currentStreak ?? 0}d'),
                        _metric('BEST', '${_streak?.longestStreak ?? 0}d'),
                        _metric(
                          'SESSIONS',
                          '${_streak?.totalCompletedSessions ?? 0}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LiquidButton(
                    label: 'OPEN_LEADERBOARD',
                    fullWidth: true,
                    onPressed: () => context.push('/leaderboard'),
                  ),
                  const SizedBox(height: 10),
                  LiquidButton(
                    label: 'OPEN_SETTINGS',
                    fullWidth: true,
                    onPressed: () => context.push('/settings'),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final String body;

  const _SettingsSection(this.title, this.body);
}

class _LanguageOption {
  final String code;
  final String label;
  final String nativeLabel;

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });
}
