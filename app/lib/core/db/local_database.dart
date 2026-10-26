import 'dart:convert';

import 'package:lakbay_core/lakbay_core.dart';
import 'package:sqflite/sqflite.dart';

import 'seed_source.dart';

/// The on-device SQLite store. All travel data lives here so the app works
/// fully offline; the UI never reads the seed assets directly.
///
/// Travel collections share one shape (`id`, `data` JSON, `updated_at`) so the
/// Phase 4 Firestore sync can write any collection the same way.
class LocalDatabase {
  LocalDatabase._(this.db);

  /// v1: first release. v2: guides, hotlines and safety tips collections.
  /// v3: advisories, the report outbox and sent reports.
  static const schemaVersion = 3;
  static const _dataVersionKey = 'data_version';
  static const _metaKey = 'meta_json';
  static const _syncCursorKey = 'sync_cursor';
  static const _lastSyncKey = 'last_sync_at';

  final Database db;

  static Future<LocalDatabase> open(
    DatabaseFactory factory,
    String path,
  ) async {
    void createTravelTables(Batch batch) {
      for (final name in _travelCollections) {
        batch.execute(
          'CREATE TABLE IF NOT EXISTS $name ('
          'id TEXT PRIMARY KEY, data TEXT NOT NULL, updated_at TEXT)',
        );
      }
    }

    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        // New travel collections only need their table; the newer seed
        // (higher dataVersion) then fills them on the same launch.
        onUpgrade: (db, oldVersion, newVersion) async {
          final batch = db.batch();
          createTravelTables(batch);
          if (oldVersion < 3) _createReportTables(batch);
          await batch.commit(noResult: true);
        },
        onCreate: (db, version) async {
          final batch = db.batch();
          createTravelTables(batch);
          batch
            ..execute('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT)')
            ..execute(
              'CREATE TABLE saved_trips (id TEXT PRIMARY KEY, name TEXT NOT NULL, '
              'request TEXT NOT NULL, plan_id TEXT NOT NULL, created_at TEXT NOT NULL)',
            )
            ..execute(
              'CREATE TABLE checklist_progress (plan_id TEXT NOT NULL, '
              'item_id TEXT NOT NULL, done_at TEXT NOT NULL, '
              'PRIMARY KEY (plan_id, item_id))',
            );
          _createReportTables(batch);
          await batch.commit(noResult: true);
        },
      ),
    );
    return LocalDatabase._(db);
  }

  static void _createReportTables(Batch batch) => batch
    ..execute(
      'CREATE TABLE report_outbox (local_id TEXT PRIMARY KEY, '
      'data TEXT NOT NULL, created_at TEXT NOT NULL)',
    )
    ..execute(
      'CREATE TABLE my_reports (id TEXT PRIMARY KEY, data TEXT NOT NULL, '
      'submitted_at TEXT NOT NULL)',
    );

  static final _travelCollections = TravelData.collections.where(
    (c) => c != 'meta',
  );

  Future<String?> getValue(String key) async {
    final rows = await db.query('kv', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setValue(String key, String value) => db.insert('kv', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<int?> storedDataVersion() async =>
      int.tryParse(await getValue(_dataVersionKey) ?? '');

  /// Imports the bundled seed when the device has none, or an older version.
  ///
  /// User tables (saved trips, checklist progress) are never touched.
  /// Returns true when an import happened.
  Future<bool> importSeedIfNewer(SeedSource seed) async {
    final files = await seed.load();
    final meta = files['meta'];
    if (meta is! Json) throw const FormatException('Seed has no meta.json');
    final seedVersion = meta.req<int>('dataVersion');
    final stored = await storedDataVersion();
    if (stored != null && stored >= seedVersion) return false;

    // Parse first so a broken seed never wipes working data.
    TravelData.fromCollections(files);

    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final name in _travelCollections) {
        batch.delete(name);
        final file = files[name];
        final items = file is Json ? file.objects('items') : const <Json>[];
        for (var i = 0; i < items.length; i++) {
          batch.insert(name, {
            'id': TravelData.documentId(name, items[i], i),
            'data': jsonEncode(items[i]),
            'updated_at': now,
          });
        }
      }
      batch
        ..insert('kv', {
          'key': _metaKey,
          'value': jsonEncode(meta),
        }, conflictAlgorithm: ConflictAlgorithm.replace)
        ..insert('kv', {
          'key': _dataVersionKey,
          'value': '$seedVersion',
        }, conflictAlgorithm: ConflictAlgorithm.replace)
        // The seed replaced synced rows, so the next sync starts over.
        ..delete('kv', where: 'key = ?', whereArgs: [_syncCursorKey]);
      await batch.commit(noResult: true);
    });
    return true;
  }

  /// Every stored item, by collection and then id, in stored order.
  Future<Map<String, Map<String, Json>>> loadRows() async => {
    for (final name in _travelCollections)
      name: {
        for (final row in await db.query(name, orderBy: 'rowid'))
          row['id']! as String: jsonDecode(row['data']! as String) as Json,
      },
  };

  Future<Json> loadMeta() async {
    final metaJson = await getValue(_metaKey);
    if (metaJson == null) {
      throw StateError('No travel data on this device yet');
    }
    return jsonDecode(metaJson) as Json;
  }

  /// Reads every collection back into a [TravelData].
  Future<TravelData> loadTravelData() async => TravelData.fromCollections(
    collectionFiles(await loadMeta(), await loadRows()),
  );

  /// The `{collection: {"items": [...]}}` shape [TravelData] parses.
  static Map<String, Object?> collectionFiles(
    Json meta,
    Map<String, Map<String, Json>> rows,
  ) => {
    'meta': meta,
    for (final entry in rows.entries)
      entry.key: {'items': entry.value.values.toList()},
  };

  /// Server time of the newest change already applied (null: never synced).
  Future<DateTime?> syncCursor() async =>
      DateTime.tryParse(await getValue(_syncCursorKey) ?? '');

  /// When this device last finished a sync (device time, for display).
  Future<DateTime?> lastSyncAt() async =>
      DateTime.tryParse(await getValue(_lastSyncKey) ?? '');

  /// Writes synced items in one transaction. A null value deletes the row.
  Future<void> applyChanges({
    required Map<String, Map<String, Json?>> changes,
    Json? meta,
    DateTime? cursor,
    required DateTime syncedAt,
  }) => db.transaction((txn) async {
    final updatedAt = syncedAt.toIso8601String();
    for (final MapEntry(key: collection, value: docs) in changes.entries) {
      for (final MapEntry(key: id, value: item) in docs.entries) {
        if (item == null) {
          await txn.delete(collection, where: 'id = ?', whereArgs: [id]);
          continue;
        }
        // Update in place so edited items keep their list position.
        // (No UPSERT: Android 7 ships an SQLite without it.)
        final row = {'data': jsonEncode(item), 'updated_at': updatedAt};
        final updated = await txn.update(
          collection,
          row,
          where: 'id = ?',
          whereArgs: [id],
        );
        if (updated == 0) await txn.insert(collection, {'id': id, ...row});
      }
    }
    final batch = txn.batch();
    void put(String key, String value) => batch.insert('kv', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    if (meta != null) put(_metaKey, jsonEncode(meta));
    if (cursor != null) put(_syncCursorKey, cursor.toUtc().toIso8601String());
    put(_lastSyncKey, syncedAt.toIso8601String());
    await batch.commit(noResult: true);
  });

  Future<void> close() => db.close();
}
