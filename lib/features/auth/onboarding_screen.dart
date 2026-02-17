import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_button.dart';

/// Onboarding — clean, Apple HIG compliant.
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
      icon: CupertinoIcons.checkmark_circle,
      title: 'Organize Everything',
      subtitle: 'Tasks, priorities, and deadlines\nin one focused workspace.',
    ),
    _Page(
      icon: CupertinoIcons.flame,
      title: 'Build Consistency',
      subtitle: 'Track habits with streaks\nand daily check-ins.',
    ),
    _Page(
      icon: CupertinoIcons.shield,
      title: 'Eliminate Distractions',
      subtitle: 'Pomodoro timer and app blocking\nto protect your focus time.',
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
      backgroundColor: AppColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: CupertinoButton(
                padding: const EdgeInsets.all(AppSpacing.md),
                onPressed: () => context.go('/tasks'),
                child: Text(
                  'Skip',
                  style: AppTypography.body.copyWith(
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: AppSpacing.screenPadding.copyWith(
                      top: AppSpacing.xxxl,
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                            border: Border.all(
                              color: AppColors.separator,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            page.icon,
                            color: AppColors.secondaryLabel,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page.title,
                          style: AppTypography.largeTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.subtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.secondaryLabel,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicators + Continue button
            Padding(
              padding: AppSpacing.screenPadding.copyWith(
                top: 0,
                bottom: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.systemBlue
                              : AppColors.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CeoButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    expand: true,
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/tasks');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
