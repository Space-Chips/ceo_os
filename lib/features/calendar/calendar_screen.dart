import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.month;
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
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/home'),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryOrange,
          ),
        ),
        middle: const NeoMonoText(
          'CALENDAR',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/event-types'),
              child: const Icon(
                CupertinoIcons.square_grid_2x2_fill,
                color: AppColors.primaryOrange,
                size: 18,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showAddEvent,
              child: const Icon(
                CupertinoIcons.plus,
                color: AppColors.primaryOrange,
                size: 20,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        border: null,
      ),
      child: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, prov, _) {
            final events = _getEventsForDay(
              _selectedDay ?? _focusedDay,
              prov.events,
            );
            final allEvents = prov.events;
            final now = DateTime.now();
            final todayStr = DateFormat('yyyy-MM-dd').format(now);
            final weekEnd = now.add(const Duration(days: 7));
            final upcomingWeek = allEvents.where((e) {
              final d = e.eventDate == null
                  ? null
                  : DateTime.tryParse(e.eventDate!);
              if (d == null) return false;
              return !d.isBefore(DateTime(now.year, now.month, now.day)) &&
                  d.isBefore(weekEnd);
            }).length;
            final todayCount = allEvents
                .where((e) => e.eventDate == todayStr)
                .length;

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ).copyWith(bottom: 100),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      _metric('Today', '$todayCount'),
                      _metric('Next 7d', '$upcomingWeek'),
                      _metric('Total', '${allEvents.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  borderRadius: 18,
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: (day) => _getEventsForDay(day, prov.events),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.tertiaryLabel,
                      ),
                      weekendStyle: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.primaryOrange.withValues(alpha: 0.6),
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
                        color: AppColors.primaryOrange.withValues(alpha: 0.2),
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
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onFormatChanged: (format) =>
                        setState(() => _calendarFormat = format),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const NeoMonoText(
                      'AGENDA',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    const Spacer(),
                    Text(
                      DateFormat(
                        'EEEE, MMM d',
                      ).format(_selectedDay ?? _focusedDay).toUpperCase(),
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'NO_EVENTS_SCHEDULED',
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    ),
                  )
                else
                  ...events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _EventCard(event: event),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
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
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final sourceColor = event.sourceType == 'task'
        ? const Color(0xFFFF6B00)
        : event.sourceType == 'habit'
        ? const Color(0xFF10B981)
        : const Color(0xFF60A5FA);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      border: Border.all(
        color: sourceColor.withValues(alpha: 0.22),
        width: 0.6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (event.eventTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sourceColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sourceColor.withValues(alpha: 0.35),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    event.eventTime!,
                    style: AppTypography.mono.copyWith(
                      fontSize: 10,
                      color: sourceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (event.sourceType ?? 'manual').toUpperCase(),
            style: AppTypography.mono.copyWith(fontSize: 9, color: sourceColor),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description!.toUpperCase(),
              style: AppTypography.mono.copyWith(
                fontSize: 11,
                color: AppColors.secondaryLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
