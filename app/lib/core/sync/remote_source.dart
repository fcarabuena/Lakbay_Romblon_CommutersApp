import 'package:lakbay_core/lakbay_core.dart';

/// One changed document from the server.
class RemoteDoc {
  const RemoteDoc({
    required this.id,
    required this.updatedAt,
    this.data,
    this.deleted = false,
  });

  final String id;

  /// The item as in the seed files, without server bookkeeping fields.
  /// Null when [deleted].
  final Json? data;
  final bool deleted;

  /// Server time of the change.
  final DateTime updatedAt;
}

/// Everything that changed on the server since a sync cursor.
class RemoteChanges {
  const RemoteChanges({this.meta, this.metaUpdatedAt, this.docs = const {}});

  /// The new `meta.json` content, when it changed.
  final Json? meta;
  final DateTime? metaUpdatedAt;

  /// Changed documents by collection name.
  final Map<String, List<RemoteDoc>> docs;

  bool get isEmpty => meta == null && docs.values.every((d) => d.isEmpty);

  /// The newest change, used as the next cursor.
  DateTime? get latest {
    DateTime? newest = metaUpdatedAt;
    for (final doc in docs.values.expand((d) => d)) {
      if (newest == null || doc.updatedAt.isAfter(newest)) {
        newest = doc.updatedAt;
      }
    }
    return newest;
  }
}

/// Where synced travel data comes from (Firestore in the app, fakes in tests).
abstract interface class RemoteSource {
  /// Changes after [since], or everything when [since] is null.
  Future<RemoteChanges> changesSince(DateTime? since);
}
