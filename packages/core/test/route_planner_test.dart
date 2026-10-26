import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final data = fixtureData();
  final planner = RoutePlanner(data);

  const toCubao = TripRequest(
    direction: TripDirection.toManila,
    municipalityId: 'town_a',
    manilaEndId: 'cubao',
  );

  List<String> legIds(TripPlan p) => p.legs.map((l) => l.id).toList();

  group('to Manila', () {
    final plans = planner.plan(toCubao);

    test('finds both sea routes door to door', () {
      expect(plans, hasLength(2));
      for (final p in plans) {
        expect(p.legs.first.fromId, 'town_a');
        expect(p.legs.last.toId, 'cubao');
        expect(p.shipLegs, isNotEmpty);
      }
    });

    test('the Batangas route has the expected legs and totals', () {
      final p = plans.firstWhere((p) => p.legs.any((l) => l.voyageId == 'v1'));
      expect(legIds(p), ['a_pa', 'v1:port_a-batangas', 'bat_walk', 'r1@cubao']);
      // ₱50 + ₱800 + ₱0 + ₱250 fares, ₱30 Port A terminal fee.
      expect(p.fare.fares, const IntRange.exact(110000));
      expect(p.fare.fees, 3000);
      expect(p.transfers, 2); // walking to the terminal is not a transfer
      expect(p.hasPlaceholders, isTrue);
    });

    test('never passes through another town', () {
      final viaTownB = planner
          .plan(toCubao)
          .where(
            (p) =>
                p.legs.any((l) => l.toId == 'town_b' || l.fromId == 'town_b'),
          );
      expect(viaTownB, isEmpty);
    });

    test('uses the cheapest fare class unless one is preferred', () {
      final v1 = plans
          .expand((p) => p.legs)
          .firstWhere((l) => l.voyageId == 'v1');
      expect(v1.fareClass, 'economy');

      final cabin = planner
          .plan(toCubao.copyWith(preferredFareClass: () => 'cabin'))
          .expand((p) => p.legs)
          .firstWhere((l) => l.voyageId == 'v1');
      expect(cabin.fareClass, 'cabin');
      expect(cabin.baseFare, const IntRange.exact(150000));
    });

    test('a different hub uses the matching drop-off', () {
      final toPitx = planner.plan(toCubao.copyWith(manilaEndId: 'pitx'));
      expect(toPitx.map(legIds), [
        ['a_pa', 'v1:port_a-batangas', 'bat_walk', 'r1@pitx'],
      ]);
    });

    test('discounts apply to the whole group', () {
      final p = planner
          .plan(
            toCubao.copyWith(
              travellers: const TravellerGroup(regular: 1, student: 1),
            ),
          )
          .firstWhere((p) => p.legs.any((l) => l.voyageId == 'v1'));
      // Regular ₱1,100 + student (₱50 + ₱640 + ₱200) = ₱1,990.
      expect(p.fare.fares, const IntRange.exact(199000));
      expect(p.fare.fees, 6000);
    });
  });

  group('balikbayan (to Romblon)', () {
    test('uses the return bus and return voyage', () {
      final plans = planner.plan(
        const TripRequest(
          direction: TripDirection.toRomblon,
          municipalityId: 'town_a',
          manilaEndId: 'cubao',
        ),
      );
      expect(plans.map(legIds), [
        ['r3@bt_batangas', 'bat_walk~r', 'v3:batangas-port_a', 'a_pa~r'],
      ]);
    });

    test('returns nothing when there is no return service', () {
      final plans = planner.plan(
        const TripRequest(
          direction: TripDirection.toRomblon,
          municipalityId: 'town_b',
          manilaEndId: 'pitx',
        ),
      );
      expect(plans, isEmpty);
    });
  });

  group('custom destination', () {
    const custom = CustomPlace(
      name: 'Tita’s house, Marikina',
      nearestHubId: 'cubao',
    );

    test('adds the traveller’s own last-leg estimate', () {
      final plans = planner.plan(
        toCubao.copyWith(
          custom: () => custom,
          customFare: () => const IntRange(10000, 15000),
          customMinutes: () => const IntRange(30, 60),
        ),
      );
      expect(plans, hasLength(2));
      final last = plans.first.legs.last;
      expect(last.kind, LegKind.custom);
      expect(last.toId, CustomPlace.placeId);
      expect(last.estimateMissing, isFalse);
      expect(plans.first.hasMissingEstimates, isFalse);
    });

    test('flags a missing estimate instead of guessing', () {
      final plans = planner.plan(toCubao.copyWith(custom: () => custom));
      expect(plans.first.legs.last.estimateMissing, isTrue);
      expect(plans.first.hasMissingEstimates, isTrue);
    });
  });

  group('trip request JSON', () {
    test('round-trips', () {
      final request = toCubao.copyWith(
        custom: () => const CustomPlace(name: 'Office', nearestHubId: 'pitx'),
        customFare: () => const IntRange(5000, 8000),
        departure: () => monday(6),
        travellers: const TravellerGroup(regular: 2, senior: 1),
        preferredFareClass: () => 'cabin',
      );
      final copy = TripRequest.fromJson(request.toJson());
      expect(copy.toJson(), request.toJson());
    });
  });
}
