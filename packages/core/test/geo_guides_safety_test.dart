import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

Map<String, Object?> _withExtras({
  List<Map<String, Object?>> guides = const [],
  List<Map<String, Object?>> hotlines = const [],
  List<Map<String, Object?>> tips = const [],
}) => fixtureCollections()
  ..['guides'] = {'items': guides}
  ..['hotlines'] = {'items': hotlines}
  ..['safety_tips'] = {'items': tips};

Map<String, Object?> _guide({
  String placeId = 'port_a',
  Map<String, Object?>? layout,
}) => {
  'id': 'g_$placeId',
  'placeId': placeId,
  'summary': {'en': 'Small pier', 'fil': 'Maliit na pantalan'},
  'tips': [
    'Buy tickets at the office',
    {'en': 'Arrive early', 'fil': 'Dumating nang maaga'},
  ],
  'layout':
      layout ??
      {
        'width': 10,
        'height': 6,
        'seaSide': 'top',
        'areas': [
          {
            'id': 'gate',
            'kind': 'gate',
            'label': 'Gate',
            'x': 0,
            'y': 0,
            'w': 4,
            'h': 2,
          },
          {
            'id': 'tix',
            'kind': 'ticketing',
            'label': 'Tickets',
            'x': 6,
            'y': 4,
            'w': 4,
            'h': 2,
          },
        ],
      },
  'pointsOfInterest': [
    {
      'id': 'p1',
      'kind': 'ticketing',
      'label': 'Ticket office',
      'location': {'lat': 12.4, 'lng': 121.98},
    },
  ],
};

void main() {
  group('GeoPoint.distanceKm', () {
    test('is zero to itself and symmetric', () {
      const a = GeoPoint(12.40, 121.98);
      const b = GeoPoint(13.75, 121.04);
      expect(a.distanceKm(a), 0);
      expect(a.distanceKm(b), closeTo(b.distanceKm(a), 1e-9));
    });

    test('matches a known distance', () {
      // One degree of latitude is about 111.2 km.
      expect(
        const GeoPoint(12, 122).distanceKm(const GeoPoint(13, 122)),
        closeTo(111.2, 0.2),
      );
    });
  });

  test('sortByDistance puts nearest first and unknown locations last', () {
    const here = GeoPoint(12.40, 121.99);
    final items = {
      'far': const GeoPoint(13.75, 121.04),
      'none': null,
      'near': const GeoPoint(12.41, 121.99),
      'none2': null,
    };
    final sorted = sortByDistance(items.keys, here, (k) => items[k]);
    expect(sorted.map((e) => e.$1), ['near', 'far', 'none', 'none2']);
    expect(sorted.first.$2, lessThan(2));
    expect(sorted.last.$2, isNull);
  });

  test('dialableNumber keeps digits and a leading plus', () {
    expect(dialableNumber('(02) 8527-3877'), '0285273877');
    expect(dialableNumber('+63 917 000 0000'), '+639170000000');
    expect(dialableNumber('911'), '911');
  });

  group('parsing', () {
    test('older data without the new collections still loads', () {
      final data = fixtureData();
      expect(data.guides, isEmpty);
      expect(data.hotlines, isEmpty);
      expect(data.safetyTips, isEmpty);
    });

    test('reads guides with layouts, tips and points of interest', () {
      final data = TravelData.fromCollections(_withExtras(guides: [_guide()]));
      final guide = data.guideFor('port_a')!;
      expect(guide.tips, hasLength(2));
      expect(guide.tips[1].resolve('fil'), 'Dumating nang maaga');
      expect(
        guide.tips[0].resolve('fil'),
        'Buy tickets at the office',
      ); // English fallback
      expect(guide.layout!.areas.map((a) => a.kind), [
        AreaKind.gate,
        AreaKind.ticketing,
      ]);
      expect(guide.layout!.isIllustrative, isTrue);
      expect(guide.layout!.hasImage, isFalse);
      expect(guide.pointsOfInterest.single.location!.lat, 12.4);
      expect(guide.verification.isPlaceholder, isTrue);
      expect(validateTravelData(data), isEmpty);
    });

    test('an uploaded image replaces the drawn layout', () {
      final data = TravelData.fromCollections(
        _withExtras(
          guides: [
            _guide(
              layout: {
                'width': 10,
                'height': 6,
                'imageUrl': 'https://example.org/pier.png',
                'isIllustrative': false,
              },
            ),
          ],
        ),
      );
      final layout = data.guideFor('port_a')!.layout!;
      expect(layout.hasImage, isTrue);
      expect(layout.areas, isEmpty);
      expect(validateTravelData(data), isEmpty);
    });

    test('reads hotlines and tips', () {
      final data = TravelData.fromCollections(
        _withExtras(
          hotlines: [
            {
              'id': 'n911',
              'agency': 'Emergency',
              'label': 'Emergency hotline',
              'scope': 'national',
              'numbers': ['911'],
            },
            {
              'id': 'mdrrmo',
              'agency': 'MDRRMO',
              'label': 'MDRRMO',
              'scope': 'municipality',
              'municipalityId': 'town_a',
              'numbers': [],
            },
          ],
          tips: [
            {
              'id': 'fixers',
              'category': 'scam',
              'title': 'Fixers',
              'body': 'Buy only at the office.',
            },
          ],
        ),
      );
      expect(data.hotlines.first.hasNumber, isTrue);
      expect(data.hotlines.last.hasNumber, isFalse);
      expect(data.hotlines.last.scope, HotlineScope.municipality);
      expect(data.safetyTips.single.category, TipCategory.scam);
      expect(validateTravelData(data), isEmpty);
    });
  });

  group('validation of new data', () {
    test('rejects areas outside the layout and unknown places', () {
      final data = TravelData.fromCollections(
        _withExtras(
          guides: [
            _guide(
              placeId: 'nowhere',
              layout: {
                'width': 10,
                'height': 6,
                'areas': [
                  {
                    'id': 'big',
                    'label': 'Too big',
                    'x': 8,
                    'y': 0,
                    'w': 5,
                    'h': 2,
                  },
                ],
              },
            ),
          ],
        ),
      );
      final problems = validateTravelData(data);
      expect(problems, contains(contains('unknown place nowhere')));
      expect(problems, contains(contains('area big lies outside the layout')));
    });

    test(
      'rejects undialable numbers and verified entries without a number',
      () {
        final data = TravelData.fromCollections(
          _withExtras(
            hotlines: [
              {
                'id': 'bad',
                'agency': 'X',
                'label': 'X',
                'scope': 'national',
                'numbers': ['call us'],
              },
              {
                'id': 'empty',
                'agency': 'Y',
                'label': 'Y',
                'scope': 'port',
                'portId': 'port_a',
                'numbers': [],
                'verification': {
                  'source': 'Office',
                  'isPlaceholder': false,
                  'lastVerified': '2026-10-01',
                },
              },
            ],
          ),
        );
        final problems = validateTravelData(data);
        expect(
          problems,
          contains(contains('Hotline bad: a number is not dialable')),
        );
        expect(
          problems,
          contains(contains('Hotline empty: verified but no number')),
        );
      },
    );
  });
}
