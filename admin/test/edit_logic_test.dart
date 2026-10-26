import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lakbay_admin/src/backend/admin_backend.dart';
import 'package:lakbay_admin/src/editing/collection_specs.dart';
import 'package:lakbay_admin/src/editing/edit_logic.dart';
import 'package:lakbay_admin/src/photos/photo_processing.dart';
import 'package:lakbay_admin/src/screens/dashboard_screen.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'fake_backend.dart';

void main() {
  final data = seedDataset();
  final fareSpec = specFor('ship_fares')!;
  final fareId = data.rows['ship_fares']!.keys.first;
  final fare = data.rows['ship_fares']![fareId]!;
  final today = DateTime.utc(2026, 11, 1, 4);

  group('verification', () {
    test('ticking "verified" stamps the date, source and editor', () {
      final item = stampVerification(
        {...fare, 'farePhp': 700},
        key: 'verification',
        before: fare,
        verified: true,
        source: 'Called the ticket office',
        uid: 'uid1',
        today: today,
      );
      expect(item['verification'], {
        'source': 'Called the ticket office',
        'isPlaceholder': false,
        'lastVerified': '2026-11-01',
        'verifiedBy': 'uid1',
      });
    });

    test('a change without ticking it is a placeholder again', () {
      final verifiedFare = {
        ...fare,
        'verification': {
          'source': 'Field check',
          'isPlaceholder': false,
          'lastVerified': '2026-10-01',
        },
      };
      final item = stampVerification(
        {...verifiedFare, 'farePhp': 700},
        key: 'verification',
        before: verifiedFare,
        verified: false,
        source: 'Field check',
        uid: 'uid1',
        today: today,
      );
      expect(
        Verification.fromJson(item['verification'] as Json?).isPlaceholder,
        isTrue,
      );
    });

    test('an untouched verified value stays verified', () {
      final verifiedFare = {
        ...fare,
        'verification': {
          'source': 'Field check',
          'isPlaceholder': false,
          'lastVerified': '2026-10-01',
        },
      };
      final item = stampVerification(
        verifiedFare,
        key: 'verification',
        before: verifiedFare,
        verified: false,
        source: 'Field check',
        uid: 'uid1',
        today: today,
      );
      expect(item['verification'], verifiedFare['verification']);
    });
  });

  group('checkEdit', () {
    test('accepts a valid fare change', () {
      final check = checkEdit(
        spec: fareSpec,
        data: data,
        existingId: fareId,
        draft: {...fare, 'farePhp': 720},
      );
      expect(check.problems, isEmpty);
      expect(check.docId, fareId);
    });

    test('blocks a negative or zero fare the app would reject', () {
      final check = checkEdit(
        spec: fareSpec,
        data: data,
        existingId: fareId,
        draft: {...fare, 'farePhp': 0},
      );
      expect(check.problems.join(), contains('fare must be positive'));
    });

    test('blocks references to things that do not exist', () {
      final check = checkEdit(
        spec: fareSpec,
        data: data,
        existingId: null,
        draft: {...fare, 'voyageId': 'ghost'},
      );
      expect(check.problems.join(), contains('unknown voyage'));
    });

    test('blocks a voyage with only one stop', () {
      final spec = specFor('voyages')!;
      final id = data.rows['voyages']!.keys.first;
      final voyage = deepCopy(data.rows['voyages']![id]!);
      voyage['stops'] = [(voyage['stops']! as List<Object?>).first];
      final check = checkEdit(
        spec: spec,
        data: data,
        existingId: id,
        draft: voyage,
      );
      expect(
        check.problems,
        contains('Stops, from first to last: add at least 2'),
      );
    });

    test('new items need a free, well-formed id', () {
      final spec = specFor('hotlines')!;
      final existing = data.rows['hotlines']!.values.first;
      expect(
        checkEdit(
          spec: spec,
          data: data,
          existingId: null,
          draft: {...existing},
        ).problems.single,
        startsWith('Another hotline already uses'),
      );
      expect(
        checkEdit(
          spec: spec,
          data: data,
          existingId: null,
          draft: {...existing, 'id': 'Bad ID'},
        ).problems.single,
        startsWith('ID must be'),
      );
    });

    test('required fields are named', () {
      final spec = specFor('advisories')!;
      final check = checkEdit(
        spec: spec,
        data: data,
        existingId: null,
        draft: {'id': 'adv1', 'type': 'weather'},
      );
      expect(
        check.problems,
        containsAll(['How serious is it? is required', 'Source is required']),
      );
    });

    test('deleting a voyage that fares use is blocked', () {
      final voyageId = fare['voyageId']! as String;
      expect(
        checkDelete(specFor('voyages')!, data, voyageId).join(),
        contains('unknown voyage'),
      );
    });
  });

  group('Philippine time', () {
    test('round-trips input and ISO', () {
      expect(manilaInputToIso('2026-11-01 14:30'), '2026-11-01T14:30:00+08:00');
      expect(isoToManilaInput('2026-11-01T06:30:00Z'), '2026-11-01 14:30');
      expect(manilaInputToIso('2026-02-30 10:00'), isNull);
      expect(manilaInputToIso('tomorrow'), isNull);
      expect(
        nowManilaIso(DateTime.utc(2026, 11, 1, 4)),
        '2026-11-01T12:00:00+08:00',
      );
    });
  });

  group('AuditedWrite', () {
    test('logs before and after, and soft-deletes', () {
      const user = AdminUser(uid: 'u1', email: 'u@example.com');
      final update = AuditedWrite(
        collection: 'ports',
        docId: 'p1',
        auditId: 'a1',
        before: {'id': 'p1'},
        after: {'id': 'p1', 'name': 'New'},
      );
      expect(update.action, 'update');
      expect(update.documentFields('u1'), {
        'id': 'p1',
        'name': 'New',
        'updatedBy': 'u1',
        'auditId': 'a1',
      });
      expect(update.auditFields(user)['before'], {'id': 'p1'});

      final delete = AuditedWrite(
        collection: 'ports',
        docId: 'p1',
        auditId: 'a2',
        before: {'id': 'p1'},
        after: null,
      );
      expect(delete.action, 'delete');
      expect(delete.documentFields('u1')['deleted'], isTrue);
      expect(delete.auditFields(user)['after'], isNull);

      final create = AuditedWrite(
        collection: 'ports',
        docId: 'p2',
        auditId: 'a3',
        before: null,
        after: {'id': 'p2'},
      );
      expect(create.action, 'create');
    });
  });

  group('starter data', () {
    test('every seed item becomes one audited write with a unique id', () {
      var n = 0;
      final writes = starterWrites(loadSeed(), () => 'a${n++}');
      final docCount = data.rows.values.fold(0, (sum, r) => sum + r.length);
      expect(writes, hasLength(docCount + 1));
      expect(
        writes.map((w) => '${w.collection}/${w.docId}').toSet(),
        hasLength(writes.length),
      );
      expect(writes.map((w) => w.auditId).toSet(), hasLength(writes.length));
      expect(writes.first.after!.containsKey('_note'), isFalse);
    });

    test('the bundled copy matches the app seed', () {
      for (final f in Directory(
        '../app/assets/data',
      ).listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        expect(
          File('assets/seed/$name').readAsStringSync(),
          f.readAsStringSync(),
          reason: '$name is out of date: run dart run tool/copy_seed.dart',
        );
      }
    });
  });

  group('preparePhoto', () {
    test('shrinks, recompresses and drops location data', () {
      final rnd = Random(1);
      final big = img.Image(width: 2400, height: 1600);
      for (final p in big) {
        p
          ..r = rnd.nextInt(256)
          ..g = (p.x ~/ 10) % 256
          ..b = (p.y ~/ 10) % 256;
      }
      big.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(12, 1);
      final jpeg = img.encodeJpg(big, quality: 95);
      expect(jpeg.length, greaterThan(PhotoLimits.maxBytes));

      final prepared = preparePhoto(Uint8List.fromList(jpeg));
      expect(prepared.bytes.length, lessThanOrEqualTo(PhotoLimits.maxBytes));
      expect(prepared.width, PhotoLimits.maxSide);
      expect(prepared.height, 853);
      final back = img.decodeJpg(prepared.bytes)!;
      expect(back.exif.gpsIfd.isEmpty, isTrue);
    });

    test('rejects files that are not images', () {
      expect(
        () => preparePhoto(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    });
  });
}
