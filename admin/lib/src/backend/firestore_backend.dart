import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'admin_backend.dart';
import 'dataset.dart';

/// Fields the panel adds to documents; not part of the item itself.
const serverFields = {'updatedAt', 'updatedBy', 'auditId', 'deleted'};

/// Documents per batch when writing many. Each audited document costs the
/// rules up to 3 lookups, plus 2 for the staff record; the limit is 20.
const starterBatchSize = 4;

class FirestoreAdminBackend implements AdminBackend {
  FirestoreAdminBackend({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static AdminUser? _user(User? u) =>
      u == null ? null : AdminUser(uid: u.uid, email: u.email ?? '');

  @override
  Stream<AdminUser?> authChanges() => _auth.authStateChanges().map(_user);

  @override
  AdminUser? get currentUser => _user(_auth.currentUser);

  AdminUser get _me => currentUser ?? (throw StateError('Not signed in'));

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ---------- users ----------

  static StaffMember? _staff(String uid, Json? data) {
    final role = StaffRole.values.asNameMap()[data?['role']];
    if (data == null || role == null) return null;
    return StaffMember(
      uid: uid,
      email: data['email'] as String? ?? '',
      role: role,
    );
  }

  @override
  Future<StaffMember?> staffRecord(String uid) async {
    try {
      final doc = await _db.doc('admins/$uid').get();
      return _staff(uid, doc.data());
    } on FirebaseException catch (e) {
      // Not staff: the rules refuse to show the record.
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  @override
  Future<List<StaffMember>> listStaff() async {
    final snapshot = await _db.collection('admins').get();
    return [for (final d in snapshot.docs) ?_staff(d.id, d.data())]
      ..sort((a, b) => a.email.compareTo(b.email));
  }

  @override
  Future<StaffMember> addStaff({
    required String email,
    required StaffRole role,
    String? existingUid,
  }) async {
    var uid = existingUid;
    if (uid == null) {
      // A second app instance, so creating the account does not sign the
      // admin out of this one.
      final app = await Firebase.initializeApp(
        name: 'add-user-${DateTime.now().microsecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      try {
        final secondary = FirebaseAuth.instanceFor(app: app);
        final created = await secondary.createUserWithEmailAndPassword(
          email: email,
          password: _randomPassword(),
        );
        uid = created.user!.uid;
        await secondary.signOut();
      } finally {
        await app.delete();
      }
      await _auth.sendPasswordResetEmail(email: email);
    }
    final batch = _db.batch()
      ..set(_db.doc('admins/$uid'), {
        'email': email,
        'role': role.name,
        'addedBy': _me.uid,
        'addedAt': FieldValue.serverTimestamp(),
      });
    _logUserChange(batch, uid, 'Added as ${role.name}: $email');
    await batch.commit();
    return StaffMember(uid: uid, email: email, role: role);
  }

  @override
  Future<void> setRole(String uid, StaffRole role) async {
    final batch = _db.batch()
      ..update(_db.doc('admins/$uid'), {'role': role.name});
    _logUserChange(batch, uid, 'Role changed to ${role.name}');
    await batch.commit();
  }

  @override
  Future<void> removeStaff(String uid) async {
    final batch = _db.batch()..delete(_db.doc('admins/$uid'));
    _logUserChange(batch, uid, 'Removed');
    await batch.commit();
  }

  void _logUserChange(WriteBatch batch, String uid, String note) {
    batch.set(_db.collection('audit_log').doc(), {
      'uid': _me.uid,
      'email': _me.email,
      'collection': 'admins',
      'docId': uid,
      'action': 'users',
      'note': note,
      'at': FieldValue.serverTimestamp(),
    });
  }

  static String _randomPassword() {
    final r = Random.secure();
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%';
    return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ---------- data ----------

  @override
  Future<Dataset> loadDataset() async {
    final snapshots = await Future.wait([
      for (final c in travelCollections) _db.collection(c).get(),
    ]);
    final meta = await _db.doc('config/meta').get();
    return Dataset(
      meta: meta.exists ? _clean(meta.data()!) : <String, Object?>{},
      rows: {
        for (final (i, c) in travelCollections.indexed)
          c: {
            for (final d in snapshots[i].docs)
              if (d.data()['deleted'] != true) d.id: _clean(d.data()),
          },
      },
    );
  }

  DocumentReference<Json> _docRef(AuditedWrite w) =>
      _db.doc('${w.collection}/${w.docId}');

  void _addToBatch(WriteBatch batch, AuditedWrite w) {
    final me = _me;
    batch
      ..set(_docRef(w), {
        ...w.documentFields(me.uid),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_db.doc('audit_log/${w.auditId}'), {
        ...w.auditFields(me),
        'at': FieldValue.serverTimestamp(),
      });
  }

  @override
  Future<void> save(AuditedWrite write) async {
    final batch = _db.batch();
    _addToBatch(batch, write);
    await batch.commit();
  }

  @override
  Future<void> saveAll(List<AuditedWrite> writes) async {
    // Small batches: the security rules look up the change-log entry for
    // every document, and Firestore allows only 20 such lookups per batch.
    for (var i = 0; i < writes.length; i += starterBatchSize) {
      final batch = _db.batch();
      for (final w in writes.skip(i).take(starterBatchSize)) {
        _addToBatch(batch, w);
      }
      await batch.commit();
    }
  }

  // ---------- reports ----------

  @override
  Future<List<ReportItem>> listReports({required bool pendingOnly}) async {
    Query<Json> q = _db.collection('reports');
    q = pendingOnly
        ? q
              .where('status', isEqualTo: 'pending')
              .orderBy('submittedAt', descending: true)
        : q.orderBy('submittedAt', descending: true).limit(200);
    final snapshot = await q.get();
    return [
      for (final d in snapshot.docs)
        ReportItem(
          report: CommunityReport.fromJson({
            ..._clean(d.data()),
            'id': d.id,
            'submittedAt':
                _iso(d.data()['submittedAt']) ??
                DateTime.now().toUtc().toIso8601String(),
            'reviewedAt': _iso(d.data()['reviewedAt']),
          }),
          reviewedBy: d.data()['reviewedBy'] as String?,
          appVersion: d.data()['appVersion'] as String?,
        ),
    ];
  }

  @override
  Future<void> reviewReport(
    String reportId, {
    required ReportStatus status,
    String? rejectReason,
    String? auditId,
  }) async {
    final me = _me;
    final batch = _db.batch()
      ..update(_db.doc('reports/$reportId'), {
        'status': status.name,
        'reviewedBy': me.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectReason': ?rejectReason,
        'resolutionAuditId': ?auditId,
      })
      ..set(_db.collection('audit_log').doc(), {
        'uid': me.uid,
        'email': me.email,
        'collection': 'reports',
        'docId': reportId,
        'action': 'review',
        'note': [status.name, ?rejectReason].join(': '),
        'at': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  // ---------- change log ----------

  @override
  Future<List<AuditEntry>> listAudit({
    String? collection,
    int limit = 100,
  }) async {
    Query<Json> q = _db.collection('audit_log');
    if (collection != null) q = q.where('collection', isEqualTo: collection);
    final snapshot = await q.orderBy('at', descending: true).limit(limit).get();
    return [
      for (final d in snapshot.docs)
        AuditEntry(
          id: d.id,
          uid: d.data()['uid'] as String? ?? '',
          email: d.data()['email'] as String? ?? '',
          collection: d.data()['collection'] as String? ?? '',
          docId: d.data()['docId'] as String? ?? '',
          action: d.data()['action'] as String? ?? '',
          at: switch (d.data()['at']) {
            final Timestamp t => t.toDate(),
            _ => null,
          },
          before: _plain(d.data()['before']),
          after: _plain(d.data()['after']),
          note: d.data()['note'] as String?,
        ),
    ];
  }

  @override
  Future<void> deleteAudit(String entryId) =>
      _db.doc('audit_log/$entryId').delete();

  // ---------- storage ----------

  @override
  Future<String> uploadImage(String storagePath, Uint8List bytes) async {
    final ref = _storage.ref(storagePath);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  // ---------- helpers ----------

  static String? _iso(Object? v) =>
      v is Timestamp ? v.toDate().toUtc().toIso8601String() : null;

  static Json _clean(Json data) => {
    for (final MapEntry(:key, :value) in data.entries)
      if (!serverFields.contains(key)) key: _plain(value),
  };

  static Object? _plain(Object? value) => switch (value) {
    final Timestamp t => t.toDate().toUtc().toIso8601String(),
    final Map<String, Object?> m => {
      for (final MapEntry(:key, :value) in m.entries) key: _plain(value),
    },
    final List<Object?> l => [for (final v in l) _plain(v)],
    _ => value,
  };
}
