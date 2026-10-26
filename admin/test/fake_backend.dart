import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_admin/src/app.dart';
import 'package:lakbay_admin/src/backend/admin_backend.dart';
import 'package:lakbay_admin/src/backend/dataset.dart';
import 'package:lakbay_admin/src/editing/editor_screen.dart';
import 'package:lakbay_admin/src/editing/map_picker.dart';
import 'package:lakbay_admin/src/photos/photo_processing.dart';
import 'package:lakbay_admin/src/photos/photo_upload_dialog.dart';
import 'package:lakbay_admin/src/state/providers.dart';
import 'package:lakbay_core/lakbay_core.dart';

/// The starter data bundled with the panel (tests run from the admin folder).
Map<String, Object?> loadSeed() => {
  for (final name in TravelData.collections)
    name: jsonDecode(File('assets/seed/$name.json').readAsStringSync()),
};

Dataset seedDataset() {
  final seed = loadSeed();
  return Dataset(
    meta: seed['meta']! as Json,
    rows: {
      for (final c in travelCollections)
        c: {
          for (final (i, item)
              in ((seed[c] as Json?)?.objects('items') ?? const <Json>[])
                  .indexed)
            TravelData.documentId(c, item, i): item,
        },
    },
  );
}

/// An in-memory backend that records every write.
class FakeAdminBackend implements AdminBackend {
  FakeAdminBackend({
    Dataset? data,
    this.signedInAs,
    Map<String, StaffMember>? staff,
  }) : data = data ?? seedDataset(),
       staff = staff ?? {};

  Dataset data;
  AdminUser? signedInAs;
  final Map<String, StaffMember> staff;
  final saves = <AuditedWrite>[];
  final reviews =
      <({String id, ReportStatus status, String? reason, String? auditId})>[];
  final uploads = <String, Uint8List>{};
  final deletedAudit = <String>[];
  List<ReportItem> reports = [];
  final _auth = StreamController<AdminUser?>.broadcast();

  @override
  Stream<AdminUser?> authChanges() async* {
    yield signedInAs;
    yield* _auth.stream;
  }

  @override
  AdminUser? get currentUser => signedInAs;

  @override
  Future<void> signIn(String email, String password) async {
    if (password != 'right') throw Exception('wrong password');
    signedInAs = AdminUser(uid: 'uid-$email', email: email);
    _auth.add(signedInAs);
  }

  @override
  Future<void> signOut() async {
    signedInAs = null;
    _auth.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<StaffMember?> staffRecord(String uid) async => staff[uid];

  @override
  Future<List<StaffMember>> listStaff() async => staff.values.toList();

  @override
  Future<StaffMember> addStaff({
    required String email,
    required StaffRole role,
    String? existingUid,
  }) async {
    final member = StaffMember(
      uid: existingUid ?? 'uid-$email',
      email: email,
      role: role,
    );
    staff[member.uid] = member;
    return member;
  }

  @override
  Future<void> setRole(String uid, StaffRole role) async =>
      staff[uid] = StaffMember(uid: uid, email: staff[uid]!.email, role: role);

  @override
  Future<void> removeStaff(String uid) async => staff.remove(uid);

  @override
  Future<Dataset> loadDataset() async => data;

  @override
  Future<void> save(AuditedWrite write) async {
    saves.add(write);
    data = data.withChange(write.collection, write.docId, write.after);
  }

  @override
  Future<void> saveAll(List<AuditedWrite> writes) async {
    for (final w in writes) {
      await save(w);
    }
  }

  @override
  Future<List<ReportItem>> listReports({required bool pendingOnly}) async => [
    for (final r in reports)
      if (!pendingOnly || r.report.status == ReportStatus.pending) r,
  ];

  @override
  Future<void> reviewReport(
    String reportId, {
    required ReportStatus status,
    String? rejectReason,
    String? auditId,
  }) async {
    reviews.add((
      id: reportId,
      status: status,
      reason: rejectReason,
      auditId: auditId,
    ));
    reports = [
      for (final r in reports)
        r.report.id == reportId
            ? ReportItem(
                report: r.report.copyWith(
                  status: status,
                  rejectReason: () => rejectReason,
                ),
              )
            : r,
    ];
  }

  @override
  Future<List<AuditEntry>> listAudit({
    String? collection,
    int limit = 100,
  }) async => [
    for (final (i, w) in saves.indexed)
      if (collection == null || w.collection == collection)
        AuditEntry(
          id: 'a$i',
          uid: signedInAs?.uid ?? '',
          email: signedInAs?.email ?? '',
          collection: w.collection,
          docId: w.docId,
          action: w.action,
          at: DateTime.utc(2026, 11, 1),
          before: w.before,
          after: w.after,
        ),
  ];

  @override
  Future<void> deleteAudit(String entryId) async => deletedAudit.add(entryId);

  @override
  Future<String> uploadImage(String storagePath, Uint8List bytes) async {
    uploads[storagePath] = bytes;
    return 'https://storage.example.com/$storagePath';
  }

  @override
  Future<void> deleteFile(String storagePath) async =>
      uploads.remove(storagePath);
}

/// Returns fixed results instead of calling OpenStreetMap.
class FakePlaceSearch implements PlaceSearch {
  FakePlaceSearch([this.results = const []]);

  final List<PlaceResult> results;
  final queries = <String>[];

  @override
  Future<List<PlaceResult>> search(String query) async {
    queries.add(query);
    return results;
  }
}

const editor = StaffMember(
  uid: 'uid-e@example.com',
  email: 'e@example.com',
  role: StaffRole.editor,
);
const admin = StaffMember(
  uid: 'uid-a@example.com',
  email: 'a@example.com',
  role: StaffRole.admin,
);

FakeAdminBackend signedIn(StaffMember member, {Dataset? data}) =>
    FakeAdminBackend(
      data: data,
      signedInAs: AdminUser(uid: member.uid, email: member.email),
      staff: {member.uid: member},
    );

/// Pumps the panel at [location] on a desktop-sized window.
Future<ProviderContainer> pumpAdmin(
  WidgetTester tester,
  FakeAdminBackend backend, {
  String location = '/',
  Future<PickedFile?> Function()? picker,
  bool photoUploads = false,
  PlaceSearch? placeSearch,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var n = 0;
  final container = ProviderContainer(
    overrides: [
      backendProvider.overrideWithValue(backend),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 1, 4)),
      idGeneratorProvider.overrideWithValue(() => 'audit-${n++}'),
      initialAdminLocationProvider.overrideWithValue(location),
      filePickerProvider.overrideWithValue(picker ?? () async => null),
      photoUploadsEnabledProvider.overrideWithValue(photoUploads),
      mapTilesEnabledProvider.overrideWithValue(false),
      placeSearchProvider.overrideWithValue(placeSearch ?? FakePlaceSearch()),
      photoPreparerProvider.overrideWithValue(
        (bytes) => PreparedPhoto(bytes, 800, 600),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AdminApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Scrolls until [finder] (already built) is on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
