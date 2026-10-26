import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:url_launcher/url_launcher.dart';

sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound(this.point);

  final GeoPoint point;
}

final class LocationDenied extends LocationResult {
  const LocationDenied();
}

final class LocationServiceOff extends LocationResult {
  const LocationServiceOff();
}

final class LocationFailed extends LocationResult {
  const LocationFailed();
}

/// The phone's current position, asked for only when the traveller taps
/// "Use my location". The position is used on the phone and never sent.
abstract interface class LocationService {
  Future<LocationResult> current();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServiceOff();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationDenied();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationFound(GeoPoint(position.latitude, position.longitude));
    } on Exception {
      // Timeouts are common indoors; a recent fix is still useful.
      final last = await Geolocator.getLastKnownPosition();
      return last == null
          ? const LocationFailed()
          : LocationFound(GeoPoint(last.latitude, last.longitude));
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

/// Opens the phone dialer with [number] filled in. Returns false if no app
/// can handle it. Uses the dialer, so no call permission is needed.
typedef Dialer = Future<bool> Function(String number);

final dialerProvider = Provider<Dialer>(
  (ref) =>
      (number) => launchUrl(Uri(scheme: 'tel', path: dialableNumber(number))),
);

/// Opens a web page in the browser (used for map attribution).
final urlOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Whether map screens load OpenStreetMap tiles. Off in widget tests.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// The last location result in this session (null until requested).
class UserLocationController extends Notifier<AsyncValue<LocationResult>?> {
  @override
  AsyncValue<LocationResult>? build() => null;

  Future<void> request() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(locationServiceProvider).current());
  }
}

final userLocationProvider =
    NotifierProvider<UserLocationController, AsyncValue<LocationResult>?>(
      UserLocationController.new,
    );

GeoPoint? foundLocation(AsyncValue<LocationResult>? value) => switch (value) {
  AsyncData(value: LocationFound(:final point)) => point,
  _ => null,
};
