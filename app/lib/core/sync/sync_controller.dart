import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/local_database.dart';
import '../providers.dart';
import 'remote_source.dart';
import 'sync_service.dart';

/// The server to sync from; null when Firebase is not set up (the app then
/// runs on the bundled and last-synced data only).
final remoteSourceProvider = Provider<RemoteSource?>((ref) => null);

/// The open local database; null in widget tests that use memory stores.
final localDatabaseProvider = Provider<LocalDatabase?>((ref) => null);

/// When the device last synced, read at startup.
final initialLastSyncProvider = Provider<DateTime?>((ref) => null);

enum SyncOutcome { updated, upToDate, notConfigured, failed }

class SyncState {
  const SyncState({this.lastSyncAt, this.running = false, this.lastOutcome});

  final DateTime? lastSyncAt;
  final bool running;
  final SyncOutcome? lastOutcome;
}

class SyncController extends Notifier<SyncState> {
  /// Automatic syncs (launch, back to the app) run at most this often.
  static const minInterval = Duration(minutes: 15);
  static const timeout = Duration(seconds: 45);

  @override
  SyncState build() => SyncState(lastSyncAt: ref.read(initialLastSyncProvider));

  bool get isAvailable =>
      ref.read(remoteSourceProvider) != null &&
      ref.read(localDatabaseProvider) != null;

  Future<SyncOutcome> syncIfDue() async {
    final last = state.lastSyncAt;
    final now = ref.read(clockProvider)();
    if (last != null && now.difference(last) < minInterval) {
      return SyncOutcome.upToDate;
    }
    return syncNow();
  }

  Future<SyncOutcome> syncNow() async {
    final remote = ref.read(remoteSourceProvider);
    final database = ref.read(localDatabaseProvider);
    if (remote == null || database == null) return SyncOutcome.notConfigured;
    if (state.running) return SyncOutcome.upToDate;

    state = SyncState(lastSyncAt: state.lastSyncAt, running: true);
    try {
      final result = await SyncService(
        database: database,
        remote: remote,
        clock: ref.read(clockProvider),
      ).sync().timeout(timeout);
      if (result.applied > 0) {
        ref.read(travelDataProvider.notifier).replace(result.data);
      }
      final outcome = result.applied > 0
          ? SyncOutcome.updated
          : SyncOutcome.upToDate;
      state = SyncState(
        lastSyncAt: ref.read(clockProvider)(),
        lastOutcome: outcome,
      );
      return outcome;
    } on Object catch (e) {
      debugPrint('Sync failed: $e');
      state = SyncState(
        lastSyncAt: state.lastSyncAt,
        lastOutcome: SyncOutcome.failed,
      );
      return SyncOutcome.failed;
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);
