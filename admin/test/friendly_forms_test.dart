import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_admin/src/backend/dataset.dart';
import 'package:lakbay_admin/src/editing/collection_specs.dart';
import 'package:lakbay_admin/src/editing/edit_logic.dart';
import 'package:lakbay_admin/src/editing/field_specs.dart';
import 'package:lakbay_admin/src/editing/form_fields.dart';
import 'package:lakbay_admin/src/editing/map_picker.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:latlong2/latlong.dart';

import 'fake_backend.dart';

void main() {
  final seed = seedDataset();

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('save')));

  group('helpers', () {
    test('ids follow the existing style and stay unique', () {
      expect(slugId('Odiongan Port'), 'odiongan_port');
      expect(slugId('  Sta. Fe – Looc  '), 'sta_fe_looc');
      expect(slugId('Señora Pier'), 'senora_pier');
      expect(uniqueId('odiongan_port', ['odiongan_port']), 'odiongan_port_2');
      expect(
        uniqueId('odiongan_port', ['odiongan_port', 'odiongan_port_2']),
        'odiongan_port_3',
      );
      expect(
        suggestId(specFor('ports')!, {'name': 'Odiongan Port'}, seed),
        'odiongan_port_2',
      );
      expect(
        suggestId(specFor('ports')!, {'name': 'Calatrava Port'}, seed),
        'calatrava_port',
      );
    });

    test('times, money and hours read the way staff expect', () {
      expect(clock12('19:30'), '7:30 PM');
      expect(clock12('00:05'), '12:05 AM');
      expect(clock12('12:00'), '12:00 PM');
      expect(parsePeso('₱1,200'), 1200);
      expect(parsePeso('650.50'), 650.5);
      expect(parsePeso('abc'), isNull);
      expect(hoursAndMinutes(150), '2 h 30 min');
      expect(hoursAndMinutes(45), '45 min');
    });

    test('problems are shown with names instead of ids', () {
      final fare = seed.rows['ship_fares']!.values.first;
      final voyage = seed.rows['voyages']![fare['voyageId']]!;
      final problems = friendlyProblems([
        'Ship fare ${fare['voyageId']} ${fare['fromPortId']}-${fare['toPortId']} economy: fare must be positive',
        'Voyage ${fare['voyageId']}: first stop has no departure',
      ], seed);
      expect(
        problems[0],
        startsWith(
          'The economy fare ${placeName(seed, fare['fromPortId'])} → ',
        ),
      );
      expect(problems[0], endsWith('the fare must be more than zero'));
      expect(problems[1], contains(voyageLabel(voyage, seed)));
      expect(problems[1], contains('the first stop needs a "Leaves" time'));
    });

    test('hidden fields and empty phone boxes are not saved', () {
      final hotline = tidyForSave(specFor('hotlines')!.fields, {
        'scope': 'port',
        'portId': 'odiongan_port',
        'municipalityId': 'odiongan',
        'numbers': ['0917 123 4567', ' ', ''],
      });
      expect(hotline.containsKey('municipalityId'), isFalse);
      expect(hotline['portId'], 'odiongan_port');
      expect(hotline['numbers'], ['0917 123 4567']);

      final voyage = tidyForSave(specFor('voyages')!.fields, {
        'stops': [
          {'portId': 'a', 'arrive': '01:00', 'depart': '02:00'},
          {'portId': 'b', 'arrive': '05:00', 'depart': '06:00'},
        ],
      });
      final stops = (voyage['stops']! as List).cast<Json>();
      expect(stops.first.containsKey('arrive'), isFalse);
      expect(stops.last.containsKey('depart'), isFalse);
    });
  });

  group('port form', () {
    testWidgets(
      'a new port gets its ID from the name and a spot from the map',
      (tester) async {
        final backend = signedIn(editor);
        final search = FakePlaceSearch([
          const PlaceResult(
            'Calatrava Port, Romblon',
            LatLng(12.6182, 122.0716),
          ),
        ]);
        await pumpAdmin(
          tester,
          backend,
          location: '/data/ports/new',
          placeSearch: search,
        );

        expect(find.byKey(const Key('howTo')), findsOneWidget);
        expect(
          find.text('Latitude'),
          findsNothing,
          reason: 'raw coordinates stay under Advanced',
        );

        await tester.enterText(
          find.byKey(const ValueKey('field-name')),
          'Calatrava Port',
        );
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('choice-side-mainland')));
        await tap(
          tester,
          find.byKey(const ValueKey('check-facilities-parking')),
        );
        await tap(
          tester,
          find.byKey(const ValueKey('check-facilities-ticket_office')),
        );

        await tap(tester, find.byKey(const ValueKey('pickOnMap-location')));
        await tester.enterText(find.byKey(const Key('mapSearch')), 'Calatrava');
        await tester.tap(find.byKey(const Key('mapSearchButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mapResult-0')));
        await tester.pumpAndSettle();
        expect(find.text('Chosen spot: 12.61820, 122.07160'), findsOneWidget);
        await tester.tap(find.byKey(const Key('mapUse')));
        await tester.pumpAndSettle();
        expect(search.queries, ['Calatrava']);
        expect(
          find.textContaining('Set on the map (12.61820, 122.07160)'),
          findsOneWidget,
        );

        await save(tester);
        final write = backend.saves.single;
        expect(write.docId, 'calatrava_port');
        expect(write.after!['id'], 'calatrava_port');
        expect(write.after!['side'], 'mainland');
        // Stored in the checklist's order, with the same codes as before.
        expect(write.after!['facilities'], ['ticket_office', 'parking']);
        expect(write.after!['location'], {'lat': 12.6182, 'lng': 122.0716});
      },
    );

    testWidgets('an empty search says to drag the pin instead', (tester) async {
      await pumpAdmin(tester, signedIn(editor), location: '/data/ports/new');
      await tap(tester, find.byKey(const ValueKey('pickOnMap-location')));
      await tester.enterText(find.byKey(const Key('mapSearch')), 'Nowhere');
      await tester.tap(find.byKey(const Key('mapSearchButton')));
      await tester.pumpAndSettle();
      expect(
        find.text('Nothing found. Drag the pin to the spot instead.'),
        findsOneWidget,
      );
    });

    testWidgets('facility codes not on the list are kept', (tester) async {
      final portId = seed.rows['ports']!.keys.first;
      final port = {
        ...seed.rows['ports']![portId]!,
        'facilities': ['restroom', 'ferris_wheel'],
      };
      final backend = signedIn(
        editor,
        data: seed.withChange('ports', portId, port),
      );
      await pumpAdmin(tester, backend, location: '/data/ports/$portId');
      expect(
        find.byKey(const ValueKey('check-facilities-ferris_wheel')),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('check-facilities-food')));
      await save(tester);
      expect(backend.saves.single.after!['facilities'], [
        'restroom',
        'food',
        'ferris_wheel',
      ]);
      expect(
        backend.saves.single.after!['id'],
        portId,
        reason: 'existing ids never change',
      );
    });
  });

  group('other editors', () {
    testWidgets('a hotline shows the port picker only for "One port"', (
      tester,
    ) async {
      final backend = signedIn(editor);
      await pumpAdmin(tester, backend, location: '/data/hotlines/new');
      expect(find.byKey(const ValueKey('box-municipalityId')), findsNothing);
      expect(
        find.text('Which town?'),
        findsWidgets,
        reason: 'new hotlines default to one town',
      );
      await tap(tester, find.byKey(const ValueKey('choice-scope-port')));
      expect(find.text('Which town?'), findsNothing);
      expect(find.textContaining('Which port?'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('phone-numbers-0')),
        '12ab',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot be dialled'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('phone-numbers-0')),
        '0917 123 4567',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('addPhone-numbers')));
      await tester.enterText(
        find.byKey(const ValueKey('phone-numbers-1')),
        '(042) 555 0100',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('field-agency')),
        'PCG Odiongan',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-label-en')),
        'Coast Guard station',
      );
      await tester.pumpAndSettle();
      await save(tester);
      final after = backend.saves.single.after!;
      expect(after['id'], 'pcg_odiongan_coast_guard_station');
      expect(after['scope'], 'port');
      expect(after['numbers'], ['0917 123 4567', '(042) 555 0100']);
      expect(after.containsKey('municipalityId'), isFalse);
    });

    testWidgets(
      'voyage stops hide times that do not apply and store the day as a number',
      (tester) async {
        final voyageId = seed.rows['voyages']!.keys.first;
        final backend = signedIn(editor);
        await pumpAdmin(tester, backend, location: '/data/voyages/$voyageId');
        expect(
          find.byKey(const ValueKey('clock-stops.0.arrive')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('clock-stops.0.depart')),
          findsOneWidget,
        );
        final stops =
            (seed.rows['voyages']![voyageId]!['stops']! as List).length;
        expect(
          find.byKey(ValueKey('clock-stops.${stops - 1}.depart')),
          findsNothing,
        );
        // Times show as 12-hour clock times.
        expect(
          find.textContaining(RegExp(r'\d{1,2}:\d{2} (AM|PM)')),
          findsWidgets,
        );

        await tap(
          tester,
          find.byKey(ValueKey('choice-stops.${stops - 1}.dayOffset-2')),
        );
        await save(tester);
        final saved = (backend.saves.single.after!['stops']! as List)
            .cast<Json>();
        expect(saved.last['dayOffset'], 2);
      },
    );

    testWidgets(
      'advisories use big severity cards and an "until further notice" switch',
      (tester) async {
        final backend = signedIn(editor);
        await pumpAdmin(tester, backend, location: '/data/advisories/new');
        await tap(
          tester,
          find.byKey(const ValueKey('choice-severity-suspended')),
        );
        expect(find.textContaining('Trips are not sailing'), findsOneWidget);
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(const ValueKey('openEnded-validUntil')),
              )
              .value,
          isTrue,
        );
        await tester.enterText(
          find.byKey(const ValueKey('field-title-en')),
          'No trips today',
        );
        await tester.enterText(
          find.byKey(const ValueKey('field-message-en')),
          'Gale warning.',
        );
        await tester.enterText(
          find.byKey(const ValueKey('field-source')),
          'PCG bulletin',
        );
        await tester.pumpAndSettle();
        expect(find.text('Suspended: No trips today'), findsOneWidget);
        await save(tester);
        final after = backend.saves.single.after!;
        expect(after['id'], 'no_trips_today');
        expect(after['severity'], 'suspended');
        expect(after.containsKey('validUntil'), isFalse);
      },
    );

    testWidgets('a ship fare only offers the stops of its voyage', (
      tester,
    ) async {
      final fareId = seed.rows['ship_fares']!.keys.first;
      final fare = seed.rows['ship_fares']![fareId]!;
      final voyage = seed.rows['voyages']![fare['voyageId']]!;
      final stops = [
        for (final s in (voyage['stops']! as List).cast<Json>())
          s['portId']! as String,
      ];
      await pumpAdmin(
        tester,
        signedIn(editor),
        location: '/data/ship_fares/${Uri.encodeComponent(fareId)}',
      );
      final from = tester.widget<DropdownButtonFormField<String>>(
        find.byWidgetPredicate(
          (w) =>
              w is DropdownButtonFormField<String> &&
              '${w.key}'.contains('field-fromPortId'),
        ),
      );
      final key = '${from.key}';
      expect(
        key,
        contains('-${stops.length}'),
        reason: 'one choice per stop of the voyage',
      );
    });

    testWidgets(
      'on the free plan, photo uploads say why they are unavailable',
      (tester) async {
        final guideId = seed.rows['guides']!.keys.first;
        await pumpAdmin(
          tester,
          signedIn(editor),
          location: '/data/guides/$guideId',
        );
        await scrollTo(tester, find.byKey(const Key('photosNeedBlaze')));
        expect(find.byKey(const Key('photosNeedBlaze')), findsOneWidget);
        final button = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.text('Upload photo'),
            matching: find.byWidgetPredicate((w) => w is OutlinedButton),
          ),
        );
        expect(button.onPressed, isNull);
      },
    );
  });

  test('every collection has a how-to tip and every new item gets an ID', () {
    for (final spec in collectionSpecs) {
      expect(spec.howTo, isNotEmpty, reason: spec.collection);
      expect(
        spec.hasIdField || spec.idFromItem != null,
        isTrue,
        reason: spec.collection,
      );
    }
  });

  test('existing seed items still pass the checks unchanged', () {
    final data = Dataset(meta: seed.meta, rows: seed.rows);
    for (final spec in collectionSpecs) {
      for (final MapEntry(key: id, value: item)
          in data.rows[spec.collection]!.entries) {
        final tidy = tidyForSave(spec.fields, item);
        final check = checkEdit(
          spec: spec,
          data: data,
          existingId: id,
          draft: tidy,
        );
        expect(check.problems, isEmpty, reason: '${spec.collection}/$id');
      }
    }
  });
}
