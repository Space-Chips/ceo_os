import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rank_art.dart';
import '../../components/ambient_backdrop.dart';

enum _BoardTab { global, friends }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserRepository _repository = UserRepository();
  final PremiumRepository _premiumRepository = PremiumRepository();

  _BoardTab _tab = _BoardTab.friends;
  bool _loading = true;
  List<LeaderboardEntry> _global = const [];
  List<FriendConnection> _friends = const [];
  Map<String, String> _identityLabels = const {};
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _t(String key) => context.read<LanguageProvider>().t(key);

  String _localizedRankName(String rankName) {
    final canonical = RankArt.displayName(rankName).toLowerCase();
    switch (canonical) {
      case 'awakened':
        return _t('rank_awakened');
      case 'immortal':
        return _t('rank_immortal');
      case 'diamond':
        return _t('rank_diamond');
      case 'platinum':
        return _t('rank_platinum');
      case 'gold':
        return _t('rank_gold');
      case 'silver':
        return _t('rank_silver');
      case 'bronze':
        return _t('rank_bronze');
      case 'asleep':
      default:
        return _t('rank_asleep');
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final premiumCheck = await _premiumRepository.canAccessLeaderboard();
    final hasPremiumAccess = premiumCheck.allowed;
    if (!hasPremiumAccess) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showPremiumGateDialog(context, premiumCheck);
      return;
    }
    await _repository.refreshLeaderboardForMe();
    final me = await _repository.getProfile().then((v) => v?.id);
    final globalRaw = await _repository.getLeaderboard();
    final friends = await _repository.getFriendConnections();
    final ranked = globalRaw.where((e) => e.optedIn).toList()
      ..sort((a, b) {
        final byLevel = (b.rankLevel ?? 0).compareTo(a.rankLevel ?? 0);
        if (byLevel != 0) return byLevel;
        final byStreak = (b.winStreak ?? 0).compareTo(a.winStreak ?? 0);
        if (byStreak != 0) return byStreak;
        return a.createdBy.compareTo(b.createdBy);
      });
    final labels = await _repository.getPublicIdentityLabelsByUserIds(
      ranked.map((e) => e.createdBy),
    );

    if (!mounted) return;
    setState(() {
      _myUserId = me;
      _global = ranked;
      _friends = friends;
      _identityLabels = labels;
      _loading = false;
    });
  }

  String _identity(LeaderboardEntry entry) {
    if (_myUserId != null && entry.createdBy == _myUserId) {
      return context
          .read<LanguageProvider>()
          .t('leaderboard_you')
          .toUpperCase();
    }
    final resolved = _identityLabels[entry.createdBy];
    if (resolved != null && resolved.trim().isNotEmpty) {
      return resolved.trim().toUpperCase();
    }
    return entry.createdBy.substring(0, 8).toUpperCase();
  }

  String _friendLabel(FriendConnection friend) {
    final name = (friend.friendName ?? '').trim();
    if (name.isNotEmpty) return name.toUpperCase();
    final email = (friend.friendEmail ?? '').trim();
    if (email.isNotEmpty) return email.split('@').first.toUpperCase();
    return context
        .read<LanguageProvider>()
        .t('leaderboard_friend')
        .toUpperCase();
  }

  int? _myGlobalPosition() {
    if (_myUserId == null) return null;
    final index = _global.indexWhere((entry) => entry.createdBy == _myUserId);
    if (index < 0) return null;
    return index + 1;
  }

  LeaderboardEntry? _myGlobalEntry() {
    if (_myUserId == null) return null;
    for (final entry in _global) {
      if (entry.createdBy == _myUserId) return entry;
    }
    return null;
  }

  Future<void> _inviteFriends() async {
    final inviter = _myUserId ?? 'invite';
    final appStoreUrl = 'https://apps.apple.com/app/id123456789?ref=$inviter';
    const text = 'Join me on CEO Compass to compare progress and win streaks: ';
    await Clipboard.setData(ClipboardData(text: '$text$appStoreUrl'));
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Invite Ready'),
        content: const Text('Invite link copied to clipboard.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: _loading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.primaryOrange,
                ),
              )
            : SafeArea(
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                      children: [
                        _topBar(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.rosette,
                              size: 32,
                              color: AppColors.rankAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _t('leaderboard_title'),
                                style: AppTypography.largeTitle.copyWith(
                                  fontSize: 32,
                                  color: AppColors.label,
                                  fontWeight: FontWeight.w700,
                                  height: 0.95,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _tabs(),
                        const SizedBox(height: 16),
                        if (_tab == _BoardTab.global) ..._globalBody(),
                        if (_tab == _BoardTab.friends) ..._friendsBody(),
                      ],
                    ),
                    Builder(
                      builder: (_) {
                        final myPosition = _myGlobalPosition();
                        final myEntry = _myGlobalEntry();
                        if (myPosition == null || myEntry == null) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _yourPositionBar(
                            position: myPosition,
                            entry: myEntry,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            minimumSize: Size.zero,
            onPressed: () => context.go('/screen-time-manager'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  _t('screen_time'),
                  style: AppTypography.mono.copyWith(
                    fontSize: 16,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            minimumSize: Size.zero,
            onPressed: () => context.go('/home'),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.house,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  _t('home'),
                  style: AppTypography.mono.copyWith(
                    fontSize: 16,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LeaderboardPressScale(
              onTap: () => setState(() => _tab = _BoardTab.global),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _tab == _BoardTab.global
                      ? AppColors.accentSurfaceSoft
                      : AppColors.topBarControlBackground.withValues(alpha: 0),
                ),
                child: Center(
                  child: Text(
                    _t('leaderboard_global_tab'),
                    style: AppTypography.callout.copyWith(
                      fontSize: 14,
                      color: AppColors.label.withValues(
                        alpha: _tab == _BoardTab.global ? 1 : 0.7,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _LeaderboardPressScale(
              onTap: () => setState(() => _tab = _BoardTab.friends),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _tab == _BoardTab.friends
                      ? AppColors.accentSurfaceSoft
                      : AppColors.topBarControlBackground.withValues(alpha: 0),
                ),
                child: Center(
                  child: Text(
                    _t('leaderboard_friends_tab'),
                    style: AppTypography.callout.copyWith(
                      fontSize: 14,
                      color: AppColors.label.withValues(
                        alpha: _tab == _BoardTab.friends ? 1 : 0.7,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _globalBody() {
    return [
      Text(
        _t('leaderboard_top_performers'),
        style: AppTypography.overline.copyWith(
          fontSize: 14,
          color: AppColors.label,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 10),
      if (_global.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 90),
          child: Center(
            child: Text(
              _t('leaderboard_empty'),
              style: AppTypography.callout.copyWith(
                fontSize: 16,
                color: AppColors.secondaryLabel.withValues(alpha: 0.8),
              ),
            ),
          ),
        )
      else
        ..._global.take(20).toList().asMap().entries.map((entry) {
          final index = entry.key + 1;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LeaderboardPressScale(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _leaderboardRowDecoration(
                  borderColor: _positionBorderColor(index),
                ),
                child: Row(
                  children: [
                    _positionBadge(index),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _identity(row),
                            style: AppTypography.callout.copyWith(
                              fontSize: 14,
                              color: AppColors.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _rankSummary(
                            row.rankName ?? _t('rank_asleep'),
                            row.winStreak ?? 0,
                          ),
                        ],
                      ),
                    ),
                    _levelBadge(row.rankLevel ?? 1),
                  ],
                ),
              ),
            ),
          );
        }),
    ];
  }

  List<Widget> _friendsBody() {
    return [
      Row(
        children: [
          Icon(CupertinoIcons.person_2, size: 24, color: AppColors.accentIcon),
          const SizedBox(width: 8),
          Text(
            _t(
              'leaderboard_your_friends_count',
            ).replaceAll('{count}', '${_friends.length}'),
            style: AppTypography.callout.copyWith(
              fontSize: 20,
              color: AppColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_friends.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 70),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.person_2,
                size: 56,
                color: AppColors.secondaryLabel.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                _t('leaderboard_no_friends'),
                style: AppTypography.callout.copyWith(
                  fontSize: 16,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t('leaderboard_add_friends_hint'),
                style: AppTypography.footnote.copyWith(
                  fontSize: 13,
                  color: AppColors.tertiaryLabel.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        )
      else
        ..._friends.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LeaderboardPressScale(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _leaderboardRowDecoration(
                  borderColor: _positionBorderColor(index),
                ),
                child: Row(
                  children: [
                    _positionBadge(index),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _friendLabel(row),
                            style: AppTypography.callout.copyWith(
                              fontSize: 14,
                              color: AppColors.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _rankSummary(
                            row.friendRankName ?? _t('rank_asleep'),
                            row.friendWinStreak ?? 0,
                          ),
                        ],
                      ),
                    ),
                    _levelBadge(row.friendRankLevel ?? 1),
                  ],
                ),
              ),
            ),
          );
        }),
      const SizedBox(height: 14),
      _LeaderboardActionButton(label: 'Invite Friends', onTap: _inviteFriends),
    ];
  }

  Widget _positionBadge(int index) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.topBarControlBackground,
        border: Border.all(
          color:
              _positionBorderColor(index) ??
              AppColors.topBarControlBackground.withValues(alpha: 0),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: AppTypography.caption1.copyWith(
          fontSize: 14,
          color: AppColors.label,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color? _positionBorderColor(int index) {
    if (index == 1) {
      return Color.lerp(
        AppColors.warning,
        AppColors.rankAccent,
        0.3,
      )!.withValues(alpha: 0.35);
    }
    if (index == 2) {
      return Color.lerp(
        AppColors.label,
        AppColors.secondaryLabel,
        0.55,
      )!.withValues(alpha: 0.28);
    }
    if (index == 3) {
      return Color.lerp(
        AppColors.rankAccent,
        AppColors.warning,
        0.62,
      )!.withValues(alpha: 0.35);
    }
    return null;
  }

  Widget _levelBadge(int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.topBarControlBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'L$level',
        style: AppTypography.caption2.copyWith(
          fontSize: 12,
          color: AppColors.label,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _leaderboardRowDecoration({Color? borderColor}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.45),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _yourPositionBar({
    required int position,
    required LeaderboardEntry entry,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardBackgroundAlt, AppColors.cardBase],
        ),
        border: Border(
          top: BorderSide(color: AppColors.borderStrong, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _leaderboardRowDecoration(
            borderColor: AppColors.selectionOutline,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('leaderboard_your_position'),
                style: AppTypography.caption1.copyWith(
                  fontSize: 12,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _positionBadge(position),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('leaderboard_you').toUpperCase(),
                      style: AppTypography.callout.copyWith(
                        fontSize: 14,
                        color: AppColors.label,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _levelBadge(entry.rankLevel ?? 1),
                ],
              ),
              const SizedBox(height: 4),
              _rankSummary(
                entry.rankName ?? _t('rank_asleep'),
                entry.winStreak ?? 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankSummary(String rankName, int streak) {
    return Row(
      children: [
        RankArt(rankName: rankName, size: RankArtSize.xs, dimension: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$rankName • $streak day streak',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.footnote.copyWith(
              fontSize: 13,
              color: AppColors.secondaryLabel.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _LeaderboardPressScale({required this.child, required this.onTap});

  @override
  State<_LeaderboardPressScale> createState() => _LeaderboardPressScaleState();
}

class _LeaderboardPressScaleState extends State<_LeaderboardPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 1.01 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}

class _LeaderboardActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LeaderboardActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final inviteGradient = AppColors.isCarbonSystem
        ? [
            Color.alphaBlend(
              AppColors.focusControlAccent.withValues(alpha: 0.74),
              AppColors.cardBackgroundStrong,
            ),
            Color.alphaBlend(
              AppColors.familyCreateAccent.withValues(alpha: 0.54),
              AppColors.cardBackgroundStrong,
            ),
          ]
        : AppColors.buttonGradient;
    return _LeaderboardPressScale(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF4C7DFF), Color(0xFF9B4DFF)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.share, color: AppColors.onAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.callout.copyWith(
                  fontSize: 16,
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
