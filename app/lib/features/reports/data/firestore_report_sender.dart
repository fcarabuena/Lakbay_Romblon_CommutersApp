import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'reports_repository.dart';

/// Sends reports to the `reports` collection with anonymous sign-in, so no
/// account or personal details are needed.
///
/// Each device may create report ids `<uid>_<utcDay>_<1..10>` only (enforced
/// by the security rules), which caps it at [ReportLimits.perDay] a day.
class FirestoreReportSender implements ReportSender {
  FirestoreReportSender({
    required this.firestore,
    required this.auth,
    required this.appVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final String appVersion;
  final DateTime Function() _clock;

  /// The next slot to try, per UTC day, remembered for this app session.
  final _nextSlot = <int, int>{};

  Future<String> _uid() async =>
      auth.currentUser?.uid ?? (await auth.signInAnonymously()).user!.uid;

  @override
  Future<String> send(CommunityReport report) async {
    final uid = await _uid();
    final now = _clock();
    final day = utcDayNumber(now);
    for (var slot = _nextSlot[day] ?? 1; slot <= ReportLimits.perDay; slot++) {
      final id = reportDocumentId(uid, now, slot);
      try {
        await firestore.collection('reports').doc(id).set({
          ...report.toSubmissionJson(),
          'reporterUid': uid,
          'appVersion': appVersion,
          'submittedAt': FieldValue.serverTimestamp(),
        });
        _nextSlot[day] = slot + 1;
        return id;
      } on FirebaseException catch (e) {
        // An existing id is refused like any other write: try the next slot.
        if (e.code != 'permission-denied') rethrow;
      }
    }
    _nextSlot[day] = ReportLimits.perDay + 1;
    throw const ReportLimitReached();
  }

  @override
  Future<List<CommunityReport>> fetchMine() async {
    final user = auth.currentUser;
    if (user == null) return const [];
    final snapshot = await firestore
        .collection('reports')
        .where('reporterUid', isEqualTo: user.uid)
        .get();
    String? iso(Object? value) =>
        value is Timestamp ? value.toDate().toUtc().toIso8601String() : null;
    return [
      for (final doc in snapshot.docs)
        CommunityReport.fromJson({
          ...doc.data(),
          'id': doc.id,
          'submittedAt':
              iso(doc.data()['submittedAt']) ??
              _clock().toUtc().toIso8601String(),
          'reviewedAt': iso(doc.data()['reviewedAt']),
        }),
    ];
  }
}
