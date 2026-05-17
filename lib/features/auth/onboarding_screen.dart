import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/onboarding_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/premium_repository.dart';
import '../../core/models/premium_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_catalog.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _OnboardingPressScale({
    required this.child,
    required this.onTap,
  });

  @override
  State<_OnboardingPressScale> createState() => _OnboardingPressScaleState();
}

class _OnboardingPressScaleState extends State<_OnboardingPressScale> {
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
        scale: _pressed ? 0.97 : 1,
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

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  String _goal = 'Execution';
  String _discipline = 'Intermediate';
  String _focusChallenge = 'Distractions';
  String _selectedThemePresetId = ThemeCatalog.defaultPresetId;
  bool _didLoadInitialTheme = false;
  final PremiumRepository _premiumRepository = PremiumRepository();
  late final Future<PremiumRuntime> _premiumRuntimeFuture =
      _premiumRepository.getRuntime();

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialTheme) return;
    final themeProvider = context.read<ThemeProvider>();
    _selectedThemePresetId = themeProvider.onboardingCurrentThemeId;
    themeProvider.previewTheme(_selectedThemePresetId);
    _didLoadInitialTheme = true;
  }

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
    final language = context.watch<LanguageProvider>();
    final showingQuestionnaire = _page >= _slides.length;
    final totalSteps = _slides.length + 1;
    final currentStep = showingQuestionnaire ? totalSteps : (_page + 1);
    final progress = currentStep / totalSteps;

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
                child: Container(
                  color: AppColors.overlayScrim.withValues(alpha: 0),
                ),
              ),
            ),
          ),
          DefaultTextStyle.merge(
            style: const TextStyle(
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
                        _t('app_name'),
                        style: AppTypography.title3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.label,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _t(
                            'onboarding_step_of',
                          ).replaceAll('{step}', '$currentStep').replaceAll(
                            '{total}',
                            '$totalSteps',
                          ),
                          style: AppTypography.footnote.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryLabel.withValues(
                              alpha: 0.6,
                            ),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: _showLanguagePicker,
                        child: Text(
                          _languageDisplayLabel(language.languageCode),
                          style: AppTypography.footnote.copyWith(
                            fontSize: 12,
                            color: AppColors.tertiaryLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () => context.go('/login'),
                        child: Text(
                          _t('onboarding_log_in'),
                          style: AppTypography.footnote.copyWith(
                            fontSize: 12,
                            color: AppColors.tertiaryLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.white.withValues(alpha: 0.08),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, _) {
                        return FractionallySizedBox(
                          widthFactor: animatedProgress,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF4C7DFF),
                                  Color(0xFF7EA4FF),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: showingQuestionnaire
                        ? FutureBuilder<PremiumRuntime>(
                            future: _premiumRuntimeFuture,
                            builder: (context, snapshot) {
                              final runtime = snapshot.data;
                              final themeProvider = context
                                  .read<ThemeProvider>();
                              return _Questionnaire(
                                goal: _goal,
                                discipline: _discipline,
                                focusChallenge: _focusChallenge,
                                selectedThemePresetId: _selectedThemePresetId,
                                premiumRuntime: runtime,
                                language: language,
                                onGoal: (v) => setState(() => _goal = v),
                                onDiscipline: (v) =>
                                    setState(() => _discipline = v),
                                onFocusChallenge: (v) =>
                                    setState(() => _focusChallenge = v),
                                onThemeSelected: (presetId) async {
                                  final themeCheck = await _premiumRepository
                                      .canUseTheme(presetId);
                                  if (!context.mounted) return;
                                  if (!themeCheck.allowed) {
                                    await showPremiumGateDialog(
                                      context,
                                      themeCheck,
                                    );
                                    return;
                                  }
                                  setState(
                                    () => _selectedThemePresetId = presetId,
                                  );
                                  themeProvider.selectThemeForOnboarding(
                                    presetId,
                                  );
                                },
                              );
                            },
                          )
                        : PageView.builder(
                            controller: _controller,
                            itemCount: _slides.length,
                            onPageChanged: (v) => setState(() => _page = v),
                            itemBuilder: (_, i) {
                              final s = _slides[i];
                              return _Slide(
                                icon: s.icon,
                                title: _t(s.titleKey),
                                subtitle: _t(s.subtitleKey),
                                isFocusSlide: i == _slides.length - 1,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalSteps, (i) {
                      final activeIndex = showingQuestionnaire
                          ? totalSteps - 1
                          : _page;
                      final active = activeIndex == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF4C7DFF)
                              : AppColors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  if (showingQuestionnaire)
                    Column(
                      children: [
                        _OnboardingPrimaryButton(
                          label: _t('onboarding_enter_wakeapp'),
                          onTap: () {
                            final setup = OnboardingSetupData(
                              goal: _localizedGoal(language, _goal),
                              discipline: _localizedDiscipline(
                                language,
                                _discipline,
                              ),
                              focusChallenge: _localizedConstraint(
                                language,
                                _focusChallenge,
                              ),
                              themePresetId: _selectedThemePresetId,
                            );
                            context
                                .read<ThemeProvider>()
                                .setPendingOnboardingSetup(setup);
                            context.go('/signup', extra: setup);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t('onboarding_adjust_later_settings'),
                          style: AppTypography.caption1.copyWith(
                            fontSize: 11,
                            color: AppColors.tertiaryLabel.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    _OnboardingPrimaryButton(
                      label: _page == _slides.length - 1 ? 'CONTINUE' : 'NEXT',
                      onTap: _next,
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
  final bool isFocusSlide;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isFocusSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cardBackgroundAlt,
                AppColors.cardBackgroundStrong,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: isFocusSlide ? 0.45 : 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              if (isFocusSlide)
                BoxShadow(
                  color: const Color(0xFF4C7DFF).withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: isFocusSlide ? 38 : 36,
            color: const Color(0xFF4C7DFF),
            shadows: [
              Shadow(
                color: const Color(0xFF4C7DFF).withValues(
                  alpha: isFocusSlide ? 0.35 : 0.25,
                ),
                blurRadius: isFocusSlide ? 10 : 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            title,
            style: AppTypography.title1.copyWith(
              fontSize: isFocusSlide ? 36 : 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: isFocusSlide ? 16 : 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            subtitle,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              color: AppColors.secondaryLabel.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OnboardingPrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _OnboardingPressScale(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF4C7DFF), Color(0xFF6FA2FF)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4C7DFF).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _Questionnaire extends StatelessWidget {
  final String goal;
  final String discipline;
  final String focusChallenge;
  final String selectedThemePresetId;
  final PremiumRuntime? premiumRuntime;
  final LanguageProvider language;
  final ValueChanged<String> onGoal;
  final ValueChanged<String> onDiscipline;
  final ValueChanged<String> onFocusChallenge;
  final Future<void> Function(String) onThemeSelected;

  const _Questionnaire({
    required this.goal,
    required this.discipline,
    required this.focusChallenge,
    required this.selectedThemePresetId,
    required this.premiumRuntime,
    required this.language,
    required this.onGoal,
    required this.onDiscipline,
    required this.onFocusChallenge,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTheme = ThemeCatalog.resolveById(selectedThemePresetId);
    String localizeGoal(String value) {
      switch (value) {
        case 'Execution':
          return language.t('onboarding_goal_execution');
        case 'Consistency':
          return language.t('onboarding_goal_consistency');
        case 'Focus':
          return language.t('onboarding_goal_focus');
        case 'Planning':
          return language.t('onboarding_goal_planning');
        default:
          return value;
      }
    }

    String localizeTheme(AppThemePreset preset) {
      switch (preset.id) {
        case 'carbon_system':
          return language.t('theme_carbon_system');
        case 'ember_protocol':
          return language.t('theme_ember_protocol');
        case 'royal_violet':
          return language.t('theme_royal_violet');
        case 'modern_desert':
          return language.t('theme_modern_desert');
        case 'cloud_studio':
          return language.t('theme_cloud_studio');
        default:
          return preset.name;
      }
    }

    String localizeDiscipline(String value) {
      switch (value) {
        case 'Beginner':
          return language.t('onboarding_level_beginner');
        case 'Intermediate':
          return language.t('onboarding_level_intermediate');
        case 'Advanced':
          return language.t('onboarding_level_advanced');
        default:
          return value;
      }
    }

    String localizeConstraint(String value) {
      switch (value) {
        case 'Distractions':
          return language.t('onboarding_constraint_distractions');
        case 'Overload':
          return language.t('onboarding_constraint_overload');
        case 'Inconsistency':
          return language.t('onboarding_constraint_inconsistency');
        default:
          return value;
      }
    }

    return ListView(
      children: [
        Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.cardBackgroundAlt,
                    AppColors.cardBackgroundStrong,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFF4C7DFF).withValues(alpha: 0.10),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 38,
                color: const Color(0xFF4C7DFF),
                shadows: [
                  Shadow(
                    color: const Color(0xFF4C7DFF).withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Quick setup',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'Define your operating profile before entering the app.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  fontSize: 15,
                  color: AppColors.secondaryLabel.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'CONFIGURATION',
          style: AppTypography.body.copyWith(
            fontSize: 12,
            color: AppColors.secondaryLabel.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 10),
        _ThemeSelectorBlock(
          selectedThemePresetId: selectedThemePresetId,
          onThemeSelected: onThemeSelected,
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 14,
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.18),
            width: 0.55,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPERATING_PROFILE'.toUpperCase(),
                style: AppTypography.mono.copyWith(
                  fontSize: 9,
                  color: AppColors.tertiaryLabel,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              _summaryRow('GOAL', goal.toUpperCase()),
              const SizedBox(height: 4),
              _summaryRow('DISCIPLINE', discipline.toUpperCase()),
              const SizedBox(height: 4),
              _summaryRow('FOCUS', focusChallenge.toUpperCase()),
              const SizedBox(height: 4),
              _summaryRow('THEME', selectedTheme.name.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: AppColors.tertiaryLabel,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeSelectorBlock extends StatelessWidget {
  final PremiumRuntime? premiumRuntime;
  final String selectedThemePresetId;
  final Future<void> Function(String) onThemeSelected;

  const _ThemeSelectorBlock({
    required this.premiumRuntime,
    required this.selectedThemePresetId,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentThemeId = context.watch<ThemeProvider>().currentPreset.id;
    final darkPresets = ThemeCatalog.presets.where((p) => p.isDark).toList();
    final lightPresets = ThemeCatalog.presets.where((p) => !p.isDark).toList();

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual theme'.toUpperCase(),
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: AppColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a color and type system. Preview updates instantly.',
            style: AppTypography.mono.copyWith(
              fontSize: 10,
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'DARK',
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: AppColors.tertiaryLabel,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: darkPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final preset = darkPresets[i];
                return _ThemePreviewCard(
                  preset: preset,
                  selected: selectedThemePresetId == preset.id,
                  isCurrentTheme: currentThemeId == preset.id,
                  onTap: () => onThemeSelected(preset.id),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'LIGHT',
            style: AppTypography.mono.copyWith(
              fontSize: 9,
              color: AppColors.tertiaryLabel,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lightPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final preset = lightPresets[i];
                return _ThemePreviewCard(
                  preset: preset,
                  selected: selectedThemePresetId == preset.id,
                  isCurrentTheme: currentThemeId == preset.id,
                  onTap: () => onThemeSelected(preset.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final AppThemePreset preset;
  final bool selected;
  final bool isCurrentTheme;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.preset,
    required this.selected,
    required this.isCurrentTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preset.colors;
    final borderColor = selected ? colors.accent : colors.glassBorder;
    final titleStyle = _previewTitleStyle(preset.typography).copyWith(
      color: colors.label,
    );
    final subtitleStyle = _previewBodyStyle(preset.typography).copyWith(
      color: colors.secondaryLabel,
      fontSize: 9,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: semantic.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor.withValues(alpha: selected ? 1 : 0.6),
            width: selected ? 1.4 : 0.8,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    preset.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle.copyWith(
                      fontSize: 8,
                      color: semantic.tertiaryText,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (isCurrentTheme)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: semantic.accentSurfaceSoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: semantic.accentBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'CURRENT',
                      style: subtitleStyle.copyWith(
                        fontSize: 7,
                        color: palette.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    semantic.dashboardGradientStart,
                    semantic.dashboardGradientEnd,
                  ],
                ),
                color: semantic.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: semantic.cardBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CEO OS', style: titleStyle.copyWith(fontSize: 12)),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: semantic.cardBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preset.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _previewTitleStyle(AppTypographyProfile profile) {
    switch (profile) {
      case AppTypographyProfile.technical:
        return AppTypography.title3.copyWith(fontWeight: FontWeight.w700);
      case AppTypographyProfile.editorial:
        return AppTypography.title2.copyWith(fontWeight: FontWeight.w600);
      case AppTypographyProfile.neo:
        return AppTypography.title3.copyWith(fontWeight: FontWeight.w700);
    }
  }

  TextStyle _previewBodyStyle(AppTypographyProfile profile) {
    switch (profile) {
      case AppTypographyProfile.technical:
        return AppTypography.caption1;
      case AppTypographyProfile.editorial:
        return AppTypography.footnote;
      case AppTypographyProfile.neo:
        return AppTypography.caption1;
    }
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
