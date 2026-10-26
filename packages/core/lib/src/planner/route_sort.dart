import 'trip.dart';

enum RouteSort { cheapest, fastest, fewestTransfers }

/// Sorts plans using the upper end of each estimate (the safer number to
/// plan around), with deterministic tie-breaks ending in the plan id.
List<TripPlan> sortPlans(Iterable<TripPlan> plans, RouteSort sort) {
  int byFare(TripPlan a, TripPlan b) {
    final c = a.fare.total.max.compareTo(b.fare.total.max);
    return c != 0 ? c : a.fare.total.min.compareTo(b.fare.total.min);
  }

  int byTime(TripPlan a, TripPlan b) {
    final c = a.time.total.max.compareTo(b.time.total.max);
    return c != 0 ? c : a.time.total.min.compareTo(b.time.total.min);
  }

  int byTransfers(TripPlan a, TripPlan b) => a.transfers.compareTo(b.transfers);

  final order = switch (sort) {
    RouteSort.cheapest => [byFare, byTime, byTransfers],
    RouteSort.fastest => [byTime, byFare, byTransfers],
    RouteSort.fewestTransfers => [byTransfers, byFare, byTime],
  };

  return plans.toList()..sort((a, b) {
    for (final compare in order) {
      final c = compare(a, b);
      if (c != 0) return c;
    }
    return a.id.compareTo(b.id);
  });
}
