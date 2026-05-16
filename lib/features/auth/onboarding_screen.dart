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
  final PageController _controller = PageController();
  int _page = 0;

  String _goal = 'Execution';
  String _discipline = 'Intermediate';
  String _focusChallenge = 'Distractions';

  static const _slides = [
    (
      icon: CupertinoIcons.chart_bar_alt_fill,
      title: 'Operate Like a CEO',
      subtitle: 'Tasks, habits, calendar, and focus in one execution system.',
    ),
    (
      icon: CupertinoIcons.flame_fill,
      title: 'Build Compounding Habits',
      subtitle: 'Track consistency daily and recover quickly when you miss.',
    ),
    (
      icon: CupertinoIcons.timer_fill,
      title: 'Protect Deep Work',
      subtitle:
          'Use focus sessions and blocking to reduce context switching. On iPhone, blocking uses Apple Screen Time / Family Controls APIs and requires permission on that device.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _page = _slides.length);
  }

  @override
  Widget build(BuildContext context) {
    final showingQuestionnaire = _page >= _slides.length;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.07),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: CupertinoColors.transparent),
              ),
            ),
          ),
          DefaultTextStyle.merge(
            style: TextStyle(
              decoration: TextDecoration.none,
              decorationColor: Color(0x00000000),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                  Row(
                    children: [
                      Text(
                        'CEO OS',
                        style: AppTypography.mono.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.label,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'LOG IN',
                          style: AppTypography.mono.copyWith(
                            fontSize: 11,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: showingQuestionnaire
                        ? _Questionnaire(
                            goal: _goal,
                            discipline: _discipline,
                            focusChallenge: _focusChallenge,
                            onGoal: (v) => setState(() => _goal = v),
                            onDiscipline: (v) =>
                                setState(() => _discipline = v),
                            onFocusChallenge: (v) =>
                                setState(() => _focusChallenge = v),
                          )
                        : PageView.builder(
                            controller: _controller,
                            itemCount: _slides.length,
                            onPageChanged: (v) => setState(() => _page = v),
                            itemBuilder: (_, i) {
                              final s = _slides[i];
                              return _Slide(
                                icon: s.icon,
                                title: s.title,
                                subtitle: s.subtitle,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  if (!showingQuestionnaire)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = _page == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 20 : 7,
                          height: 4,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primaryOrange
                                : AppColors.glassBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 18),
                  if (showingQuestionnaire)
                    Column(
                      children: [
                        LiquidButton(
                          label: 'START_SETUP',
                          fullWidth: true,
                          onPressed: () => context.go('/signup'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can adjust these preferences later in Settings.',
                          style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ],
                    )
                  else
                    LiquidButton(
                      label: _page == _slides.length - 1 ? 'CONTINUE' : 'NEXT',
                      fullWidth: true,
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(28),
          borderRadius: 28,
          child: Icon(icon, size: 46, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          style: AppTypography.mono.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: AppTypography.mono.copyWith(
            fontSize: 12,
            color: AppColors.secondaryLabel,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Questionnaire extends StatelessWidget {
  final String goal;
  final String discipline;
  final String focusChallenge;
  final ValueChanged<String> onGoal;
  final ValueChanged<String> onDiscipline;
  final ValueChanged<String> onFocusChallenge;

  const _Questionnaire({
    required this.goal,
    required this.discipline,
    required this.focusChallenge,
    required this.onGoal,
    required this.onDiscipline,
    required this.onFocusChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          'Quick setup',
          style: AppTypography.mono.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inspired by CEOV1 onboarding: define your operating profile before entering the app.',
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 16),
        _QBlock(
          label: 'Primary goal',
          value: goal,
          options: const ['Execution', 'Consistency', 'Focus', 'Planning'],
          onChanged: onGoal,
        ),
        const SizedBox(height: 10),
        _QBlock(
          label: 'Current discipline',
          value: discipline,
          options: const ['Beginner', 'Intermediate', 'Advanced'],
          onChanged: onDiscipline,
        ),
        const SizedBox(height: 10),
        _QBlock(
          label: 'Main focus challenge',
          value: focusChallenge,
          options: const [
            'Distractions',
            'Overload',
            'Inconsistency',
            'Planning',
          ],
          onChanged: onFocusChallenge,
        ),
      ],
    );
  }
}

class _QBlock extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _QBlock({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => GestureDetector(
                    onTap: () => onChanged(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: value == option
                            ? AppColors.primaryOrange.withValues(alpha: 0.18)
                            : AppColors.backgroundLight.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: value == option
                              ? AppColors.primaryOrange.withValues(alpha: 0.35)
                              : AppColors.glassBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        option.toUpperCase(),
                        style: AppTypography.mono.copyWith(
                          fontSize: 10,
                          color: value == option
                              ? AppColors.primaryOrange
                              : AppColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
