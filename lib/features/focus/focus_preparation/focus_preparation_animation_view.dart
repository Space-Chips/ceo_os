import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FocusPreparationAnimationView extends StatefulWidget {
  const FocusPreparationAnimationView({super.key});

  @override
  State<FocusPreparationAnimationView> createState() =>
      _FocusPreparationAnimationViewState();
}

class _FocusPreparationAnimationViewState
    extends State<FocusPreparationAnimationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 0.66,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cardBackgroundAlt,
                AppColors.cardBase.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: AppColors.borderStrong.withValues(alpha: 0.95),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.32),
                blurRadius: 34,
                offset: const Offset(0, 16),
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                _FocusPhoneMock(progress: _controller.value, language: language),
          ),
        ),
      ),
    );
  }
}

class _FocusPhoneMock extends StatelessWidget {
  const _FocusPhoneMock({required this.progress, required this.language});

  final double progress;
  final LanguageProvider language;

  double _segment(double begin, double end, {Curve curve = Curves.easeInOut}) {
    final t = ((progress - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final lockIn = _segment(0.12, 0.34, curve: Curves.easeOutCubic);
    final timerPulse = _segment(0.28, 0.86, curve: Curves.easeInOutCubic);
    final streakIn = _segment(0.62, 0.88, curve: Curves.easeOutCubic);
    final finalLabel = _segment(0.84, 1.0, curve: Curves.easeInOutCubic);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final iconSize = width * 0.2;
        final baseOpacity = 1 - (0.55 * lockIn);

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Center(
                child: Container(
                  width: width * 0.22,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.08,
              top: 54,
              child: _appTile(
                icon: CupertinoIcons.chat_bubble_fill,
                size: iconSize,
                alpha: baseOpacity,
              ),
            ),
            Positioned(
              left: width * 0.39,
              top: 54,
              child: _appTile(
                icon: CupertinoIcons.photo_fill,
                size: iconSize,
                alpha: baseOpacity,
              ),
            ),
            Positioned(
              left: width * 0.70,
              top: 54,
              child: _appTile(
                icon: CupertinoIcons.play_rectangle_fill,
                size: iconSize,
                alpha: baseOpacity,
              ),
            ),
            Positioned(
              left: width * 0.08,
              top: 54 + iconSize + 20,
              child: _appTile(
                icon: CupertinoIcons.globe,
                size: iconSize,
                alpha: baseOpacity,
              ),
            ),
            Positioned(
              left: width * 0.39,
              top: 54 + iconSize + 20,
              child: _appTile(
                icon: CupertinoIcons.game_controller_solid,
                size: iconSize,
                alpha: baseOpacity,
              ),
            ),
            Positioned(
              left: width * 0.70,
              top: 54 + iconSize + 20,
              child: _appTile(
                icon: CupertinoIcons.music_note_2,
                size: iconSize,
                alpha: baseOpacity,
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: lockIn,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.scale(
                    scale: 0.92 + (0.08 * timerPulse),
                    child: Container(
                      width: width * 0.62,
                      height: width * 0.62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardBackgroundStrong.withValues(
                          alpha: 0.98,
                        ),
                        border: Border.all(
                          color: AppColors.focusPrimary.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '24:59',
                            style: AppTypography.heroDisplay.copyWith(
                              fontSize: 46,
                              color: AppColors.label,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1.8,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            language.t('focus_active'),
                            style: AppTypography.overline.copyWith(
                              fontSize: 11,
                              color: AppColors.accentText.withValues(alpha: 0.9),
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 42,
              child: Opacity(
                opacity: streakIn,
                child: Transform.scale(
                  scale: 0.92 + (0.08 * streakIn),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.success.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      language.t('focus_plus_one_streak'),
                      style: AppTypography.caption1.copyWith(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Opacity(
                opacity: finalLabel,
                child: Text(
                  language.t('focus_blocking_active_until_end'),
                  textAlign: TextAlign.center,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.secondaryLabel.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _appTile({
    required IconData icon,
    required double size,
    required double alpha,
  }) {
    final angle = math.sin(progress * math.pi * 16) * 0.01;
    return Opacity(
      opacity: alpha.clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardRaised,
                AppColors.cardBase,
              ],
            ),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: size * 0.46, color: AppColors.secondaryLabel),
        ),
      ),
    );
  }
}
