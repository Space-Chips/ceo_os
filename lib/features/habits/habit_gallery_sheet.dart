import 'package:flutter/cupertino.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'add_habit_sheet.dart';

class HabitGallerySheet extends StatelessWidget {
  const HabitGallerySheet({super.key});

  final Map<String, List<Map<String, String>>> _categories = const {
    'LIFE': [
      {
        'title': 'Daily Check-in',
        'quote': 'Try a little harder to be a little better',
        'icon': 'check',
      },
      {
        'title': 'Learn Musical Instruments',
        'quote': 'Get some inspirations from your own melody',
        'icon': 'music',
      },
      {
        'title': 'Listen to Music',
        'quote': 'Get in the right mood',
        'icon': 'headphones',
      },
      {
        'title': 'Watch a Movie',
        'quote': 'Experience life in another way',
        'icon': 'film',
      },
      {
        'title': 'Reduce Screen Time',
        'quote': 'Disconnect from the phone and reconnect to...',
        'icon': 'phone_off',
      },
      {
        'title': 'Learn new words',
        'quote': 'Small number, big result',
        'icon': 'book',
      },
      {
        'title': 'Learn a new language',
        'quote': 'Open up a new window to look at the world',
        'icon': 'globe',
      },
      {
        'title': 'Read',
        'quote': 'A chapter a day will light your way',
        'icon': 'book_open',
      },
      {
        'title': 'Write',
        'quote': 'Note down some inspirations',
        'icon': 'pencil',
      },
      {
        'title': 'Keep a Diary',
        'quote': 'Keep a diary and someday it will keep you',
        'icon': 'notebook',
      },
      {
        'title': 'Track expenses',
        'quote': 'Get some financial wisdom',
        'icon': 'money',
      },
      {
        'title': 'Connect a Loved One',
        'quote': 'It\'s always good to get in touch',
        'icon': 'heart',
      },
      {
        'title': 'No Video Games',
        'quote': 'Break free from game addiction',
        'icon': 'game_controller_off',
      },
      {
        'title': 'Help Others',
        'quote': 'It is better to give than to take',
        'icon': 'hand_heart',
      },
      {
        'title': 'Take photos',
        'quote': 'Capture your happy moments',
        'icon': 'camera',
      },
      {
        'title': 'Clean up',
        'quote': 'Ready for best productivity',
        'icon': 'broom',
      },
      {
        'title': 'Do Housework',
        'quote': 'Live away from a mess',
        'icon': 'home',
      },
      {
        'title': 'Water Flowers',
        'quote': 'Every flower is a soul blossoming in nature',
        'icon': 'flower',
      },
      {
        'title': 'Walk the Dog',
        'quote': 'Happiness Is a long walk with your dog',
        'icon': 'dog',
      },
      {
        'title': 'Be a Good Cat Keeper',
        'quote': 'Comfort yourself by comforting your cat',
        'icon': 'cat',
      },
      {
        'title': 'Watch a Documentary',
        'quote': 'Explore the magic and the unknown world',
        'icon': 'tv',
      },
      {
        'title': 'Get News Updates',
        'quote': 'Stay-informed about the world',
        'icon': 'newspaper',
      },
      {'title': 'Watch TV Shows', 'quote': 'Spice up your life', 'icon': 'tv'},
      {
        'title': 'Watch Soap Opera',
        'quote': 'Stop thinking, just have fun',
        'icon': 'tv',
      },
    ],
    'HEALTH': [
      {
        'title': 'Take Medicine',
        'quote': 'Never forget to take your pills again',
        'icon': 'pill',
      },
      {
        'title': 'Take Care of Eyes',
        'quote': 'Eyes are windows to the soul',
        'icon': 'eye',
      },
      {
        'title': 'Brush Teeth',
        'quote': 'Teeth are always in style',
        'icon': 'smile',
      },
      {'title': 'Take a Shower', 'quote': 'Wash off the day', 'icon': 'drop'},
      {
        'title': 'Do Skincare',
        'quote': 'May your day be as flawless as your skin',
        'icon': 'sparkles',
      },
      {
        'title': 'Keep fit',
        'quote': 'Keep fit for your life, not just for summer',
        'icon': 'fitness',
      },
      {
        'title': 'Quit Smoking',
        'quote': 'Smoke away from worries, not your lungs',
        'icon': 'smoke_off',
      },
      {
        'title': 'Quit alcohol',
        'quote': 'Stay clean headed',
        'icon': 'no_drink',
      },
    ],
    'SPORTS': [
      {'title': 'Swim', 'quote': 'Let waves be your company', 'icon': 'waves'},
      {
        'title': 'Exercise',
        'quote': 'Energize your body and sharpen your mind',
        'icon': 'dumbell',
      },
      {'title': 'Take a Walk', 'quote': 'Walkers live longer', 'icon': 'walk'},
      {
        'title': 'Stand',
        'quote': 'See this world from another perspective',
        'icon': 'stand',
      },
      {
        'title': 'Do Neck Exercises',
        'quote': 'For a healthier and more beautiful neck',
        'icon': 'body',
      },
    ],
    'MINDSET': [
      {
        'title': 'Complain Less',
        'quote': 'Complain never makes anything better',
        'icon': 'mouth_off',
      },
      {
        'title': 'Self Reflection',
        'quote': 'Pain plus reflection equals progress',
        'icon': 'mirror',
      },
      {
        'title': 'Plan your day',
        'quote': 'Today is going to be a positive day',
        'icon': 'calendar',
      },
      {
        'title': 'Stay Positive',
        'quote': "Tough times don't last, but tough people do",
        'icon': 'sun',
      },
      {
        'title': 'Groom Yourself',
        'quote': 'Dress the way you want to be addressed',
        'icon': 'shirt',
      },
      {
        'title': 'No Dirty Words',
        'quote': 'You are what you say',
        'icon': 'chat_off',
      },
      {
        'title': 'Say I Love You',
        'quote': 'Most powerful three words',
        'icon': 'heart_text',
      },
      {
        'title': 'Smile to yourself',
        'quote': 'Good luck comes to you when you smile',
        'icon': 'smile_face',
      },
    ],
  };

  void _openCreateSheet(BuildContext context, {Map<String, String>? preset}) {
    Navigator.pop(context); // Close gallery
    showCupertinoModalPopup(
      context: context,
      builder: (_) => AddHabitSheet(preset: preset),
    );
  }

  IconData _presetIcon(String? iconName) {
    switch (iconName) {
      case 'check':
        return CupertinoIcons.check_mark_circled;
      case 'music':
        return CupertinoIcons.music_note_2;
      case 'headphones':
        return CupertinoIcons.headphones;
      case 'film':
      case 'tv':
        return CupertinoIcons.tv;
      case 'phone_off':
        return CupertinoIcons.phone_down_fill;
      case 'book':
      case 'book_open':
      case 'notebook':
        return CupertinoIcons.book;
      case 'globe':
        return CupertinoIcons.globe;
      case 'pencil':
        return CupertinoIcons.pencil;
      case 'money':
        return CupertinoIcons.money_dollar_circle;
      case 'heart':
      case 'heart_text':
      case 'hand_heart':
        return CupertinoIcons.heart;
      case 'camera':
        return CupertinoIcons.camera;
      case 'home':
        return CupertinoIcons.home;
      case 'flower':
      case 'leaf':
        return CupertinoIcons.leaf_arrow_circlepath;
      case 'dog':
        return CupertinoIcons.paw;
      case 'cat':
        return CupertinoIcons.paw_solid;
      case 'newspaper':
        return CupertinoIcons.news;
      case 'pill':
        return CupertinoIcons.bandage;
      case 'eye':
        return CupertinoIcons.eye;
      case 'drop':
      case 'water':
        return CupertinoIcons.drop;
      case 'fitness':
      case 'dumbell':
        return CupertinoIcons.sportscourt;
      case 'smoke_off':
      case 'no_drink':
        return CupertinoIcons.nosign;
      case 'waves':
        return CupertinoIcons.waveform_path;
      case 'walk':
        return CupertinoIcons.person;
      case 'stand':
      case 'body':
        return CupertinoIcons.person;
      case 'calendar':
        return CupertinoIcons.calendar;
      case 'sun':
        return CupertinoIcons.sun_max;
      case 'moon':
        return CupertinoIcons.moon;
      default:
        return CupertinoIcons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Protocol Gallery',
                        style: AppTypography.title2.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a blueprint or create custom',
                        style: AppTypography.caption1.copyWith(
                          fontSize: 12,
                          color: AppColors.tertiaryLabel.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              ..._categories.entries.map((entry) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 4),
                        child: Text(
                          entry.key,
                          style: AppTypography.overline.copyWith(
                            fontSize: 12,
                            color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      ...entry.value.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HabitSheetPressScale(
                            onTap: () =>
                                _openCreateSheet(context, preset: item),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.06),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.white.withValues(alpha: 0.06),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      _presetIcon(item['icon']),
                                      color: AppColors.secondaryLabel,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title']!,
                                          style: AppTypography.headline.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['quote']!,
                                          style: AppTypography.caption1.copyWith(
                                            fontSize: 11,
                                            color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: AppColors.tertiaryLabel,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                );
              }),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0),
                  ],
                ),
              ),
              child: _HabitSheetPressScale(
                onTap: () => _openCreateSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Create Custom Protocol',
                      style: AppTypography.callout.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.label,
                      ),
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
}

class _HabitSheetPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HabitSheetPressScale({required this.child, required this.onTap});

  @override
  State<_HabitSheetPressScale> createState() => _HabitSheetPressScaleState();
}

class _HabitSheetPressScaleState extends State<_HabitSheetPressScale> {
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
