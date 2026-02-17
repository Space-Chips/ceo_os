import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

/// A countdown event targeting a future date.
class CountdownEvent {
  final String id;
  String title;
  DateTime targetDate;
  Color color;
  IconData icon;
  DateTime createdAt;

  CountdownEvent({
    String? id,
    required this.title,
    required this.targetDate,
    this.color = const Color(0xFF0A84FF),
    this.icon = CupertinoIcons.calendar,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Duration get remaining {
    final diff = targetDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isPast => DateTime.now().isAfter(targetDate);

  int get daysRemaining => remaining.inDays;
  int get hoursRemaining => remaining.inHours % 24;
  int get minutesRemaining => remaining.inMinutes % 60;
  int get secondsRemaining => remaining.inSeconds % 60;
}

/// In-memory countdown events with live ticker.
class CountdownProvider extends ChangeNotifier {
  final List<CountdownEvent> _events = [];
  Timer? _ticker;

  List<CountdownEvent> get events => List.unmodifiable(_events);

  List<CountdownEvent> get upcomingEvents =>
      _events.where((e) => !e.isPast).toList()
        ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

  List<CountdownEvent> get pastEvents =>
      _events.where((e) => e.isPast).toList()
        ..sort((a, b) => b.targetDate.compareTo(a.targetDate));

  CountdownProvider() {
    _startTicker();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void addEvent(CountdownEvent event) {
    _events.insert(0, event);
    notifyListeners();
  }

  void removeEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void updateEvent(CountdownEvent event) {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _events[index] = event;
      notifyListeners();
    }
  }

  void loadSampleData() {
    if (_events.isNotEmpty) return;
    final now = DateTime.now();
    _events.addAll([
      CountdownEvent(
        title: 'Product Launch',
        targetDate: now.add(const Duration(days: 14, hours: 6)),
        color: const Color(0xFFFF9F0A),
        icon: CupertinoIcons.rocket,
      ),
      CountdownEvent(
        title: 'Board Meeting',
        targetDate: now.add(const Duration(days: 3, hours: 2)),
        color: const Color(0xFFBF5AF2),
        icon: CupertinoIcons.person_3,
      ),
      CountdownEvent(
        title: 'Q1 Deadline',
        targetDate: now.add(const Duration(days: 45)),
        color: const Color(0xFFFF453A),
        icon: CupertinoIcons.flag,
      ),
      CountdownEvent(
        title: 'Team Offsite',
        targetDate: now.add(const Duration(days: 30, hours: 10)),
        color: const Color(0xFF30D158),
        icon: CupertinoIcons.airplane,
      ),
    ]);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
