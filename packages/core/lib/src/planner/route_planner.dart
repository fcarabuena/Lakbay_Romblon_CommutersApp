import '../calculators/fare_calculator.dart';
import '../calculators/time_calculator.dart';
import '../models/discounts.dart';
import '../models/int_range.dart';
import '../models/places.dart';
import '../models/sea.dart';
import '../models/travel_data.dart';
import '../models/verification.dart';
import 'advisory_impact.dart';
import 'leg.dart';
import 'route_sort.dart';
import 'trip.dart';

/// Builds door-to-door plans by searching a graph of places and legs.
///
/// Nodes are places (towns, ports, terminals, hubs). Edges are local rides,
/// ship segments between any two stops of a voyage, and bus segments from a
/// route's origin to each drop-off. Voyages and bus routes are directional,
/// so the return trip uses real return services.
final class RoutePlanner {
  RoutePlanner(this.data, {this.maxLegs = 7, this.maxResults = 20})
    : _edges = _buildEdges(data);

  final TravelData data;
  final int maxLegs;
  final int maxResults;

  /// Edges without a preferred fare class, keyed by origin place id.
  final Map<String, List<_Edge>> _edges;

  List<TripPlan> plan(
    TripRequest request, {
    RouteSort sort = RouteSort.cheapest,
    PlannerAvoid avoid = PlannerAvoid.none,
  }) {
    final edges = _edgesFor(request);
    final fares = FareCalculator(data.meta.discounts);
    const times = TimeCalculator();
    final destination = request.destinationId;
    final customHub = request.custom?.nearestHubId;
    final plans = <TripPlan>[];

    bool canPassThrough(String placeId) {
      final place = data.place(placeId);
      return switch (place?.kind) {
        PlaceKind.municipality => false,
        PlaceKind.hub => placeId == customHub,
        _ => true,
      };
    }

    void search(String at, List<Leg> path, Set<String> visited) {
      if (at == destination) {
        if (path.any((l) => l.kind == LegKind.ship)) {
          plans.add(
            TripPlan(
              legs: List.unmodifiable(path),
              fare: fares.plan(path, request.travellers),
              time: times.estimate(path, departure: request.departure),
            ),
          );
        }
        return;
      }
      if (path.length >= maxLegs) return;
      if (path.isNotEmpty && !canPassThrough(at)) return;

      for (final edge in edges[at] ?? const <_Edge>[]) {
        final leg = edge.legFor(request.preferredFareClass);
        if (visited.contains(leg.toId)) continue;
        if (avoid.blocks(leg)) continue;
        if (leg.kind == LegKind.ship) {
          final ships = path.where((l) => l.kind == LegKind.ship);
          if (ships.length >= 2) continue;
          // Re-boarding the same voyage is never better than staying on it.
          if (ships.any((l) => l.voyageId == leg.voyageId)) continue;
        }
        path.add(leg);
        visited.add(leg.toId);
        search(leg.toId, path, visited);
        visited.remove(leg.toId);
        path.removeLast();
      }
    }

    search(request.originId, [], {request.originId});
    return sortPlans(plans, sort).take(maxResults).toList();
  }

  Map<String, List<_Edge>> _edgesFor(TripRequest request) {
    final custom = request.custom;
    if (custom == null) return _edges;

    Leg leg(bool outbound) => Leg(
      id: outbound ? 'custom' : 'custom~r',
      kind: LegKind.custom,
      fromId: outbound ? custom.nearestHubId : CustomPlace.placeId,
      toId: outbound ? CustomPlace.placeId : custom.nearestHubId,
      baseFare: request.customFare ?? IntRange.zero,
      perPerson: true,
      duration: request.customMinutes ?? IntRange.zero,
      verification: const Verification(
        source: 'USER_ESTIMATE',
        isPlaceholder: true,
      ),
      estimateMissing: request.customFare == null,
    );

    return {
        for (final entry in _edges.entries) entry.key: [...entry.value],
      }
      ..putIfAbsent(custom.nearestHubId, () => []).add(_Edge.single(leg(true)))
      ..putIfAbsent(
        CustomPlace.placeId,
        () => [],
      ).add(_Edge.single(leg(false)));
  }

  static Map<String, List<_Edge>> _buildEdges(TravelData data) {
    final edges = <String, List<_Edge>>{};
    void add(_Edge e) => edges.putIfAbsent(e.fromId, () => []).add(e);

    for (final ride in data.localRides) {
      Leg legOf(String id, String from, String to) => Leg(
        id: id,
        kind: LegKind.localRide,
        fromId: from,
        toId: to,
        baseFare: ride.fare,
        perPerson: ride.perPerson,
        duration: ride.minutes,
        verification: ride.verification,
        rideMode: ride.mode,
        note: ride.note,
      );
      add(_Edge.single(legOf(ride.id, ride.fromId, ride.toId)));
      if (ride.bidirectional) {
        add(_Edge.single(legOf('${ride.id}~r', ride.toId, ride.fromId)));
      }
    }

    for (final voyage in data.voyages) {
      for (var i = 0; i < voyage.stops.length; i++) {
        for (var j = i + 1; j < voyage.stops.length; j++) {
          final edge = _shipEdge(
            data,
            voyage,
            voyage.stops[i],
            voyage.stops[j],
          );
          if (edge != null) add(edge);
        }
      }
    }

    for (final route in data.busRoutes) {
      for (final drop in route.dropOffs) {
        add(
          _Edge.single(
            Leg(
              id: '${route.id}@${drop.placeId}',
              kind: LegKind.bus,
              fromId: route.originId,
              toId: drop.placeId,
              baseFare: drop.fare,
              discountable: true,
              duration: drop.minutes,
              verification: route.verification,
              busRouteId: route.id,
              schedule: FrequentDeparture(
                firstTrip: route.firstTrip,
                lastTrip: route.lastTrip,
                headwayMinutes: route.headwayMinutes,
              ),
            ),
          ),
        );
      }
    }

    for (final list in edges.values) {
      list.sort((a, b) => a.id.compareTo(b.id));
    }
    return edges;
  }

  static _Edge? _shipEdge(
    TravelData data,
    Voyage voyage,
    VoyageStop from,
    VoyageStop to,
  ) {
    final depart = from.departAbs;
    final arrive = to.arriveAbs;
    if (depart == null || arrive == null || arrive <= depart) return null;

    // Room fares (e.g. a VIP room for 2) are listed in Schedules only.
    final fares = data.shipFares
        .where(
          (f) =>
              !f.isRoom &&
              f.voyageId == voyage.id &&
              f.fromPortId == from.portId &&
              f.toPortId == to.portId,
        )
        .toList();
    if (fares.isEmpty) return null;

    final port = data.port(from.portId);
    final travel = arrive - depart;
    final legs = {
      for (final fare in fares)
        fare.fareClass: Leg(
          id: '${voyage.id}:${from.portId}-${to.portId}',
          kind: LegKind.ship,
          fromId: from.portId,
          toId: to.portId,
          baseFare: IntRange.exact(fare.amount),
          discountable: true,
          feePerPerson: port?.terminalFee ?? 0,
          feeVerification: port?.terminalFeeVerification,
          duration: IntRange(travel, travel + voyage.delayAllowanceMinutes),
          verification: Verification.weakest([
            voyage.verification,
            fare.verification,
            ?fare.pricesVerification,
          ]),
          typePrices: {
            for (final type in PassengerType.values)
              if (type != PassengerType.regular) type: ?fare.priceFor(type),
          },
          timeEstimated: from.estimated || to.estimated,
          note: voyage.note,
          voyageId: voyage.id,
          fareClass: fare.fareClass,
          schedule: FixedDeparture(
            departAbs: depart,
            daysOfWeek: voyage.daysOfWeek,
            checkInMinutes: voyage.checkInMinutes,
          ),
        ),
    };
    return _Edge(legs);
  }
}

/// A graph edge; ship edges hold one leg per fare class.
final class _Edge {
  _Edge(this.byClass) : assert(byClass.isNotEmpty);

  _Edge.single(Leg leg) : byClass = {'': leg};

  final Map<String, Leg> byClass;

  Leg get _any => byClass.values.first;
  String get id => _any.id;
  String get fromId => _any.fromId;

  /// The preferred class when offered, otherwise the cheapest one.
  Leg legFor(String? preferredClass) {
    final preferred = preferredClass == null ? null : byClass[preferredClass];
    if (preferred != null) return preferred;
    return byClass.values.reduce(
      (a, b) => b.baseFare.max < a.baseFare.max ? b : a,
    );
  }
}
