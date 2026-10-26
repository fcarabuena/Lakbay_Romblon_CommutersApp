import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';
import 'package:lakbayromblon/features/planner/application/planner_providers.dart';

import '../helpers.dart';

Json advisory({
  String id = 'adv1',
  String severity = 'suspended',
  List<String> voyages = const [],
  List<String> ports = const [],
  String validFrom = '2026-10-20T00:00:00Z',
  String? validUntil,
}) => {
  'id': id,
  'type': 'coastGuard',
  'severity': severity,
  'title': {'en': 'Sailing suspended', 'fil': 'Suspendido ang biyahe'},
  'message': {'en': 'Gale warning. No trips until further notice.'},
  'validFrom': validFrom,
  'validUntil': validUntil,
  'source': 'Test notice',
  'affectedVoyageIds': voyages,
  'affectedPortIds': ports,
};

void main() {
  final firstVoyage = RoutePlanner(seedData())
      .plan(odionganToCubao)
      .first
      .shipLegs
      .first
      .voyageId!;

  group('Advisory banner', () {
    testWidgets('is hidden when there are no advisories', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('advisoryBanner')), findsNothing);
    });

    testWidgets('shows on Plan, Schedules and Guide but not Safety', (
      tester,
    ) async {
      await pumpApp(
        tester,
        data: seedDataWith({
          'advisories': [advisory()],
        }),
      );
      expect(find.byKey(const Key('advisoryBanner')), findsOneWidget);
      expect(find.text('Suspended: Sailing suspended'), findsOneWidget);

      await tester.tap(find.text('Schedules'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('advisoryBanner')), findsOneWidget);

      await tester.tap(find.text('Safety'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('advisoryBanner')), findsNothing);
    });

    testWidgets('an ended advisory leaves the banner but is still listed', (
      tester,
    ) async {
      await pumpApp(
        tester,
        data: seedDataWith({
          'advisories': [
            advisory(
              validFrom: '2026-10-22T00:00:00Z',
              validUntil: '2026-10-23T00:00:00Z',
            ),
          ],
        }),
        location: '/advisories',
      );
      expect(find.text('Recently ended'), findsOneWidget);
      expect(find.byKey(const Key('advisory-adv1')), findsOneWidget);
      expect(find.text('In effect now'), findsNothing);
    });

    testWidgets('opens the list, then the detail with its source', (
      tester,
    ) async {
      await pumpApp(
        tester,
        data: seedDataWith({
          'advisories': [
            advisory(),
            advisory(
              id: 'adv2',
              severity: 'info',
              validFrom: '2026-10-21T00:00:00Z',
            ),
          ],
        }),
      );
      expect(find.textContaining('+1 more'), findsOneWidget);
      await tester.tap(find.byKey(const Key('advisoryBanner')));
      await tester.pumpAndSettle();
      expect(find.text('In effect now'), findsOneWidget);
      expect(
        find.text(
          'Always confirm with the Coast Guard or shipping line before travelling.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('advisory-adv1')));
      await tester.pumpAndSettle();
      expect(
        find.text('Gale warning. No trips until further notice.'),
        findsOneWidget,
      );
      expect(find.text('Test notice'), findsOneWidget);
      expect(find.text('Until further notice'), findsOneWidget);
      expect(find.text('All sea trips in Romblon'), findsOneWidget);
    });

    testWidgets('shows Tagalog titles in Tagalog', (tester) async {
      await pumpApp(
        tester,
        data: seedDataWith({
          'advisories': [advisory()],
        }),
        settings: const AppSettings(languageCode: 'fil'),
      );
      expect(find.text('Suspendido: Suspendido ang biyahe'), findsOneWidget);
    });
  });

  group('Results and advisories', () {
    testWidgets('affected plans are flagged and can be avoided', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        location: '/plan/results',
        request: odionganToCubao,
        data: seedDataWith({
          'advisories': [
            advisory(voyages: [firstVoyage]),
          ],
        }),
      );
      final before = container.read(planResultsProvider);
      final affected = before
          .where((p) => p.shipLegs.any((l) => l.voyageId == firstVoyage))
          .length;
      expect(affected, greaterThan(0));
      expect(
        find.text('Some trips are affected by an advisory.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('planAdvisory-adv1')), findsWidgets);

      await tester.tap(find.byKey(const Key('avoidAdvisories')));
      await tester.pumpAndSettle();
      final after = container.read(planResultsProvider);
      expect(after.length, before.length - affected);
      expect(
        after.every((p) => p.shipLegs.every((l) => l.voyageId != firstVoyage)),
        isTrue,
      );
      expect(find.byKey(const Key('planAdvisory-adv1')), findsNothing);
    });

    testWidgets('a province-wide advisory cannot be avoided', (tester) async {
      await pumpApp(
        tester,
        location: '/plan/results',
        request: odionganToCubao,
        data: seedDataWith({
          'advisories': [advisory()],
        }),
      );
      expect(find.byKey(const Key('avoidAdvisories')), findsNothing);
      expect(find.textContaining('no way around it'), findsOneWidget);
    });

    testWidgets('an info notice is flagged but nothing is avoided', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: '/plan/results',
        request: odionganToCubao,
        data: seedDataWith({
          'advisories': [
            advisory(severity: 'info', voyages: [firstVoyage]),
          ],
        }),
      );
      expect(find.byKey(const Key('planAdvisory-adv1')), findsWidgets);
      expect(find.byKey(const Key('avoidAdvisories')), findsNothing);
    });

    testWidgets('plan detail shows the warning and opens the advisory', (
      tester,
    ) async {
      final plan = RoutePlanner(seedData()).plan(odionganToCubao).first;
      await pumpApp(
        tester,
        location: planLocation('/plan/detail', plan.id),
        request: odionganToCubao,
        data: seedDataWith({
          'advisories': [
            advisory(voyages: [firstVoyage]),
          ],
        }),
      );
      await tester.tap(find.byKey(const Key('planAdvisory-adv1')));
      await tester.pumpAndSettle();
      expect(find.text('Test notice'), findsOneWidget);
    });
  });

  group('Tide colours', () {
    Material bannerMaterial(WidgetTester tester, Key key) =>
        tester.widget<Material>(
          find
              .ancestor(of: find.byKey(key), matching: find.byType(Material))
              .first,
        );

    testWidgets('a suspension banner is red, with an icon and a bold word', (
      tester,
    ) async {
      await pumpApp(
        tester,
        data: seedDataWith({
          'advisories': [advisory()],
        }),
      );
      final material = bannerMaterial(tester, const Key('advisoryBanner'));
      expect(material.color, const Color(0xFFFEF3F2));
      expect((material.shape! as Border).bottom.color, const Color(0xFFF4B4AD));
      expect(find.byIcon(Icons.block), findsOneWidget);
      final text = tester.widget<Text>(
        find.text('Suspended: Sailing suspended'),
      );
      expect(text.style!.color, const Color(0xFF9A1C12));
      expect(text.style!.fontWeight, FontWeight.w700);
    });

    testWidgets('a caution warning on a trip is amber', (tester) async {
      await pumpApp(
        tester,
        location: '/plan/results',
        request: odionganToCubao,
        data: seedDataWith({
          'advisories': [
            advisory(severity: 'caution', voyages: [firstVoyage]),
          ],
        }),
      );
      final material = bannerMaterial(tester, const Key('planAdvisory-adv1'));
      expect(material.color, const Color(0xFFFFF6DB));
    });

    testWidgets('the main button on the planner is island green', (
      tester,
    ) async {
      await pumpApp(tester);
      await scrollTo(tester, find.byKey(const Key('findRoutes')));
      final button = find.byKey(const Key('findRoutes'));
      final material = tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)).first,
      );
      expect(material.color, const Color(0xFF1F7A4D));
    });
  });
}
