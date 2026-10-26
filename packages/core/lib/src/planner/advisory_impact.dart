import '../models/advisory.dart';
import '../models/travel_data.dart';
import 'leg.dart';
import 'trip.dart';

/// Voyages and ports the planner must not use, e.g. those under an advisory.
final class PlannerAvoid {
  const PlannerAvoid({this.voyageIds = const {}, this.portIds = const {}});

  static const none = PlannerAvoid();

  /// Everything the [advisories] name. Province-wide advisories name nothing,
  /// so they cannot be avoided (every sea trip is affected).
  factory PlannerAvoid.from(Iterable<Advisory> advisories) => PlannerAvoid(
    voyageIds: {for (final a in advisories) ...a.affectedVoyageIds},
    portIds: {for (final a in advisories) ...a.affectedPortIds},
  );

  final Set<String> voyageIds;
  final Set<String> portIds;

  bool get isEmpty => voyageIds.isEmpty && portIds.isEmpty;

  bool blocks(Leg leg) =>
      (leg.voyageId != null && voyageIds.contains(leg.voyageId)) ||
      portIds.contains(leg.fromId) ||
      portIds.contains(leg.toId);
}

/// Whether [advisory] touches [plan]: it names one of the plan's voyages or
/// a port the plan passes through, or it is province-wide.
bool advisoryAffectsPlan(Advisory advisory, TripPlan plan) {
  final shipLegs = plan.shipLegs.toList();
  if (shipLegs.isEmpty) return false;
  if (advisory.isProvinceWide) return true;

  final ports = advisory.affectedPortIds.toSet();
  for (final leg in plan.legs) {
    if (ports.contains(leg.fromId) || ports.contains(leg.toId)) return true;
  }
  return shipLegs.any((l) => advisory.affectedVoyageIds.contains(l.voyageId));
}

/// Advisories active at [at] that affect [plan], most severe first.
List<Advisory> advisoriesForPlan(TripPlan plan, TravelData data, DateTime at) =>
    [
      for (final a in sortAdvisories(data.advisories, at))
        if (a.isActiveAt(at) && advisoryAffectsPlan(a, plan)) a,
    ];

/// The moment to judge a trip's advisories at: its departure when known,
/// otherwise now.
DateTime advisoryCheckTime(TripRequest request, DateTime now) {
  final departure = request.departure;
  return departure == null || departure.isBefore(now) ? now : departure;
}
