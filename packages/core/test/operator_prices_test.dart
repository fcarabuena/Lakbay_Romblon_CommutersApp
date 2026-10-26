import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// The fixture with v1's economy fare carrying published prices, a VIP room
/// fare, and estimated arrival times.
Map<String, Object?> withOperatorPrices() {
  final files = fixtureCollections();
  final fares = (files['ship_fares']! as Json).objects('items');
  final economy = fares.firstWhere(
    (f) => f['voyageId'] == 'v1' && f['fareClass'] == 'economy',
  );
  economy['pricesPhp'] = {
    'student': 400,
    'senior': 350,
    'pwd': 350,
    'minor': 250,
    'infant': 50,
  };
  ((files['ship_fares']! as Json)['items']! as List).add(
    {...economy, 'fareClass': 'vip_room', 'farePhp': 5000, 'roomFor': 2}
      ..remove('pricesPhp'),
  );
  final v1 = (files['voyages']! as Json)
      .objects('items')
      .firstWhere((v) => v['id'] == 'v1');
  ((v1['stops']! as List).last! as Json)['estimated'] = true;
  return files;
}

void main() {
  const toCubao = TripRequest(
    direction: TripDirection.toManila,
    municipalityId: 'town_a',
    manilaEndId: 'cubao',
  );

  group('published operator prices', () {
    final data = TravelData.fromCollections(withOperatorPrices());
    final economy = data.shipFares.firstWhere(
      (f) => f.voyageId == 'v1' && f.fareClass == 'economy',
    );

    test('are read in centavos and override the discount percentages', () {
      expect(economy.priceFor(PassengerType.student), 40000);
      expect(economy.priceFor(PassengerType.senior), 35000);
      expect(economy.priceFor(PassengerType.regular), economy.amount);
      expect(economy.prices['infant'], 5000);

      final plan = RoutePlanner(data)
          .plan(
            toCubao.copyWith(
              travellers: const TravellerGroup(
                regular: 0,
                student: 1,
                senior: 1,
              ),
            ),
          )
          .firstWhere((p) => p.shipLegs.single.voyageId == 'v1');
      final index = plan.legs.indexWhere((l) => l.kind == LegKind.ship);
      expect(plan.fare.perLeg[index], const IntRange.exact(40000 + 35000));
    });

    test('a fare without published prices still uses the percentages', () {
      final plain = TravelData.fromCollections(fixtureCollections());
      final plan = RoutePlanner(plain)
          .plan(
            toCubao.copyWith(
              travellers: const TravellerGroup(regular: 0, student: 1),
            ),
          )
          .firstWhere((p) => p.shipLegs.single.voyageId == 'v1');
      final leg = plan.shipLegs.single;
      final index = plan.legs.indexOf(leg);
      expect(plan.fare.perLeg[index].min, applyDiscount(leg.baseFare.min, 20));
    });

    test('room fares are listed but never planned', () {
      final room = data.shipFares.singleWhere((f) => f.fareClass == 'vip_room');
      expect(room.isRoom, isTrue);
      final plans = RoutePlanner(
        data,
      ).plan(toCubao.copyWith(preferredFareClass: () => 'vip_room'));
      expect(
        plans.expand((p) => p.shipLegs).every((l) => l.fareClass != 'vip_room'),
        isTrue,
      );
    });

    test('estimated stop times mark the leg as an estimate', () {
      final plan = RoutePlanner(
        data,
      ).plan(toCubao).firstWhere((p) => p.shipLegs.single.voyageId == 'v1');
      expect(plan.shipLegs.single.timeEstimated, isTrue);
    });

    test('the validator checks price types and amounts', () {
      final files = withOperatorPrices();
      final fare = (files['ship_fares']! as Json).objects('items').first;
      fare['pricesPhp'] = {'student': 0, 'pensioner': 100};
      final problems = validateTravelData(
        TravelData.fromCollections(files),
      ).join('\n');
      expect(problems, contains('student price must be positive'));
      expect(problems, contains('unknown price type "pensioner"'));
    });
  });

  group('voyages with times to confirm', () {
    Map<String, Object?> withVoyage(Json voyage) {
      final files = fixtureCollections();
      ((files['voyages']! as Json)['items']! as List).add(voyage);
      return files;
    }

    final unknown = {
      'id': 'v9',
      'lineId': 'line1',
      'vesselName': 'MV Unknown',
      'daysOfWeek': <int>[],
      'stops': [
        {'portId': 'port_a'},
        {'portId': 'batangas'},
      ],
    };

    test('are rejected without the flag', () {
      final problems = validateTravelData(
        TravelData.fromCollections(withVoyage(unknown)),
      ).join('\n');
      expect(problems, contains('v9: no sailing days'));
      expect(problems, contains('v9: first stop has no departure'));
    });

    test(
      'are accepted with the flag, but still need two stops in a sane order',
      () {
        final flagged = {
          ...unknown,
          'timesToConfirm': true,
          'note': {'en': 'Schedule subject to change.'},
        };
        final data = TravelData.fromCollections(withVoyage(flagged));
        expect(validateTravelData(data), isEmpty);
        expect(data.voyage('v9')!.note!.en, 'Schedule subject to change.');

        final oneStop = {
          ...flagged,
          'stops': [
            {'portId': 'port_a'},
          ],
        };
        expect(
          validateTravelData(
            TravelData.fromCollections(withVoyage(oneStop)),
          ).join(),
          contains('needs at least 2 stops'),
        );
      },
    );

    test('are never used for segments without both times', () {
      final data = TravelData.fromCollections(
        withVoyage({...unknown, 'timesToConfirm': true}),
      );
      final plans = RoutePlanner(data).plan(toCubao);
      expect(
        plans.expand((p) => p.shipLegs).any((l) => l.voyageId == 'v9'),
        isFalse,
      );
    });
  });

  test('shipping lines keep their phones, office and links', () {
    final line = ShippingLine.fromJson({
      'id': 'x',
      'name': 'Real Line',
      'isPlaceholder': false,
      'phones': ['0995 515 9149'],
      'office': 'Lucena City',
      'website': 'https://example.com',
      'bookingUrl': 'https://example.com/book',
    });
    expect(line.phones, ['0995 515 9149']);
    expect(line.office, 'Lucena City');
    expect(line.bookingUrl, 'https://example.com/book');
    expect(line.isPlaceholder, isFalse);
  });
}
