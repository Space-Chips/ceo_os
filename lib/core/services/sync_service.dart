import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/connectivity_provider.dart';
import 'write_queue.dart';

/// Flushes the [WriteQueue] when connectivity is restored. Listen-once
/// per state change so we don't hammer Supabase on flaky networks.
class SyncService {
  final ConnectivityProvider _connectivity;
  final SupabaseClient _client;
  bool _flushing = false;
  bool _wasOnline = true;

  SyncService({
    required ConnectivityProvider connectivity,
    SupabaseClient? client,
  }) : _connectivity = connectivity,
       _client = client ?? Supabase.instance.client {
    _wasOnline = connectivity.isOnline;
    connectivity.addListener(_onConnectivityChanged);
  }

  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    final nowOnline = _connectivity.isOnline;
    final justReconnected = nowOnline && !_wasOnline;
    _wasOnline = nowOnline;
    if (justReconnected) {
      // Fire-and-forget; failures stay queued for the next attempt.
      unawaited(flush());
    }
  }

  /// Public entry point so app bootstrap / pull-to-refresh can trigger
  /// a flush manually.
  Future<void> flush() async {
    if (_flushing) return;
    if (!_connectivity.isOnline) return;
    if (_client.auth.currentUser == null) return;
    _flushing = true;
    try {
      final ops = await WriteQueue.list();
      if (ops.isEmpty) return;
      ops.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
      for (final op in ops) {
        try {
          await _apply(op);
          await WriteQueue.remove(op.id);
        } catch (_) {
          // Keep the op for next flush; bump retry counter for visibility.
          await WriteQueue.replace(op.withRetryIncrement());
          // Stop on first failure — if Supabase is unreachable now, the
          // rest will fail too. Connectivity listener will retry later.
          break;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _apply(WriteOperation op) async {
    switch (op.type) {
      case WriteOpType.insert:
        await _client.from(op.table).insert(op.payload);
        return;
      case WriteOpType.update:
        var query = _client.from(op.table).update(op.payload);
        for (final entry in op.match.entries) {
          query = query.eq(entry.key, entry.value);
        }
        await query;
        return;
      case WriteOpType.delete:
        var query = _client.from(op.table).delete();
        for (final entry in op.match.entries) {
          query = query.eq(entry.key, entry.value);
        }
        await query;
        return;
      case WriteOpType.upsert:
        final onConflict = op.onConflict;
        if (onConflict != null && onConflict.isNotEmpty) {
          await _client
              .from(op.table)
              .upsert(op.payload, onConflict: onConflict);
        } else {
          await _client.from(op.table).upsert(op.payload);
        }
        return;
    }
  }
}
