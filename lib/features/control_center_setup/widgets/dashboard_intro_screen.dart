import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../components/liquid_button.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';

class DashboardIntroScreen extends StatefulWidget {
  final ControlCenterSetupState state;
  final VoidCallback onContinue;

  const DashboardIntroScreen({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  State<DashboardIntroScreen> createState() => _DashboardIntroScreenState();
}

class _DashboardIntroScreenState extends State<DashboardIntroScreen>
    with SingleTickerProviderStateMixin {
  // Master timeline: 0..1 → 4-phase choreography.
  // Phase 1 — tap user icon: 0.00 → 0.14
  //   sub: pulse 0.00-0.08, ripple 0.08-0.14
  // Phase 2 — menu opens + toggles ON: 0.14 → 0.50
  //   sub: slide-in 0.14-0.26, toggles cascade 0.26-0.50
  // Pause: 0.50 → 0.56
  // Phase 3 — 2 toggles flip OFF: 0.56 → 0.74
  // Pause: 0.74 → 0.80
  // Phase 4 — menu slides OUT, home revealed with only 2 items: 0.80 → 0.94
  // Hold: 0.94 → 1.00, then loop.
  late final AnimationController _master;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6800),
    )..repeat();
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  double _interval(double start, double end, [Curve curve = Curves.easeOutCubic]) {
    final t = ((_master.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final state = widget.state;
    final modules = state.selectedModules
        .whereType<ControlCenterModuleItem>()
        .toList(growable: false);
    final shortcuts = state.selectedShortcuts
        .whereType<ControlCenterShortcutItem>()
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ton centre, toujours adaptable',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Active ou désactive tes apps et raccourcis en un geste depuis le menu latéral.",
            style: AppTypography.subhead.copyWith(
              color: AppColors.secondaryLabel.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: AnimatedBuilder(
              animation: _master,
              builder: (context, _) {
                final pulse = _interval(0.00, 0.08, Curves.easeInOut);
                final ripple = _interval(0.08, 0.14);
                final slideIn = _interval(0.14, 0.26);
                final cascade = _interval(0.26, 0.50);
                final offPhase = _interval(0.56, 0.74);
                final slideOut = _interval(0.80, 0.94);
                // menuVisible = slideIn while closing, drops via slideOut
                final menuVisible =
                    (slideIn - slideOut).clamp(0.0, 1.0).toDouble();

                return _AnimationStage(
                  modules: modules,
                  shortcuts: shortcuts,
                  pulse: pulse,
                  ripple: ripple,
                  menuVisible: menuVisible,
                  cascade: cascade,
                  offPhase: offPhase,
                  homeFullReveal: slideOut,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          LiquidButton(label: 'Continuer', onPressed: widget.onContinue),
        ],
      ),
    );
  }
}

class _AnimationStage extends StatelessWidget {
  final List<ControlCenterModuleItem> modules;
  final List<ControlCenterShortcutItem> shortcuts;
  final double pulse;          // 0..1
  final double ripple;         // 0..1
  final double menuVisible;    // 0..1 (in - out)
  final double cascade;        // 0..1 staggered toggles ON
  final double offPhase;       // 0..1 last 2 toggles OFF
  final double homeFullReveal; // 0..1 menu closing — home becomes prominent

  const _AnimationStage({
    required this.modules,
    required this.shortcuts,
    required this.pulse,
    required this.ripple,
    required this.menuVisible,
    required this.cascade,
    required this.offPhase,
    required this.homeFullReveal,
  });

  /// Staggered progress for toggle ON for item index `i` of `count`.
  double _staggerOn(int i, int count) {
    if (count == 0) return 1;
    final span = 1.0 / (count + 1);
    final start = i * span;
    final end = start + span * 2.0;
    final t = ((cascade - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  /// Whether item `i` of `count` is being switched OFF in phase 3.
  /// We turn off the last 2 items (mix of modules + shortcuts list end).
  bool _isOffCandidate(int globalIndex, int total) {
    return globalIndex >= total - 2;
  }

  double _offProgress(int globalIndex, int total) {
    if (!_isOffCandidate(globalIndex, total)) return 0;
    // Stagger the two OFFs slightly: first at 0.0-0.55, second at 0.25-0.85
    final whichOff = globalIndex - (total - 2); // 0 or 1
    final start = whichOff * 0.25;
    final end = start + 0.55;
    final t = ((offPhase - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final total = modules.length + shortcuts.length;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _TopBarMock(pulse: pulse, ripple: ripple),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background: mini home grid (peeks behind menu, then revealed full when menu closes)
              _HomeGridPeek(
                modules: modules,
                shortcuts: shortcuts,
                offFor: (i) => _offProgress(i, total),
                visibility: (0.55 + 0.45 * homeFullReveal).clamp(0.0, 1.0),
                centerShift: homeFullReveal,
              ),
              // Side menu sheet (slides in then out)
              FractionalTranslation(
                translation: Offset(-1.0 + menuVisible, 0),
                child: Opacity(
                  opacity: menuVisible,
                  child: _SideMenuSheet(
                    modules: modules,
                    shortcuts: shortcuts,
                    onProgressFor: (i) => _staggerOn(i, total),
                    offProgressFor: (i) => _offProgress(i, total),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarMock extends StatelessWidget {
  final double pulse;
  final double ripple;

  const _TopBarMock({required this.pulse, required this.ripple});

  @override
  Widget build(BuildContext context) {
    // pulse 0..1 → scale 1.0 → 1.08 → 0.96
    final scale = pulse < 0.5
        ? 1 + pulse * 0.16
        : 1.08 - (pulse - 0.5) * 0.24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.background.withValues(alpha: 0.40),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Ripple
              if (ripple > 0)
                Container(
                  width: 30 + ripple * 38,
                  height: 30 + ripple * 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.label.withValues(
                      alpha: (1 - ripple).clamp(0.0, 1.0) * 0.32,
                    ),
                  ),
                ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundLight.withValues(alpha: 0.30),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.30),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.person_fill,
                    size: 16,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          _topBarPill('WakeApp Pro', 90),
          const SizedBox(width: 8),
          _topBarChip(CupertinoIcons.bolt_fill),
          const SizedBox(width: 8),
          _topBarChip(CupertinoIcons.doc_text_fill),
        ],
      ),
    );
  }

  Widget _topBarPill(String label, double width) {
    return Container(
      width: width,
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.backgroundLight.withValues(alpha: 0.30),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.arrow_up_circle_fill,
            size: 10,
            color: AppColors.secondaryLabel,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.footnote.copyWith(
                fontSize: 9,
                color: AppColors.secondaryLabel,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBarChip(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundLight.withValues(alpha: 0.30),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Icon(icon, size: 14, color: AppColors.secondaryLabel),
    );
  }
}

class _HomeGridPeek extends StatelessWidget {
  final List<ControlCenterModuleItem> modules;
  final List<ControlCenterShortcutItem> shortcuts;
  final double Function(int globalIndex) offFor;
  final double visibility;
  final double centerShift; // 0 = peeking right, 1 = centered (menu closed)

  const _HomeGridPeek({
    required this.modules,
    required this.shortcuts,
    required this.offFor,
    required this.visibility,
    required this.centerShift,
  });

  @override
  Widget build(BuildContext context) {
    final items = <ControlCenterItem>[...modules, ...shortcuts];
    final showLimit = items.length.clamp(0, 4);
    // When menu is open (centerShift=0): left padding = 70 (peek), opacity 0.55.
    // When menu closes (centerShift=1): left padding = 0 (full width), opacity 1.0.
    final leftPad = 70.0 * (1 - centerShift);
    return Opacity(
      opacity: visibility,
      child: Padding(
        padding: EdgeInsets.only(left: leftPad, top: 14, bottom: 6),
        child: Column(
          children: [
            for (int row = 0; row < 2; row++)
              Padding(
                padding: EdgeInsets.only(bottom: row == 0 ? 10 : 0),
                child: Row(
                  children: [
                    for (int col = 0; col < 2; col++)
                      Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(right: col == 0 ? 10 : 0),
                          child: _slotCell(
                            items: items,
                            index: row * 2 + col,
                            limit: showLimit,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _slotCell({
    required List<ControlCenterItem> items,
    required int index,
    required int limit,
  }) {
    if (index >= limit) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.background.withValues(alpha: 0.20),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.16),
              width: 0.5,
            ),
          ),
        ),
      );
    }
    final item = items[index];
    final off = offFor(index);
    // off=0 → fully visible; off=1 → faded + scaled down
    final opacity = (1 - off).clamp(0.0, 1.0);
    final scale = 1 - off * 0.12;
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBackgroundStrong.withValues(alpha: 0.60),
                  AppColors.background.withValues(alpha: 0.45),
                ],
              ),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.30),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: AppColors.backgroundLight.withValues(alpha: 0.40),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.30),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.title,
                    maxLines: 1,
                    style: AppTypography.callout.copyWith(
                      fontSize: 13,
                      color: AppColors.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideMenuSheet extends StatelessWidget {
  final List<ControlCenterModuleItem> modules;
  final List<ControlCenterShortcutItem> shortcuts;
  final double Function(int globalIndex) onProgressFor;
  final double Function(int globalIndex) offProgressFor;

  const _SideMenuSheet({
    required this.modules,
    required this.shortcuts,
    required this.onProgressFor,
    required this.offProgressFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.cardBackgroundStrong.withValues(alpha: 0.72),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.30),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: 0.40),
            blurRadius: 32,
            offset: const Offset(6, 16),
            spreadRadius: -8,
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
                  'CEO OS',
                  style: AppTypography.largeTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.label,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.background.withValues(alpha: 0.40),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.30),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 12,
                  color: AppColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _menuActionRow(
            icon: CupertinoIcons.person_circle,
            label: 'Profil & Réglages',
          ),
          const SizedBox(height: 6),
          _menuActionRow(
            icon: CupertinoIcons.paintbrush,
            label: 'Personnaliser mon centre',
          ),
          const SizedBox(height: 14),
          _sectionLabel('SYSTEM MODULES'),
          const SizedBox(height: 8),
          for (int i = 0; i < modules.length; i++) ...[
            _toggleRow(
              icon: modules[i].icon,
              label: modules[i].title,
              progressOn: onProgressFor(i),
              progressOff: offProgressFor(i),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 6),
          _sectionLabel('SHORTCUTS'),
          const SizedBox(height: 8),
          for (int i = 0; i < shortcuts.length; i++) ...[
            _toggleRow(
              icon: shortcuts[i].icon,
              label: shortcuts[i].title,
              accent: true,
              progressOn: onProgressFor(modules.length + i),
              progressOff: offProgressFor(modules.length + i),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _menuActionRow({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background.withValues(alpha: 0.30),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryLabel),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.callout.copyWith(
                fontSize: 12,
                color: AppColors.label,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            size: 12,
            color: AppColors.tertiaryLabel.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.overline.copyWith(
        fontSize: 10,
        letterSpacing: 1.4,
        color: AppColors.secondaryLabel.withValues(alpha: 0.55),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required double progressOn,
    required double progressOff,
    bool accent = false,
  }) {
    // Final ON state = progressOn fully reached AND not turned OFF.
    final on = (progressOn > 0.55) && (progressOff < 0.55);
    final iconOpacity = progressOn.clamp(0.0, 1.0);
    final iconColor = accent ? AppColors.accentIcon : AppColors.secondaryLabel;
    return Row(
      children: [
        Opacity(
          opacity: iconOpacity,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: accent && on
                  ? AppColors.accentIcon.withValues(alpha: 0.14)
                  : AppColors.background.withValues(alpha: 0.30),
              border: Border.all(
                color: accent && on
                    ? AppColors.accentIcon.withValues(alpha: 0.35)
                    : AppColors.border.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Opacity(
            opacity: iconOpacity,
            child: Text(
              label,
              style: AppTypography.callout.copyWith(
                fontSize: 12,
                color: AppColors.label,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        _AnimatedToggle(on: on, accent: accent),
      ],
    );
  }
}

class _AnimatedToggle extends StatelessWidget {
  final bool on;
  final bool accent;

  const _AnimatedToggle({required this.on, required this.accent});

  @override
  Widget build(BuildContext context) {
    final activeColor = accent
        ? AppColors.accentIcon
        : AppColors.secondaryLabel.withValues(alpha: 0.45);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 20,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: on ? activeColor : AppColors.border.withValues(alpha: 0.30),
      ),
      child: AnimatedAlign(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow.withValues(alpha: 0.22),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
