import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_admin/src/editing/collection_specs.dart';
import 'package:lakbay_admin/src/editing/delete_flow.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'fake_backend.dart';

void main() {
  final seed = seedDataset();
  final tipId = seed.rows['safety_tips']!.keys.first;
  final tip = seed.rows['safety_tips']![tipId]!;
  final tipTitle = specFor('safety_tips')!.titleOf(tip, seed);

  group('what uses an item', () {
    test('a port counts the voyages, fares and others that use it', () {
      final usages = usagesOf('ports', 'lucena_port', seed);
      final voyages = seed.rows['voyages']!.values
          .where(
            (v) => (v['stops']! as List).cast<Json>().any(
              (s) => s['portId'] == 'lucena_port',
            ),
          )
          .length;
      final fares = seed.rows['ship_fares']!.values
          .where(
            (f) =>
                f['fromPortId'] == 'lucena_port' ||
                f['toPortId'] == 'lucena_port',
          )
          .length;
      expect(usages['voyages'], voyages);
      expect(usages['ship_fares'], fares);
      expect(
        usages.containsKey('ports'),
        isFalse,
        reason: 'an item does not use itself',
      );
    });

    test('ids are only matched in fields that point to that kind of item', () {
      // The town "romblon" is not the port "romblon_port", and a voyage's
      // "lineId" never points to a town.
      final usages = usagesOf('municipalities', 'romblon', seed);
      expect(usages.containsKey('voyages'), isFalse);
      expect(usages['ports'], 1);
    });

    test('an unused item has no usages', () {
      expect(usagesOf('safety_tips', tipId, seed), isEmpty);
    });

    test('the message reads as a plain sentence', () {
      expect(
        usageMessage({'voyages': 3, 'ship_fares': 12}, 'port'),
        '3 voyages and 12 fares use this port. Delete or change those first.',
      );
      expect(
        usageMessage({'ship_fares': 1}, 'voyage'),
        '1 fare uses this voyage. Delete or change those first.',
      );
      expect(
        usageMessage({'voyages': 2, 'ship_fares': 5, 'hotlines': 1}, 'port'),
        '2 voyages, 5 fares and 1 hotline use this port. Delete or change those first.',
      );
    });
  });

  group('deleting', () {
    testWidgets(
      'a row delete asks with the name, then deletes with a logged copy',
      (tester) async {
        final backend = signedIn(editor);
        await pumpAdmin(tester, backend, location: '/data/safety_tips');
        await scrollTo(tester, find.byKey(Key('deleteRow-$tipId')));
        await tester.tap(find.byKey(Key('deleteRow-$tipId')));
        await tester.pumpAndSettle();
        expect(find.text('Delete $tipTitle?'), findsOneWidget);
        expect(
          find.textContaining('removes it from the app for everyone'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('confirmDelete')));
        await tester.pumpAndSettle();
        final write = backend.saves.single;
        expect(write.action, 'delete');
        expect(write.after, isNull);
        expect(write.before, tip, reason: 'the change log keeps a full copy');
        expect(
          write.documentFields(editor.uid)['deleted'],
          isTrue,
          reason: 'phones drop it on sync',
        );
        expect(find.byKey(Key('row-$tipId')), findsNothing);
        expect(find.text('Deleted $tipTitle'), findsOneWidget);
      },
    );

    testWidgets('Cancel deletes nothing', (tester) async {
      final backend = signedIn(editor);
      await pumpAdmin(tester, backend, location: '/data/safety_tips');
      await scrollTo(tester, find.byKey(Key('deleteRow-$tipId')));
      await tester.tap(find.byKey(Key('deleteRow-$tipId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.saves, isEmpty);
    });

    testWidgets(
      'an item other data uses is not deleted, and says what uses it',
      (tester) async {
        final backend = signedIn(editor);
        await pumpAdmin(tester, backend, location: '/data/ports');
        await scrollTo(tester, find.byKey(const Key('deleteRow-lucena_port')));
        await tester.tap(find.byKey(const Key('deleteRow-lucena_port')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('deleteBlocked')), findsOneWidget);
        final portName = specFor('ports')!
            .titleOf(seed.rows['ports']!['lucena_port']!, seed);
        expect(find.text("Can't delete $portName yet"), findsOneWidget);
        expect(
          find.textContaining(
            RegExp(
              r'\d+ voyages.*\d+ fares.*use this port\. Delete or change those first\.',
            ),
          ),
          findsOneWidget,
        );
        expect(backend.saves, isEmpty);
      },
    );

    testWidgets('the edit page has a red Delete button', (tester) async {
      final backend = signedIn(editor);
      await pumpAdmin(tester, backend, location: '/data/safety_tips/$tipId');
      final button = find.byKey(const Key('delete'));
      await scrollTo(tester, button);
      final style = tester.widget<OutlinedButton>(button).style!;
      expect(style.foregroundColor!.resolve({}), const Color(0xFFB42318));
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pumpAndSettle();
      expect(backend.saves.single.after, isNull);
      expect(
        find.text('Safety tips'),
        findsWidgets,
        reason: 'back on the list',
      );
    });
  });

  group('restoring', () {
    Future<FakeAdminBackend> deletedTip(
      WidgetTester tester, {
      required bool asAdmin,
    }) async {
      final backend = signedIn(asAdmin ? admin : editor);
      await pumpAdmin(tester, backend, location: '/data/safety_tips');
      await scrollTo(tester, find.byKey(Key('deleteRow-$tipId')));
      await tester.tap(find.byKey(Key('deleteRow-$tipId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('admins restore a deleted item from the change log', (
      tester,
    ) async {
      final backend = await deletedTip(tester, asAdmin: true);
      expect(backend.data.item('safety_tips', tipId), isNull);
      await pumpAdmin(tester, backend, location: '/audit');
      await tester.tap(find.byKey(const Key('audit-a0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-a0')));
      await tester.pumpAndSettle();
      final restore = backend.saves.last;
      expect(restore.action, 'restore');
      expect(restore.after, tip);
      expect(backend.data.item('safety_tips', tipId), tip);
      // Wait for the earlier "Deleted" message to make way.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.textContaining('Restored.'), findsOneWidget);
    });

    testWidgets('restoring twice is refused because the item is back', (
      tester,
    ) async {
      final backend = await deletedTip(tester, asAdmin: true);
      await pumpAdmin(tester, backend, location: '/audit');
      await tester.tap(find.byKey(const Key('audit-a0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-a0')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await pumpAdmin(tester, backend, location: '/audit');
      await tester.tap(find.byKey(const Key('audit-a0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-a0')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 5));
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('exists again'), findsOneWidget);
      expect(backend.saves.where((w) => w.action == 'restore'), hasLength(1));
    });

    testWidgets('editors see no Restore button', (tester) async {
      final backend = await deletedTip(tester, asAdmin: false);
      await pumpAdmin(tester, backend, location: '/audit');
      await tester.tap(find.byKey(const Key('audit-a0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('restore-a0')), findsNothing);
    });
  });
}
