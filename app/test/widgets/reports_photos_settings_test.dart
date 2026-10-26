import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';
import 'package:lakbayromblon/core/settings_controller.dart';
import 'package:lakbayromblon/features/alerts/application/alerts_controller.dart';
import 'package:lakbayromblon/features/alerts/data/alerts_service.dart';
import 'package:lakbayromblon/features/reports/data/reports_repository.dart';

import '../helpers.dart';

void main() {
  final voyage = seedData().voyages.first;

  Future<void> openReportForm(WidgetTester tester) async {
    final button = find.byKey(Key('report-voyages-${voyage.id}'));
    await scrollTo(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSend(
    WidgetTester tester, {
    String note = 'Leaves 30 min later now',
  }) async {
    await tester.enterText(find.byKey(const Key('reportNote')), note);
    await scrollTo(tester, find.byKey(const Key('reportSubmit')));
    await tester.tap(find.byKey(const Key('reportSubmit')));
    await tester.pumpAndSettle();
  }

  group('Reports', () {
    testWidgets('a report from a voyage is sent for review', (tester) async {
      final sender = FakeReportSender();
      final store = MemoryReportStore();
      await pumpApp(
        tester,
        location: '/schedules/voyage/${voyage.id}',
        reportSender: sender,
        reportStore: store,
      );
      await openReportForm(tester);
      expect(find.text('Report an update'), findsWidgets);
      // A voyage defaults to "Schedule changed".
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('reportKind-scheduleChange')),
      );
      expect(chip.selected, isTrue);

      await fillAndSend(tester);
      expect(
        find.text('Thank you! Your report was sent for review.'),
        findsOneWidget,
      );
      final sent = sender.sent.single;
      expect(sent.targetCollection, 'voyages');
      expect(sent.targetId, voyage.id);
      expect(sent.kind, ReportKind.scheduleChange);
      expect(sent.note, 'Leaves 30 min later now');
      expect((await store.sent()).single.id, 'server-1');
    });

    testWidgets('an empty report is not sent', (tester) async {
      final sender = FakeReportSender();
      await pumpApp(tester, location: '/report', reportSender: sender);
      await scrollTo(tester, find.byKey(const Key('reportSubmit')));
      await tester.tap(find.byKey(const Key('reportSubmit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Add the correct value or some details.'),
        findsOneWidget,
      );
      expect(sender.sent, isEmpty);
    });

    testWidgets('offline reports wait in the outbox and send later', (
      tester,
    ) async {
      final sender = FakeReportSender()..offline = true;
      final store = MemoryReportStore();
      await pumpApp(
        tester,
        location: '/schedules/voyage/${voyage.id}',
        reportSender: sender,
        reportStore: store,
      );
      await openReportForm(tester);
      await fillAndSend(tester);
      expect(
        find.text('Saved. It will be sent when you are online.'),
        findsOneWidget,
      );
      expect(await store.outbox(), hasLength(1));

      // Back online: opening My reports sends it.
      sender.offline = false;
      await pumpApp(
        tester,
        location: '/more/reports',
        reportSender: sender,
        reportStore: store,
      );
      expect(await store.outbox(), isEmpty);
      expect(sender.sent, hasLength(1));
      expect(find.text('Sent, waiting for review'), findsOneWidget);
    });

    testWidgets('without Firebase, reports stay queued', (tester) async {
      final store = MemoryReportStore();
      await pumpApp(tester, location: '/report', reportStore: store);
      await fillAndSend(tester);
      expect(
        find.text('Saved. It will be sent when you are online.'),
        findsOneWidget,
      );
      expect(await store.outbox(), hasLength(1));
    });

    testWidgets('the daily limit keeps the report for tomorrow', (
      tester,
    ) async {
      final sender = FakeReportSender()..overLimit = true;
      await pumpApp(tester, location: '/report', reportSender: sender);
      await fillAndSend(tester);
      expect(find.textContaining('most reports allowed today'), findsOneWidget);
    });

    testWidgets('My reports shows review results', (tester) async {
      final store = MemoryReportStore();
      final submitted = CommunityReport(
        id: 'server-1',
        kind: ReportKind.fareChange,
        targetCollection: 'ship_fares',
        targetId: 'x',
        targetLabel: 'Odiongan → Batangas, economy',
        submittedAt: DateTime.utc(2026, 10, 24),
        suggestedValue: '₱720',
      );
      await store.enqueue(submitted.copyWith(id: 'local-1'));
      await store.markSent('local-1', submitted);
      final sender = FakeReportSender()
        ..remoteStatus = [
          submitted.copyWith(
            status: ReportStatus.rejected,
            rejectReason: () => 'Fare confirmed unchanged',
          ),
        ];
      await pumpApp(
        tester,
        location: '/more/reports',
        reportSender: sender,
        reportStore: store,
      );
      expect(find.text('Odiongan → Batangas, economy'), findsOneWidget);
      expect(find.text('Not used'), findsOneWidget);
      expect(find.text('Reason: Fare confirmed unchanged'), findsOneWidget);
    });
  });

  group('Photos', () {
    Json withPhotos(Json guide) => guide['placeId'] == 'odiongan_port'
        ? {
            ...guide,
            'photos': [
              {
                'url': 'https://example.com/odiongan-ticketing.jpg',
                'caption': {'en': 'Ticket windows', 'fil': 'Bilihan ng tiket'},
                'credit': 'Lakbay Romblon team',
              },
            ],
          }
        : guide;

    Future<void> openTips(WidgetTester tester) async {
      await tester.tap(find.text('Tips'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const Key('savePhotos')));
    }

    testWidgets('shows caption and credit, and saves for offline', (
      tester,
    ) async {
      final cache = FakePhotoCache();
      await pumpApp(
        tester,
        location: '/guide/odiongan_port',
        data: seedDataWith({}, editGuide: withPhotos),
        photoCache: cache,
      );
      await openTips(tester);
      expect(find.text('Ticket windows'), findsOneWidget);
      expect(find.text('Photo: Lakbay Romblon team'), findsOneWidget);

      await tester.tap(find.byKey(const Key('savePhotos')));
      await tester.pumpAndSettle();
      expect(cache.saved, {'https://example.com/odiongan-ticketing.jpg'});
      expect(find.text('Photos saved on this phone'), findsWidgets);
    });

    testWidgets('asks before downloading on mobile data', (tester) async {
      final cache = FakePhotoCache();
      await pumpApp(
        tester,
        location: '/guide/odiongan_port',
        data: seedDataWith({}, editGuide: withPhotos),
        photoCache: cache,
        onMobileData: true,
      );
      await openTips(tester);
      await tester.tap(find.byKey(const Key('savePhotos')));
      await tester.pumpAndSettle();
      expect(find.text('Use mobile data?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cache.saved, isEmpty);

      await tester.tap(find.byKey(const Key('savePhotos')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmMobileData')));
      await tester.pumpAndSettle();
      expect(cache.saved, hasLength(1));
    });

    testWidgets('tapping a photo opens it full screen', (tester) async {
      await pumpApp(
        tester,
        location: '/guide/odiongan_port',
        data: seedDataWith({}, editGuide: withPhotos),
      );
      await openTips(tester);
      await scrollTo(tester, find.byKey(const Key('photo-0')));
      await tester.tap(find.byKey(const Key('photo-0')));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });

  group('Settings', () {
    testWidgets('shows bundled data and hides alerts without Firebase', (
      tester,
    ) async {
      await pumpApp(tester, location: '/more/settings');
      await scrollTo(tester, find.byKey(const Key('lastSync')));
      expect(
        find.text('Using the data that came with the app.'),
        findsOneWidget,
      );
      expect(
        find.text('Online updates are not set up in this version.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('alertsEnabled')), findsNothing);
    });

    testWidgets('turning alerts on subscribes to all of Romblon', (
      tester,
    ) async {
      final alerts = FakeAlertsService();
      final prefs = MemoryAlertPrefsRepository();
      await pumpApp(
        tester,
        location: '/more/settings',
        alertsService: alerts,
        alertPrefs: prefs,
      );
      await scrollTo(tester, find.byKey(const Key('alertsEnabled')));
      await tester.tap(find.byKey(const Key('alertsEnabled')));
      await tester.pumpAndSettle();
      expect(alerts.permissionRequests, 1);
      expect(alerts.topics, {'adv_all_en'});
      expect(prefs.prefs.enabled, isTrue);
      expect(prefs.prefs.subscribedTopics, {'adv_all_en'});

      // Choosing ports switches topics.
      await scrollTo(tester, find.byKey(const Key('alertsPorts')));
      await tester.tap(find.byKey(const Key('alertsPorts')));
      await tester.pumpAndSettle();
      expect(alerts.topics, contains('adv_general_en'));
      expect(alerts.topics, isNot(contains('adv_all_en')));

      // Off removes every topic.
      await scrollTo(
        tester,
        find.byKey(const Key('alertsEnabled')),
        delta: -300,
      );
      await tester.tap(find.byKey(const Key('alertsEnabled')));
      await tester.pumpAndSettle();
      expect(alerts.topics, isEmpty);
    });

    testWidgets('a refused permission leaves alerts off', (tester) async {
      final alerts = FakeAlertsService()..grant = false;
      await pumpApp(tester, location: '/more/settings', alertsService: alerts);
      await scrollTo(tester, find.byKey(const Key('alertsEnabled')));
      await tester.tap(find.byKey(const Key('alertsEnabled')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Notifications are off'), findsOneWidget);
      expect(alerts.topics, isEmpty);
    });

    testWidgets('changing language moves alerts to Tagalog topics', (
      tester,
    ) async {
      final alerts = FakeAlertsService();
      final container = await pumpApp(
        tester,
        location: '/more/settings',
        alertsService: alerts,
      );
      await container.read(alertsControllerProvider.notifier).setEnabled(true);
      expect(alerts.topics, {'adv_all_en'});
      await container.read(appSettingsProvider.notifier).setLanguage('fil');
      await tester.pumpAndSettle();
      expect(alerts.topics, {'adv_all_fil'});
    });

    test('alert prefs survive a round trip', () {
      const prefs = AlertPrefs(
        enabled: true,
        allPorts: false,
        portIds: {'b', 'a'},
        subscribedTopics: {'t'},
      );
      final back = AlertPrefs.fromJson(prefs.toJson());
      expect(back.portIds, {'a', 'b'});
      expect(back.allPorts, isFalse);
      expect(back.subscribedTopics, {'t'});
    });

    test('settings default to no language', () {
      expect(const AppSettings().languageCode, isNull);
    });
  });
}
