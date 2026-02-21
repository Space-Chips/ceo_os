import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../components/components.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/task_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'add_event_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadEvents();
    });
  }

  void _showAddEvent() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => AddEventSheet(selectedDate: _selectedDay),
    );
  }

  List<CalendarEvent> _getEventsForDay(
    DateTime day,
    List<CalendarEvent> allEvents,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return allEvents.where((e) => e.eventDate == dateStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            bottom: 200,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: CupertinoColors.transparent),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const NeoMonoText(
                  'TEMPORAL_GRID',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: AppColors.background.withValues(alpha: 0.8),
                border: null,
              ),

              SliverToBoxAdapter(
                child: Consumer<TaskProvider>(
                  builder: (context, prov, _) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TableCalendar<CalendarEvent>(
                          firstDay: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDay: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          calendarFormat: _calendarFormat,
                          eventLoader: (day) =>
                              _getEventsForDay(day, prov.events),
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: AppTypography.mono.copyWith(
                              fontSize: 10,
                              color: AppColors.tertiaryLabel,
                            ),
                            weekendStyle: AppTypography.mono.copyWith(
                              fontSize: 10,
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            defaultTextStyle: AppTypography.mono.copyWith(
                              fontSize: 13,
                            ),
                            weekendTextStyle: AppTypography.mono.copyWith(
                              fontSize: 13,
                              color: AppColors.secondaryLabel,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: AppTypography.mono.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: const Icon(
                              CupertinoIcons.chevron_left,
                              color: AppColors.primaryOrange,
                              size: 18,
                            ),
                            rightChevronIcon: const Icon(
                              CupertinoIcons.chevron_right,
                              color: AppColors.primaryOrange,
                              size: 18,
                            ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              Consumer<TaskProvider>(
                builder: (context, prov, _) {
                  final events = _getEventsForDay(_selectedDay!, prov.events);
                  if (events.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: NeoMonoText(
                          'NO_EVENTS_SCHEDULED',
                          fontSize: 12,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ).copyWith(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final event = events[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title.toUpperCase(),
                                  style: AppTypography.mono.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (event.eventTime != null)
                                      Text(
                                        event.eventTime!,
                                        style: AppTypography.mono.copyWith(
                                          fontSize: 11,
                                          color: AppColors.primaryOrange,
                                        ),
                                      ),
                                    if (event.description != null &&
                                        event.description!.isNotEmpty) ...[
                                      if (event.eventTime != null)
                                        const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          event.description!.toUpperCase(),
                                          style: AppTypography.mono.copyWith(
                                            fontSize: 10,
                                            color: AppColors.secondaryLabel,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: events.length),
                    ),
                  );
                },
              ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 40,
            child: FloatingAddButton(onPressed: _showAddEvent),
          ),
        ],
      ),
    );
  }
}
