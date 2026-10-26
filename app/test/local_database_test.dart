import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';
import 'package:lakbayromblon/core/db/local_database.dart';
import 'package:lakbayromblon/features/alerts/data/alerts_service.dart';
import 'package:lakbayromblon/features/reports/data/reports_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

void main() {
  sqfliteFfiInit();
  late LocalDatabase db;

  setUp(() async {
    db = await LocalDatabase.open(databaseFactoryFfi, inMemoryDatabasePath);
  });
  tearDown(() => db.close());

  Map<String, Object?> seedWithVersion(int version) {
    final files = loadSeedFiles();
    (files['meta']! as Map<String, Object?>)['dataVersion'] = version;
    return files;
  }

  test('imports the seed on first launch and reads it back', () async {
    expect(await db.importSeedIfNewer(FileSeedSource()), isTrue);
    final data = await db.loadTravelData();
    final seed = seedData();
    expect(data.municipalities.length, seed.municipalities.length);
    expect(data.shipFares.length, seed.shipFares.length);
    expect(validateTravelData(data), isEmpty);
  });

  test('does not re-import the same version', () async {
    await db.importSeedIfNewer(FileSeedSource());
    expect(await db.importSeedIfNewer(FileSeedSource()), isFalse);
  });

  test('a newer seed replaces travel data but keeps saved trips', () async {
    await db.importSeedIfNewer(FileSeedSource(seedWithVersion(1)));
    final trips = SqliteSavedTripsRepository(db);
    await trips.save(
      SavedTrip(
        id: 't1',
        name: 'Odiongan → Cubao',
        request: odionganToCubao,
        planId: 'p1',
        createdAt: DateTime(2026, 10, 1),
      ),
    );

    expect(
      await db.importSeedIfNewer(FileSeedSource(seedWithVersion(2))),
      isTrue,
    );
    expect(await db.storedDataVersion(), 2);
    final saved = await trips.all();
    expect(saved.single.request.toJson(), odionganToCubao.toJson());
  });

  test('a broken seed is rejected without wiping existing data', () async {
    await db.importSeedIfNewer(FileSeedSource(seedWithVersion(1)));
    final broken = seedWithVersion(2)
      ..['ports'] = {
        'items': [
          {'id': 'x'},
        ],
      };
    await expectLater(
      db.importSeedIfNewer(FileSeedSource(broken)),
      throwsFormatException,
    );
    expect(await db.storedDataVersion(), 1);
    expect((await db.loadTravelData()).ports, isNotEmpty);
  });

  test('checklist progress and settings persist', () async {
    final progress = SqliteChecklistProgressRepository(db);
    await progress.setDone('plan', 'bring_id', done: true);
    await progress.setDone('plan', 'bring_cash', done: true);
    await progress.setDone('plan', 'bring_cash', done: false);
    expect(await progress.load('plan'), {'bring_id'});

    final settings = SqliteSettingsRepository(db);
    expect(await settings.onboardingDone(), isFalse);
    await settings.setOnboardingDone();
    expect(await settings.onboardingDone(), isTrue);
  });

  test('upgrading a version 1 database adds the new tables and keeps trips', () async {
    await db.close();
    final path =
        '${Directory.systemTemp.createTempSync('lakbay').path}/upgrade.db';
    // A first-release install: v1 schema without guides/hotlines/safety_tips.
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, _) async {
          for (final name in TravelData.collections.where(
            (c) => c != 'meta' && !TravelData.optionalCollections.contains(c),
          )) {
            await d.execute(
              'CREATE TABLE $name (id TEXT PRIMARY KEY, data TEXT NOT NULL, updated_at TEXT)',
            );
          }
          await d.execute('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT)');
          await d.execute(
            'CREATE TABLE saved_trips (id TEXT PRIMARY KEY, name TEXT NOT NULL, request TEXT NOT NULL, plan_id TEXT NOT NULL, created_at TEXT NOT NULL)',
          );
          await d.execute(
            'CREATE TABLE checklist_progress (plan_id TEXT NOT NULL, item_id TEXT NOT NULL, done_at TEXT NOT NULL, PRIMARY KEY (plan_id, item_id))',
          );
          await d.insert('kv', {'key': 'data_version', 'value': '1'});
          await d.insert('saved_trips', {
            'id': 'old',
            'name': 'Old trip',
            'request': jsonEncode(odionganToCubao.toJson()),
            'plan_id': 'p',
            'created_at': '2026-10-01T00:00:00.000',
          });
        },
      ),
    );
    await v1.close();

    db = await LocalDatabase.open(databaseFactoryFfi, path);
    expect(await db.importSeedIfNewer(FileSeedSource()), isTrue);
    final data = await db.loadTravelData();
    expect(data.guides, isNotEmpty);
    expect(data.hotlines, isNotEmpty);
    expect(data.safetyTips, isNotEmpty);
    expect((await SqliteSavedTripsRepository(db).all()).single.id, 'old');
    // v3 tables exist after the upgrade.
    expect(await SqliteReportStore(db).outbox(), isEmpty);
    expect(await db.syncCursor(), isNull);
  });

  test('reports move from the outbox to sent, and statuses update', () async {
    final store = SqliteReportStore(db);
    final report = CommunityReport(
      id: 'local-1',
      kind: ReportKind.fareChange,
      targetCollection: 'ship_fares',
      targetId: 'x',
      targetLabel: 'A → B',
      submittedAt: DateTime.utc(2026, 10, 25),
      note: 'Fare is now 700',
    );
    await store.enqueue(report);
    expect((await store.outbox()).single.note, 'Fare is now 700');

    await store.markSent('local-1', report.copyWith(id: 'srv-1'));
    expect(await store.outbox(), isEmpty);
    expect((await store.sent()).single.id, 'srv-1');

    await store.updateSent([
      report.copyWith(id: 'srv-1', status: ReportStatus.approved),
      report.copyWith(id: 'unknown', status: ReportStatus.rejected),
    ]);
    final sent = await store.sent();
    expect(sent.single.status, ReportStatus.approved);
  });

  test('alert preferences persist', () async {
    final repo = SqliteAlertPrefsRepository(db);
    expect((await repo.load()).enabled, isFalse);
    await repo.save(
      const AlertPrefs(enabled: true, allPorts: false, portIds: {'p1'}),
    );
    final back = await repo.load();
    expect(back.enabled, isTrue);
    expect(back.portIds, {'p1'});
  });

  test('language and text size settings persist', () async {
    final settings = SqliteSettingsRepository(db);
    expect((await settings.load()).languageCode, isNull);
    await settings.save(const AppSettings(languageCode: 'fil', textScale: 1.3));
    final loaded = await settings.load();
    expect(loaded.languageCode, 'fil');
    expect(loaded.textScale, 1.3);
    await settings.save(const AppSettings());
    expect((await settings.load()).languageCode, isNull);
  });
}
