import '../json.dart';
import 'int_range.dart';
import 'localized_text.dart';
import 'verification.dart';

final class BusOperator {
  const BusOperator({
    required this.id,
    required this.name,
    required this.isPlaceholder,
    this.contact,
  });

  final String id;
  final String name;
  final String? contact;
  final bool isPlaceholder;

  factory BusOperator.fromJson(Json json) => BusOperator(
    id: json.req<String>('id'),
    name: json.req<String>('name'),
    contact: json.opt<String>('contact'),
    isPlaceholder: json.opt<bool>('isPlaceholder') ?? true,
  );
}

final class BusDropOff {
  const BusDropOff({
    required this.placeId,
    required this.fare,
    required this.minutes,
  });

  final String placeId;

  /// Regular fare from the route origin, in centavos.
  final IntRange fare;

  /// Travel time from the route origin.
  final IntRange minutes;

  factory BusDropOff.fromJson(Json json) => BusDropOff(
    placeId: json.req<String>('placeId'),
    fare: IntRange.fromJson(json['farePhp'], pesos: true),
    minutes: IntRange.fromJson(json['minutes']),
  );
}

/// A bus service leaving [originId] at regular intervals.
final class BusRoute {
  const BusRoute({
    required this.id,
    required this.operatorId,
    required this.originId,
    required this.dropOffs,
    required this.firstTrip,
    required this.lastTrip,
    required this.headwayMinutes,
    required this.verification,
    this.aircon = true,
  });

  final String id;
  final String operatorId;
  final String originId;
  final List<BusDropOff> dropOffs;

  /// First and last departures, minutes after midnight.
  final int firstTrip;
  final int lastTrip;
  final int headwayMinutes;
  final bool aircon;
  final Verification verification;

  factory BusRoute.fromJson(Json json) => BusRoute(
    id: json.req<String>('id'),
    operatorId: json.req<String>('operatorId'),
    originId: json.req<String>('originId'),
    dropOffs: json.objects('dropOffs').map(BusDropOff.fromJson).toList(),
    firstTrip: parseClock(json.req<String>('firstTrip')),
    lastTrip: parseClock(json.req<String>('lastTrip')),
    headwayMinutes: json.req<int>('headwayMinutes'),
    aircon: json.opt<bool>('aircon') ?? true,
    verification: Verification.fromJson(json.opt<Json>('verification')),
  );
}

enum RideMode {
  walk,
  tricycle,
  jeepney,
  van,
  multicab,
  habalHabal,
  pumpboat,
  taxi,
}

/// A short local trip (to the pier, between port and bus terminal, last mile).
final class LocalRide {
  const LocalRide({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.mode,
    required this.fare,
    required this.minutes,
    required this.verification,
    this.perPerson = true,
    this.bidirectional = true,
    this.note,
  });

  final String id;
  final String fromId;
  final String toId;
  final RideMode mode;

  /// Fare in centavos: per passenger when [perPerson], otherwise per trip.
  final IntRange fare;
  final IntRange minutes;
  final bool perPerson;
  final bool bidirectional;
  final LocalizedText? note;
  final Verification verification;

  factory LocalRide.fromJson(Json json) => LocalRide(
    id: json.req<String>('id'),
    fromId: json.req<String>('fromId'),
    toId: json.req<String>('toId'),
    mode: RideMode.values.byName(json.req<String>('mode')),
    fare: IntRange.fromJson(json['farePhp'] ?? 0, pesos: true),
    minutes: IntRange.fromJson(json['minutes']),
    perPerson: json.opt<bool>('perPerson') ?? true,
    bidirectional: json.opt<bool>('bidirectional') ?? true,
    note: LocalizedText.maybe(json['note']),
    verification: Verification.fromJson(json.opt<Json>('verification')),
  );
}
