import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app/app.dart';
import 'core/data/user_repositories.dart';
import 'core/db/local_database.dart';
import 'core/db/seed_source.dart';
import 'core/firebase/firebase_setup.dart';
import 'core/providers.dart';
import 'core/settings_controller.dart';
import 'core/sync/sync_controller.dart';
import 'features/alerts/application/alerts_controller.dart';
import 'features/alerts/data/alerts_service.dart';
import 'features/reports/application/reports_controller.dart';
import 'features/reports/data/reports_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final db = await LocalDatabase.open(
      databaseFactory,
      p.join(await getDatabasesPath(), 'lakbay.db'),
    );
    await db.importSeedIfNewer(const AssetSeedSource());
    final data = await db.loadTravelData();
    final settings = SqliteSettingsRepository(db);
    final onboarded = await settings.onboardingDone();
    final appSettings = await settings.load();
    final alertPrefs = SqliteAlertPrefsRepository(db);
    final firebase = await FirebaseServices.start();

    runApp(
      ProviderScope(
        overrides: [
          initialTravelDataProvider.overrideWithValue(data),
          onboardingDoneAtStartProvider.overrideWithValue(onboarded),
          initialSettingsProvider.overrideWithValue(appSettings),
          settingsRepositoryProvider.overrideWithValue(settings),
          savedTripsRepositoryProvider.overrideWithValue(
            SqliteSavedTripsRepository(db),
          ),
          checklistProgressRepositoryProvider.overrideWithValue(
            SqliteChecklistProgressRepository(db),
          ),
          localDatabaseProvider.overrideWithValue(db),
          initialLastSyncProvider.overrideWithValue(await db.lastSyncAt()),
          reportStoreProvider.overrideWithValue(SqliteReportStore(db)),
          alertPrefsRepositoryProvider.overrideWithValue(alertPrefs),
          initialAlertPrefsProvider.overrideWithValue(await alertPrefs.load()),
          if (firebase != null) ...[
            remoteSourceProvider.overrideWithValue(firebase.remote),
            reportSenderProvider.overrideWithValue(firebase.reportSender),
            alertsServiceProvider.overrideWithValue(firebase.alerts),
          ],
        ],
        child: const LakbayApp(),
      ),
    );
  } catch (error) {
    runApp(_StartupErrorApp(error: error));
  }
}

/// Shown only if the local database cannot be opened or the data is broken.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Lakbay Romblon could not load its travel data.\n\n'
              'Please reinstall the app or contact support.\n\n$error',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
