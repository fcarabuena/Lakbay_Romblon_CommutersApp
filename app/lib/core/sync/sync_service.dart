import 'package:flutter/foundation.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../db/local_database.dart';
import 'remote_source.dart';

/// What one sync did.
class SyncResult {
  const SyncResult({
    required this.data,
    required this.applied,
    required this.skipped,
  });

  /// The travel data after the sync (unchanged when nothing applied).
  final TravelData data;
  final int applied;

  /// Documents rejected because they were malformed or would break the
  /// data (e.g. a fare for a voyage that does not exist). They are logged
  /// and never replace working data.
  final List<String> skipped;
}

/// Copies server changes into the local database.
///
/// The phone always reads from sqflite; the server only refreshes it. Every
/// change is checked before it is stored: a malformed document, or one that
/// adds a data problem, is skipped and the rest still apply.
class SyncService {
  SyncService({
    required this.database,
    required this.remote,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocalDatabase database;
  final RemoteSource remote;
  final DateTime Function() _clock;

  Future<SyncResult> sync() async {
    final changes = await remote.changesSince(await database.syncCursor());
    var meta = await database.loadMeta();
    final rows = await database.loadRows();
    final skipped = <String>[];

    Json? newMeta;
    if (changes.meta case final remoteMeta?) {
      try {
        DataMeta.fromJson(remoteMeta);
        newMeta = {...remoteMeta, 'dataVersion': meta['dataVersion']};
        meta = newMeta;
      } on Object catch (e) {
        skipped.add('meta: $e');
      }
    }

    // 1. Each document must parse on its own.
    final candidates = <({String collection, RemoteDoc doc})>[];
    for (final MapEntry(key: collection, value: docs) in changes.docs.entries) {
      if (!rows.containsKey(collection)) continue;
      for (final doc in docs) {
        if (doc.data case final item? when !doc.deleted) {
          try {
            TravelData.checkItem(collection, item);
          } on FormatException catch (e) {
            skipped.add('$collection/${doc.id}: ${e.message}');
            continue;
          }
        }
        candidates.add((collection: collection, doc: doc));
      }
    }

    // 2. Together they must not add data problems.
    final baseline = _problems(meta, rows)?.toSet() ?? const <String>{};
    var accepted = candidates;
    final merged = _apply(rows, candidates);
    final mergedProblems = _problems(meta, merged);
    if (mergedProblems == null || !baseline.containsAll(mergedProblems)) {
      // Rare: find the offending documents by adding one change at a time.
      accepted = [];
      var current = rows;
      for (final c in candidates) {
        final next = _apply(current, [c]);
        final problems = _problems(meta, next);
        if (problems != null && baseline.containsAll(problems)) {
          accepted.add(c);
          current = next;
        } else {
          skipped.add(
            '${c.collection}/${c.doc.id}: '
            '${problems?.where((p) => !baseline.contains(p)).join('; ') ?? 'breaks the data'}',
          );
        }
      }
    }

    final changesByCollection = <String, Map<String, Json?>>{};
    for (final c in accepted) {
      (changesByCollection[c.collection] ??= {})[c.doc.id] = c.doc.deleted
          ? null
          : c.doc.data;
    }
    await database.applyChanges(
      changes: changesByCollection,
      meta: newMeta,
      cursor: changes.latest,
      syncedAt: _clock(),
    );
    for (final s in skipped) {
      debugPrint('Sync skipped $s');
    }
    return SyncResult(
      data: await database.loadTravelData(),
      applied: accepted.length + (newMeta == null ? 0 : 1),
      skipped: skipped,
    );
  }

  static Map<String, Map<String, Json>> _apply(
    Map<String, Map<String, Json>> rows,
    List<({String collection, RemoteDoc doc})> changes,
  ) {
    final result = {
      for (final MapEntry(:key, :value) in rows.entries) key: {...value},
    };
    for (final (:collection, :doc) in changes) {
      final table = result[collection]!;
      if (doc.deleted || doc.data == null) {
        table.remove(doc.id);
      } else {
        table[doc.id] = doc.data!;
      }
    }
    return result;
  }

  /// Validator problems for a dataset, or null if it does not even parse.
  static List<String>? _problems(
    Json meta,
    Map<String, Map<String, Json>> rows,
  ) {
    try {
      return validateTravelData(
        TravelData.fromCollections(LocalDatabase.collectionFiles(meta, rows)),
      );
    } on Object {
      return null;
    }
  }
}
