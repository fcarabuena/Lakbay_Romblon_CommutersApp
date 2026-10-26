import '../models/checklist.dart';
import '../models/places.dart';
import '../models/safety.dart';
import '../models/sea.dart';
import '../models/travel_data.dart';
import '../models/verification.dart';

/// Checks a dataset for broken references and impossible values.
///
/// Returns human-readable problems; an empty list means the data is usable.
/// Run on the bundled seed in tests and on admin edits before publishing.
List<String> validateTravelData(TravelData data) {
  final problems = <String>[];
  void check(bool ok, String message) {
    if (!ok) problems.add(message);
  }

  void checkVerification(Verification v, String where) {
    check(
      v.isPlaceholder || v.lastVerified != null,
      '$where is marked verified but has no lastVerified date',
    );
  }

  final ids = <String>{};
  for (final place in <Place>[
    ...data.municipalities,
    ...data.ports,
    ...data.busTerminals,
    ...data.hubs,
  ]) {
    check(ids.add(place.id), 'Duplicate place id "${place.id}"');
    check(place.id != CustomPlace.placeId, 'Place id "custom" is reserved');
  }

  bool isPlace(String id) => data.place(id) != null;
  bool isPort(String id) => data.port(id) != null;

  for (final port in data.ports) {
    final town = port.municipalityId;
    check(town == null || isPlace(town), 'Port ${port.id}: unknown town $town');
    check(port.terminalFee >= 0, 'Port ${port.id}: negative terminal fee');
    checkVerification(port.terminalFeeVerification, 'Port ${port.id} fee');
  }

  for (final terminal in data.busTerminals) {
    final port = terminal.portId;
    check(
      port == null || isPort(port),
      'Terminal ${terminal.id}: unknown port $port',
    );
  }

  final lineIds = data.shippingLines.map((l) => l.id).toSet();
  for (final v in data.voyages) {
    final where = 'Voyage ${v.id}';
    check(lineIds.contains(v.lineId), '$where: unknown line ${v.lineId}');
    check(v.stops.length >= 2, '$where: needs at least 2 stops');
    // Voyages with times still to confirm may lack days and end times.
    check(
      v.timesToConfirm || v.daysOfWeek.isNotEmpty,
      '$where: no sailing days',
    );
    check(
      v.daysOfWeek.every((d) => d >= 1 && d <= 7),
      '$where: days must be 1 (Mon) to 7 (Sun)',
    );
    for (final stop in v.stops) {
      check(isPort(stop.portId), '$where: unknown port ${stop.portId}');
    }
    if (v.stops.length >= 2 && !v.timesToConfirm) {
      check(
        v.stops.first.depart != null,
        '$where: first stop has no departure',
      );
      check(v.stops.last.arrive != null, '$where: last stop has no arrival');
    }
    var last = -1;
    for (final stop in v.stops) {
      for (final t in [stop.arriveAbs, stop.departAbs]) {
        if (t == null) continue;
        check(t >= last, '$where: times go backwards at ${stop.portId}');
        last = t;
      }
    }
    checkVerification(v.verification, where);
  }

  for (final fare in data.shipFares) {
    final where =
        'Ship fare ${fare.voyageId} ${fare.fromPortId}-${fare.toPortId} ${fare.fareClass}';
    final voyage = data.voyage(fare.voyageId);
    check(voyage != null, '$where: unknown voyage');
    check(fare.amount > 0, '$where: fare must be positive');
    for (final MapEntry(:key, :value) in fare.prices.entries) {
      check(
        FarePriceKey.all.contains(key),
        '$where: unknown price type "$key"',
      );
      check(value > 0, '$where: $key price must be positive');
    }
    check(
      fare.roomFor == null || fare.roomFor! >= 1,
      '$where: a room must be for at least 1 person',
    );
    if (fare.pricesVerification case final pv?) {
      checkVerification(pv, '$where prices');
    }
    if (voyage != null) {
      final ports = voyage.stops.map((s) => s.portId).toList();
      final from = ports.indexOf(fare.fromPortId);
      final to = ports.lastIndexOf(fare.toPortId);
      check(
        from >= 0 && to > from,
        '$where: stops not on voyage in this order',
      );
    }
    checkVerification(fare.verification, where);
  }

  final operatorIds = data.busOperators.map((o) => o.id).toSet();
  for (final r in data.busRoutes) {
    final where = 'Bus route ${r.id}';
    check(operatorIds.contains(r.operatorId), '$where: unknown operator');
    check(isPlace(r.originId), '$where: unknown origin ${r.originId}');
    check(r.dropOffs.isNotEmpty, '$where: no drop-off points');
    check(r.firstTrip <= r.lastTrip, '$where: first trip after last trip');
    check(r.headwayMinutes > 0, '$where: headway must be positive');
    for (final d in r.dropOffs) {
      check(isPlace(d.placeId), '$where: unknown drop-off ${d.placeId}');
      check(d.fare.min > 0, '$where: fare to ${d.placeId} must be positive');
      check(d.minutes.min > 0, '$where: time to ${d.placeId} must be positive');
    }
    checkVerification(r.verification, where);
  }

  for (final ride in data.localRides) {
    final where = 'Local ride ${ride.id}';
    check(isPlace(ride.fromId), '$where: unknown from ${ride.fromId}');
    check(isPlace(ride.toId), '$where: unknown to ${ride.toId}');
    check(ride.minutes.min > 0, '$where: time must be positive');
    checkVerification(ride.verification, where);
  }

  for (final direction in TripDirection.values) {
    check(
      data.checklistFor(direction) != null,
      'Missing checklist for ${direction.name}',
    );
  }
  for (final c in data.checklists) {
    final itemIds = <String>{};
    for (final item in c.phases.expand((p) => p.items)) {
      check(
        itemIds.add(item.id),
        'Checklist ${c.id}: duplicate item ${item.id}',
      );
    }
  }

  final guidePlaces = <String>{};
  for (final g in data.guides) {
    final where = 'Guide ${g.id}';
    check(isPlace(g.placeId), '$where: unknown place ${g.placeId}');
    check(guidePlaces.add(g.placeId), '$where: second guide for ${g.placeId}');
    checkVerification(g.verification, where);
    final layout = g.layout;
    if (layout != null) {
      check(layout.width > 0 && layout.height > 0, '$where: empty layout size');
      check(
        layout.hasImage || layout.areas.isNotEmpty,
        '$where: layout needs areas or an image',
      );
      final areaIds = <String>{};
      for (final a in layout.areas) {
        check(areaIds.add(a.id), '$where: duplicate area ${a.id}');
        check(
          a.width > 0 &&
              a.height > 0 &&
              a.x >= 0 &&
              a.y >= 0 &&
              a.x + a.width <= layout.width &&
              a.y + a.height <= layout.height,
          '$where: area ${a.id} lies outside the layout',
        );
      }
      checkVerification(layout.verification, '$where layout');
    }
  }

  final hotlineIds = <String>{};
  for (final h in data.hotlines) {
    final where = 'Hotline ${h.id}';
    check(hotlineIds.add(h.id), '$where: duplicate id');
    check(
      h.portId == null || isPort(h.portId!),
      '$where: unknown port ${h.portId}',
    );
    check(
      h.municipalityId == null || isPlace(h.municipalityId!),
      '$where: unknown town ${h.municipalityId}',
    );
    check(
      h.numbers.every(
        (n) => RegExp(r'^\+?[0-9]{3,15}$').hasMatch(dialableNumber(n)),
      ),
      '$where: a number is not dialable',
    );
    // A number shown as verified must actually be there.
    check(
      h.hasNumber || !h.verification.isVerified,
      '$where: verified but no number',
    );
    checkVerification(h.verification, where);
  }

  for (final g in data.guides) {
    for (final (i, p) in g.photos.indexed) {
      final where = 'Guide ${g.id} photo ${i + 1}';
      check(
        (p.url == null) != (p.asset == null),
        '$where: needs exactly one of url or asset',
      );
      check(
        p.url == null || p.url!.startsWith('https://'),
        '$where: url must start with https://',
      );
      check(
        p.url == null || (p.credit?.trim().isNotEmpty ?? false),
        '$where: uploaded photos need a credit',
      );
    }
  }

  final advisoryIds = <String>{};
  for (final a in data.advisories) {
    final where = 'Advisory ${a.id}';
    check(advisoryIds.add(a.id), '$where: duplicate id');
    check(a.source.trim().isNotEmpty, '$where: needs a source');
    check(a.title.en.trim().isNotEmpty, '$where: needs an English title');
    check(a.message.en.trim().isNotEmpty, '$where: needs an English message');
    check(
      a.validUntil == null || a.validUntil!.isAfter(a.validFrom),
      '$where: ends before it starts',
    );
    for (final id in a.affectedPortIds) {
      check(isPort(id), '$where: unknown port $id');
    }
    for (final id in a.affectedVoyageIds) {
      check(data.voyage(id) != null, '$where: unknown voyage $id');
    }
  }

  final tipIds = <String>{};
  for (final t in data.safetyTips) {
    check(tipIds.add(t.id), 'Safety tip ${t.id}: duplicate id');
  }

  return problems;
}

/// Problems an edit would add: those in [after] that [before] did not have.
///
/// Both are `{collection: {"items": [...]}}` maps as [TravelData] parses.
/// Existing problems are ignored, so a long-standing issue elsewhere never
/// blocks an unrelated fix. If [after] does not parse, that is the problem.
List<String> problemsIntroduced(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  List<String> problemsOf(Map<String, Object?> files) =>
      validateTravelData(TravelData.fromCollections(files));

  final List<String> newProblems;
  try {
    newProblems = problemsOf(after);
  } on Object catch (e) {
    return [
      'The data could not be read: ${e is FormatException ? e.message : e}',
    ];
  }
  Set<String> old;
  try {
    old = problemsOf(before).toSet();
  } on Object {
    old = {};
  }
  return [
    for (final p in newProblems)
      if (!old.contains(p)) p,
  ];
}
