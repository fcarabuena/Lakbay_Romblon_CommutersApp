import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../backend/admin_backend.dart';
import '../backend/dataset.dart';
import '../state/providers.dart';
import 'collection_specs.dart';
import 'edit_logic.dart';

/// Which collections a reference field can point to.
const _placeCollections = {'municipalities', 'ports', 'bus_terminals', 'hubs'};
const _referenceTargets = <String, Set<String>>{
  'portId': {'ports'},
  'fromPortId': {'ports'},
  'toPortId': {'ports'},
  'affectedPortIds': {'ports'},
  'municipalityId': {'municipalities'},
  'voyageId': {'voyages'},
  'affectedVoyageIds': {'voyages'},
  'lineId': {'shipping_lines'},
  'operatorId': {'bus_operators'},
  'placeId': _placeCollections,
  'originId': _placeCollections,
  'fromId': _placeCollections,
  'toId': _placeCollections,
};

/// How each collection is counted in a sentence: (one, many).
const _nouns = <String, (String, String)>{
  'voyages': ('voyage', 'voyages'),
  'ship_fares': ('fare', 'fares'),
  'bus_routes': ('bus route', 'bus routes'),
  'local_rides': ('local ride', 'local rides'),
  'ports': ('port', 'ports'),
  'bus_terminals': ('bus terminal', 'bus terminals'),
  'guides': ('guide', 'guides'),
  'hotlines': ('hotline', 'hotlines'),
  'advisories': ('advisory', 'advisories'),
};

bool _mentions(Object? value, String key, String id, String collection) {
  switch (value) {
    case final Map<String, Object?> map:
      return map.entries.any((e) => _mentions(e.value, e.key, id, collection));
    case final List<Object?> list:
      return list.any((v) => _mentions(v, key, id, collection));
    case final String s:
      return s == id && (_referenceTargets[key]?.contains(collection) ?? false);
    default:
      return false;
  }
}

/// How many items in each other collection use [id] of [collection],
/// e.g. `{'voyages': 3, 'ship_fares': 12}` for a port.
Map<String, int> usagesOf(String collection, String id, Dataset data) {
  final counts = <String, int>{};
  for (final MapEntry(key: other, value: rows) in data.rows.entries) {
    for (final MapEntry(key: otherId, value: item) in rows.entries) {
      if (other == collection && otherId == id) continue;
      if (_mentions(item, '', id, collection)) {
        counts[other] = (counts[other] ?? 0) + 1;
      }
    }
  }
  return counts;
}

/// "3 voyages and 12 fares use this port. Delete or change those first."
String usageMessage(Map<String, int> usages, String singular) {
  final parts = [
    for (final MapEntry(key: c, value: n) in usages.entries)
      '$n ${n == 1 ? (_nouns[c]?.$1 ?? c) : (_nouns[c]?.$2 ?? c)}',
  ];
  final list = parts.length <= 1
      ? parts.join()
      : '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  final total = usages.values.fold(0, (a, b) => a + b);
  return '$list ${total == 1 ? 'uses' : 'use'} this $singular. Delete or change those first.';
}

Future<void> _message(BuildContext context, String title, String body) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('deleteBlocked'),
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

/// Asks, then deletes item [id] of [spec] with a change-log entry holding a
/// copy of it. Blocked, with an explanation, while other data uses it.
/// Returns true when the item was deleted.
Future<bool> confirmAndDelete(
  BuildContext context,
  WidgetRef ref,
  CollectionSpec spec,
  String id,
) async {
  final data = ref.read(datasetProvider).value;
  final item = data?.item(spec.collection, id);
  if (data == null || item == null) return false;
  final name = spec.titleOf(item, data);

  final usages = usagesOf(spec.collection, id, data);
  if (usages.isNotEmpty) {
    await _message(
      context,
      "Can't delete $name yet",
      usageMessage(usages, spec.singular),
    );
    return false;
  }
  // Anything else the app's checks would object to.
  final problems = checkDelete(spec, data, id);
  if (problems.isNotEmpty) {
    if (!context.mounted) return false;
    await _message(
      context,
      "Can't delete $name yet",
      friendlyProblems(problems, data).join('\n'),
    );
    return false;
  }

  if (!context.mounted) return false;
  final error = Theme.of(context).colorScheme.error;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('deleteDialog'),
      title: Text('Delete $name?'),
      content: const Text(
        'This removes it from the app for everyone. Phones drop it at their next update. '
        'Admins can restore it from the change log.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirmDelete'),
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  await ref
      .read(backendProvider)
      .save(
        AuditedWrite(
          collection: spec.collection,
          docId: id,
          auditId: ref.read(idGeneratorProvider)(),
          before: item,
          after: null,
          note: 'Deleted "$name"',
        ),
      );
  ref.invalidate(auditProvider);
  await ref.read(datasetProvider.notifier).reload();
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Deleted $name')));
  }
  return true;
}

/// Puts a deleted item back from its change-log entry (admins only).
/// Returns a problem to show, or null when restored.
Future<String?> restoreFromLog(WidgetRef ref, AuditEntry entry) async {
  final spec = specFor(entry.collection);
  final copy = entry.before;
  if (spec == null ||
      entry.action != 'delete' ||
      copy is! Map<String, Object?>) {
    return 'This entry cannot be restored.';
  }
  final data =
      ref.read(datasetProvider).value ??
      await ref.read(backendProvider).loadDataset();
  if (data.item(spec.collection, entry.docId) != null) {
    return 'An item with this ID exists again, so it was not restored.';
  }
  final item = deepCopy(copy);
  final problems = problemsIntroduced(
    data.files(),
    data.withChange(spec.collection, entry.docId, item).files(),
  );
  if (problems.isNotEmpty) {
    return 'It cannot be restored yet: ${friendlyProblems(problems, data).join('; ')}';
  }
  await ref
      .read(backendProvider)
      .save(
        AuditedWrite(
          collection: spec.collection,
          docId: entry.docId,
          auditId: ref.read(idGeneratorProvider)(),
          before: null,
          after: item,
          restore: true,
          note: 'Restored from the change log',
        ),
      );
  ref.invalidate(auditProvider);
  await ref.read(datasetProvider.notifier).reload();
  return null;
}
