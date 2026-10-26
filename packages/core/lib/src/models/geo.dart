import 'dart:math' as math;

import '../json.dart';

/// A WGS84 coordinate. Kept free of map-library types so `core` stays pure Dart.
final class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  factory GeoPoint.fromJson(Json json) => GeoPoint(
    json.req<num>('lat').toDouble(),
    json.req<num>('lng').toDouble(),
  );

  static const _earthRadiusKm = 6371.0088;

  /// Great-circle (haversine) distance in kilometres.
  double distanceKm(GeoPoint other) {
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(other.lat - lat);
    final dLng = rad(other.lng - lng);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) *
            math.cos(rad(other.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
  }
}

/// Items paired with their distance from [from], nearest first. Items without
/// a location go last, in their original order.
List<(T, double?)> sortByDistance<T>(
  Iterable<T> items,
  GeoPoint from,
  GeoPoint? Function(T item) locationOf,
) {
  final entries = [
    for (final (i, item) in items.indexed)
      (i, item, locationOf(item)?.distanceKm(from)),
  ];
  entries.sort((a, b) {
    final (ia, _, da) = a;
    final (ib, _, db) = b;
    if (da != null && db != null && da != db) return da.compareTo(db);
    if (da == null && db != null) return 1;
    if (da != null && db == null) return -1;
    return ia.compareTo(ib);
  });
  return [for (final (_, item, d) in entries) (item, d)];
}
