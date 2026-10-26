import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';

import '../helpers.dart';

void main() {
  final plan = RoutePlanner(seedData()).plan(odionganToCubao).first;

  group('First-Timer Mode', () {
    testWidgets('checking items advances and saves progress', (tester) async {
      final progress = MemoryChecklistProgressRepository();
      await pumpApp(
        tester,
        location: planLocation('/plan/first-timer', plan.id),
        request: odionganToCubao,
        progress: progress,
      );

      final guide = FirstTimerGuide.build(
        seedData().checklistFor(TripDirection.toManila)!,
        plan,
      );
      expect(find.text('0 of ${guide.totalCount} done'), findsOneWidget);
      expect(find.text('You are here'), findsOneWidget);

      await tester.tap(find.byKey(const Key('check-bring_id')));
      await tester.pumpAndSettle();
      expect(find.text('1 of ${guide.totalCount} done'), findsOneWidget);
      expect(await progress.load(plan.id), {'bring_id'});

      // The plan's own legs appear as steps.
      final firstLeg = find.byKey(Key('check-leg:${plan.legs.first.id}'));
      await scrollTo(tester, firstLeg);
      expect(firstLeg, findsOneWidget);
    });

    testWidgets('restores saved progress', (tester) async {
      final progress = MemoryChecklistProgressRepository();
      await progress.setDone(plan.id, 'bring_id', done: true);
      await progress.setDone(plan.id, 'bring_cash', done: true);
      await pumpApp(
        tester,
        location: planLocation('/plan/first-timer', plan.id),
        request: odionganToCubao,
        progress: progress,
      );
      expect(find.textContaining('2 of '), findsOneWidget);
    });
  });

  group('Budget planner', () {
    Future<void> enterCash(WidgetTester tester, String pesos) async {
      await tester.enterText(find.byKey(const Key('budgetCash')), pesos);
      await tester.pumpAndSettle();
    }

    Finder status(BudgetStatus s) => find.byKey(Key('budgetStatus-${s.name}'));

    testWidgets('uses the plan and reports covered or short', (tester) async {
      await pumpApp(
        tester,
        location: planLocation('/plan/budget', plan.id),
        request: odionganToCubao,
      );
      expect(
        find.text(
          'Fares and fees come from your trip plan (higher estimate, to be safe).',
        ),
        findsOneWidget,
      );
      await scrollTo(tester, status(BudgetStatus.short));
      expect(status(BudgetStatus.short), findsOneWidget);

      await scrollTo(tester, find.byKey(const Key('budgetCash')), delta: -300);
      await enterCash(tester, '10000');
      await scrollTo(tester, status(BudgetStatus.covered));
      expect(status(BudgetStatus.covered), findsOneWidget);
      expect(find.textContaining('Left over:'), findsOneWidget);
    });

    testWidgets('without a plan, uses the typed fare estimate', (tester) async {
      await pumpApp(tester, location: '/plan/budget');
      expect(
        find.text(
          'No trip selected. Enter your own fare estimate, or plan a trip first.',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('budgetManualFares')),
        '1000',
      );
      // Needed: ₱1,000 fares + ₱150 food + ₱500 minimum buffer = ₱1,650.
      await enterCash(tester, '1200');
      await scrollTo(tester, status(BudgetStatus.tight));
      expect(status(BudgetStatus.tight), findsOneWidget);
      expect(find.text('₱1,650'), findsOneWidget);
    });
  });

  testWidgets('welcome screen leads to the planner', (tester) async {
    await pumpApp(tester, location: '/welcome');
    expect(find.text('Welcome to Lakbay Romblon'), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcomeStart')));
    await tester.pumpAndSettle();
    expect(find.text('Plan a trip'), findsOneWidget);
  });

  testWidgets('schedules tab lists sample voyages with badges', (tester) async {
    await pumpApp(tester, location: '/schedules');
    expect(find.text('Sample Shipping Line A · MV Sample Alpha'), findsWidgets);
    expect(find.text('Sample, not verified'), findsWidgets);
  });
}
