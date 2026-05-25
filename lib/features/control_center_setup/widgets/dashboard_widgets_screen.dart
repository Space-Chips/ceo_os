import 'package:flutter/cupertino.dart';

import '../../../components/liquid_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';

class DashboardWidgetsScreen extends StatelessWidget {
  final ControlCenterSetupState state;
  final void Function(DashboardWidget widget) onToggle;
  final VoidCallback onContinue;

  const DashboardWidgetsScreen({
    super.key,
    required this.state,
    required this.onToggle,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ton dashboard rassemble tout',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un espace dédié — habits, tâches, agenda et stats. Toujours à portée.',
            style: AppTypography.subhead.copyWith(
              color: AppColors.secondaryLabel.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DashboardHeroCard(),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: AppColors.secondaryLabel.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Contenu du dashboard',
                          style: AppTypography.overline.copyWith(
                            fontSize: 12,
                            color: AppColors.secondaryLabel.withValues(
                              alpha: 0.72,
                            ),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _TasksCard(),
                  const SizedBox(height: 12),
                  const _HabitsTodayCard(),
                  const SizedBox(height: 12),
                  const _ScheduleCard(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          LiquidButton(
            label: 'Entrer dans mon centre',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.cardBackgroundStrong.withValues(alpha: 0.42),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: AppTypography.largeTitle.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.label,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _miniStat('3', 'Tâches'),
                    const SizedBox(width: 20),
                    _miniStat('4', 'Habits'),
                    const SizedBox(width: 20),
                    Expanded(child: _miniStat('2', 'Événements')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const _ScoreRing(score: 87),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.largeTitle.copyWith(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: AppColors.label,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption1.copyWith(
            fontSize: 12,
            color: AppColors.tertiaryLabel,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;

  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(112, 112),
            painter: _RingPainter(progress: score / 100),
          ),
          Text(
            '$score',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 37,
              fontWeight: FontWeight.w800,
              color: AppColors.label,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke,
    );
    final base = Paint()
      ..color = AppColors.border.withValues(alpha: 0.30)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = AppColors.label.withValues(alpha: 0.92)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2831853, false, base);
    canvas.drawArc(rect, -1.5708, 6.2831853 * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _HabitsTodayCard extends StatelessWidget {
  const _HabitsTodayCard();

  @override
  Widget build(BuildContext context) {
    final habits = const [
      ('Sport', '🏃', true),
      ('Méditer', '🧘', true),
      ('Lire', '📚', false),
      ('Journaliser', '✍️', false),
    ];
    final done = habits.where((h) => h.$3).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardBackgroundStrong.withValues(alpha: 0.42),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.flame_fill,
                size: 16,
                color: AppColors.label,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Habits du jour',
                  style: AppTypography.callout.copyWith(
                    fontSize: 15,
                    color: AppColors.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$done/${habits.length}',
                style: AppTypography.callout.copyWith(
                  fontSize: 13,
                  color: AppColors.tertiaryLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: AppColors.border.withValues(alpha: 0.30),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: done / habits.length,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final h in habits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: h.$3
                          ? AppColors.success
                          : AppColors.background.withValues(alpha: 0.30),
                      border: Border.all(
                        color: h.$3
                            ? AppColors.success
                            : AppColors.border.withValues(alpha: 0.40),
                        width: 0.5,
                      ),
                    ),
                    child: h.$3
                        ? Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 12,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${h.$1} ${h.$2}',
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      color: AppColors.label,
                      fontWeight: FontWeight.w600,
                      decoration:
                          h.$3 ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.tertiaryLabel,
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

class _TasksCard extends StatelessWidget {
  const _TasksCard();

  @override
  Widget build(BuildContext context) {
    final tasks = const [
      ('Préparer présentation', _Priority.critical),
      ('Répondre aux emails', _Priority.high),
      ('Sprint review', _Priority.medium),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardBackgroundStrong.withValues(alpha: 0.42),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < tasks.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  height: 0.5,
                  color: AppColors.border.withValues(alpha: 0.22),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _RankBubble(rank: i + 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tasks[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 14,
                            color: AppColors.label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _PriorityBadge(priority: tasks[i].$2),
                            const SizedBox(width: 8),
                            Text(
                              '1 hour',
                              style: AppTypography.caption1.copyWith(
                                fontSize: 11,
                                color: AppColors.tertiaryLabel,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _Priority { critical, high, medium }

class _PriorityBadge extends StatelessWidget {
  final _Priority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, base) = switch (priority) {
      _Priority.critical => ('CRITICAL', const Color(0xFFEF4444)),
      _Priority.high => ('HIGH', const Color(0xFFF59E0B)),
      _Priority.medium => ('MEDIUM', const Color(0xFFFCD34D)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: base.withValues(alpha: 0.16),
        border: Border.all(
          color: base.withValues(alpha: 0.40),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          fontSize: 9,
          color: base,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _RankBubble extends StatelessWidget {
  final int rank;
  const _RankBubble({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background.withValues(alpha: 0.40),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Text(
        '$rank',
        style: AppTypography.caption1.copyWith(
          fontSize: 12,
          color: AppColors.label,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard();

  @override
  Widget build(BuildContext context) {
    final events = const [
      ('Sprint planning', '09:00', Color(0xFF60A5FA)),
      ('Lunch · Sarah', '12:30', Color(0xFF34D399)),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardBackgroundStrong.withValues(alpha: 0.42),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 16,
                color: AppColors.label,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Schedule',
                  style: AppTypography.callout.copyWith(
                    fontSize: 15,
                    color: AppColors.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '2 events',
                style: AppTypography.caption1.copyWith(
                  fontSize: 11,
                  color: AppColors.tertiaryLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < events.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: events[i].$3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    events[i].$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      color: AppColors.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  events[i].$2,
                  style: AppTypography.callout.copyWith(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
