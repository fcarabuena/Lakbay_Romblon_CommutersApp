import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/core/db/local_database.dart';
import 'package:lakbayromblon/core/providers.dart';
import 'package:lakbayromblon/core/sync/remote_source.dart';
import 'package:lakbayromblon/core/sync/sync_controller.dart';
import 'package:lakbayromblon/core/sync/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

/// Serves queued changes once each, newest cursor last, like Firestore would.
class FakeRemoteSource implements RemoteSource {
  final List<RemoteChanges> pending = [];
  final List<DateTime?> askedSince = [];
  Object? error;

  @override
  Future<RemoteChanges> changesSince(DateTime? since) async {
    askedSince.add(since);
    if (error != null) throw error!;
    return pending.isEmpty ? const RemoteChanges() : pending.removeAt(0);
  }
}

final t1 = DateTime.utc(2026, 11, 1, 8);
final t2 = DateTime.utc(2026, 11, 2, 8);

Json advisory({String id = 'adv1', String? port}) => {
  'id': id,
  'type': 'coastGuard',
  'severity': 'suspended',
  'title': {'en': 'Trips suspended'},
  'message': {'en': 'No sailing.'},
  'validFrom': '2026-11-01T00:00:00+08:00',
  'source': 'PCG test notice',
  'affectedPortIds': [?port],
};

void main() {
  sqfliteFfiInit();
  late LocalDatabase db;
  late FakeRemoteSource remote;
  late SyncService sync;
  final seed = seedData();
  final fare = seed.shipFares.first;
  final fareId = TravelData.documentId('ship_fares', {
    'voyageId': fare.voyageId,
    'fromPortId': fare.fromPortId,
    'toPortId': fare.toPortId,
    'fareClass': fare.fareClass,
  });
  final fareJson = (loadSeedFiles()['ship_fares']! as Json)
      .objects('items')
      .first;

  setUp(() async {
    db = await LocalDatabase.open(databaseFactoryFfi, inMemoryDatabasePath);
    await db.importSeedIfNewer(FileSeedSource());
    remote = FakeRemoteSource();
    sync = SyncService(database: db, remote: remote, clock: () => t2);
  });
  tearDown(() => db.close());

  test('applies new and changed documents and advances the cursor', () async {
    remote.pending.add(
      RemoteChanges(
        docs: {
          'advisories': [
            RemoteDoc(id: 'adv1', updatedAt: t1, data: advisory()),
          ],
          'ship_fares': [
            RemoteDoc(
              id: fareId,
              updatedAt: t2,
              data: {...fareJson, 'farePhp': 999},
            ),
          ],
        },
      ),
    );

    final result = await sync.sync();
    expect(result.applied, 2);
    expect(result.skipped, isEmpty);
    expect(result.data.advisories.single.id, 'adv1');
    expect(result.data.shipFares.length, seed.shipFares.length);
    expect(result.data.shipFares.first.amount, 99900);
    expect(await db.syncCursor(), t2);
    expect(await db.lastSyncAt(), t2);

    // The next sync asks only for newer changes.
    final again = await sync.sync();
    expect(again.applied, 0);
    expect(remote.askedSince, [null, t2]);
  });

  test('a soft-deleted document is removed', () async {
    remote.pending
      ..add(
        RemoteChanges(
          docs: {
            'advisories': [
              RemoteDoc(id: 'adv1', updatedAt: t1, data: advisory()),
            ],
          },
        ),
      )
      ..add(
        RemoteChanges(
          docs: {
            'advisories': [RemoteDoc(id: 'adv1', updatedAt: t2, deleted: true)],
          },
        ),
      );
    await sync.sync();
    final result = await sync.sync();
    expect(result.data.advisories, isEmpty);
  });

  test('a malformed document is skipped and the rest still apply', () async {
    remote.pending.add(
      RemoteChanges(
        docs: {
          'advisories': [
            RemoteDoc(
              id: 'bad',
              updatedAt: t1,
              data: {
                ...advisory(id: 'bad'),
                'severity': 'apocalyptic',
              },
            ),
            RemoteDoc(id: 'adv1', updatedAt: t1, data: advisory()),
          ],
        },
      ),
    );
    final result = await sync.sync();
    expect(result.data.advisories.map((a) => a.id), ['adv1']);
    expect(result.skipped.single, startsWith('advisories/bad'));
  });

  test('a document that breaks the data is skipped', () async {
    remote.pending.add(
      RemoteChanges(
        docs: {
          'ship_fares': [
            RemoteDoc(
              id: 'ghost',
              updatedAt: t1,
              data: {...fareJson, 'voyageId': 'no-such-voyage'},
            ),
          ],
          'advisories': [
            RemoteDoc(
              id: 'adv2',
              updatedAt: t1,
              data: advisory(id: 'adv2', port: 'no-such-port'),
            ),
            RemoteDoc(id: 'adv1', updatedAt: t1, data: advisory()),
          ],
        },
      ),
    );
    final result = await sync.sync();
    expect(result.data.shipFares.length, seed.shipFares.length);
    expect(result.data.advisories.map((a) => a.id), ['adv1']);
    expect(result.skipped, hasLength(2));
    expect(result.skipped.join(), contains('unknown voyage'));
    expect(validateTravelData(result.data), isEmpty);
  });

  test(
    'server meta replaces the local one but keeps the local data version',
    () async {
      final meta = loadSeedFiles()['meta']! as Json;
      remote.pending.add(
        RemoteChanges(
          meta: {...meta, 'dataVersion': 99, 'isPlaceholderData': false},
          metaUpdatedAt: t1,
        ),
      );
      final result = await sync.sync();
      expect(result.data.meta.isPlaceholderData, isFalse);
      expect(result.data.meta.dataVersion, seed.meta.dataVersion);
    },
  );

  test(
    'a newer bundled seed resets the cursor so everything resyncs',
    () async {
      remote.pending.add(
        RemoteChanges(
          docs: {
            'advisories': [
              RemoteDoc(id: 'adv1', updatedAt: t1, data: advisory()),
            ],
          },
        ),
      );
      await sync.sync();
      expect(await db.syncCursor(), t1);

      final files = loadSeedFiles();
      (files['meta']! as Json)['dataVersion'] = seed.meta.dataVersion + 1;
      await db.importSeedIfNewer(FileSeedSource(files));
      expect(await db.syncCursor(), isNull);
      expect((await db.loadTravelData()).advisories, isEmpty);
    },
  );

  group('SyncController', () {
    ProviderContainer container({RemoteSource? remoteSource}) {
      final c = ProviderContainer(
        overrides: [
          initialTravelDataProvider.overrideWithValue(seed),
          localDatabaseProvider.overrideWithValue(db),
          remoteSourceProvider.overrideWithValue(remoteSource),
          clockProvider.overrideWithValue(() => t2),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('without a server it reports not configured', () async {
      final c = container();
      expect(
        await c.read(syncControllerProvider.notifier).syncNow(),
        SyncOutcome.notConfigured,
      );
    });

    test('a successful sync replaces the travel data everywhere', () async {
      remote.pending.add(
        RemoteChanges(
          docs: {
            'advisories': [
              RemoteDoc(id: 'adv1', updatedAt: t1, data: advisory()),
            ],
          },
        ),
      );
      final c = container(remoteSource: remote);
      final controller = c.read(syncControllerProvider.notifier);
      expect(await controller.syncNow(), SyncOutcome.updated);
      expect(c.read(travelDataProvider).advisories, hasLength(1));
      expect(c.read(syncControllerProvider).lastSyncAt, t2);

      // Within 15 minutes an automatic sync does nothing.
      expect(await controller.syncIfDue(), SyncOutcome.upToDate);
      expect(remote.askedSince, hasLength(1));
    });

    test('a network error keeps the current data', () async {
      remote.error = Exception('offline');
      final c = container(remoteSource: remote);
      expect(
        await c.read(syncControllerProvider.notifier).syncNow(),
        SyncOutcome.failed,
      );
      expect(c.read(travelDataProvider), same(seed));
      expect(c.read(syncControllerProvider).lastOutcome, SyncOutcome.failed);
    });
  });
}
