import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_models.dart';
import '../utils/app_logger.dart';
import '../services/offline_cache.dart';
import '../services/supabase_service.dart';
import '../services/write_queue.dart';

class TaskRepository {
  static const String _tasksCacheKey = 'tasks_v1';

  final SupabaseService _supabaseService;

  TaskRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;
  String get _currentUserId => _client.auth.currentUser!.id;

  Future<List<ParetoTask>> getTasks({bool includeCompleted = false}) async {
    try {
      dynamic query = _client
          .from('pareto_tasks')
          .select()
          .eq('created_by', _currentUserId);

      if (!includeCompleted) {
        query = query.eq('completed', false);
      }

      final response = await query.order('sort_order', ascending: true);
      final raw = (response as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);

      // Cache the full raw set (incl. completed when we just fetched them) so
      // the offline read can answer either flavour from the same snapshot.
      await OfflineCache.writeList(_tasksCacheKey, raw);

      return raw.map(ParetoTask.fromJson).toList(growable: false);
    } catch (_) {
      // Network/Supabase failure — serve last known snapshot.
      final cached = await OfflineCache.readList(_tasksCacheKey);
      if (cached == null) return const [];
      final tasks = cached.map(ParetoTask.fromJson).toList(growable: false);
      if (includeCompleted) return tasks;
      return tasks.where((t) => !t.completed).toList(growable: false);
    }
  }

  Future<void> uncompleteTask(String taskId) async {
    const payload = {'completed': false, 'completed_date': null};
    final match = {'id': taskId, 'created_by': _currentUserId};
    try {
      await _client
          .from('pareto_tasks')
          .update(payload)
          .eq('id', taskId)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'pareto_tasks',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    final match = {'id': taskId, 'created_by': _currentUserId};
    try {
      await _client
          .from('pareto_tasks')
          .delete()
          .eq('id', taskId)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'pareto_tasks',
        type: WriteOpType.delete,
        match: match,
      );
    }
  }

  Future<void> addTask(
    String title, {
    String? importance,
    String? duration,
    String? groupId,
    DateTime? deadline,
    String? description,
    bool syncToCalendar = false,
  }) async {
    // Pre-allocate a UUID so the same id is reused if we have to enqueue
    // the write for offline replay. Postgres accepts client-side UUIDs.
    final clientId = const Uuid().v4();
    final payload = <String, dynamic>{
      'id': clientId,
      'created_by': _currentUserId,
      'title': title,
      'importance_level': importance,
      'time_duration': duration,
      'group_id': groupId,
      'deadline': deadline?.toIso8601String(),
      'description': description,
      'completed': false,
    };
    Map<String, dynamic> response = {};
    var queuedOffline = false;
    try {
      response = await _client
          .from('pareto_tasks')
          .insert(payload)
          .select('id, title, deadline')
          .single();
    } on PostgrestException catch (e) {
      var current = e;
      final fallbackPayload = Map<String, dynamic>.from(payload);
      while (true) {
        final isSchemaColumnIssue =
            current.code == 'PGRST204' || current.code == '42703';
        if (!isSchemaColumnIssue) rethrow;

        final msg = current.message;
        final quoted = RegExp(r"'([^']+)' column").firstMatch(msg)?.group(1);
        final dotted = RegExp(
          r'pareto_tasks\.([a-zA-Z0-9_]+)',
        ).firstMatch(msg)?.group(1);
        final missingColumn = quoted ?? dotted;
        if (missingColumn == null ||
            !fallbackPayload.containsKey(missingColumn)) {
          rethrow;
        }
        fallbackPayload.remove(missingColumn);

        try {
          response = await _client
              .from('pareto_tasks')
              .insert(fallbackPayload)
              .select('id, title')
              .single();
          break;
        } on PostgrestException catch (next) {
          current = next;
          continue;
        }
      }
    } catch (_) {
      // Network / offline — optimistically write to local cache and queue
      // the insert for replay on reconnect.
      queuedOffline = true;
      await _optimisticallyAppendTaskToCache(payload);
      await WriteQueue.enqueue(
        table: 'pareto_tasks',
        type: WriteOpType.insert,
        payload: payload,
      );
      response = {'id': clientId, 'title': title};
    }

    if (syncToCalendar && deadline != null) {
      final eventDate =
          '${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
      if (queuedOffline) {
        // Queue the event insert directly to keep the offline flow self-contained.
        await WriteQueue.enqueue(
          table: 'calendar_events',
          type: WriteOpType.insert,
          payload: {
            'id': const Uuid().v4(),
            'created_by': _currentUserId,
            'title': title,
            'description': description,
            'event_date': eventDate,
            'source_type': 'task',
            'source_id': response['id'] as String?,
          },
        );
      } else {
        await addEvent(
          title,
          eventDate,
          description: description,
          sourceType: 'task',
          sourceId: response['id'] as String?,
        );
      }
    }
  }

  Future<void> _optimisticallyAppendTaskToCache(
    Map<String, dynamic> payload,
  ) async {
    final cached = await OfflineCache.readList(_tasksCacheKey) ?? const [];
    final next = [
      ...cached,
      Map<String, dynamic>.from(payload),
    ];
    await OfflineCache.writeList(_tasksCacheKey, next);
  }

  Future<void> completeTask(String taskId) async {
    final payload = {
      'completed': true,
      'completed_date': DateTime.now().toIso8601String(),
    };
    final match = {'id': taskId, 'created_by': _currentUserId};
    try {
      await _client
          .from('pareto_tasks')
          .update(payload)
          .eq('id', taskId)
          .eq('created_by', _currentUserId);
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'pareto_tasks',
        type: WriteOpType.update,
        payload: payload,
        match: match,
      );
    }
  }

  // --- Task Groups ---

  Future<List<TaskGroup>> getTaskGroups() async {
    try {
      final response = await _client
          .from('task_groups')
          .select()
          .eq('created_by', _currentUserId)
          .order('name', ascending: true);

      return (response as List)
          .map((data) => TaskGroup.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('getting task groups', e);
      return [];
    }
  }

  Future<TaskGroup> addTaskGroup(String name, {String? color}) async {
    final response = await _client
        .from('task_groups')
        .insert({'created_by': _currentUserId, 'name': name, 'color': color})
        .select()
        .single();

    return TaskGroup.fromJson(response);
  }

  // --- Events ---

  Future<List<CalendarEvent>> getAllEvents() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final horizonDate = DateTime.now().add(const Duration(days: 740));
      final dateStr = _formatDate(cutoffDate);

      final upcomingResponse = await _client
          .from('calendar_events')
          .select()
          .eq('created_by', _currentUserId)
          .gte('event_date', dateStr)
          .order('event_date', ascending: true);

      final recurringResponse = await _client
          .from('calendar_events')
          .select()
          .eq('created_by', _currentUserId)
          .not('recurrence_rule', 'is', null);

      final merged = <String, Map<String, dynamic>>{};
      for (final item in (upcomingResponse as List)) {
        final row = Map<String, dynamic>.from(item as Map);
        final id = row['id'] as String?;
        if (id != null && id.isNotEmpty) {
          merged[id] = row;
        }
      }
      for (final item in (recurringResponse as List)) {
        final row = Map<String, dynamic>.from(item as Map);
        final id = row['id'] as String?;
        if (id != null && id.isNotEmpty) {
          merged[id] = row;
        }
      }

      final baseEvents = merged.values
          .map((data) => CalendarEvent.fromJson(data))
          .toList();

      return _expandRecurringEvents(
        baseEvents,
        cutoffDate: cutoffDate,
        horizonDate: horizonDate,
      );
    } catch (e) {
      AppLogger.error('getting events', e);
      return [];
    }
  }

  Future<void> addEvent(
    String title,
    String date, {
    String? time,
    int? durationMinutes,
    String? description,
    String? sourceType,
    String? sourceId,
    String? recurrenceRule,
    String? eventTypeId,
  }) async {
    final payload = <String, dynamic>{
      'id': const Uuid().v4(),
      'created_by': _currentUserId,
      'title': title,
      'description': description,
      'event_date': date,
      'event_time': time,
      'duration_minutes': durationMinutes,
      'source_type': sourceType ?? 'manual',
      'source_id': sourceId,
      'recurrence_rule': recurrenceRule,
      'event_type_id': eventTypeId,
    };

    try {
      await _client.from('calendar_events').insert(payload);
    } on PostgrestException catch (e) {
      var current = e;
      final fallbackPayload = Map<String, dynamic>.from(payload);

      while (true) {
        final isSchemaColumnIssue =
            current.code == 'PGRST204' || current.code == '42703';
        if (!isSchemaColumnIssue) rethrow;

        final msg = current.message;
        final quoted = RegExp(r"'([^']+)' column").firstMatch(msg)?.group(1);
        final dotted = RegExp(
          r'calendar_events\\.([a-zA-Z0-9_]+)',
        ).firstMatch(msg)?.group(1);
        final missingColumn = quoted ?? dotted;
        if (missingColumn == null ||
            !fallbackPayload.containsKey(missingColumn)) {
          rethrow;
        }

        fallbackPayload.remove(missingColumn);

        try {
          await _client.from('calendar_events').insert(fallbackPayload);
          break;
        } on PostgrestException catch (next) {
          current = next;
          continue;
        }
      }
    } catch (_) {
      await WriteQueue.enqueue(
        table: 'calendar_events',
        type: WriteOpType.insert,
        payload: payload,
      );
    }
  }

  List<CalendarEvent> _expandRecurringEvents(
    List<CalendarEvent> baseEvents, {
    required DateTime cutoffDate,
    required DateTime horizonDate,
  }) {
    final output = <CalendarEvent>[];

    for (final event in baseEvents) {
      final recurrence = (event.recurrenceRule ?? '').trim().toLowerCase();
      final baseDate = _parseDate(event.eventDate);

      if (recurrence.isEmpty || baseDate == null) {
        if (baseDate != null &&
            (baseDate.isBefore(cutoffDate) || baseDate.isAfter(horizonDate))) {
          continue;
        }
        output.add(event);
        continue;
      }

      if (recurrence.contains('year')) {
        for (var year = cutoffDate.year - 1; year <= horizonDate.year; year++) {
          final occurrenceDate = _safeDate(year, baseDate.month, baseDate.day);
          if (occurrenceDate.isBefore(cutoffDate) ||
              occurrenceDate.isAfter(horizonDate)) {
            continue;
          }
          output.add(_cloneWithDate(event, occurrenceDate, suffix: 'y-$year'));
        }
        continue;
      }

      if (recurrence.contains('week')) {
        var occurrenceDate = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
        );
        while (occurrenceDate.isBefore(cutoffDate)) {
          occurrenceDate = occurrenceDate.add(const Duration(days: 7));
        }

        while (!occurrenceDate.isAfter(horizonDate)) {
          output.add(
            _cloneWithDate(
              event,
              occurrenceDate,
              suffix: 'w-${_formatDate(occurrenceDate)}',
            ),
          );
          occurrenceDate = occurrenceDate.add(const Duration(days: 7));
        }
        continue;
      }

      if (!baseDate.isBefore(cutoffDate) && !baseDate.isAfter(horizonDate)) {
        output.add(event);
      }
    }

    output.sort((a, b) {
      final byDate = (a.eventDate ?? '').compareTo(b.eventDate ?? '');
      if (byDate != 0) return byDate;
      return (a.eventTime ?? '').compareTo(b.eventTime ?? '');
    });
    return output;
  }

  CalendarEvent _cloneWithDate(
    CalendarEvent source,
    DateTime day, {
    required String suffix,
  }) {
    return CalendarEvent(
      id: '${source.id}::$suffix',
      createdBy: source.createdBy,
      title: source.title,
      description: source.description,
      eventDate: _formatDate(day),
      eventTime: source.eventTime,
      durationMinutes: source.durationMinutes,
      sourceType: source.sourceType,
      sourceId: source.sourceId,
      recurrenceRule: source.recurrenceRule,
      eventTypeId: source.eventTypeId,
      notification24hTime: source.notification24hTime,
      notification2hTime: source.notification2hTime,
      notification24hSent: source.notification24hSent,
      notification2hSent: source.notification2hSent,
      createdAt: source.createdAt,
    );
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _safeDate(int year, int month, int day) {
    final maxDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > maxDay ? maxDay : day);
  }
}
