import 'dart:convert';

import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/db/local_database.dart';

/// Reports waiting to be sent (the outbox) and reports already sent.
///
/// Outbox reports use a local id; once sent they are stored under the
/// server id so their review status can be refreshed.
abstract interface class ReportStore {
  Future<void> enqueue(CommunityReport report);
  Future<List<CommunityReport>> outbox();
  Future<void> markSent(String localId, CommunityReport sent);
  Future<List<CommunityReport>> sent();
  Future<void> updateSent(Iterable<CommunityReport> reports);
}

/// The daily limit was reached; the report stays in the outbox until tomorrow.
class ReportLimitReached implements Exception {
  const ReportLimitReached();
}

/// Sends reports to the review queue and reads back their status.
abstract interface class ReportSender {
  /// Returns the server id. Throws [ReportLimitReached] or a network error.
  Future<String> send(CommunityReport report);

  /// Reports sent from this device, with their current status.
  Future<List<CommunityReport>> fetchMine();
}

class SqliteReportStore implements ReportStore {
  const SqliteReportStore(this.database);

  final LocalDatabase database;

  @override
  Future<void> enqueue(CommunityReport report) =>
      database.db.insert('report_outbox', {
        'local_id': report.id,
        'data': jsonEncode(report.toJson()),
        'created_at': report.submittedAt.toIso8601String(),
      });

  @override
  Future<List<CommunityReport>> outbox() async => [
    for (final row in await database.db.query(
      'report_outbox',
      orderBy: 'created_at',
    ))
      CommunityReport.fromJson(jsonDecode(row['data']! as String) as Json),
  ];

  @override
  Future<void> markSent(String localId, CommunityReport sent) =>
      database.db.transaction((txn) async {
        await txn.delete(
          'report_outbox',
          where: 'local_id = ?',
          whereArgs: [localId],
        );
        await txn.insert('my_reports', _sentRow(sent));
      });

  @override
  Future<List<CommunityReport>> sent() async => [
    for (final row in await database.db.query(
      'my_reports',
      orderBy: 'submitted_at DESC',
    ))
      CommunityReport.fromJson(jsonDecode(row['data']! as String) as Json),
  ];

  @override
  Future<void> updateSent(Iterable<CommunityReport> reports) async {
    final batch = database.db.batch();
    for (final r in reports) {
      batch.update(
        'my_reports',
        {'data': jsonEncode(r.toJson())},
        where: 'id = ?',
        whereArgs: [r.id],
      );
    }
    await batch.commit(noResult: true);
  }

  static Map<String, Object?> _sentRow(CommunityReport r) => {
    'id': r.id,
    'data': jsonEncode(r.toJson()),
    'submitted_at': r.submittedAt.toIso8601String(),
  };
}

class MemoryReportStore implements ReportStore {
  final _outbox = <String, CommunityReport>{};
  final _sent = <String, CommunityReport>{};

  @override
  Future<void> enqueue(CommunityReport report) async =>
      _outbox[report.id] = report;

  @override
  Future<List<CommunityReport>> outbox() async => _outbox.values.toList();

  @override
  Future<void> markSent(String localId, CommunityReport sent) async {
    _outbox.remove(localId);
    _sent[sent.id] = sent;
  }

  @override
  Future<List<CommunityReport>> sent() async =>
      _sent.values.toList().reversed.toList();

  @override
  Future<void> updateSent(Iterable<CommunityReport> reports) async {
    for (final r in reports) {
      if (_sent.containsKey(r.id)) _sent[r.id] = r;
    }
  }
}
