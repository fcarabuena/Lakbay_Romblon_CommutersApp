import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final data = fixtureData();

  group('FirstTimerGuide', () {
    final plan = RoutePlanner(data)
        .plan(
          const TripRequest(
            direction: TripDirection.toManila,
            municipalityId: 'town_a',
            manilaEndId: 'cubao',
          ),
        )
        .first;
    final guide = FirstTimerGuide.build(
      data.checklistFor(TripDirection.toManila)!,
      plan,
    );

    test('places plan legs in the matching phases', () {
      List<String> idsOf(int section) =>
          guide.sections[section].entries.map((e) => e.id).toList();
      expect(idsOf(0), ['id', 'cash']);
      expect(idsOf(1), ['leg:a_pa']);
      expect(idsOf(2), ['leg:v1:port_a-batangas', 'seat']);
      expect(idsOf(3), ['leg:bat_walk', 'leg:r1@cubao']);
      expect(guide.totalCount, 7);
    });

    test('tracks progress and the current section', () {
      expect(guide.progress({}), 0);
      expect(guide.currentSection({}), 0);

      final done = {'id', 'cash', 'unrelated-id'};
      expect(guide.completedCount(done), 2);
      expect(guide.progress(done), closeTo(2 / 7, 1e-9));
      expect(guide.currentSection(done), 1);

      expect(guide.currentSection(guide.allIds.toSet()), isNull);
      expect(guide.progress(guide.allIds.toSet()), 1);
    });
  });

  group('validateTravelData', () {
    test('accepts the fixture', () {
      expect(validateTravelData(data), isEmpty);
    });

    test('reports broken references and bad values', () {
      final files = fixtureCollections();
      (files['local_rides']! as Map<String, Object?>)['items'] = [
        {
          'id': 'bad',
          'fromId': 'nowhere',
          'toId': 'port_a',
          'mode': 'walk',
          'minutes': 5,
        },
      ];
      (files['ship_fares']! as Map<String, Object?>)['items'] = [
        {
          'voyageId': 'v1',
          'fromPortId': 'batangas',
          'toPortId': 'port_a',
          'fareClass': 'economy',
          'farePhp': 800,
        },
      ];
      final problems = validateTravelData(TravelData.fromCollections(files));
      expect(problems, contains(contains('unknown from nowhere')));
      expect(problems, contains(contains('not on voyage in this order')));
    });

    test('rejects values marked verified without a date', () {
      final files = fixtureCollections();
      final voyages =
          (files['voyages']! as Map<String, Object?>)['items']!
              as List<Object?>;
      (voyages.first! as Map<String, Object?>)['verification'] = {
        'source': 'Operator',
        'isPlaceholder': false,
      };
      expect(
        validateTravelData(TravelData.fromCollections(files)),
        contains(contains('no lastVerified date')),
      );
    });

    test('names the collection when parsing fails', () {
      final files = fixtureCollections();
      (files['ports']! as Map<String, Object?>)['items'] = [
        {'id': 'p', 'name': 'P', 'side': 'romblon', 'terminalFeePhp': 'thirty'},
      ];
      expect(
        () => TravelData.fromCollections(files),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('"ports"'),
          ),
        ),
      );
    });
  });

  group('Verification', () {
    test('weakest prefers placeholders, then the oldest date', () {
      final old = Verification(
        source: 'x',
        isPlaceholder: false,
        lastVerified: DateTime(2026, 1, 1),
      );
      final recent = Verification(
        source: 'y',
        isPlaceholder: false,
        lastVerified: DateTime(2026, 9, 1),
      );
      expect(Verification.weakest([recent, old]), same(old));
      expect(
        Verification.weakest([recent, Verification.placeholder]).isPlaceholder,
        isTrue,
      );
    });

    test('is stale after 90 days', () {
      final v = Verification(
        source: 'x',
        isPlaceholder: false,
        lastVerified: DateTime(2026, 1, 1),
      );
      expect(v.isStale(DateTime(2026, 3, 1)), isFalse);
      expect(v.isStale(DateTime(2026, 6, 1)), isTrue);
    });
  });
}
