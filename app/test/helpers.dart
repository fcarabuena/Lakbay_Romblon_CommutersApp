import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/app/app.dart';
import 'package:lakbayromblon/app/router.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';
import 'package:lakbayromblon/core/db/seed_source.dart';
import 'package:lakbayromblon/core/providers.dart';
import 'package:lakbayromblon/core/services/device_services.dart';
import 'package:lakbayromblon/core/settings_controller.dart';
import 'package:lakbayromblon/core/sync/remote_source.dart';
import 'package:lakbayromblon/core/sync/sync_controller.dart';
import 'package:lakbayromblon/features/alerts/application/alerts_controller.dart';
import 'package:lakbayromblon/features/alerts/data/alerts_service.dart';
import 'package:lakbayromblon/features/guides/presentation/photo_gallery.dart';
import 'package:lakbayromblon/features/planner/application/planner_providers.dart';
import 'package:lakbayromblon/features/reports/application/reports_controller.dart';
import 'package:lakbayromblon/features/reports/data/reports_repository.dart';

/// The real seed files from `assets/data` (tests run from the app folder).
Map<String, Object?> loadSeedFiles() => {
  for (final name in TravelData.collections)
    name: jsonDecode(File('assets/data/$name.json').readAsStringSync()),
};

TravelData seedData() => TravelData.fromCollections(loadSeedFiles());

class FileSeedSource implements SeedSource {
  FileSeedSource([Map<String, Object?>? files]) : _files = files;

  final Map<String, Object?>? _files;

  @override
  Future<Map<String, Object?>> load() async => _files ?? loadSeedFiles();
}

/// A location service that returns a fixed answer and counts requests.
class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  LocationResult result;
  int calls = 0;

  @override
  Future<LocationResult> current() async {
    calls++;
    return result;
  }
}

/// Records numbers instead of opening the phone dialer.
class FakeDialer {
  final dialed = <String>[];
  bool succeed = true;

  Future<bool> call(String number) async {
    dialed.add(number);
    return succeed;
  }
}

/// Seed data with extra collection items, e.g. advisories or guide photos.
TravelData seedDataWith(
  Map<String, List<Json>> extra, {
  Json Function(Json item)? editGuide,
}) {
  final files = loadSeedFiles();
  for (final MapEntry(:key, :value) in extra.entries) {
    final file = files[key] as Json? ?? {'items': <Object?>[]};
    files[key] = {
      'items': [...file.objects('items'), ...value],
    };
  }
  if (editGuide != null) {
    final guides = files['guides']! as Json;
    files['guides'] = {
      'items': guides.objects('items').map(editGuide).toList(),
    };
  }
  return TravelData.fromCollections(files);
}

/// Records reports instead of sending them; can act offline or over limit.
class FakeReportSender implements ReportSender {
  final sent = <CommunityReport>[];
  bool offline = false;
  bool overLimit = false;
  List<CommunityReport> remoteStatus = [];

  @override
  Future<String> send(CommunityReport report) async {
    if (offline) throw Exception('offline');
    if (overLimit) throw const ReportLimitReached();
    sent.add(report);
    return 'server-${sent.length}';
  }

  @override
  Future<List<CommunityReport>> fetchMine() async => remoteStatus;
}

/// Records topic changes instead of talking to Firebase Messaging.
class FakeAlertsService implements AlertsService {
  bool grant = true;
  final topics = <String>{};
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> subscribe(String topic) async => topics.add(topic);

  @override
  Future<void> unsubscribe(String topic) async => topics.remove(topic);

  @override
  Future<String?> initialAdvisoryId() async => null;

  @override
  Stream<String> get openedAdvisoryIds => const Stream.empty();

  @override
  Stream<void> get foregroundAlerts => const Stream.empty();
}

/// Pretends to save photos for offline use.
class FakePhotoCache implements PhotoCache {
  final saved = <String>{};

  @override
  Future<bool> isSaved(String url) async => saved.contains(url);

  @override
  Future<void> save(String url) async => saved.add(url);
}

/// Serves one batch of changes, then nothing.
class OneShotRemoteSource implements RemoteSource {
  OneShotRemoteSource(this.changes);

  RemoteChanges? changes;

  @override
  Future<RemoteChanges> changesSince(DateTime? since) async {
    final c = changes ?? const RemoteChanges();
    changes = null;
    return c;
  }
}

const odionganToCubao = TripRequest(
  direction: TripDirection.toManila,
  municipalityId: 'odiongan',
  manilaEndId: 'cubao',
);

/// Pumps the full app at [location] on a phone-sized screen with in-memory
/// repositories. Returns the container so tests can inspect state.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  String location = '/plan',
  TripRequest? request,
  MemorySavedTripsRepository? savedTrips,
  MemoryChecklistProgressRepository? progress,
  AppSettings settings = const AppSettings(languageCode: 'en'),
  LocationService? locationService,
  FakeDialer? dialer,
  TravelData? data,
  DateTime? now,
  ReportStore? reportStore,
  ReportSender? reportSender,
  AlertsService? alertsService,
  AlertPrefsRepository? alertPrefs,
  PhotoCache? photoCache,
  bool onMobileData = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      initialTravelDataProvider.overrideWithValue(data ?? seedData()),
      appRouterProvider.overrideWithValue(
        buildRouter(initialLocation: location),
      ),
      savedTripsRepositoryProvider.overrideWithValue(
        savedTrips ?? MemorySavedTripsRepository(),
      ),
      checklistProgressRepositoryProvider.overrideWithValue(
        progress ?? MemoryChecklistProgressRepository(),
      ),
      settingsRepositoryProvider.overrideWithValue(MemorySettingsRepository()),
      clockProvider.overrideWithValue(() => now ?? DateTime(2026, 10, 25, 9)),
      initialSettingsProvider.overrideWithValue(settings),
      // Never hit OpenStreetMap, the GPS or the dialer from tests.
      mapTilesEnabledProvider.overrideWithValue(false),
      locationServiceProvider.overrideWithValue(
        locationService ?? FakeLocationService(const LocationDenied()),
      ),
      dialerProvider.overrideWithValue((dialer ?? FakeDialer()).call),
      urlOpenerProvider.overrideWithValue((_) async => true),
      networkImagesEnabledProvider.overrideWithValue(false),
      photoCacheProvider.overrideWithValue(photoCache ?? FakePhotoCache()),
      onMobileDataProvider.overrideWithValue(() async => onMobileData),
      reportStoreProvider.overrideWithValue(reportStore ?? MemoryReportStore()),
      reportSenderProvider.overrideWithValue(reportSender),
      alertsServiceProvider.overrideWithValue(alertsService),
      alertPrefsRepositoryProvider.overrideWithValue(
        alertPrefs ?? MemoryAlertPrefsRepository(),
      ),
      // No server in widget tests unless a test sets one up.
      remoteSourceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  if (request != null) {
    container.read(tripRequestProvider.notifier).set(request);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LakbayApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

String planLocation(String path, String planId) =>
    Uri(path: path, queryParameters: {'id': planId}).toString();

/// Scrolls the screen's main list until [finder] is built and visible.
/// Lists build lazily, so off-screen widgets are not found otherwise.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    // The first vertical list: tab views and chip rows scroll sideways.
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
  await tester.pumpAndSettle();
}
