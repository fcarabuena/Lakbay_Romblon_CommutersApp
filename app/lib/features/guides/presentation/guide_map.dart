import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/services/device_services.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import 'layout_view.dart';

LatLng _latLng(GeoPoint p) => LatLng(p.lat, p.lng);

/// Live OpenStreetMap view of a pier or terminal.
///
/// Follows the OSM tile usage policy: identifies the app in the User-Agent,
/// shows attribution, and only caches tiles the traveller has viewed (the
/// flutter_map default). Nothing is downloaded in bulk for offline use.
class GuideMap extends ConsumerStatefulWidget {
  const GuideMap({super.key, required this.place, required this.guide});

  final Place place;
  final Guide? guide;

  @override
  ConsumerState<GuideMap> createState() => _GuideMapState();
}

class _GuideMapState extends ConsumerState<GuideMap> {
  bool _tilesFailed = false;

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (_tilesFailed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tilesFailed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = widget.place.location;
    if (location == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Notice(l10n.noLocationForPlace),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final tilesEnabled = ref.watch(mapTilesEnabledProvider);
    final userLocation = foundLocation(ref.watch(userLocationProvider));
    final locating = ref.watch(userLocationProvider) is AsyncLoading;
    final lang = context.languageCode;

    Marker pin(GeoPoint p, IconData icon, Color color, String label) => Marker(
      point: _latLng(p),
      width: 44,
      height: 44,
      child: Semantics(
        label: label,
        child: Icon(icon, color: color, size: 40),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Notice(
            _tilesFailed ? l10n.mapTilesFailed : l10n.mapNeedsInternet,
            tone: _tilesFailed ? NoticeTone.warning : NoticeTone.info,
            icon: Icons.wifi,
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _latLng(location),
              initialZoom: 16,
              minZoom: 5,
              maxZoom: 19,
            ),
            children: [
              if (tilesEnabled)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'app.lakbayromblon',
                  maxNativeZoom: 19,
                  errorTileCallback: _onTileError,
                ),
              MarkerLayer(
                markers: [
                  pin(
                    location,
                    Icons.location_on,
                    scheme.error,
                    widget.place.name,
                  ),
                  for (final poi
                      in widget.guide?.pointsOfInterest ??
                          const <PointOfInterest>[])
                    if (poi.location != null)
                      pin(
                        poi.location!,
                        areaIcon(poi.kind),
                        scheme.tertiary,
                        poi.label.resolve(lang),
                      ),
                  if (userLocation != null)
                    pin(
                      userLocation,
                      Icons.my_location,
                      scheme.primary,
                      l10n.myLocation,
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => ref.read(urlOpenerProvider)(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            key: const Key('mapMyLocation'),
            onPressed: locating
                ? null
                : () => ref.read(userLocationProvider.notifier).request(),
            icon: const Icon(Icons.my_location),
            label: Text(locating ? l10n.locating : l10n.useMyLocation),
          ),
        ),
      ],
    );
  }
}
