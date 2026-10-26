import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

Json advisoryJson({
  String id = 'a1',
  String severity = 'suspended',
  String validFrom = '2027-10-25T06:00:00+08:00',
  String? validUntil,
  List<String> ports = const [],
  List<String> voyages = const [],
}) => {
  'id': id,
  'type': 'coastGuard',
  'severity': severity,
  'title': {'en': 'Trips suspended', 'fil': 'Suspendido ang biyahe'},
  'message': {'en': 'No sailing due to rough seas.'},
  'validFrom': validFrom,
  'validUntil': validUntil,
  'source': 'Test source',
  'affectedPortIds': ports,
  'affectedVoyageIds': voyages,
};

TravelData withAdvisories(List<Json> advisories) => TravelData.fromCollections({
  ...fixtureCollections(),
  'advisories': {'items': advisories},
});

void main() {
  group('Advisory active window', () {
    final a = Advisory.fromJson(
      advisoryJson(validUntil: '2027-10-26T06:00:00+08:00'),
    );

    test('is active from the start up to (not including) the end', () {
      // 06:00 +08:00 is 22:00 UTC the day before.
      expect(a.isActiveAt(DateTime.utc(2027, 10, 24, 21, 59)), isFalse);
      expect(a.isActiveAt(DateTime.utc(2027, 10, 24, 22)), isTrue);
      expect(a.isActiveAt(DateTime.utc(2027, 10, 25, 21, 59)), isTrue);
      expect(a.isActiveAt(DateTime.utc(2027, 10, 25, 22)), isFalse);
      expect(a.hasEndedAt(DateTime.utc(2027, 10, 25, 22)), isTrue);
    });

    test('an open-ended advisory never ends', () {
      final open = Advisory.fromJson(advisoryJson());
      expect(open.isActiveAt(DateTime.utc(2030)), isTrue);
      expect(open.hasEndedAt(DateTime.utc(2030)), isFalse);
    });

    test('sorting puts active and severe first, ended last', () {
      final now = DateTime.utc(2027, 10, 25, 12);
      final list = sortAdvisories([
        Advisory.fromJson(
          advisoryJson(
            id: 'ended',
            validFrom: '2027-10-20T00:00:00Z',
            validUntil: '2027-10-21T00:00:00Z',
          ),
        ),
        Advisory.fromJson(advisoryJson(id: 'info', severity: 'info')),
        Advisory.fromJson(
          advisoryJson(id: 'future', validFrom: '2027-11-01T00:00:00Z'),
        ),
        Advisory.fromJson(advisoryJson(id: 'suspended')),
      ], now);
      expect(list.map((a) => a.id), ['suspended', 'info', 'future', 'ended']);
    });
  });

  group('advisories and the planner', () {
    const toCubao = TripRequest(
      direction: TripDirection.toManila,
      municipalityId: 'town_a',
      manilaEndId: 'cubao',
    );
    final now = DateTime.utc(2027, 10, 25, 12);

    test('a voyage advisory flags only plans on that voyage', () {
      final data = withAdvisories([
        advisoryJson(voyages: ['v1']),
      ]);
      final plans = RoutePlanner(data).plan(toCubao);
      final flagged = {
        for (final p in plans)
          p.shipLegs.first.voyageId: advisoriesForPlan(p, data, now).length,
      };
      expect(flagged, {'v1': 1, 'v2': 0});
    });

    test('a port advisory flags plans passing that port', () {
      final data = withAdvisories([
        advisoryJson(ports: ['lucena']),
      ]);
      final plans = RoutePlanner(data).plan(toCubao);
      final affected = plans.where(
        (p) => advisoriesForPlan(p, data, now).isNotEmpty,
      );
      expect(affected.single.shipLegs.single.voyageId, 'v2');
    });

    test('a province-wide advisory affects every plan', () {
      final data = withAdvisories([advisoryJson()]);
      for (final p in RoutePlanner(data).plan(toCubao)) {
        expect(advisoriesForPlan(p, data, now), hasLength(1));
      }
    });

    test('ended or not-yet-started advisories are ignored', () {
      final data = withAdvisories([
        advisoryJson(validFrom: '2027-11-01T00:00:00Z'),
      ]);
      final plan = RoutePlanner(data).plan(toCubao).first;
      expect(advisoriesForPlan(plan, data, now), isEmpty);
    });

    test('avoiding a voyage or port leaves only the other route', () {
      final data = fixtureData();
      final planner = RoutePlanner(data);
      final noV1 = planner.plan(
        toCubao,
        avoid: const PlannerAvoid(voyageIds: {'v1'}),
      );
      expect(noV1.map((p) => p.shipLegs.single.voyageId).toSet(), {'v2'});

      final noLucena = planner.plan(
        toCubao,
        avoid: const PlannerAvoid(portIds: {'lucena'}),
      );
      expect(noLucena.map((p) => p.shipLegs.single.voyageId).toSet(), {'v1'});
    });

    test('avoiding everything returns no plans', () {
      final plans = RoutePlanner(
        fixtureData(),
      ).plan(toCubao, avoid: const PlannerAvoid(voyageIds: {'v1', 'v2'}));
      expect(plans, isEmpty);
    });

    test('PlannerAvoid.from collects what advisories name', () {
      final avoid = PlannerAvoid.from([
        Advisory.fromJson(advisoryJson(voyages: ['v1'])),
        Advisory.fromJson(advisoryJson(ports: ['lucena'])),
        Advisory.fromJson(advisoryJson()),
      ]);
      expect(avoid.voyageIds, {'v1'});
      expect(avoid.portIds, {'lucena'});
    });

    test('trips are checked at their departure, or now if none or past', () {
      final later = DateTime.utc(2027, 11, 2);
      expect(
        advisoryCheckTime(toCubao.copyWith(departure: () => later), now),
        later,
      );
      expect(advisoryCheckTime(toCubao, now), now);
      expect(
        advisoryCheckTime(
          toCubao.copyWith(departure: () => DateTime.utc(2027, 10, 1)),
          now,
        ),
        now,
      );
    });
  });

  group('validation', () {
    test('accepts a valid advisory', () {
      final data = withAdvisories([
        advisoryJson(ports: ['port_a'], voyages: ['v1']),
      ]);
      expect(validateTravelData(data), isEmpty);
    });

    test('rejects unknown references, bad windows and missing source', () {
      final data = withAdvisories([
        {
          ...advisoryJson(ports: ['nowhere'], voyages: ['v9']),
          'source': ' ',
          'validUntil': '2027-10-01T00:00:00Z',
        },
      ]);
      final problems = validateTravelData(data).join('\n');
      expect(problems, contains('unknown port nowhere'));
      expect(problems, contains('unknown voyage v9'));
      expect(problems, contains('ends before it starts'));
      expect(problems, contains('needs a source'));
    });

    test('uploaded photos need https and a credit', () {
      final files = fixtureCollections();
      files['guides'] = {
        'items': [
          {
            'id': 'g1',
            'placeId': 'port_a',
            'photos': [
              {'url': 'http://example.com/a.jpg'},
              {'url': 'https://example.com/b.jpg', 'credit': 'Admin'},
            ],
          },
        ],
      };
      final problems = validateTravelData(TravelData.fromCollections(files));
      expect(problems, [
        'Guide g1 photo 1: url must start with https://',
        'Guide g1 photo 1: uploaded photos need a credit',
      ]);
    });
  });

  group('Verification', () {
    test('round-trips through JSON with the verifier', () {
      final v = Verification.fromJson({
        'source': 'Operator notice',
        'isPlaceholder': false,
        'lastVerified': '2026-11-20',
        'verifiedBy': 'uid1',
      });
      expect(v.verifiedBy, 'uid1');
      expect(v.toJson(), {
        'source': 'Operator notice',
        'isPlaceholder': false,
        'lastVerified': '2026-11-20',
        'verifiedBy': 'uid1',
      });
    });
  });

  group('documentId', () {
    test('uses the item id, or a ship fare key', () {
      expect(TravelData.documentId('ports', {'id': 'p1'}), 'p1');
      expect(
        TravelData.documentId('ship_fares', {
          'voyageId': 'v1',
          'fromPortId': 'a',
          'toPortId': 'b',
          'fareClass': 'economy',
        }),
        'v1:a-b:economy',
      );
    });
  });

  group('CommunityReport', () {
    CommunityReport report({String suggested = '', String note = ''}) =>
        CommunityReport(
          id: 'r1',
          kind: ReportKind.fareChange,
          targetCollection: 'ship_fares',
          targetId: 'v1:a-b:economy',
          targetLabel: 'A → B, economy',
          submittedAt: DateTime.utc(2027, 10, 25),
          suggestedValue: suggested,
          note: note,
        );

    test('needs a suggestion or a note', () {
      expect(report().problems(), isNotEmpty);
      expect(report(suggested: '₱700').problems(), isEmpty);
      expect(report(note: 'Fare went up').problems(), isEmpty);
    });

    test('enforces the length limits', () {
      expect(report(note: 'x' * (ReportLimits.maxNote + 1)).problems(), [
        'Note is longer than ${ReportLimits.maxNote} characters',
      ]);
      expect(
        report(suggested: 'x' * (ReportLimits.maxSuggested + 1)).problems(),
        hasLength(1),
      );
    });

    test('round-trips through JSON', () {
      final r = report(note: 'n').copyWith(
        status: ReportStatus.rejected,
        rejectReason: () => 'Duplicate',
        reviewedAt: () => DateTime.utc(2027, 10, 26),
      );
      final back = CommunityReport.fromJson(r.toJson());
      expect(back.toJson(), r.toJson());
      expect(back.status, ReportStatus.rejected);
    });

    test('submission JSON carries no review fields', () {
      final json = report(note: 'n').toSubmissionJson();
      expect(json['status'], 'pending');
      expect(json.containsKey('rejectReason'), isFalse);
      expect(json.containsKey('submittedAt'), isFalse);
    });

    test('document ids use the UTC day and a slot', () {
      // 25 Oct 2027 07:00 in Manila is still 24 Oct in UTC.
      final manilaMorning = DateTime.utc(2027, 10, 24, 23);
      final day = DateTime.utc(
        2027,
        10,
        24,
      ).difference(DateTime.utc(1970)).inDays;
      expect(utcDayNumber(manilaMorning), day);
      expect(utcDayNumber(DateTime.utc(2027, 10, 24, 0, 1)), day);
      expect(reportDocumentId('u1', manilaMorning, 3), 'u1_${day}_3');
    });
  });

  group('alert topics', () {
    test('all of Romblon is a single topic per language', () {
      expect(
        alertTopics(allPorts: true, portIds: {'p1'}, languageCode: 'fil'),
        {'adv_all_fil'},
      );
    });

    test('ports add the general topic; other languages use English', () {
      expect(
        alertTopics(
          allPorts: false,
          portIds: {'p1', 'a b'},
          languageCode: 'bno',
        ),
        {'adv_general_en', 'adv_port_p1_en', 'adv_port_a-b_en'},
      );
    });

    test('no ports chosen means no topics', () {
      expect(
        alertTopics(allPorts: false, portIds: {}, languageCode: 'en'),
        isEmpty,
      );
    });
  });

  group('problemsIntroduced', () {
    test('reports only new problems', () {
      final before = fixtureCollections();
      final after = fixtureCollections();
      (after['ship_fares']! as Json).objects('items').first['farePhp'] = -5;
      expect(
        problemsIntroduced(before, after).single,
        contains('fare must be positive'),
      );
      expect(problemsIntroduced(after, after), isEmpty);
    });

    test('unreadable data is a problem', () {
      final after = fixtureCollections();
      (after['voyages']! as Json).objects('items').first['daysOfWeek'] =
          'daily';
      expect(
        problemsIntroduced(fixtureCollections(), after).single,
        startsWith('The data could not be read'),
      );
    });
  });
}
