import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';
import 'package:lakbayromblon/features/planner/application/planner_providers.dart';

import '../helpers.dart';

void main() {
  group('Planner screen', () {
    testWidgets('shows the sample-data banner and asks for a hometown', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('placeholderBanner')), findsOneWidget);

      await scrollTo(tester, find.byKey(const Key('findRoutes')));
      await tester.tap(find.byKey(const Key('findRoutes')));
      await tester.pumpAndSettle();
      await scrollTo(
        tester,
        find.text('Please pick your hometown.'),
        delta: -300,
      );
      expect(find.text('Please pick your hometown.'), findsOneWidget);
    });

    testWidgets('finds routes for a hometown', (tester) async {
      final container = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('hometown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odiongan (Tablas)').last);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('findRoutes')));
      await tester.tap(find.byKey(const Key('findRoutes')));
      await tester.pumpAndSettle();

      expect(find.text('Routes'), findsOneWidget);
      final request = container.read(tripRequestProvider)!;
      expect(request.municipalityId, 'odiongan');
      expect(request.manilaEndId, 'cubao');
      expect(container.read(planResultsProvider), isNotEmpty);
      expect(find.byType(Card), findsWidgets);
    });
  });

  group('Results screen', () {
    testWidgets('sort chips reorder the plans', (tester) async {
      // Find a trip in the seed where the cheapest and fastest routes differ.
      final planner = RoutePlanner(seedData());
      final data = seedData();
      late TripRequest request;
      late TripPlan cheapest, fastest;
      search:
      for (final town in data.municipalities) {
        for (final hub in data.hubs) {
          request = TripRequest(
            direction: TripDirection.toManila,
            municipalityId: town.id,
            manilaEndId: hub.id,
          );
          cheapest = planner.plan(request, sort: RouteSort.cheapest).first;
          fastest = planner.plan(request, sort: RouteSort.fastest).first;
          if (cheapest.id != fastest.id) break search;
        }
      }
      expect(
        cheapest.id,
        isNot(fastest.id),
        reason: 'seed should offer a real trade-off',
      );
      final container = await pumpApp(
        tester,
        location: '/plan/results',
        request: request,
      );

      // Finders return widgets in tree order, so .first is the top card.
      String? firstCard() =>
          (find
                      .byWidgetPredicate(
                        (w) =>
                            w.key is ValueKey<String> &&
                            (w.key! as ValueKey<String>).value.startsWith(
                              'plan-',
                            ),
                      )
                      .evaluate()
                      .first
                      .widget
                      .key!
                  as ValueKey<String>)
              .value;

      expect(firstCard(), 'plan-${cheapest.id}');
      await tester.tap(find.byKey(const Key('sort-fastest')));
      await tester.pumpAndSettle();
      expect(container.read(planResultsProvider).first.id, fastest.id);
      expect(firstCard(), 'plan-${fastest.id}');
    });
  });

  group('Plan detail screen', () {
    testWidgets('shows totals, sample badges and saves the trip', (
      tester,
    ) async {
      final trips = MemorySavedTripsRepository();
      final plan = RoutePlanner(seedData()).plan(odionganToCubao).first;
      await pumpApp(
        tester,
        location: planLocation('/plan/detail', plan.id),
        request: odionganToCubao,
        savedTrips: trips,
      );

      expect(find.text('Trip plan'), findsOneWidget);
      expect(find.text(formatPesoRange(plan.fare.total)), findsOneWidget);
      expect(
        find.text('This estimate includes unverified sample values.'),
        findsOneWidget,
      );
      await scrollTo(tester, find.byKey(const Key('leg-0')));
      expect(find.text('Sample, not verified'), findsWidgets);

      await scrollTo(tester, find.byKey(const Key('saveTrip')));
      await tester.tap(find.byKey(const Key('saveTrip')));
      await tester.pumpAndSettle();
      expect(find.text('Trip saved to My trips.'), findsOneWidget);
      expect((await trips.all()).single.planId, plan.id);
    });

    testWidgets('explains when the route no longer exists', (tester) async {
      await pumpApp(
        tester,
        location: planLocation('/plan/detail', 'gone'),
        request: odionganToCubao,
      );
      expect(
        find.text('This route is no longer available. Please plan again.'),
        findsOneWidget,
      );
    });
  });
}
