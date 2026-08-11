import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// A single deferred write to apply when the device is back online.
/// Serialized as JSON inside a per-user list in SharedPreferences.
class WriteOperation {
  final String id;
  final String table;
  final WriteOpType type;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> match;
  final int createdAtMs;
  final int retries;

  /// For [WriteOpType.upsert] only — the column(s) used by Postgres for
  /// conflict resolution. Comma-separated to match Supabase's expected format.
  final String? onConflict;

  const WriteOperation({
    required this.id,
    required this.table,
    required this.type,
    required this.payload,
    required this.match,
    required this.createdAtMs,
    this.retries = 0,
    this.onConflict,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'type': type.name,
    'payload': payload,
    'match': match,
    'createdAtMs': createdAtMs,
    'retries': retries,
    if (onConflict != null) 'onConflict': onConflict,
  };

  static WriteOperation fromJson(Map<String, dynamic> json) => WriteOperation(
    id: json['id'] as String,
    table: json['table'] as String,
    type: WriteOpType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => WriteOpType.update,
    ),
    payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    match: (json['match'] as Map?)?.cast<String, dynamic>() ?? const {},
    createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    retries: (json['retries'] as num?)?.toInt() ?? 0,
    onConflict: json['onConflict'] as String?,
  );

  WriteOperation withRetryIncrement() => WriteOperation(
    id: id,
    table: table,
    type: type,
    payload: payload,
    match: match,
    createdAtMs: createdAtMs,
    retries: retries + 1,
    onConflict: onConflict,
  );
}

enum WriteOpType { insert, update, delete, upsert }

/// Persistent FIFO queue of deferred writes, scoped per Supabase user.
class WriteQueue {
  WriteQueue._();

  static const String _keyBase = 'write_queue::v1';
  static const Uuid _uuid = Uuid();

  static String _scopedKey() {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return '$_keyBase::$uid';
  }

  /// Push a new write at the tail of the queue. Returns the assigned id.
  static Future<String> enqueue({
    required String table,
    required WriteOpType type,
    Map<String, dynamic> payload = const {},
    Map<String, dynamic> match = const {},
    String? onConflict,
  }) async {
    final op = WriteOperation(
      id: _uuid.v4(),
      table: table,
      type: type,
      payload: payload,
      match: match,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      onConflict: onConflict,
    );
    final current = await list();
    current.add(op);
    await _write(current);
    return op.id;
  }

  static Future<List<WriteOperation>> list() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedKey());
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => WriteOperation.fromJson(m.cast<String, dynamic>()))
          .toList(growable: true);
    } catch (_) {
      return [];
    }
  }

  static Future<int> size() async => (await list()).length;

  static Future<void> _write(List<WriteOperation> ops) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _scopedKey(),
        jsonEncode(ops.map((o) => o.toJson()).toList(growable: false)),
      );
    } catch (_) {}
  }

  /// Remove an operation from the queue by its [id].
  static Future<void> remove(String id) async {
    final current = await list();
    current.removeWhere((o) => o.id == id);
    await _write(current);
  }

  /// Replace an existing operation (used to update retry count).
  static Future<void> replace(WriteOperation op) async {
    final current = await list();
    final idx = current.indexWhere((o) => o.id == op.id);
    if (idx == -1) return;
    current[idx] = op;
    await _write(current);
  }

  /// Wipe the queue (e.g. on sign-out).
  static Future<void> clear() async {
    await _write(const []);
  }
}
