import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../components/liquid_button.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/repositories/premium_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_catalog.dart';

class ThemePickerScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const ThemePickerScreen({super.key, required this.onContinue});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  Set<String> _premiumThemeIds = const {};
  bool _isUserPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    try {
      final repo = PremiumRepository();
      final runtime = await repo.getRuntime();
      if (!mounted) return;
      setState(() {
        _premiumThemeIds = runtime.config.premiumThemes;
        _isUserPremium = runtime.resolved.isPremiumUser;
      });
    } catch (_) {}
  }

  bool _isPremium(String presetId) => _premiumThemeIds.contains(presetId);

  void _onSelect(BuildContext context, AppThemePreset preset) {
    if (_isPremium(preset.id) && !_isUserPremium) {
      // Premium gating: don't select but could open paywall here.
      return;
    }
    context.read<ThemeProvider>().selectThemeForOnboarding(preset.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();
    final isFr = language.languageCode.toLowerCase().startsWith('fr');
    final selectedId = theme.currentPreset.id;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              isFr ? 'Choisis ton thème' : 'Choose your theme',
              style: AppTypography.largeTitle.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.label,
                height: 1.05,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFr
                  ? 'Tu pourras le changer à tout moment depuis le menu.'
                  : 'You can change it anytime from the menu.',
              style: AppTypography.body.copyWith(
                fontSize: 15,
                color: AppColors.secondaryLabel.withValues(alpha: 0.78),
                height: 1.32,
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: ThemeCatalog.presets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final preset = ThemeCatalog.presets[index];
                  return _ThemeRow(
                    preset: preset,
                    selected: preset.id == selectedId,
                    premium: _isPremium(preset.id),
                    locked: _isPremium(preset.id) && !_isUserPremium,
                    isFr: isFr,
                    onTap: () => _onSelect(context, preset),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            LiquidButton(
              label: isFr ? 'Continuer' : 'Continue',
              onPressed: widget.onContinue,
              fullWidth: true,
              height: 54,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final AppThemePreset preset;
  final bool selected;
  final bool premium;
  final bool locked;
  final bool isFr;
  final VoidCallback onTap;

  const _ThemeRow({
    required this.preset,
    required this.selected,
    required this.premium,
    required this.locked,
    required this.isFr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = preset.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.cardBackgroundStrong.withValues(alpha: 0.46),
            border: Border.all(
              color: selected
                  ? AppColors.label.withValues(alpha: 0.55)
                  : AppColors.border.withValues(alpha: 0.30),
              width: selected ? 0.8 : 0.5,
            ),
          ),
          child: Row(
            children: [
              _ThemeSwatch(palette: palette),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            preset.name,
                            style: AppTypography.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.label,
                            ),
                          ),
                        ),
                        if (premium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.cardBackgroundStrong.withValues(
                                alpha: 0.70,
                              ),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.40),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'PREMIUM',
                              style: AppTypography.overline.copyWith(
                                fontSize: 9,
                                color: AppColors.secondaryLabel,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localizedSubtitle(preset.id),
                      style: AppTypography.subhead.copyWith(
                        fontSize: 13,
                        color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SelectionRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedSubtitle(String id) {
    if (!isFr) return preset.subtitle;
    switch (id) {
      case 'carbon_system':
        return 'Sombre, sobre, par défaut.';
      case 'cloud_studio':
        return 'Clair, doux, propre.';
      case 'ember_protocol':
        return 'Sombre orange, énergique.';
      case 'royal_violet':
        return 'Violet profond, premium.';
      case 'modern_desert':
        return 'Crème chaud, premium.';
      default:
        return preset.subtitle;
    }
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppThemePalette palette;

  const _ThemeSwatch({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: palette.bgPrimary,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: palette.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionRadio extends StatelessWidget {
  final bool selected;

  const _SelectionRadio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.label.withValues(alpha: 0.18)
            : AppColors.background.withValues(alpha: 0.30),
        border: Border.all(
          color: selected
              ? AppColors.label.withValues(alpha: 0.85)
              : AppColors.border.withValues(alpha: 0.35),
          width: selected ? 1.2 : 0.5,
        ),
      ),
      child: selected
          ? Icon(
              CupertinoIcons.checkmark_alt,
              size: 14,
              color: AppColors.label,
            )
          : null,
    );
  }
}
