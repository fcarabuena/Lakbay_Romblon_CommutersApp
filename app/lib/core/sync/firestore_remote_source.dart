import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'remote_source.dart';

/// Fields the admin panel adds to every document. They are not part of the
/// item itself, so they are removed before the item is stored on the phone.
const serverFields = {'updatedAt', 'updatedBy', 'auditId', 'deleted'};

/// Reads changed travel documents from Firestore.
///
/// Layout: one collection per seed file (same names), plus `config/meta`.
/// Every document has a server `updatedAt`; deletions are `deleted: true`.
class FirestoreRemoteSource implements RemoteSource {
  FirestoreRemoteSource(this.firestore);

  final FirebaseFirestore firestore;

  static final _collections = TravelData.collections.where((c) => c != 'meta');

  @override
  Future<RemoteChanges> changesSince(DateTime? since) async {
    Query<Json> changed(Query<Json> query) => since == null
        ? query
        : query.where('updatedAt', isGreaterThan: Timestamp.fromDate(since));

    final results = await Future.wait([
      for (final name in _collections)
        changed(firestore.collection(name)).get(),
    ]);
    final metaDoc = await firestore.doc('config/meta').get();

    final docs = <String, List<RemoteDoc>>{};
    for (final (i, name) in _collections.indexed) {
      docs[name] = [
        for (final doc in results[i].docs)
          if (_updatedAt(doc.data()) case final updatedAt?)
            RemoteDoc(
              id: doc.id,
              updatedAt: updatedAt,
              deleted: doc.data()['deleted'] == true,
              data: doc.data()['deleted'] == true ? null : _clean(doc.data()),
            ),
      ];
    }

    final metaData = metaDoc.data();
    final metaUpdated = metaData == null ? null : _updatedAt(metaData);
    final metaChanged =
        metaUpdated != null && (since == null || metaUpdated.isAfter(since));
    return RemoteChanges(
      meta: metaChanged ? _clean(metaData!) : null,
      metaUpdatedAt: metaChanged ? metaUpdated : null,
      docs: docs,
    );
  }

  static DateTime? _updatedAt(Json data) => switch (data['updatedAt']) {
    final Timestamp t => t.toDate().toUtc(),
    _ => null,
  };

  static Json _clean(Json data) => {
    for (final MapEntry(:key, :value) in data.entries)
      if (!serverFields.contains(key)) key: _plain(value),
  };

  /// Converts Firestore types to the plain JSON the seed parser expects.
  static Object? _plain(Object? value) => switch (value) {
    final Timestamp t => t.toDate().toUtc().toIso8601String(),
    final Map<String, Object?> m => {
      for (final MapEntry(:key, :value) in m.entries) key: _plain(value),
    },
    final List<Object?> l => [for (final v in l) _plain(v)],
    _ => value,
  };
}
