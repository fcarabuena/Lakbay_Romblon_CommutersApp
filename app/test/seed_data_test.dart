import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'helpers.dart';

void main() {
  final data = seedData();

  test('seed data has no broken references', () {
    expect(validateTravelData(data), isEmpty);
  });

  test('covers all 17 municipalities of Romblon', () {
    expect(data.municipalities, hasLength(17));
    expect(data.municipalities.map((m) => m.id).toSet(), hasLength(17));
  });

  test('only Starhorse values are verified; everything else is a placeholder', () {
    // Starhorse fares and Lucena departures were checked against the
    // operator's own posters (see docs/data-to-verify.md). Starlite values come
    // from a ticket agent and stay unverified until checked.
    final starhorseVoyages = {
      for (final v in data.voyages)
        if (v.lineId == 'starhorse') v.id,
    };
    final verified = [
      for (final v in data.voyages)
        if (!v.verification.isPlaceholder) v.id,
      for (final f in data.shipFares)
        if (!f.verification.isPlaceholder) f.voyageId,
    ];
    expect(verified, isNotEmpty);
    expect(verified.every(starhorseVoyages.contains), isTrue);
    final others = [
      ...data.busRoutes.map((r) => r.verification),
      ...data.localRides.map((r) => r.verification),
      ...data.ports.map((p) => p.terminalFeeVerification),
      for (final f in data.shipFares)
        if (!starhorseVoyages.contains(f.voyageId)) f.verification,
    ];
    expect(
      others.every((v) => v.isPlaceholder && v.lastVerified == null),
      isTrue,
    );
    expect(data.meta.isPlaceholderData, isTrue);
    expect(
      {
        for (final l in data.shippingLines)
          if (!l.isPlaceholder) l.id,
      },
      {'starhorse', 'starlite'},
    );
    expect(
      data.shippingLines
          .where((l) => l.isPlaceholder)
          .every((l) => l.name.startsWith('Sample')),
      isTrue,
    );
    expect(data.busOperators.every((o) => o.name.startsWith('Sample')), isTrue);
  });

  test('times that are not on the posters are left empty, not guessed', () {
    for (final v in data.voyages.where((v) => v.lineId == 'starhorse')) {
      expect(v.timesToConfirm, isTrue, reason: v.id);
      expect(
        v.stops.skip(1).every((s) => s.arrive == null),
        isTrue,
        reason: v.id,
      );
      expect(v.note?.en, 'Schedule subject to change without prior notice.');
    }
    for (final v in data.voyages.where((v) => v.lineId == 'starlite')) {
      expect(
        v.stops.last.estimated,
        isTrue,
        reason: '${v.id} arrival is an estimate',
      );
    }
    final comfort = data.shipFares.singleWhere(
      (f) =>
          f.voyageId == 'sh_vdp12_lucena_sibuyan' && f.fareClass == 'comfort',
    );
    expect(comfort.verification.isPlaceholder, isFalse);
    expect(
      comfort.pricesVerification!.isPlaceholder,
      isTrue,
      reason: 'poster may have a typo',
    );
  });

  test('every town has a plan to and from every Manila hub', () {
    final planner = RoutePlanner(data);
    final missing = <String>[];
    for (final town in data.municipalities) {
      for (final hub in data.hubs) {
        for (final direction in TripDirection.values) {
          final plans = planner.plan(
            TripRequest(
              direction: direction,
              municipalityId: town.id,
              manilaEndId: hub.id,
            ),
          );
          if (plans.isEmpty) {
            missing.add('${town.id} ${direction.name} ${hub.id}');
          }
        }
      }
    }
    expect(missing, isEmpty);
  });

  test(
    'every port and bus terminal has a guide with an illustrative layout',
    () {
      // Ports added with the Starhorse and Starlite data have no guide yet.
      const noGuideYet = {
        'banton_port',
        'simara_port',
        'cajidiocan_port',
        'sibuyan_tbc_port',
      };
      final guided = {for (final g in data.guides) g.placeId};
      expect(
        guided,
        containsAll([
          ...data.ports
              .map((p) => p.id)
              .where((id) => !noGuideYet.contains(id)),
          ...data.busTerminals.map((t) => t.id),
        ]),
      );
      for (final g in data.guides) {
        expect(g.layout, isNotNull, reason: g.id);
        expect(
          g.layout!.isIllustrative,
          isTrue,
          reason: '${g.id} is a placeholder drawing',
        );
        expect(g.photos, isEmpty, reason: 'no invented photos');
        expect(g.tips, isNotEmpty, reason: g.id);
      }
    },
  );

  test('only 911 has a number, and every hotline awaits verification', () {
    expect(data.hotlines.where((h) => h.hasNumber).map((h) => h.numbers), [
      ['911'],
    ]);
    expect(data.hotlines.every((h) => h.verification.isPlaceholder), isTrue);
    for (final town in data.municipalities) {
      final ids = data.hotlines
          .where((h) => h.municipalityId == town.id)
          .map((h) => h.id);
      expect(ids, containsAll(['${town.id}_mdrrmo', '${town.id}_police']));
    }
    for (final port in data.ports.where((p) => p.id != 'sibuyan_tbc_port')) {
      expect(
        data.hotlines.where((h) => h.portId == port.id),
        hasLength(2),
        reason: port.id,
      );
    }
  });

  test('safety tips cover every category', () {
    expect(
      data.safetyTips.map((t) => t.category).toSet(),
      TipCategory.values.toSet(),
    );
  });

  test('content has Tagalog alongside English', () {
    final texts = [
      for (final c in data.checklists)
        for (final p in c.phases) ...[
          p.title,
          p.whatHappensNext,
          for (final i in p.items) i.text,
        ],
      for (final g in data.guides) ...[
        ...g.tips,
        for (final a in g.layout!.areas) a.label,
      ],
      for (final t in data.safetyTips) ...[t.title, t.body],
      for (final h in data.hotlines) h.label,
    ];
    final missing = texts.where((t) => !t.has('fil')).map((t) => t.en).toList();
    expect(missing, isEmpty);
  });
}
