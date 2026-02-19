import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../components/components.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _Page(
      icon: CupertinoIcons.layers_fill,
      title: 'CORE_SYSTEM',
      subtitle:
          'Advanced AI productivity matrix\ndesigned for high-performance operators.',
    ),
    _Page(
      icon: CupertinoIcons.waveform_path_ecg,
      title: 'NEURAL_HABITS',
      subtitle:
          'Rewire your focus with biometric\ntracking and consistency protocols.',
    ),
    _Page(
      icon: CupertinoIcons.shield_lefthalf_fill,
      title: 'FOCUS_SHIELD',
      subtitle:
          'Active distraction blocking to protect\nyour cognitive bandwidth.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: CupertinoColors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(20),
                    onPressed: () => context.go('/signup'),
                    child: Text(
                      'SKIP_PROTOCOL',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.secondaryLabel,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) {
                      final page = _pages[i];
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(32),
                              borderRadius: 40,
                              child: Icon(
                                page.icon,
                                color: AppColors.primaryOrange,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 48),
                            NeoMonoText(
                              page.title,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              page.subtitle.toUpperCase(),
                              style: AppTypography.mono.copyWith(
                                color: AppColors.secondaryLabel,
                                fontSize: 12,
                                height: 1.6,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 32 : 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? AppColors.primaryOrange
                                  : AppColors.glassBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      LiquidButton(
                        label: _currentPage == _pages.length - 1
                            ? 'INITIALIZE'
                            : 'NEXT_PHASE',
                        fullWidth: true,
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutQuart,
                            );
                          } else {
                            context.go('/signup');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Page {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Page({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
