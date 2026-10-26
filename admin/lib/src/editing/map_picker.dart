import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Roughly the middle of Romblon province, where the map starts by default.
const romblonCenter = LatLng(12.55, 122.28);

class PlaceResult {
  const PlaceResult(this.name, this.point);

  final String name;
  final LatLng point;
}

/// Finds places by name; OpenStreetMap's Nominatim in the panel.
abstract interface class PlaceSearch {
  Future<List<PlaceResult>> search(String query);
}

/// Searches OpenStreetMap, limited to the Philippines.
///
/// Nominatim's usage policy allows at most one request a second, so requests
/// are spaced out. The panel is used by a few staff, well within the policy.
class NominatimSearch implements PlaceSearch {
  NominatimSearch([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<List<PlaceResult>> search(String query) async {
    final wait = const Duration(seconds: 1) - DateTime.now().difference(_last);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _last = DateTime.now();
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'countrycodes': 'ph',
      'limit': '6',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Search failed (${response.statusCode})');
    }
    return [
      for (final r in jsonDecode(response.body) as List<Object?>)
        if (r case {
          'display_name': final String name,
          'lat': final String lat,
          'lon': final String lon,
        })
          PlaceResult(name, LatLng(double.parse(lat), double.parse(lon))),
    ];
  }
}

final placeSearchProvider = Provider<PlaceSearch>((ref) => NominatimSearch());

/// Whether the map loads OpenStreetMap tiles. Off in widget tests.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// Opens the map; returns the chosen spot, or null if cancelled.
///
/// Starts at [initial] when set, otherwise at [center] (e.g. the chosen
/// town), otherwise in the middle of Romblon.
Future<LatLng?> showMapPicker(
  BuildContext context, {
  required String title,
  LatLng? initial,
  LatLng? center,
}) => showDialog<LatLng>(
  context: context,
  builder: (_) =>
      _MapPickerDialog(title: title, initial: initial, center: center),
);

class _MapPickerDialog extends ConsumerStatefulWidget {
  const _MapPickerDialog({required this.title, this.initial, this.center});

  final String title;
  final LatLng? initial;
  final LatLng? center;

  @override
  ConsumerState<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends ConsumerState<_MapPickerDialog> {
  final _map = MapController();
  final _query = TextEditingController();
  late LatLng _pin = widget.initial ?? widget.center ?? romblonCenter;
  List<PlaceResult>? _results;
  String? _searchMessage;
  bool _searching = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final results = await ref.read(placeSearchProvider).search(q);
      setState(() {
        _results = results;
        _searchMessage = results.isEmpty
            ? 'Nothing found. Drag the pin to the spot instead.'
            : null;
      });
    } on Object {
      setState(
        () => _searchMessage = 'Search is not working right now. Drag the pin to the spot instead.',
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _moveTo(LatLng point, {double? zoom}) {
    setState(() {
      _pin = point;
      _results = null;
    });
    _map.move(point, zoom ?? _map.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = ref.watch(mapTilesEnabledProvider);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 720,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('mapSearch'),
                    controller: _query,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search for a place, e.g. Odiongan Port',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: const Key('mapSearchButton'),
                  onPressed: _searching ? null : _search,
                  child: const Text('Search'),
                ),
              ],
            ),
            if (_searchMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _searchMessage!,
                  key: const Key('mapSearchMessage'),
                ),
              ),
            if (_results case final results? when results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: Card(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final (i, r) in results.indexed)
                        ListTile(
                          key: Key('mapResult-$i'),
                          dense: true,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            r.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _moveTo(r.point, zoom: 16),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Drag the pin, or tap the map, to mark the exact spot.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  key: const Key('pickerMap'),
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: widget.initial != null
                        ? 16
                        : (widget.center != null ? 14 : 9),
                    onTap: (_, point) => setState(() => _pin = point),
                  ),
                  children: [
                    if (tiles)
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'app.lakbayromblon.admin',
                      )
                    else
                      Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pin,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            key: const Key('mapPin'),
                            onPanUpdate: (d) {
                              final camera = _map.camera;
                              final at =
                                  camera.latLngToScreenOffset(_pin) + d.delta;
                              setState(
                                () => _pin = camera.screenOffsetToLatLng(at),
                              );
                            },
                            child: Icon(
                              Icons.location_on,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (tiles)
                      const SimpleAttributionWidget(
                        source: Text('OpenStreetMap contributors'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chosen spot: ${_pin.latitude.toStringAsFixed(5)}, ${_pin.longitude.toStringAsFixed(5)}',
              key: const Key('mapChosen'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('mapUse'),
          onPressed: () => Navigator.pop(context, _pin),
          child: const Text('Use this spot'),
        ),
      ],
    );
  }
}
