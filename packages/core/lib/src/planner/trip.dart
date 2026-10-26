import '../calculators/fare_calculator.dart';
import '../calculators/time_calculator.dart';
import '../json.dart';
import '../models/checklist.dart';
import '../models/discounts.dart';
import '../models/int_range.dart';
import '../models/places.dart';
import '../models/verification.dart';
import 'leg.dart';

/// What the traveller asked for.
final class TripRequest {
  const TripRequest({
    required this.direction,
    required this.municipalityId,
    required this.manilaEndId,
    this.custom,
    this.customFare,
    this.customMinutes,
    this.departure,
    this.travellers = const TravellerGroup(),
    this.preferredFareClass,
  });

  final TripDirection direction;
  final String municipalityId;

  /// The Metro Manila hub (Cubao, Buendia, PITX). When [custom] is set this is
  /// ignored and [CustomPlace.nearestHubId] is used instead.
  final String manilaEndId;
  final CustomPlace? custom;

  /// The traveller's own estimate for the hub ↔ custom place leg.
  final IntRange? customFare;
  final IntRange? customMinutes;

  /// When the traveller leaves. Without it, schedule waits are not included.
  final DateTime? departure;
  final TravellerGroup travellers;
  final String? preferredFareClass;

  String get manilaPlaceId =>
      custom == null ? manilaEndId : CustomPlace.placeId;

  String get originId =>
      direction == TripDirection.toManila ? municipalityId : manilaPlaceId;

  String get destinationId =>
      direction == TripDirection.toManila ? manilaPlaceId : municipalityId;

  TripRequest copyWith({
    TripDirection? direction,
    String? municipalityId,
    String? manilaEndId,
    CustomPlace? Function()? custom,
    IntRange? Function()? customFare,
    IntRange? Function()? customMinutes,
    DateTime? Function()? departure,
    TravellerGroup? travellers,
    String? Function()? preferredFareClass,
  }) => TripRequest(
    direction: direction ?? this.direction,
    municipalityId: municipalityId ?? this.municipalityId,
    manilaEndId: manilaEndId ?? this.manilaEndId,
    custom: custom == null ? this.custom : custom(),
    customFare: customFare == null ? this.customFare : customFare(),
    customMinutes: customMinutes == null ? this.customMinutes : customMinutes(),
    departure: departure == null ? this.departure : departure(),
    travellers: travellers ?? this.travellers,
    preferredFareClass: preferredFareClass == null
        ? this.preferredFareClass
        : preferredFareClass(),
  );

  Json toJson() => {
    'direction': direction.name,
    'municipalityId': municipalityId,
    'manilaEndId': manilaEndId,
    if (custom != null)
      'custom': {'name': custom!.name, 'nearestHubId': custom!.nearestHubId},
    if (customFare != null)
      'customFare': {'min': customFare!.min, 'max': customFare!.max},
    if (customMinutes != null)
      'customMinutes': {'min': customMinutes!.min, 'max': customMinutes!.max},
    if (departure != null) 'departure': departure!.toIso8601String(),
    'travellers': travellers.toJson(),
    if (preferredFareClass != null) 'preferredFareClass': preferredFareClass,
  };

  factory TripRequest.fromJson(Json json) {
    final custom = json.opt<Json>('custom');
    final departure = json.opt<String>('departure');
    IntRange? range(String key) {
      final r = json.opt<Json>(key);
      return r == null ? null : IntRange.fromJson(r);
    }

    return TripRequest(
      direction: TripDirection.values.byName(json.req<String>('direction')),
      municipalityId: json.req<String>('municipalityId'),
      manilaEndId: json.req<String>('manilaEndId'),
      custom: custom == null
          ? null
          : CustomPlace(
              name: custom.req<String>('name'),
              nearestHubId: custom.req<String>('nearestHubId'),
            ),
      customFare: range('customFare'),
      customMinutes: range('customMinutes'),
      departure: departure == null ? null : DateTime.parse(departure),
      travellers: TravellerGroup.fromJson(
        json.opt<Json>('travellers') ?? const <String, Object?>{},
      ),
      preferredFareClass: json.opt<String>('preferredFareClass'),
    );
  }
}

/// A complete door-to-door option with its totals.
final class TripPlan {
  TripPlan({required this.legs, required this.fare, required this.time})
    : id = legs.map((l) => l.id).join('>');

  /// Built from leg ids, so the same route gets the same id after a reload.
  final String id;
  final List<Leg> legs;
  final FareBreakdown fare;
  final TimeEstimate time;

  /// Number of vehicle changes (walking between port and terminal not counted).
  int get transfers {
    final rides = legs.where((l) => !l.isWalk).length;
    return rides <= 1 ? 0 : rides - 1;
  }

  Verification get weakestVerification =>
      Verification.weakest(legs.expand((l) => l.verifications));

  bool get hasPlaceholders =>
      legs.expand((l) => l.verifications).any((v) => v.isPlaceholder);

  bool get hasMissingEstimates => legs.any((l) => l.estimateMissing);

  Iterable<Leg> get shipLegs => legs.where((l) => l.kind == LegKind.ship);
}
