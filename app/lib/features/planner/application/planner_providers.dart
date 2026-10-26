import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';

/// The trip the traveller last asked for (null before the first search).
class TripRequestController extends Notifier<TripRequest?> {
  @override
  TripRequest? build() => null;

  void set(TripRequest request) => state = request;
}

final tripRequestProvider =
    NotifierProvider<TripRequestController, TripRequest?>(
      TripRequestController.new,
    );

class RouteSortController extends Notifier<RouteSort> {
  @override
  RouteSort build() => RouteSort.cheapest;

  void set(RouteSort sort) => state = sort;
}

final routeSortProvider = NotifierProvider<RouteSortController, RouteSort>(
  RouteSortController.new,
);

/// Whether results leave out voyages and ports under an active advisory.
class AvoidAdvisoriesController extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(tripRequestProvider);
    return false;
  }

  void set(bool avoid) => state = avoid;
}

final avoidAdvisoriesProvider =
    NotifierProvider<AvoidAdvisoriesController, bool>(
      AvoidAdvisoriesController.new,
    );

/// When the current trip's advisories are judged (its departure, or now).
final advisoryCheckTimeProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider)();
  final request = ref.watch(tripRequestProvider);
  return request == null ? now : advisoryCheckTime(request, now);
});

/// Caution and suspension advisories in effect for the current trip.
final tripAlertAdvisoriesProvider = Provider<List<Advisory>>((ref) {
  final at = ref.watch(advisoryCheckTimeProvider);
  return [
    for (final a in ref.watch(travelDataProvider).advisories)
      if (a.severity.isAlert && a.isActiveAt(at)) a,
  ];
});

/// What results avoid when [avoidAdvisoriesProvider] is on.
final plannerAvoidProvider = Provider<PlannerAvoid>(
  (ref) => PlannerAvoid.from(ref.watch(tripAlertAdvisoriesProvider)),
);

/// Sorted plans for the current request, without avoiding anything.
final allPlanResultsProvider = Provider<List<TripPlan>>((ref) {
  final request = ref.watch(tripRequestProvider);
  if (request == null) return const [];
  return ref
      .watch(routePlannerProvider)
      .plan(request, sort: ref.watch(routeSortProvider));
});

/// The plans shown: all of them, or only those avoiding advisories.
final planResultsProvider = Provider<List<TripPlan>>((ref) {
  final all = ref.watch(allPlanResultsProvider);
  final request = ref.watch(tripRequestProvider);
  final avoid = ref.watch(plannerAvoidProvider);
  if (request == null || !ref.watch(avoidAdvisoriesProvider) || avoid.isEmpty) {
    return all;
  }
  return ref
      .watch(routePlannerProvider)
      .plan(request, sort: ref.watch(routeSortProvider), avoid: avoid);
});

/// A plan from the current results, or null if it no longer exists
/// (e.g. the data changed since the trip was saved).
final planByIdProvider = Provider.family<TripPlan?, String>((ref, id) {
  bool match(TripPlan p) => p.id == id;
  return ref.watch(planResultsProvider).where(match).firstOrNull ??
      ref.watch(allPlanResultsProvider).where(match).firstOrNull;
});

/// Active advisories affecting [plan], judged at the trip's departure.
final planAdvisoriesProvider = Provider.autoDispose
    .family<List<Advisory>, TripPlan>((ref, plan) {
      return advisoriesForPlan(
        plan,
        ref.watch(travelDataProvider),
        ref.watch(advisoryCheckTimeProvider),
      );
    });
