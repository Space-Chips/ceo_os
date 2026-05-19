import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, FontWeight, IconData, TimeOfDay;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/components.dart';
import '../../core/models/habit_models.dart';
import '../../core/models/task_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/task_provider.dart';
import '../../core/repositories/feature_repository.dart';
import '../../core/repositories/habit_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'add_event_sheet.dart';
import '../../components/ambient_backdrop.dart';
import '../../components/glass_card.dart';

enum _CalendarPanel { calendar, stats }

enum _CalendarDisplayMode { yearly, monthly, daily }

enum _EventPriority { important, normal, secondary }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final HabitRepository _habitRepository = HabitRepository();
  final FeatureRepository _featureRepository = FeatureRepository();

  _CalendarPanel _activePanel = _CalendarPanel.calendar;
  _CalendarDisplayMode _displayMode = _CalendarDisplayMode.yearly;
  int _panelDirection = -1;

  DateTime _currentDate = DateTime.now();
  bool _loadingHabits = true;
  bool _loadingEventTypes = true;
  List<Habit> _habits = const [];
  List<EventType> _eventTypes = const [];

  static const List<String> _importantKeywords = <String>[
    'meeting',
    'deadline',
    'presentation',
    'interview',
    'important',
    'urgent',
    'critical',
  ];

  static const List<String> _secondaryKeywords = <String>[
    'optional',
    'maybe',
    'tentative',
    'coffee',
    'lunch',
  ];

  String _t(String key) {
    try {
      return context.read<LanguageProvider>().t(key);
    } catch (_) {
      return key;
    }
  }

  String _localeCode() {
    try {
      return context.read<LanguageProvider>().languageCode;
    } catch (_) {
      return 'en';
    }
  }

  String _safeDateFormat(
    String pattern,
    DateTime date, {
    String? fallbackPattern,
  }) {
    String formatWithLocale(String locale, String activePattern) {
      final formatted = DateFormat(activePattern, locale).format(date);
      return formatted.trim();
    }

    try {
      final formatted = formatWithLocale(_localeCode(), pattern);
      if (formatted.isNotEmpty) return formatted;
    } catch (_) {}

    final candidate = fallbackPattern ?? pattern;
    try {
      final formatted = formatWithLocale('en', candidate);
      if (formatted.isNotEmpty) return formatted;
    } catch (_) {}

    return DateFormat('yMMMd', 'en').format(date);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<TaskProvider>().loadEvents(),
      context.read<TaskProvider>().loadTasksWithCompleted(
        includeCompleted: true,
      ),
      _loadHabits(),
      _loadEventTypes(),
    ]);
  }

  Future<void> _loadHabits() async {
    setState(() => _loadingHabits = true);
    try {
      final habits = await _habitRepository.getHabits();
      if (!mounted) return;
      setState(() {
        _habits = habits;
        _loadingHabits = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _habits = const [];
        _loadingHabits = false;
      });
    }
  }

  Future<void> _loadEventTypes() async {
    setState(() => _loadingEventTypes = true);
    try {
      final types = await _featureRepository.getEventTypes();
      if (!mounted) return;
      setState(() {
        _eventTypes = types;
        _loadingEventTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eventTypes = const [];
        _loadingEventTypes = false;
      });
    }
  }

  void _showAddEvent({TimeOfDay? initialTime}) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) =>
          AddEventSheet(selectedDate: _currentDate, initialTime: initialTime),
    );
  }

  void _setPanel(_CalendarPanel panel) {
    if (panel == _activePanel) return;
    final direction = panel.index > _activePanel.index ? -1 : 1;
    setState(() {
      _panelDirection = direction;
      _activePanel = panel;
    });
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300 && _activePanel == _CalendarPanel.calendar) {
      _setPanel(_CalendarPanel.stats);
    } else if (velocity > 300 && _activePanel == _CalendarPanel.stats) {
      _setPanel(_CalendarPanel.calendar);
    }
  }

  Future<void> _navigatePrevious() async {
    final wasYearly = _displayMode == _CalendarDisplayMode.yearly;
    setState(() {
      if (wasYearly) {
        _currentDate = DateTime(_currentDate.year - 1, 1, 1);
      } else if (_displayMode == _CalendarDisplayMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      } else {
        _currentDate = _currentDate.subtract(const Duration(days: 1));
      }
    });
    if (wasYearly) {}
  }

  Future<void> _navigateNext() async {
    final wasYearly = _displayMode == _CalendarDisplayMode.yearly;
    setState(() {
      if (wasYearly) {
        _currentDate = DateTime(_currentDate.year + 1, 1, 1);
      } else if (_displayMode == _CalendarDisplayMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      } else {
        _currentDate = _currentDate.add(const Duration(days: 1));
      }
    });
    if (wasYearly) {}
  }

  void _stepBackView() {
    setState(() {
      if (_displayMode == _CalendarDisplayMode.daily) {
        _displayMode = _CalendarDisplayMode.monthly;
      } else if (_displayMode == _CalendarDisplayMode.monthly) {
        _displayMode = _CalendarDisplayMode.yearly;
      }
    });
  }

  String _headerLabel() {
    if (_displayMode == _CalendarDisplayMode.yearly) {
      return '${_currentDate.year}';
    }
    if (_displayMode == _CalendarDisplayMode.monthly) {
      return _safeDateFormat('MMMM yyyy', _currentDate);
    }
    return _safeDateFormat(
      'MMMM d, yyyy',
      _currentDate,
      fallbackPattern: 'MMM d, yyyy',
    );
  }

  DateTime _startOfWeekMonday(DateTime day) {
    final localDay = DateTime(day.year, day.month, day.day);
    final offset = localDay.weekday - DateTime.monday;
    return localDay.subtract(Duration(days: offset));
  }

  DateTime _endOfWeekSunday(DateTime day) {
    final start = _startOfWeekMonday(day);
    return start.add(const Duration(days: 6));
  }

  List<DateTime> _monthGridDays(DateTime monthDate) {
    final monthStart = DateTime(monthDate.year, monthDate.month, 1);
    final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);
    final startDate = _startOfWeekMonday(monthStart);
    final endDate = _endOfWeekSunday(monthEnd);
    final days = <DateTime>[];
    var day = startDate;
    while (!day.isAfter(endDate)) {
      days.add(day);
      day = day.add(const Duration(days: 1));
    }
    return days;
  }

  DateTime? _parseEventDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  int? _parseHour(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return null;
    final parts = rawTime.split(':');
    if (parts.isEmpty) return null;
    final hour = int.tryParse(parts.first);
    if (hour == null || hour < 0 || hour > 23) return null;
    return hour;
  }

  int _duration(CalendarEvent event) {
    final value = event.durationMinutes;
    if (value == null || value <= 0) return 60;
    return value;
  }

  _EventPriority _priority(CalendarEvent event) {
    final text = '${event.title} ${event.description ?? ''}'.toLowerCase();
    if (_importantKeywords.any(text.contains)) return _EventPriority.important;
    if (_secondaryKeywords.any(text.contains)) return _EventPriority.secondary;
    return _EventPriority.normal;
  }

  Color _colorFromHex(String value, {required Color fallback}) {
    final normalized = value.trim().replaceFirst('#', '');
    final expanded = normalized.length == 3
        ? normalized.split('').map((part) => '$part$part').join()
        : normalized;
    final candidate = expanded.length == 6 ? 'FF$expanded' : expanded;
    if (candidate.length != 8) return fallback;
    final parsed = int.tryParse(candidate, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  Color _colorByNamedType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'red':
      case 'urgent':
        return AppColors.error;
      case 'orange':
      case 'important':
        return AppColors.warning;
      case 'green':
      case 'habit':
        return AppColors.success;
      case 'purple':
      case 'focus':
        return const Color(0xFF8B5CF6);
      case 'pink':
      case 'birthday':
        return const Color(0xFFF472B6);
      case 'blue':
      case 'task':
      case 'calendar':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _fallbackColorByPriority(_EventPriority priority) {
    switch (priority) {
      case _EventPriority.important:
        return AppColors.warning;
      case _EventPriority.secondary:
        return AppColors.secondaryLabel;
      case _EventPriority.normal:
        return const Color(0xFF3B82F6);
    }
  }

  int _priorityWeight(_EventPriority priority) {
    switch (priority) {
      case _EventPriority.important:
        return 0;
      case _EventPriority.normal:
        return 1;
      case _EventPriority.secondary:
        return 2;
    }
  }

  int _timeToMinutes(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return 24 * 60;
    final parts = rawTime.split(':');
    if (parts.length < 2) return 24 * 60;
    final hour = int.tryParse(parts[0]) ?? 24;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  List<CalendarEvent> _prioritizeEvents(List<CalendarEvent> events) {
    final sorted = [...events];
    sorted.sort((a, b) {
      final byPriority = _priorityWeight(
        _priority(a),
      ).compareTo(_priorityWeight(_priority(b)));
      if (byPriority != 0) return byPriority;
      final byTime = _timeToMinutes(
        a.eventTime,
      ).compareTo(_timeToMinutes(b.eventTime));
      if (byTime != 0) return byTime;
      final byDuration = _duration(b).compareTo(_duration(a));
      if (byDuration != 0) return byDuration;
      return a.title.compareTo(b.title);
    });
    return sorted;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentHour(DateTime day, int hour) {
    final now = DateTime.now();
    return _isSameDate(day, now) && now.hour == hour;
  }

  List<CalendarEvent> _eventsForDay(
    DateTime day,
    List<CalendarEvent> allEvents,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _prioritizeEvents(
      allEvents.where((event) => event.eventDate == dateStr).toList(),
    );
  }

  List<CalendarEvent> _eventsForHour(
    DateTime day,
    int hour,
    List<CalendarEvent> allEvents,
  ) {
    final dayEvents = _eventsForDay(day, allEvents);
    return dayEvents
        .where((event) => _parseHour(event.eventTime) == hour)
        .toList();
  }

  int _eventCountForMonth(DateTime monthDate, List<CalendarEvent> allEvents) {
    return allEvents.where((event) {
      final parsed = _parseEventDate(event.eventDate);
      if (parsed == null) return false;
      return parsed.year == monthDate.year && parsed.month == monthDate.month;
    }).length;
  }

  Color _eventColor(CalendarEvent event) {
    if (_isBirthdayEvent(event)) {
      return const Color(0xFFF472B6);
    }
    if (_isFocusPlanEvent(event)) {
      return const Color(0xFF8B5CF6);
    }
    final typeId = event.eventTypeId;
    if (typeId != null && typeId.isNotEmpty) {
      final type = _eventTypes.cast<EventType?>().firstWhere(
        (it) => it?.id == typeId,
        orElse: () => null,
      );
      if (type?.color != null && type!.color!.isNotEmpty) {
        final value = type.color!;
        if (value.startsWith('#') ||
            RegExp(r'^[0-9a-fA-F]{3,8}$').hasMatch(value)) {
          return _colorFromHex(value, fallback: _colorByNamedType('blue'));
        }
        return _colorByNamedType(value);
      }
    }
    return _fallbackColorByPriority(_priority(event));
  }

  bool _isBirthdayEvent(CalendarEvent event) {
    final source = (event.sourceType ?? '').trim().toLowerCase();
    final recurrence = (event.recurrenceRule ?? '').trim().toLowerCase();
    return source == 'birthday' || recurrence.contains('year');
  }

  bool _isFocusPlanEvent(CalendarEvent event) {
    final source = (event.sourceType ?? '').trim().toLowerCase();
    return source == 'focus_plan';
  }

  String _eventMetaLabel(CalendarEvent event) {
    if (event.eventTime == null) {
      return _isBirthdayEvent(event)
          ? _t('calendar_event_birthday_repeats_yearly')
          : _t('calendar_event_all_day');
    }
    final base =
        '${event.eventTime} • ${_duration(event)}${_t('calendar_event_minutes_short')}';
    if (_isFocusPlanEvent(event) &&
        (event.recurrenceRule ?? '').toLowerCase().contains('week')) {
      return '$base • ${_t('calendar_event_weekly_short')}';
    }
    return base;
  }

  _DayOverloadInfo _detectOverload(List<CalendarEvent> dayEvents) {
    if (dayEvents.isEmpty) {
      return const _DayOverloadInfo(
        overloaded: false,
        reason: null,
        totalMinutes: 0,
        eventCount: 0,
      );
    }

    final totalMinutes = dayEvents.fold<int>(
      0,
      (sum, event) => sum + _duration(event),
    );

    final sortedEvents = [...dayEvents]
      ..sort(
        (a, b) => (a.eventTime ?? '00:00').compareTo(b.eventTime ?? '00:00'),
      );

    var hasNoBreaks = false;
    for (var i = 0; i < sortedEvents.length - 1; i++) {
      final current = sortedEvents[i];
      final next = sortedEvents[i + 1];
      final currentTime = (current.eventTime ?? '00:00').split(':');
      final nextTime = (next.eventTime ?? '00:00').split(':');
      if (currentTime.length < 2 || nextTime.length < 2) continue;

      final currentHour = int.tryParse(currentTime[0]) ?? 0;
      final currentMinute = int.tryParse(currentTime[1]) ?? 0;
      final nextHour = int.tryParse(nextTime[0]) ?? 0;
      final nextMinute = int.tryParse(nextTime[1]) ?? 0;

      final currentEndMinutes =
          (currentHour * 60) + currentMinute + _duration(current);
      final nextStartMinutes = (nextHour * 60) + nextMinute;

      if (nextStartMinutes - currentEndMinutes < 15) {
        hasNoBreaks = true;
        break;
      }
    }

    final overloaded =
        totalMinutes > 480 || hasNoBreaks || dayEvents.length > 6;
    String? reason;
    if (totalMinutes > 480) {
      reason = 'too_many_hours';
    } else if (hasNoBreaks) {
      reason = 'no_breaks';
    } else if (dayEvents.length > 6) {
      reason = 'too_many_events';
    }

    return _DayOverloadInfo(
      overloaded: overloaded,
      reason: reason,
      totalMinutes: totalMinutes,
      eventCount: dayEvents.length,
    );
  }

  _FocusSuggestion _suggestFocus(List<CalendarEvent> dayEvents) {
    if (dayEvents.isEmpty) {
      return const _FocusSuggestion(
        suggest: true,
        reason: 'no_events',
        recommendedDuration: 120,
      );
    }

    final totalMinutes = dayEvents.fold<int>(
      0,
      (sum, event) => sum + _duration(event),
    );

    if (totalMinutes < 180) {
      return const _FocusSuggestion(
        suggest: true,
        reason: 'light_schedule',
        recommendedDuration: 90,
      );
    }

    return const _FocusSuggestion(
      suggest: false,
      reason: 'busy_schedule',
      recommendedDuration: 45,
    );
  }

  _FreeTimeInfo _freeTime(List<CalendarEvent> dayEvents) {
    const totalDayMinutes = 24 * 60;
    const sleepMinutes = 8 * 60;
    final eventMinutes = dayEvents.fold<int>(
      0,
      (sum, event) => sum + _duration(event),
    );
    final freeTimeMinutes = totalDayMinutes - sleepMinutes - eventMinutes;
    final wakingMinutes = totalDayMinutes - sleepMinutes;

    return _FreeTimeInfo(
      freeTimeMinutes: freeTimeMinutes,
      freeTimeHours: freeTimeMinutes ~/ 60,
      freeTimeRemainingMinutes: freeTimeMinutes % 60,
      eventMinutes: eventMinutes,
      sleepMinutes: sleepMinutes,
      percentageFree: ((freeTimeMinutes / wakingMinutes) * 100).round(),
    );
  }

  _HabitConflict _habitConflict(DateTime day, List<CalendarEvent> dayEvents) {
    final totalEventMinutes = dayEvents.fold<int>(
      0,
      (sum, event) => sum + _duration(event),
    );
    final weekday = day.weekday % 7;
    final habitsForDay = _habits.where((habit) {
      if (habit.isDaily) return true;
      final days = habit.specificDays;
      return days != null && days.contains(weekday);
    }).toList();

    if (totalEventMinutes > 360 && habitsForDay.isNotEmpty) {
      return _HabitConflict(
        conflict: true,
        reason: 'overloaded_day_with_habits',
        habitCount: habitsForDay.length,
        eventMinutes: totalEventMinutes,
      );
    }

    return const _HabitConflict(
      conflict: false,
      reason: null,
      habitCount: 0,
      eventMinutes: 0,
    );
  }

  _WeekAnalysis _analyzeWeek(
    List<CalendarEvent> allEvents,
    DateTime reference,
  ) {
    final weekStart = _startOfWeekMonday(reference);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekEvents = allEvents.where((event) {
      final date = _parseEventDate(event.eventDate);
      if (date == null) return false;
      final day = DateTime(date.year, date.month, date.day);
      return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
    }).toList();

    final totalMinutes = weekEvents.fold<int>(
      0,
      (sum, event) => sum + _duration(event),
    );
    final importantMinutes = weekEvents
        .where((event) => _priority(event) == _EventPriority.important)
        .fold<int>(0, (sum, event) => sum + _duration(event));

    const totalWakingMinutes = 7 * 16 * 60;
    final freeMinutes = totalWakingMinutes - totalMinutes;

    return _WeekAnalysis(
      totalEventHours: (totalMinutes / 60).round(),
      importantEventHours: (importantMinutes / 60).round(),
      freeTimeHours: (freeMinutes / 60).round(),
      percentageImportant: totalMinutes > 0
          ? ((importantMinutes / totalMinutes) * 100).round()
          : 0,
      percentageFree: ((freeMinutes / totalWakingMinutes) * 100).round(),
      eventCount: weekEvents.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when language changes so localized date labels refresh.
    context.watch<LanguageProvider>().languageCode;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: AmbientBackdrop(
        child: SafeArea(
          child: Consumer<TaskProvider>(
            builder: (context, provider, _) {
              final allEvents = provider.events;
              final selectedDayEvents = _eventsForDay(_currentDate, allEvents);
              final overloadInfo = _detectOverload(selectedDayEvents);
              final focusSuggestion = _suggestFocus(selectedDayEvents);
              final freeTime = _freeTime(selectedDayEvents);
              final habitConflict = _habitConflict(
                _currentDate,
                selectedDayEvents,
              );
              final weekAnalysis = _analyzeWeek(allEvents, _currentDate);

              return GestureDetector(
                onHorizontalDragEnd: _handleHorizontalSwipe,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Column(
                    children: [
                      _buildTopHeader(),
                      const SizedBox(height: 12),
                      _buildControlsRow(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final begin = _panelDirection < 0
                                ? const Offset(0.2, 0)
                                : const Offset(-0.2, 0);
                            final slide = Tween<Offset>(
                              begin: begin,
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: _activePanel == _CalendarPanel.calendar
                              ? _buildCalendarPanel(allEvents)
                              : _buildStatsPanel(
                                  overloadInfo: overloadInfo,
                                  focusSuggestion: focusSuggestion,
                                  freeTime: freeTime,
                                  habitConflict: habitConflict,
                                  weekAnalysis: weekAnalysis,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activePanel == _CalendarPanel.calendar
                            ? _t('calendar_swipe_stats_hint')
                            : _t('calendar_swipe_calendar_hint'),
                        style: AppTypography.mono.copyWith(
                          fontSize: 10,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              onPressed: () => context.go('/home'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.arrow_left,
                    color: AppColors.secondaryLabel,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _t('home'),
                    style: AppTypography.callout.copyWith(
                      fontSize: 15,
                      color: AppColors.secondaryLabel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              _t('calendar_schedule_title'),
              style: AppTypography.callout.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryLabel.withValues(alpha: 0.72),
                letterSpacing: 1,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () async {
                final taskProvider = context.read<TaskProvider>();
                await context.push('/event-types');
                if (!mounted) return;
                await _loadEventTypes();
                await taskProvider.loadEvents();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.backgroundLight.withValues(alpha: 0.72),
                  border: Border.all(color: AppColors.glassBorder, width: 0.8),
                ),
                child: Text(
                  _loadingEventTypes ? 'Types…' : 'Types',
                  style: AppTypography.mono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.label,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow() {
    final isYearly = _displayMode == _CalendarDisplayMode.yearly;
    final isMonthly = _displayMode == _CalendarDisplayMode.monthly;
    return Row(
      children: [
        if (_displayMode != _CalendarDisplayMode.yearly) ...[
          _squareControlButton(
            icon: CupertinoIcons.arrow_left,
            onTap: _stepBackView,
          ),
          const SizedBox(width: 8),
        ],
        _squareControlButton(
          icon: CupertinoIcons.chevron_left,
          onTap: () {
            _navigatePrevious();
          },
          size: isYearly ? 40 : 50,
        ),
        SizedBox(width: isYearly ? 16 : 10),
        Expanded(
          child: Text(
            _headerLabel(),
            textAlign: TextAlign.center,
            style:
                (isYearly
                        ? AppTypography.largeTitle
                        : isMonthly
                        ? AppTypography.title1
                        : AppTypography.title3)
                    .copyWith(
                      fontSize: isYearly
                          ? 26
                          : isMonthly
                          ? 28
                          : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: isYearly || isMonthly ? 0.2 : -0.1,
                      color: AppColors.label,
                    ),
          ),
        ),
        SizedBox(width: isYearly ? 16 : 10),
        _squareControlButton(
          icon: CupertinoIcons.chevron_right,
          onTap: () {
            _navigateNext();
          },
          size: isYearly ? 40 : 50,
        ),
        const SizedBox(width: 10),
        _squareControlButton(
          icon: CupertinoIcons.add,
          onTap: _showAddEvent,
          filled: false,
          size: isYearly ? 40 : 56,
        ),
      ],
    );
  }

  Widget _squareControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    double size = 50,
  }) {
    return _CalendarPressScale(
      onTap: onTap,
      scaleWhenPressed: 1.03,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.pillBackground
              : AppColors.topBarControlBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? AppColors.pillBorder
                : AppColors.topBarControlBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadowSoft.withValues(
                alpha: AppColors.isDark ? 0.12 : 0.08,
              ),
              blurRadius: AppColors.isDark ? 12 : 10,
              offset: Offset(0, AppColors.isDark ? 5 : 4),
              spreadRadius: -8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: AppColors.label.withValues(alpha: 0.8),
          size: size <= 40 ? 20 : 24,
        ),
      ),
    );
  }

  Widget _buildCalendarPanel(List<CalendarEvent> events) {
    if (_displayMode == _CalendarDisplayMode.yearly) {
      return _buildYearlyView(events);
    }
    if (_displayMode == _CalendarDisplayMode.monthly) {
      return _buildMonthlyView(events);
    }
    return _buildDailyView(events);
  }

  Widget _buildYearlyView(List<CalendarEvent> events) {
    return GridView.builder(
      key: const ValueKey('yearly'),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final monthDate = DateTime(_currentDate.year, index + 1, 1);
        final count = _eventCountForMonth(monthDate, events);
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentDate = monthDate;
              _displayMode = _CalendarDisplayMode.monthly;
            });
          },
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            borderRadius: 18,
            level: GlassCardLevel.standard,
            showEdgeGlow: count > 0,
            border: Border.all(color: AppColors.glassBorder, width: 0.65),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM', _localeCode()).format(monthDate),
                  style: AppTypography.mono.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 6),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.55),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF93C5FD),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyView(List<CalendarEvent> events) {
    final monthStart = DateTime(_currentDate.year, _currentDate.month, 1);
    final days = _monthGridDays(monthStart);
    final weekdayLabels = [
      _t('calendar_weekday_mon'),
      _t('calendar_weekday_tue'),
      _t('calendar_weekday_wed'),
      _t('calendar_weekday_thu'),
      _t('calendar_weekday_fri'),
      _t('calendar_weekday_sat'),
      _t('calendar_weekday_sun'),
    ];

    return Column(
      key: const ValueKey('monthly'),
      children: [
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.tertiaryLabel,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.59,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final inMonth = day.month == monthStart.month;
              final isToday = _isSameDate(day, DateTime.now());
              final dayEvents = _eventsForDay(day, events);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentDate = day;
                    _displayMode = _CalendarDisplayMode.daily;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: inMonth
                        ? AppColors.backgroundLight.withValues(alpha: 0.58)
                        : AppColors.background.withValues(alpha: 0.4),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF2563EB).withValues(alpha: 0.75)
                          : AppColors.glassBorder.withValues(
                              alpha: inMonth ? 0.65 : 0.25,
                            ),
                      width: isToday ? 1.2 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${day.day}',
                        style: AppTypography.mono.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: !inMonth
                              ? AppColors.tertiaryLabel.withValues(alpha: 0.35)
                              : (isToday
                                    ? const Color(0xFF93C5FD)
                                    : AppColors.label),
                        ),
                      ),
                      const Spacer(),
                      if (dayEvents.isNotEmpty)
                        ...dayEvents
                            .take(2)
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Container(
                                  height: 4.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    color: _eventColor(event),
                                  ),
                                ),
                              ),
                            ),
                      if (dayEvents.length > 2)
                        Text(
                          '+${dayEvents.length - 2}',
                          style: AppTypography.mono.copyWith(
                            fontSize: 9,
                            color: AppColors.tertiaryLabel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyView(List<CalendarEvent> events) {
    final dayLabel = DateFormat(
      'EEEE, MMM d',
      _localeCode(),
    ).format(_currentDate);
    final now = DateTime.now();

    return GlassCard(
      key: const ValueKey('daily'),
      padding: EdgeInsets.zero,
      borderRadius: 22,
      level: GlassCardLevel.standard,
      showEdgeGlow: true,
      border: Border.all(color: AppColors.glassBorder, width: 0.7),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Text(
              dayLabel,
              style: AppTypography.mono.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.label,
              ),
            ),
          ),
          Container(
            height: 0.6,
            color: AppColors.glassBorder.withValues(alpha: 0.5),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: 24,
              itemBuilder: (context, hour) {
                final hourEvents = _eventsForHour(_currentDate, hour, events);
                final hasEvents = hourEvents.isNotEmpty;
                return GestureDetector(
                  onTap: () => _showAddEvent(
                    initialTime: TimeOfDay(hour: hour, minute: 0),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 74),
                    decoration: BoxDecoration(
                      color: hasEvents
                          ? AppColors.backgroundLight.withValues(alpha: 0.26)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.glassBorder.withValues(alpha: 0.32),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 74,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, right: 10),
                            child: Text(
                              "${hour.toString().padLeft(2, '0')}:00",
                              textAlign: TextAlign.right,
                              style: AppTypography.mono.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tertiaryLabel,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hourEvents.isEmpty)
                                  const SizedBox(height: 18)
                                else
                                  ...hourEvents.map(
                                    (event) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: _eventColor(
                                            event,
                                          ).withValues(alpha: 0.16),
                                          border: Border.all(
                                            color: _eventColor(
                                              event,
                                            ).withValues(alpha: 0.65),
                                            width: 0.7,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.title,
                                              style: AppTypography.mono
                                                  .copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.label,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${event.eventTime ?? '${hour.toString().padLeft(2, '0')}:00'} • ${_duration(event)}min",
                                              style: AppTypography.mono
                                                  .copyWith(
                                                    fontSize: 10,
                                                    color: AppColors
                                                        .secondaryLabel,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel({
    required _DayOverloadInfo overloadInfo,
    required _FocusSuggestion focusSuggestion,
    required _FreeTimeInfo freeTime,
    required _HabitConflict habitConflict,
    required _WeekAnalysis weekAnalysis,
  }) {
    return ListView(
      key: const ValueKey('stats'),
      padding: EdgeInsets.zero,
      children: [
        if (overloadInfo.overloaded)
          _warningTile(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            title: _t('calendar_stats_overloaded_day'),
            message: overloadInfo.reason == 'too_many_hours'
                ? _t('calendar_stats_overload_too_many_hours').replaceAll(
                    '{hours}',
                    '${(overloadInfo.totalMinutes / 60).round()}',
                  )
                : overloadInfo.reason == 'no_breaks'
                ? _t('calendar_stats_overload_no_breaks')
                : _t(
                    'calendar_stats_overload_too_many_events',
                  ).replaceAll('{count}', '${overloadInfo.eventCount}'),
            color: AppColors.warning,
          ),
        if (!_loadingHabits && habitConflict.conflict)
          _warningTile(
            icon: CupertinoIcons.check_mark_circled_solid,
            title: _t('calendar_stats_habit_conflict'),
            message: _t('calendar_stats_habit_conflict_message')
                .replaceAll('{habits}', '${habitConflict.habitCount}')
                .replaceAll(
                  '{hours}',
                  '${(habitConflict.eventMinutes / 60).round()}',
                ),
            color: AppColors.success,
          ),
        _focusOpportunityCard(focusSuggestion),
        const SizedBox(height: 12),
        _freeTimeCard(freeTime),
        const SizedBox(height: 14),
        _weekOverviewCard(weekAnalysis),
      ],
    );
  }

  Widget _warningTile({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        level: GlassCardLevel.standard,
        showEdgeGlow: true,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
        gradientColors: [
          color.withValues(alpha: 0.17),
          AppColors.backgroundLight.withValues(alpha: 0.78),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headline.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTypography.callout.copyWith(
                      fontSize: 11,
                      color: AppColors.secondaryLabel,
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

  Widget _focusOpportunityCard(_FocusSuggestion focusSuggestion) {
    final canStart = focusSuggestion.suggest;
    final subtitle = focusSuggestion.reason == 'no_events'
        ? _t('calendar_focus_reason_no_events')
        : focusSuggestion.reason == 'light_schedule'
        ? _t('calendar_focus_reason_light_schedule')
        : _t('calendar_focus_reason_busy_schedule');

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 22,
      level: GlassCardLevel.elevated,
      showEdgeGlow: canStart,
      border: Border.all(
        color: canStart ? AppColors.borderStrong : AppColors.border,
        width: 0.9,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.moduleIconBackground,
              border: Border.all(
                color: canStart
                    ? AppColors.activeBorder.withValues(alpha: 0.48)
                    : AppColors.border,
                width: 0.9,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.bolt_fill,
              color: canStart ? AppColors.accentIcon : AppColors.secondaryLabel,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('calendar_focus_opportunity'),
                  style: AppTypography.title3.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.callout.copyWith(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: canStart ? () => context.push('/focus') : null,
            child: Opacity(
              opacity: canStart ? 1 : 0.55,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.backgroundLight.withValues(alpha: 0.72),
                  border: Border.all(color: AppColors.glassBorder, width: 0.7),
                ),
                child: Text(
                  'Start ${focusSuggestion.recommendedDuration}min',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.label,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _freeTimeCard(_FreeTimeInfo freeTime) {
    final timeLabel =
        '${freeTime.freeTimeHours}h${freeTime.freeTimeRemainingMinutes > 0 ? '${freeTime.freeTimeRemainingMinutes}m' : ''}';
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      borderRadius: 22,
      level: GlassCardLevel.standard,
      showEdgeGlow: true,
      border: Border.all(color: AppColors.glassBorder, width: 0.75),
      child: Row(
        children: [
          Icon(CupertinoIcons.clock, color: AppColors.secondaryLabel, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real Free Time',
                  style: AppTypography.mono.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t('calendar_real_free_time_subtitle'),
                  style: AppTypography.footnote.copyWith(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeLabel,
            style: AppTypography.largeTitle.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekOverviewCard(_WeekAnalysis weekAnalysis) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      level: GlassCardLevel.elevated,
      showEdgeGlow: true,
      border: Border.all(color: AppColors.glassBorder, width: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: const Color(0xFF818CF8),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _t('calendar_week_overview'),
                style: AppTypography.title3.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _weekTile(
                icon: CupertinoIcons.calendar,
                value: '${weekAnalysis.totalEventHours}h',
                label: _t('calendar_week_scheduled'),
                color: AppColors.accent,
                gradient: [
                  AppColors.accent.withValues(alpha: 0.2),
                  AppColors.accentLight.withValues(alpha: 0.12),
                ],
              ),
              const SizedBox(width: 10),
              _weekTile(
                icon: CupertinoIcons.scope,
                value: '${weekAnalysis.importantEventHours}h',
                label: _t('calendar_week_important'),
                color: AppColors.warning,
                emphasizeBorder: true,
                gradient: [
                  AppColors.warning.withValues(alpha: 0.2),
                  AppColors.warning.withValues(alpha: 0.1),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _weekTile(
                icon: CupertinoIcons.clock,
                value: '${weekAnalysis.freeTimeHours}h',
                label: _t('calendar_week_free_time'),
                color: AppColors.success,
                emphasizeBorder: true,
                gradient: [
                  AppColors.success.withValues(alpha: 0.18),
                  AppColors.success.withValues(alpha: 0.1),
                ],
              ),
              const SizedBox(width: 10),
              _weekTile(
                icon: CupertinoIcons.arrow_up_right,
                value: '${weekAnalysis.percentageImportant}%',
                label: _t('calendar_week_priority'),
                color: AppColors.rankAccent,
                gradient: [
                  AppColors.rankAccent.withValues(alpha: 0.18),
                  AppColors.rankAccent.withValues(alpha: 0.1),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.pillBackground,
              border: Border.all(color: AppColors.pillBorder, width: 0.8),
            ),
            child: Text(
              _t(
                'calendar_week_free_hours',
              ).replaceAll('{percent}', '${weekAnalysis.percentageFree}'),
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(
                fontSize: 11,
                color: AppColors.secondaryLabel.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required List<Color> gradient,
    bool emphasizeBorder = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: emphasizeBorder
                ? color.withValues(alpha: 0.34)
                : AppColors.borderStrong.withValues(alpha: 0.72),
            width: 0.85,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassShadowSoft.withValues(
                alpha: AppColors.isDark ? 0.14 : 0.08,
              ),
              blurRadius: AppColors.isDark ? 12 : 10,
              offset: Offset(0, AppColors.isDark ? 5 : 4),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.title1.copyWith(
                fontSize: 31,
                fontWeight: FontWeight.w700,
                color: AppColors.label,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: AppTypography.overline.copyWith(
                fontSize: 9,
                color: color.withValues(alpha: 0.84),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayOverloadInfo {
  final bool overloaded;
  final String? reason;
  final int totalMinutes;
  final int eventCount;

  const _DayOverloadInfo({
    required this.overloaded,
    required this.reason,
    required this.totalMinutes,
    required this.eventCount,
  });
}

class _FocusSuggestion {
  final bool suggest;
  final String? reason;
  final int recommendedDuration;

  const _FocusSuggestion({
    required this.suggest,
    required this.reason,
    required this.recommendedDuration,
  });
}

class _FreeTimeInfo {
  final int freeTimeMinutes;
  final int freeTimeHours;
  final int freeTimeRemainingMinutes;
  final int eventMinutes;
  final int sleepMinutes;
  final int percentageFree;

  const _FreeTimeInfo({
    required this.freeTimeMinutes,
    required this.freeTimeHours,
    required this.freeTimeRemainingMinutes,
    required this.eventMinutes,
    required this.sleepMinutes,
    required this.percentageFree,
  });
}

class _HabitConflict {
  final bool conflict;
  final String? reason;
  final int habitCount;
  final int eventMinutes;

  const _HabitConflict({
    required this.conflict,
    required this.reason,
    required this.habitCount,
    required this.eventMinutes,
  });
}

class _WeekAnalysis {
  final int totalEventHours;
  final int importantEventHours;
  final int freeTimeHours;
  final int percentageImportant;
  final int percentageFree;
  final int eventCount;

  const _WeekAnalysis({
    required this.totalEventHours,
    required this.importantEventHours,
    required this.freeTimeHours,
    required this.percentageImportant,
    required this.percentageFree,
    required this.eventCount,
  });
}

class _CalendarPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleWhenPressed;

  const _CalendarPressScale({
    required this.child,
    required this.onTap,
    this.scaleWhenPressed = 1.03,
  });

  @override
  State<_CalendarPressScale> createState() => _CalendarPressScaleState();
}

class _CalendarPressScaleState extends State<_CalendarPressScale> {
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
        scale: _pressed ? widget.scaleWhenPressed : 1,
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
