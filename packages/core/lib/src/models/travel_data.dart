import '../json.dart';
import 'advisory.dart';
import 'checklist.dart';
import 'discounts.dart';
import 'guide.dart';
import 'land.dart';
import 'places.dart';
import 'safety.dart';
import 'sea.dart';

/// Version and global settings from `meta.json`.
final class DataMeta {
  const DataMeta({
    required this.dataVersion,
    required this.discounts,
    this.generatedAt,
    this.isPlaceholderData = true,
  });

  final int dataVersion;
  final DateTime? generatedAt;
  final bool isPlaceholderData;
  final DiscountRules discounts;

  factory DataMeta.fromJson(Json json) {
    final generated = json.opt<String>('generatedAt');
    return DataMeta(
      dataVersion: json.req<int>('dataVersion'),
      generatedAt: generated == null ? null : DateTime.parse(generated),
      isPlaceholderData: json.opt<bool>('isPlaceholderData') ?? true,
      discounts: DiscountRules.fromJson(json.opt<Json>('discounts')),
    );
  }
}

/// Everything the planner needs, held in memory with id lookups.
///
/// The whole dataset is small (hundreds of rows), so loading it at once keeps
/// the planner synchronous and fast even on low-end phones.
final class TravelData {
  TravelData({
    required this.meta,
    required this.municipalities,
    required this.ports,
    required this.busTerminals,
    required this.hubs,
    required this.shippingLines,
    required this.voyages,
    required this.shipFares,
    required this.busOperators,
    required this.busRoutes,
    required this.localRides,
    required this.checklists,
    this.guides = const [],
    this.hotlines = const [],
    this.safetyTips = const [],
    this.advisories = const [],
  }) : _places = {
         for (final p in <Place>[
           ...municipalities,
           ...ports,
           ...busTerminals,
           ...hubs,
         ])
           p.id: p,
       };

  /// Collection names, matching the seed file names in `assets/data/`.
  static const collections = [
    'meta',
    'municipalities',
    'ports',
    'bus_terminals',
    'hubs',
    'shipping_lines',
    'voyages',
    'ship_fares',
    'bus_operators',
    'bus_routes',
    'local_rides',
    'checklists',
    'guides',
    'hotlines',
    'safety_tips',
    'advisories',
  ];

  /// Collections added after the first release; missing ones load as empty
  /// so older stored data and small test fixtures still parse.
  static const optionalCollections = {
    'guides',
    'hotlines',
    'safety_tips',
    'advisories',
  };

  final DataMeta meta;
  final List<Municipality> municipalities;
  final List<Port> ports;
  final List<BusTerminal> busTerminals;
  final List<Hub> hubs;
  final List<ShippingLine> shippingLines;
  final List<Voyage> voyages;
  final List<ShipFare> shipFares;
  final List<BusOperator> busOperators;
  final List<BusRoute> busRoutes;
  final List<LocalRide> localRides;
  final List<ChecklistTemplate> checklists;
  final List<Guide> guides;
  final List<Hotline> hotlines;
  final List<SafetyTip> safetyTips;
  final List<Advisory> advisories;

  final Map<String, Place> _places;

  Place? place(String id) => _places[id];
  Iterable<String> get placeIds => _places.keys;

  Port? port(String id) => _places[id] is Port ? _places[id]! as Port : null;

  ShippingLine? line(String id) =>
      shippingLines.where((l) => l.id == id).firstOrNull;

  BusOperator? busOperator(String id) =>
      busOperators.where((o) => o.id == id).firstOrNull;

  Voyage? voyage(String id) => voyages.where((v) => v.id == id).firstOrNull;

  Advisory? advisory(String id) =>
      advisories.where((a) => a.id == id).firstOrNull;

  Guide? guideFor(String placeId) =>
      guides.where((g) => g.placeId == placeId).firstOrNull;

  ChecklistTemplate? checklistFor(TripDirection direction) =>
      checklists.where((c) => c.direction == direction).firstOrNull;

  /// Builds the dataset from decoded JSON keyed by collection name.
  ///
  /// `meta` is an object; every other collection is `{"items": [...]}`.
  factory TravelData.fromCollections(Map<String, Object?> files) {
    List<T> items<T>(String name, T Function(Json) parse) {
      final file = files[name];
      if (file == null && optionalCollections.contains(name)) return [];
      if (file is! Json) throw FormatException('Missing collection "$name"');
      try {
        return file.objects('items').map(parse).toList();
      } on FormatException catch (e) {
        throw FormatException('In "$name": ${e.message}');
      }
    }

    final meta = files['meta'];
    if (meta is! Json) throw const FormatException('Missing "meta"');

    return TravelData(
      meta: DataMeta.fromJson(meta),
      municipalities: items('municipalities', Municipality.fromJson),
      ports: items('ports', Port.fromJson),
      busTerminals: items('bus_terminals', BusTerminal.fromJson),
      hubs: items('hubs', Hub.fromJson),
      shippingLines: items('shipping_lines', ShippingLine.fromJson),
      voyages: items('voyages', Voyage.fromJson),
      shipFares: items('ship_fares', ShipFare.fromJson),
      busOperators: items('bus_operators', BusOperator.fromJson),
      busRoutes: items('bus_routes', BusRoute.fromJson),
      localRides: items('local_rides', LocalRide.fromJson),
      checklists: items('checklists', ChecklistTemplate.fromJson),
      guides: items('guides', Guide.fromJson),
      hotlines: items('hotlines', Hotline.fromJson),
      safetyTips: items('safety_tips', SafetyTip.fromJson),
      advisories: items('advisories', Advisory.fromJson),
    );
  }

  /// Parses one [item] of [collection], throwing a [FormatException] if it
  /// is malformed. Used to reject a single bad synced document.
  static void checkItem(String collection, Json item) {
    final Object Function(Json)? parse = switch (collection) {
      'municipalities' => Municipality.fromJson,
      'ports' => Port.fromJson,
      'bus_terminals' => BusTerminal.fromJson,
      'hubs' => Hub.fromJson,
      'shipping_lines' => ShippingLine.fromJson,
      'voyages' => Voyage.fromJson,
      'ship_fares' => ShipFare.fromJson,
      'bus_operators' => BusOperator.fromJson,
      'bus_routes' => BusRoute.fromJson,
      'local_rides' => LocalRide.fromJson,
      'checklists' => ChecklistTemplate.fromJson,
      'guides' => Guide.fromJson,
      'hotlines' => Hotline.fromJson,
      'safety_tips' => SafetyTip.fromJson,
      'advisories' => Advisory.fromJson,
      _ => null,
    };
    if (parse == null) {
      throw FormatException('Unknown collection "$collection"');
    }
    try {
      parse(item);
    } on TypeError catch (e) {
      throw FormatException('In "$collection": $e');
    } on ArgumentError catch (e) {
      // e.g. an unknown enum name passed to `byName`.
      throw FormatException('In "$collection": ${e.message}');
    }
  }

  /// The id a collection item is stored under, locally and in Firestore.
  ///
  /// Items carry their own `id`, except ship fares, which are keyed by voyage,
  /// stops and class. Firestore ids may not contain `/`.
  static String documentId(String collection, Json item, [int index = 0]) {
    if (item['id'] case final String id) return id;
    if (collection == 'ship_fares') {
      return '${item['voyageId']}:${item['fromPortId']}-${item['toPortId']}'
          ':${item['fareClass']}';
    }
    return '$collection#$index';
  }
}
