import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/providers/countdown_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'add_countdown_sheet.dart';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});
  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CountdownProvider>().loadSampleData();
    });
  }

  void _showAddCountdown() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const AddCountdownSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Countdowns'),
            backgroundColor: AppColors.systemBackground,
            border: null,
            trailing: GestureDetector(
              onTap: _showAddCountdown,
              child: const Icon(
                CupertinoIcons.plus_circle_fill,
                color: AppColors.systemBlue,
                size: 28,
              ),
            ),
          ),
          Consumer<CountdownProvider>(
            builder: (context, prov, _) {
              final upcoming = prov.upcomingEvents;
              final past = prov.pastEvents;

              if (upcoming.isEmpty && past.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.timer,
                          size: 40,
                          color: AppColors.tertiaryLabel,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No countdowns',
                          style: AppTypography.title3.copyWith(
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tap + to count down to something big',
                          style: AppTypography.subhead.copyWith(
                            color: AppColors.tertiaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(
                  AppSpacing.md,
                ).copyWith(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (upcoming.isNotEmpty) ...[
                      ...upcoming.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CountdownCard(
                            event: e,
                            onDelete: () => prov.removeEvent(e.id),
                          ),
                        ),
                      ),
                    ],
                    if (past.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          'PAST',
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.secondaryLabel,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      ...past.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CountdownCard(
                            event: e,
                            isPast: true,
                            onDelete: () => prov.removeEvent(e.id),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final CountdownEvent event;
  final bool isPast;
  final VoidCallback onDelete;
  const _CountdownCard({
    required this.event,
    this.isPast = false,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = event.remaining;
    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.systemRed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        ),
        child: const Icon(CupertinoIcons.trash, color: CupertinoColors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusGrouped),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(event.icon, size: 18, color: event.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(event.title, style: AppTypography.headline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (isPast)
              Text(
                'Event has passed',
                style: AppTypography.subhead.copyWith(
                  color: AppColors.tertiaryLabel,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TimeUnit(
                    value: '${r.inDays}',
                    label: 'DAYS',
                    color: event.color,
                  ),
                  _TimeUnit(
                    value: '${r.inHours % 24}',
                    label: 'HRS',
                    color: event.color,
                  ),
                  _TimeUnit(
                    value: '${r.inMinutes % 60}',
                    label: 'MIN',
                    color: event.color,
                  ),
                  _TimeUnit(
                    value: '${r.inSeconds % 60}',
                    label: 'SEC',
                    color: event.color,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value, label;
  final Color color;
  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: AppTypography.title1.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      Text(
        label,
        style: AppTypography.caption2.copyWith(
          color: AppColors.secondaryLabel,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );
}
