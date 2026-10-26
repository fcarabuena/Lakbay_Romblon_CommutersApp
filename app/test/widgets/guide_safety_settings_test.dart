import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';
import 'package:lakbayromblon/core/providers.dart';
import 'package:lakbayromblon/core/services/device_services.dart';
import 'package:lakbayromblon/core/settings_controller.dart';

import '../helpers.dart';

void main() {
  group('Guide list', () {
    testWidgets('lists ports and terminals with guides', (tester) async {
      await pumpApp(tester, location: '/guide');
      expect(find.text('Pier and terminal guides'), findsOneWidget);
      expect(find.byKey(const Key('guide-odiongan_port')), findsOneWidget);
      await scrollTo(
        tester,
        find.byKey(const Key('guide-lucena_grand_terminal')),
      );
      expect(
        find.byKey(const Key('guide-lucena_grand_terminal')),
        findsOneWidget,
      );
    });

    testWidgets('sorts by distance after sharing location', (tester) async {
      // Standing in Odiongan town.
      final gps = FakeLocationService(
        const LocationFound(GeoPoint(12.40, 121.99)),
      );
      await pumpApp(tester, location: '/guide', locationService: gps);

      await tester.tap(find.byKey(const Key('useMyLocation')));
      await tester.pumpAndSettle();

      expect(gps.calls, 1);
      expect(find.text('Nearest'), findsOneWidget);
      expect(find.text('Your location stays on your phone.'), findsOneWidget);
      final nearestTile = find.ancestor(
        of: find.text('Nearest'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(of: nearestTile, matching: find.text('Odiongan Port')),
        findsOneWidget,
      );
      expect(find.textContaining('km away'), findsWidgets);
    });

    testWidgets('explains a refused permission and keeps working', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: '/guide',
        locationService: FakeLocationService(const LocationDenied()),
      );
      await tester.tap(find.byKey(const Key('useMyLocation')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Location permission was not given. You can still use every guide.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('guide-odiongan_port')), findsOneWidget);
    });
  });

  group('Guide detail', () {
    testWidgets('layout tab shows the illustrative plan and its areas', (
      tester,
    ) async {
      await pumpApp(tester, location: '/guide/odiongan_port');
      expect(find.text('Odiongan Port'), findsOneWidget);
      expect(find.byKey(const Key('illustrativeNotice')), findsOneWidget);
      await scrollTo(tester, find.byKey(const Key('area-tickets')));
      expect(find.text('Ticket office'), findsOneWidget);
    });

    testWidgets('map tab renders without loading real tiles', (tester) async {
      await pumpApp(tester, location: '/guide/odiongan_port');
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsNothing);
      expect(
        find.text(
          'The map needs internet. Without a connection, use the Layout tab.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tips tab shows tips and says there are no photos yet', (
      tester,
    ) async {
      await pumpApp(tester, location: '/guide/batangas_port');
      await tester.tap(find.text('Tips'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Buses to Manila leave from the bus area'),
        findsOneWidget,
      );
      await scrollTo(tester, find.text('No photos yet.'));
      expect(find.text('No photos yet.'), findsOneWidget);
    });

    testWidgets('Tagalog guide content comes from the data', (tester) async {
      await pumpApp(
        tester,
        location: '/guide/odiongan_port',
        settings: const AppSettings(languageCode: 'fil'),
      );
      await scrollTo(tester, find.byKey(const Key('area-tickets')));
      expect(find.text('Bilihan ng tiket'), findsOneWidget);
    });
  });

  group('Safety', () {
    testWidgets('the 911 button opens the dialer', (tester) async {
      final dialer = FakeDialer();
      await pumpApp(tester, location: '/safety', dialer: dialer);
      await tester.tap(find.byKey(const Key('call-911')));
      await tester.pumpAndSettle();
      expect(dialer.dialed, ['911']);
    });

    testWidgets('a failed dial shows a message', (tester) async {
      final dialer = FakeDialer()..succeed = false;
      await pumpApp(tester, location: '/safety', dialer: dialer);
      await tester.tap(find.byKey(const Key('call-911')));
      await tester.pumpAndSettle();
      expect(find.text('Could not open the phone dialer.'), findsOneWidget);
    });

    testWidgets('shows the trip summary and the hometown numbers first', (
      tester,
    ) async {
      await pumpApp(tester, location: '/safety', request: odionganToCubao);
      expect(find.byKey(const Key('sosBody')), findsOneWidget);
      expect(
        find.textContaining('I am travelling from Odiongan to Cubao'),
        findsOneWidget,
      );

      await scrollTo(tester, find.byKey(const Key('town-odiongan')));
      expect(find.text('Your hometown: Odiongan'), findsOneWidget);
      // Expanded by default; no verified number yet.
      await scrollTo(tester, find.byKey(const Key('needed-odiongan_mdrrmo')));
      expect(find.byKey(const Key('needed-odiongan_mdrrmo')), findsOneWidget);
    });

    testWidgets('scam warnings expand to show advice', (tester) async {
      await pumpApp(tester, location: '/safety');
      await scrollTo(tester, find.byKey(const Key('tip-fixers')));
      await tester.tap(find.byKey(const Key('tip-fixers')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Buy only at the official ticket office'),
        findsOneWidget,
      );
    });
  });

  group('Settings', () {
    testWidgets('switching to Tagalog changes the app and is saved', (
      tester,
    ) async {
      final container = await pumpApp(tester, location: '/more/settings');
      await tester.tap(find.byKey(const Key('lang-fil')));
      await tester.pumpAndSettle();
      expect(find.text('Wika'), findsOneWidget); // "Language"
      expect(container.read(appSettingsProvider).languageCode, 'fil');
      expect(
        (await container.read(settingsRepositoryProvider).load()).languageCode,
        'fil',
      );
    });

    testWidgets('local languages are labelled as in progress', (tester) async {
      await pumpApp(tester, location: '/more/settings');
      final asi = find.byKey(const Key('lang-bno'));
      expect(
        find.descendant(
          of: asi,
          matching: find.text('translation in progress'),
        ),
        findsOneWidget,
      );
      final tagalog = find.byKey(const Key('lang-fil'));
      expect(
        find.descendant(
          of: tagalog,
          matching: find.text('draft, needs review'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('text size scales text app-wide', (tester) async {
      await pumpApp(tester, location: '/more/settings');
      final extraLarge = find.byKey(Key('textScale-${textScaleOptions[2]}'));
      await scrollTo(tester, extraLarge);
      // Measured on the tapped button itself, which stays on screen.
      double appScale() =>
          MediaQuery.textScalerOf(tester.element(extraLarge)).scale(10) / 10;
      expect(appScale(), closeTo(1.0, 1e-6));

      await tester.tap(extraLarge);
      await tester.pumpAndSettle();
      // Bigger text above pushes the button down; bring it back into view.
      await scrollTo(tester, extraLarge);
      expect(appScale(), closeTo(1.3, 1e-6));
    });

    testWidgets('More opens My trips and Settings', (tester) async {
      await pumpApp(tester, location: '/more');
      await tester.tap(find.byKey(const Key('more-trips')));
      await tester.pumpAndSettle();
      expect(
        find.text('No saved trips yet. Plan a trip and tap Save trip.'),
        findsOneWidget,
      );
    });
  });
}
