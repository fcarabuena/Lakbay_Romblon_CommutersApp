import 'package:lakbay_core/lakbay_core.dart';

/// Collections stored in Firestore, one per seed file (`meta` lives in
/// `config/meta`).
final travelCollections = [
  for (final c in TravelData.collections)
    if (c != 'meta') c,
];

/// Every live (not deleted) document, as the editors and validator see it.
class Dataset {
  Dataset({required this.meta, required Map<String, Map<String, Json>> rows})
    : rows = {for (final c in travelCollections) c: rows[c] ?? {}};

  /// The `config/meta` document (same shape as `meta.json`).
  final Json meta;

  /// Items by collection, then document id.
  final Map<String, Map<String, Json>> rows;

  bool get isEmpty => rows.values.every((r) => r.isEmpty);

  /// The `{collection: {"items": [...]}}` shape [TravelData] parses.
  Map<String, Object?> files() => {
    'meta': meta,
    for (final MapEntry(:key, :value) in rows.entries)
      key: {'items': value.values.toList()},
  };

  Json? item(String collection, String id) => collection == 'config'
      ? (id == 'meta' ? meta : null)
      : rows[collection]?[id];

  /// This dataset with one document replaced, added or (when [item] is null)
  /// removed. `config/meta` replaces [meta].
  Dataset withChange(String collection, String id, Json? item) {
    if (collection == 'config') {
      return Dataset(meta: item ?? meta, rows: rows);
    }
    final table = {...?rows[collection]};
    item == null ? table.remove(id) : table[id] = item;
    return Dataset(meta: meta, rows: {...rows, collection: table});
  }

  TravelData? parse() {
    try {
      return TravelData.fromCollections(files());
    } on Object {
      return null;
    }
  }
}
