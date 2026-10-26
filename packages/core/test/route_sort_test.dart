import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// Builds a plan with given totals; [legs] non-walking rides set transfers.
TripPlan _plan(
  String id, {
  required int fare,
  required int minutes,
  int legs = 3,
}) {
  final legList = [
    for (var i = 0; i < legs; i++)
      Leg(
        id: '$id$i',
        kind: LegKind.localRide,
        fromId: 'x',
        toId: 'y',
        baseFare: IntRange.zero,
        duration: IntRange.zero,
        verification: Verification.placeholder,
      ),
  ];
  return TripPlan(
    legs: legList,
    fare: FareBreakdown(perLeg: const [], fares: IntRange.exact(fare), fees: 0),
    time: TimeEstimate(
      travel: IntRange.exact(minutes),
      waiting: IntRange.zero,
      total: IntRange.exact(minutes),
      schedulesApplied: false,
      legs: const [],
    ),
  );
}

void main() {
  final cheapSlow = _plan('a', fare: 1000, minutes: 900, legs: 4);
  final dearFast = _plan('b', fare: 2000, minutes: 600, legs: 5);
  final middleDirect = _plan('c', fare: 1500, minutes: 700, legs: 2);

  List<String> ids(List<TripPlan> plans) => plans.map((p) => p.id).toList();
  final all = [dearFast, middleDirect, cheapSlow];

  test('cheapest first', () {
    expect(ids(sortPlans(all, RouteSort.cheapest)), [
      cheapSlow.id,
      middleDirect.id,
      dearFast.id,
    ]);
  });

  test('fastest first', () {
    expect(ids(sortPlans(all, RouteSort.fastest)), [
      dearFast.id,
      middleDirect.id,
      cheapSlow.id,
    ]);
  });

  test('fewest transfers first', () {
    expect(ids(sortPlans(all, RouteSort.fewestTransfers)), [
      middleDirect.id,
      cheapSlow.id,
      dearFast.id,
    ]);
  });

  test('ties fall back to the next criterion, then the id', () {
    final x = _plan('x', fare: 1000, minutes: 800);
    final y = _plan('y', fare: 1000, minutes: 700);
    final z = _plan('z', fare: 1000, minutes: 700);
    expect(ids(sortPlans([x, z, y], RouteSort.cheapest)), [y.id, z.id, x.id]);
  });

  test('does not modify the input list', () {
    final input = [dearFast, cheapSlow];
    sortPlans(input, RouteSort.cheapest);
    expect(input, [dearFast, cheapSlow]);
  });

  test('on real plans, cheapest and fastest differ', () {
    final planner = RoutePlanner(fixtureData());
    const request = TripRequest(
      direction: TripDirection.toManila,
      municipalityId: 'town_a',
      manilaEndId: 'cubao',
    );
    final cheapest = planner.plan(request, sort: RouteSort.cheapest).first;
    final fastest = planner.plan(request, sort: RouteSort.fastest).first;
    final fewest = planner.plan(request, sort: RouteSort.fewestTransfers).first;
    expect(cheapest.legs.any((l) => l.voyageId == 'v1'), isTrue);
    expect(fastest.legs.any((l) => l.voyageId == 'v2'), isTrue);
    expect(fewest.id, cheapest.id);
  });
}
