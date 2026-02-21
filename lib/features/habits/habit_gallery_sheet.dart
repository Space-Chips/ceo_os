import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../../components/components.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'add_habit_sheet.dart';

class HabitGallerySheet extends StatelessWidget {
  const HabitGallerySheet({super.key});

  final Map<String, List<Map<String, String>>> _categories = const {
    'LIFE': [
      {'title': 'Daily Check-in', 'quote': 'Try a little harder to be a little better', 'icon': 'check'},
      {'title': 'Learn Musical Instruments', 'quote': 'Get some inspirations from your own melody', 'icon': 'music'},
      {'title': 'Listen to Music', 'quote': 'Get in the right mood', 'icon': 'headphones'},
      {'title': 'Watch a Movie', 'quote': 'Experience life in another way', 'icon': 'film'},
      {'title': 'Reduce Screen Time', 'quote': 'Disconnect from the phone and reconnect to...', 'icon': 'phone_off'},
      {'title': 'Learn new words', 'quote': 'Small number, big result', 'icon': 'book'},
      {'title': 'Learn a new language', 'quote': 'Open up a new window to look at the world', 'icon': 'globe'},
      {'title': 'Read', 'quote': 'A chapter a day will light your way', 'icon': 'book_open'},
      {'title': 'Write', 'quote': 'Note down some inspirations', 'icon': 'pencil'},
      {'title': 'Keep a Diary', 'quote': 'Keep a diary and someday it will keep you', 'icon': 'notebook'},
      {'title': 'Track expenses', 'quote': 'Get some financial wisdom', 'icon': 'money'},
      {'title': 'Connect a Loved One', 'quote': 'It\'s always good to get in touch', 'icon': 'heart'},
      {'title': 'No Video Games', 'quote': 'Break free from game addiction', 'icon': 'game_controller_off'},
      {'title': 'Help Others', 'quote': 'It is better to give than to take', 'icon': 'hand_heart'},
      {'title': 'Take photos', 'quote': 'Capture your happy moments', 'icon': 'camera'},
      {'title': 'Clean up', 'quote': 'Ready for best productivity', 'icon': 'broom'},
      {'title': 'Do Housework', 'quote': 'Live away from a mess', 'icon': 'home'},
      {'title': 'Water Flowers', 'quote': 'Every flower is a soul blossoming in nature', 'icon': 'flower'},
      {'title': 'Walk the Dog', 'quote': 'Happiness Is a long walk with your dog', 'icon': 'dog'},
      {'title': 'Be a Good Cat Keeper', 'quote': 'Comfort yourself by comforting your cat', 'icon': 'cat'},
      {'title': 'Watch a Documentary', 'quote': 'Explore the magic and the unknown world', 'icon': 'tv'},
      {'title': 'Get News Updates', 'quote': 'Stay-informed about the world', 'icon': 'newspaper'},
      {'title': 'Watch TV Shows', 'quote': 'Spice up your life', 'icon': 'tv'},
      {'title': 'Watch Soap Opera', 'quote': 'Stop thinking, just have fun', 'icon': 'tv'},
    ],
    'HEALTH': [
      {'title': 'Take Medicine', 'quote': 'Never forget to take your pills again', 'icon': 'pill'},
      {'title': 'Take Care of Eyes', 'quote': 'Eyes are windows to the soul', 'icon': 'eye'},
      {'title': 'Brush Teeth', 'quote': 'Teeth are always in style', 'icon': 'smile'},
      {'title': 'Take a Shower', 'quote': 'Wash off the day', 'icon': 'drop'},
      {'title': 'Do Skincare', 'quote': 'May your day be as flawless as your skin', 'icon': 'sparkles'},
      {'title': 'Keep fit', 'quote': 'Keep fit for your life, not just for summer', 'icon': 'fitness'},
      {'title': 'Quit Smoking', 'quote': 'Smoke away from worries, not your lungs', 'icon': 'smoke_off'},
      {'title': 'Quit alcohol', 'quote': 'Stay clean headed', 'icon': 'no_drink'},
    ],
    'SPORTS': [
      {'title': 'Swim', 'quote': 'Let waves be your company', 'icon': 'waves'},
      {'title': 'Exercise', 'quote': 'Energize your body and sharpen your mind', 'icon': 'dumbell'},
      {'title': 'Take a Walk', 'quote': 'Walkers live longer', 'icon': 'walk'},
      {'title': 'Stand', 'quote': 'See this world from another perspective', 'icon': 'stand'},
      {'title': 'Do Neck Exercises', 'quote': 'For a healthier and more beautiful neck', 'icon': 'body'},
    ],
    'MINDSET': [
      {'title': 'Complain Less', 'quote': 'Complain never makes anything better', 'icon': 'mouth_off'},
      {'title': 'Self Reflection', 'quote': 'Pain plus reflection equals progress', 'icon': 'mirror'},
      {'title': 'Plan your day', 'quote': 'Today is going to be a positive day', 'icon': 'calendar'},
      {'title': 'Stay Positive', 'quote': 'Tough times don’t last, but tough people do', 'icon': 'sun'},
      {'title': 'Groom Yourself', 'quote': 'Dress the way you want to be addressed', 'icon': 'shirt'},
      {'title': 'No Dirty Words', 'quote': 'You are what you say', 'icon': 'chat_off'},
      {'title': 'Say I Love You', 'quote': 'Most powerful three words', 'icon': 'heart_text'},
      {'title': 'Smile to yourself', 'quote': 'Good luck comes to you when you smile', 'icon': 'smile_face'},
    ],
  };

  void _openCreateSheet(BuildContext context, {Map<String, String>? preset}) {
    Navigator.pop(context); // Close gallery
    showCupertinoModalPopup(
      context: context,
      builder: (_) => AddHabitSheet(preset: preset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
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
                      const NeoMonoText('PROTOCOL_GALLERY', fontSize: 20, fontWeight: FontWeight.bold),
                      const SizedBox(height: 8),
                      Text(
                        'SELECT_A_BLUEPRINT_OR_CREATE_CUSTOM',
                        style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.tertiaryLabel),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              ..._categories.entries.map((entry) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 4),
                        child: Text(
                          entry.key,
                          style: AppTypography.mono.copyWith(
                            fontSize: 12,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...entry.value.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _openCreateSheet(context, preset: item),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(CupertinoIcons.star_fill, color: AppColors.primaryOrange, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title']!.toUpperCase(),
                                        style: AppTypography.mono.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['quote']!,
                                        style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.secondaryLabel),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(CupertinoIcons.chevron_right, color: AppColors.tertiaryLabel, size: 16),
                              ],
                            ),
                          ),
                        ),
                      )),
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
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.background,
                        AppColors.background.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: LiquidButton(
                    label: 'CREATE_CUSTOM_PROTOCOL',
                    fullWidth: true,
                    onPressed: () => _openCreateSheet(context),
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
