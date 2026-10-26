import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_admin/src/backend/admin_backend.dart';
import 'package:lakbay_admin/src/backend/dataset.dart';
import 'package:lakbay_admin/src/photos/photo_upload_dialog.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'fake_backend.dart';

void main() {
  final seed = seedDataset();
  final fareId = seed.rows['ship_fares']!.keys.first;

  String editorPath(String collection, String id, {String? report}) => Uri(
    path: '/data/$collection/${Uri.encodeComponent(id)}',
    queryParameters: report == null ? null : {'report': report},
  ).toString();

  Future<void> setField(WidgetTester tester, String path, String text) async {
    final field = find.byKey(ValueKey('field-$path'));
    await scrollTo(tester, field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await scrollTo(tester, find.byKey(const Key('save')));
    await tester.tap(find.byKey(const Key('save')));
    await tester.pumpAndSettle();
  }

  group('sign-in', () {
    testWidgets('signed out shows the login form', (tester) async {
      await pumpAdmin(tester, FakeAdminBackend());
      expect(find.byKey(const Key('signIn')), findsOneWidget);
    });

    testWidgets('a wrong password is refused', (tester) async {
      await pumpAdmin(tester, FakeAdminBackend());
      await tester.enterText(find.byKey(const Key('email')), 'a@example.com');
      await tester.enterText(find.byKey(const Key('password')), 'wrong');
      await tester.tap(find.byKey(const Key('signIn')));
      await tester.pumpAndSettle();
      expect(find.text('Wrong email or password.'), findsOneWidget);
    });

    testWidgets('an account that is not staff is turned away', (tester) async {
      await pumpAdmin(tester, FakeAdminBackend());
      await tester.enterText(
        find.byKey(const Key('email')),
        'stranger@example.com',
      );
      await tester.enterText(find.byKey(const Key('password')), 'right');
      await tester.tap(find.byKey(const Key('signIn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notStaff')), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('staff reach the dashboard', (tester) async {
      await pumpAdmin(tester, signedIn(editor));
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.byKey(const Key('tile-placeholders')), findsOneWidget);
    });
  });

  group('roles', () {
    testWidgets('editors do not see Users; admins do', (tester) async {
      await pumpAdmin(tester, signedIn(editor));
      expect(find.byKey(const Key('nav-/users')), findsNothing);
      await pumpAdmin(tester, signedIn(admin));
      expect(find.byKey(const Key('nav-/users')), findsOneWidget);
    });

    testWidgets('an editor opening /users is refused', (tester) async {
      await pumpAdmin(tester, signedIn(editor), location: '/users');
      expect(find.text('Only admins can manage users.'), findsOneWidget);
    });

    testWidgets('only admins can delete change-log entries', (tester) async {
      final backend = signedIn(editor);
      await backend.save(
        const AuditedWrite(
          collection: 'ports',
          docId: 'p',
          auditId: 'x',
          before: null,
          after: {'id': 'p'},
        ),
      );
      await pumpAdmin(tester, backend, location: '/audit');
      await tester.tap(find.byKey(const Key('audit-a0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deleteAudit-a0')), findsNothing);

      final adminBackend = signedIn(admin);
      await adminBackend.save(
        const AuditedWrite(
          collection: 'ports',
          docId: 'p',
          auditId: 'x',
          before: null,
          after: {'id': 'p'},
        ),
      );
      await pumpAdmin(tester, adminBackend, location: '/audit');
      await tester.tap(find.byKey(const Key('audit-a0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deleteAudit-a0')), findsOneWidget);
    });

    testWidgets('admins add users', (tester) async {
      final backend = signedIn(admin);
      await pumpAdmin(tester, backend, location: '/users');
      await tester.tap(find.byKey(const Key('addUser')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('newUserEmail')),
        'new@example.com',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmAddUser')));
      await tester.pumpAndSettle();
      expect(backend.staff['uid-new@example.com']?.role, StaffRole.editor);
      expect(find.text('new@example.com'), findsOneWidget);
    });
  });

  group('editing', () {
    testWidgets('a saved change stays a placeholder unless verified', (
      tester,
    ) async {
      final backend = signedIn(editor);
      await pumpAdmin(
        tester,
        backend,
        location: editorPath('ship_fares', fareId),
      );
      await setField(tester, 'farePhp', '777');
      await save(tester);

      final write = backend.saves.single;
      expect(write.after!['farePhp'], 777);
      expect(write.before!['farePhp'], isNot(777));
      expect(write.action, 'update');
      final v = Verification.fromJson(write.after!['verification'] as Json?);
      expect(v.isPlaceholder, isTrue);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('ticking "verified" with a source stamps it', (tester) async {
      final backend = signedIn(editor);
      await pumpAdmin(
        tester,
        backend,
        location: editorPath('ship_fares', fareId),
      );
      await setField(tester, 'farePhp', '777');
      await scrollTo(tester, find.byKey(const Key('verificationSource')));
      await tester.enterText(
        find.byKey(const Key('verificationSource')),
        'Ticket office, 1 Nov',
      );
      await tester.tap(find.byKey(const Key('verifiedCheckbox')));
      await tester.pumpAndSettle();
      await save(tester);

      final v = Verification.fromJson(
        backend.saves.single.after!['verification'] as Json?,
      );
      expect(v.isPlaceholder, isFalse);
      expect(v.source, 'Ticket office, 1 Nov');
      expect(v.verifiedBy, editor.uid);
      expect(v.lastVerified, DateTime(2026, 11, 1));
    });

    testWidgets('verifying without a source is refused', (tester) async {
      final backend = signedIn(editor);
      await pumpAdmin(
        tester,
        backend,
        location: editorPath('ship_fares', fareId),
      );
      await scrollTo(tester, find.byKey(const Key('verifiedCheckbox')));
      await tester.tap(find.byKey(const Key('verifiedCheckbox')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.textContaining('Say where you verified it'), findsOneWidget);
      expect(backend.saves, isEmpty);
    });

    testWidgets('invalid input blocks saving', (tester) async {
      final backend = signedIn(editor);
      await pumpAdmin(
        tester,
        backend,
        location: editorPath('ship_fares', fareId),
      );
      await setField(tester, 'farePhp', '0');
      await save(tester);
      expect(find.byKey(const Key('saveProblems')), findsOneWidget);
      expect(
        find.textContaining('the fare must be more than zero'),
        findsOneWidget,
      );
      expect(backend.saves, isEmpty);

      await setField(tester, 'farePhp', 'abc');
      expect(find.textContaining('Enter pesos only'), findsOneWidget);
      await save(tester);
      expect(backend.saves, isEmpty);
    });

    testWidgets(
      'publishing an advisory shows a preview and stamps publishedAt',
      (tester) async {
        final backend = signedIn(editor);
        await pumpAdmin(tester, backend, location: '/data/advisories/new');
        await setField(tester, 'title-en', 'Trips suspended');
        expect(find.text('Caution: Trips suspended'), findsOneWidget);
        await setField(tester, 'message-en', 'Gale warning from PAGASA.');
        await setField(tester, 'source', 'PCG Romblon bulletin');
        await save(tester);

        final write = backend.saves.single;
        expect(write.collection, 'advisories');
        expect(write.after!['publishedAt'], '2026-11-01T12:00:00+08:00');
        expect(write.after!['validFrom'], '2026-11-01T12:00:00+08:00');
        expect(Advisory.fromJson(write.after!).isProvinceWide, isTrue);
      },
    );

    testWidgets('deleting is a soft delete after confirmation', (tester) async {
      final backend = signedIn(editor);
      final hotlineId = seed.rows['hotlines']!.keys.first;
      await pumpAdmin(
        tester,
        backend,
        location: editorPath('hotlines', hotlineId),
      );
      await scrollTo(tester, find.byKey(const Key('delete')));
      await tester.tap(find.byKey(const Key('delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pumpAndSettle();
      expect(backend.saves.single.action, 'delete');
      expect(backend.saves.single.after, isNull);
    });
  });

  group('photos', () {
    final guideId = seed.rows['guides']!.keys.first;
    Future<PickedFile?> picker() async =>
        (name: 'pier.jpg', bytes: Uint8List.fromList([1, 2, 3]));

    Future<void> openUpload(
      WidgetTester tester,
      FakeAdminBackend backend,
    ) async {
      await pumpAdmin(
        tester,
        backend,
        location: editorPath('guides', guideId),
        picker: picker,
        photoUploads: true,
      );
      await scrollTo(tester, find.byKey(const Key('addPhoto')));
      await tester.tap(find.byKey(const Key('addPhoto')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pickPhoto')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('captionEn')),
        'Ticket windows',
      );
      await tester.enterText(
        find.byKey(const Key('credit')),
        'Juan, Lakbay team',
      );
      await tester.pumpAndSettle();
    }

    bool uploadEnabled(WidgetTester tester) =>
        tester
            .widget<FilledButton>(find.byKey(const Key('uploadPhoto')))
            .onPressed !=
        null;

    testWidgets('upload needs both permission checks', (tester) async {
      final backend = signedIn(editor);
      await openUpload(tester, backend);
      expect(uploadEnabled(tester), isFalse);
      await tester.tap(find.byKey(const Key('confirmPermission')));
      await tester.pumpAndSettle();
      expect(uploadEnabled(tester), isFalse);
      await tester.tap(find.byKey(const Key('confirmNoFaces')));
      await tester.pumpAndSettle();
      expect(uploadEnabled(tester), isTrue);
    });

    testWidgets('an uploaded photo is saved with the guide', (tester) async {
      final backend = signedIn(editor);
      await openUpload(tester, backend);
      await tester.tap(find.byKey(const Key('confirmPermission')));
      await tester.tap(find.byKey(const Key('confirmNoFaces')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('uploadPhoto')));
      await tester.pumpAndSettle();
      expect(backend.uploads.keys.single, startsWith('guides/$guideId/photo-'));
      expect(find.text('Ticket windows'), findsOneWidget);

      await save(tester);
      final photo =
          (backend.saves.single.after!['photos']! as List<Object?>).last!
              as Json;
      expect(photo['url'], startsWith('https://'));
      expect(photo['credit'], 'Juan, Lakbay team');
      expect(photo['permissionConfirmed'], isTrue);
      expect(photo['noFacesConfirmed'], isTrue);
      expect(photo['uploadedBy'], editor.uid);
      final parsed = Guide.fromJson(backend.saves.single.after!).photos.last;
      expect(parsed.caption!.en, 'Ticket windows');
    });
  });

  group('reports', () {
    final report = CommunityReport(
      id: 'r1',
      kind: ReportKind.fareChange,
      targetCollection: 'ship_fares',
      targetId: fareId,
      targetLabel: 'A → B, economy',
      submittedAt: DateTime.utc(2026, 10, 31),
      suggestedValue: '₱777',
    );

    testWidgets('opening a report in the editor approves it on save', (
      tester,
    ) async {
      final backend = signedIn(editor)..reports = [ReportItem(report: report)];
      await pumpAdmin(tester, backend, location: '/reports');
      expect(find.text('Suggested: ₱777'), findsOneWidget);
      await tester.tap(find.byKey(const Key('openEditor-r1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reportContext')), findsOneWidget);

      await setField(tester, 'farePhp', '777');
      await save(tester);
      expect(backend.saves.single.reportId, 'r1');
      expect(backend.reviews.single.status, ReportStatus.approved);
      expect(backend.reviews.single.auditId, backend.saves.single.auditId);
    });

    testWidgets('rejecting records the reason', (tester) async {
      final backend = signedIn(editor)..reports = [ReportItem(report: report)];
      await pumpAdmin(tester, backend, location: '/reports');
      await tester.tap(find.byKey(const Key('reject-r1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('rejectReason')),
        'Fare unchanged',
      );
      await tester.tap(find.byKey(const Key('confirmReject')));
      await tester.pumpAndSettle();
      expect(backend.reviews.single.status, ReportStatus.rejected);
      expect(backend.reviews.single.reason, 'Fare unchanged');
      expect(find.text('Nothing to review.'), findsOneWidget);
    });
  });

  group('starter data', () {
    testWidgets('an empty project explains what to do', (tester) async {
      await pumpAdmin(
        tester,
        signedIn(
          admin,
          data: Dataset(meta: {}, rows: {}),
        ),
      );
      expect(
        find.text('The app has no travel information yet'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('addOwn')), findsOneWidget);
      for (final step in ['ports', 'shipping_lines', 'voyages', 'hotlines']) {
        expect(find.byKey(Key('step-$step')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('addOwn')));
      await tester.pumpAndSettle();
      expect(find.text('New port'), findsOneWidget);
    });

    testWidgets('admins load it into an empty project', (tester) async {
      final backend = signedIn(
        admin,
        data: Dataset(meta: {}, rows: {}),
      );
      await pumpAdmin(tester, backend);
      await tester.tap(find.byKey(const Key('importStarter')));
      await tester.pumpAndSettle();
      expect(backend.saves.length, greaterThan(100));
      expect(find.byKey(const Key('tile-placeholders')), findsOneWidget);
    });
  });
}
