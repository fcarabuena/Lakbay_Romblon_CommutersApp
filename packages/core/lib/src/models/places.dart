import '../json.dart';
import 'geo.dart';
import 'localized_text.dart';
import 'verification.dart';

enum PlaceKind { municipality, port, busTerminal, hub, custom }

/// Any node a trip can start at, pass through or end at.
abstract interface class Place {
  String get id;
  String get name;
  PlaceKind get kind;
  GeoPoint? get location;
}

/// One of Romblon's 17 municipalities (the traveller's hometown).
final class Municipality implements Place {
  const Municipality({
    required this.id,
    required this.name,
    required this.island,
    this.location,
  });

  @override
  final String id;
  @override
  final String name;
  final String island;
  @override
  final GeoPoint? location;

  @override
  PlaceKind get kind => PlaceKind.municipality;

  factory Municipality.fromJson(Json json) => Municipality(
    id: json.req<String>('id'),
    name: json.req<String>('name'),
    island: json.req<String>('island'),
    location: _location(json),
  );
}

enum PortSide { romblon, mainland }

final class Port implements Place {
  const Port({
    required this.id,
    required this.name,
    required this.side,
    required this.terminalFee,
    required this.terminalFeeVerification,
    this.municipalityId,
    this.location,
    this.facilities = const [],
  });

  @override
  final String id;
  @override
  final String name;
  final PortSide side;
  final String? municipalityId;
  @override
  final GeoPoint? location;

  /// Terminal fee per passenger, in centavos.
  final int terminalFee;
  final Verification terminalFeeVerification;
  final List<String> facilities;

  @override
  PlaceKind get kind => PlaceKind.port;

  factory Port.fromJson(Json json) => Port(
    id: json.req<String>('id'),
    name: json.req<String>('name'),
    side: PortSide.values.byName(json.req<String>('side')),
    municipalityId: json.opt<String>('municipalityId'),
    location: _location(json),
    terminalFee: pesosToCentavos(json.opt<num>('terminalFeePhp') ?? 0),
    terminalFeeVerification: Verification.fromJson(
      json.opt<Json>('terminalFeeVerification'),
    ),
    facilities: json.strings('facilities'),
  );
}

final class BusTerminal implements Place {
  const BusTerminal({
    required this.id,
    required this.name,
    this.city,
    this.portId,
    this.location,
  });

  @override
  final String id;
  @override
  final String name;
  final String? city;

  /// The sea port this terminal serves, if any.
  final String? portId;
  @override
  final GeoPoint? location;

  @override
  PlaceKind get kind => PlaceKind.busTerminal;

  factory BusTerminal.fromJson(Json json) => BusTerminal(
    id: json.req<String>('id'),
    name: json.req<String>('name'),
    city: json.opt<String>('city'),
    portId: json.opt<String>('portId'),
    location: _location(json),
  );
}

/// A Metro Manila destination offered in the planner (Cubao, Buendia, PITX).
final class Hub implements Place {
  const Hub({
    required this.id,
    required this.name,
    required this.area,
    this.location,
    this.description,
  });

  @override
  final String id;
  @override
  final String name;
  final String area;
  @override
  final GeoPoint? location;
  final LocalizedText? description;

  @override
  PlaceKind get kind => PlaceKind.hub;

  factory Hub.fromJson(Json json) => Hub(
    id: json.req<String>('id'),
    name: json.req<String>('name'),
    area: json.req<String>('area'),
    location: _location(json),
    description: LocalizedText.maybe(json['description']),
  );
}

/// A user-entered place in Metro Manila, reached from the nearest hub.
final class CustomPlace implements Place {
  const CustomPlace({required this.name, required this.nearestHubId});

  static const placeId = 'custom';

  @override
  String get id => placeId;
  @override
  final String name;
  final String nearestHubId;

  @override
  PlaceKind get kind => PlaceKind.custom;
  @override
  GeoPoint? get location => null;
}

GeoPoint? _location(Json json) {
  final loc = json.opt<Json>('location');
  return loc == null ? null : GeoPoint.fromJson(loc);
}
