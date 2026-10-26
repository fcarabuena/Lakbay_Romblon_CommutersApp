import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../advisories/presentation/advisory_widgets.dart';
import '../application/planner_providers.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plans = ref.watch(planResultsProvider);
    final sort = ref.watch(routeSortProvider);
    final avoiding = ref.watch(avoidAdvisoriesProvider);
    final avoid = ref.watch(plannerAvoidProvider);
    final anyAffected = ref
        .watch(allPlanResultsProvider)
        .any((p) => ref.watch(planAdvisoriesProvider(p)).isNotEmpty);

    String sortLabel(RouteSort s) => switch (s) {
      RouteSort.cheapest => l10n.sortCheapest,
      RouteSort.fastest => l10n.sortFastest,
      RouteSort.fewestTransfers => l10n.sortFewestTransfers,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.sortLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in RouteSort.values)
                ChoiceChip(
                  key: Key('sort-${s.name}'),
                  label: Text(sortLabel(s)),
                  selected: s == sort,
                  onSelected: (_) =>
                      ref.read(routeSortProvider.notifier).set(s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (anyAffected || avoiding) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Notice(l10n.resultsAdvisoryNotice, tone: NoticeTone.warning),
                  if (avoid.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.resultsCannotAvoid),
                    )
                  else
                    SwitchListTile(
                      key: const Key('avoidAdvisories'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.resultsAvoidAdvisories),
                      value: avoiding,
                      onChanged: (v) =>
                          ref.read(avoidAdvisoriesProvider.notifier).set(v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (plans.isEmpty)
            Notice(
              avoiding ? l10n.noRoutesAvoiding : l10n.noRoutes,
              tone: NoticeTone.warning,
            )
          else
            for (final plan in plans) ...[
              _PlanCard(plan: plan),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final theme = Theme.of(context);
    final ship = plan.shipLegs.first;
    final line = data.line(data.voyage(ship.voyageId!)?.lineId ?? '');
    final lastShip = plan.shipLegs.last;
    final advisories = ref.watch(planAdvisoriesProvider(plan));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('plan-${plan.id}'),
        onTap: () => context.push(
          Uri(
            path: '/plan/detail',
            queryParameters: {'id': plan.id},
          ).toString(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.viaPorts(
                  placeName(data, ship.fromId),
                  placeName(data, lastShip.toId),
                ),
                style: theme.textTheme.titleMedium,
              ),
              if (line != null)
                Text(line.name, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [for (final leg in plan.legs) LegIcon(leg, size: 28)],
              ),
              const SizedBox(height: 8),
              AmountRow(
                l10n.totalCost,
                formatPesoRange(plan.fare.total),
                emphasize: true,
              ),
              AmountRow(
                l10n.totalTime,
                formatDurationRange(l10n, plan.time.total),
              ),
              AmountRow(l10n.transfersCount(plan.transfers), ''),
              const SizedBox(height: 4),
              VerifiedBadge(plan.weakestVerification),
              if (advisories.isNotEmpty) ...[
                const SizedBox(height: 8),
                PlanAdvisoryWarning(advisories),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
