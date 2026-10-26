import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/data/user_repositories.dart';
import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../trips/presentation/trips_screen.dart';
import '../../advisories/presentation/advisory_widgets.dart';
import '../application/planner_providers.dart';

/// Step-by-step timeline of one plan with totals and next actions.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  Future<void> _save(BuildContext context, WidgetRef ref, TripPlan plan) async {
    final request = ref.read(tripRequestProvider)!;
    final data = ref.read(travelDataProvider);
    final now = ref.read(clockProvider)();
    final name =
        '${placeName(data, request.originId, request: request)} → '
        '${placeName(data, request.destinationId, request: request)}';
    await ref
        .read(savedTripsRepositoryProvider)
        .save(
          SavedTrip(
            id: '${now.microsecondsSinceEpoch}',
            name: name,
            request: request,
            planId: plan.id,
            createdAt: now,
          ),
        );
    ref.invalidate(savedTripsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.tripSaved)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plan = ref.watch(planByIdProvider(planId));
    final request = ref.watch(tripRequestProvider);

    if (plan == null || request == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.planDetailTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Notice(l10n.planNotFound, tone: NoticeTone.warning),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/plan'),
                child: Text(l10n.planAgain),
              ),
            ],
          ),
        ),
      );
    }

    final idQuery = {'id': plan.id};
    final advisories = ref.watch(planAdvisoriesProvider(plan));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.planDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final a in advisories) ...[
            PlanAdvisoryWarning([a]),
            const SizedBox(height: 8),
          ],
          _TotalsCard(plan: plan, request: request),
          const SizedBox(height: 12),
          if (plan.hasPlaceholders) ...[
            Notice(l10n.warningPlaceholder, tone: NoticeTone.warning),
            const SizedBox(height: 8),
          ],
          if (!plan.time.schedulesApplied) ...[
            Notice(l10n.warningNoSchedule),
            const SizedBox(height: 8),
          ],
          if (plan.hasMissingEstimates) ...[
            Notice(l10n.warningMissingEstimate, tone: NoticeTone.warning),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < plan.legs.length; i++)
            LegCard(key: Key('leg-$i'), plan: plan, index: i, request: request),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('startFirstTimer'),
            onPressed: () => context.push(
              Uri(
                path: '/plan/first-timer',
                queryParameters: idQuery,
              ).toString(),
            ),
            icon: const Icon(Icons.checklist),
            label: Text(l10n.startFirstTimer),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('checkBudget'),
            onPressed: () => context.push(
              Uri(path: '/plan/budget', queryParameters: idQuery).toString(),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text(l10n.checkBudget),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('saveTrip'),
            onPressed: () => _save(context, ref, plan),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l10n.saveTrip),
          ),
        ],
      ),
    );
  }
}

/// The trip summary on marine blue: route, total cost, door-to-door time and
/// number of rides.
class _TotalsCard extends ConsumerWidget {
  const _TotalsCard({required this.plan, required this.request});

  final TripPlan plan;
  final TripRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final on = scheme.onPrimary;
    final time = plan.time;
    return Card(
      key: const Key('tripSummary'),
      color: scheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${placeName(data, request.originId, request: request)} → '
              '${placeName(data, request.destinationId, request: request)}',
              style: text.titleLarge?.copyWith(color: on),
            ),
            Text(
              l10n.travellerCount(request.travellers.total),
              style: text.bodyMedium?.copyWith(color: on),
            ),
            const SizedBox(height: 8),
            AmountRow(
              l10n.totalCost,
              formatPesoRange(plan.fare.total),
              emphasize: true,
              color: on,
            ),
            AmountRow(
              l10n.totalFare,
              formatPesoRange(plan.fare.fares),
              color: on,
            ),
            AmountRow(l10n.totalFees, formatPesos(plan.fare.fees), color: on),
            Divider(color: on.withValues(alpha: 0.3)),
            AmountRow(
              l10n.totalTime,
              formatDurationRange(l10n, time.total),
              emphasize: true,
              color: on,
            ),
            if (time.arriveEarliest != null && time.arriveLatest != null)
              Text(
                l10n.arrivalWindow(
                  formatDateTime(l10n, time.arriveEarliest!),
                  formatDateTime(l10n, time.arriveLatest!),
                ),
                style: text.bodyMedium?.copyWith(color: on),
              ),
            AmountRow(l10n.transfersCount(plan.transfers), '', color: on),
          ],
        ),
      ),
    );
  }
}

class LegCard extends ConsumerWidget {
  const LegCard({
    super.key,
    required this.plan,
    required this.index,
    this.request,
  });

  final TripPlan plan;
  final int index;
  final TripRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final theme = Theme.of(context);
    final leg = plan.legs[index];
    final timing = plan.time.legs[index];
    final fare = plan.fare.perLeg[index];
    final voyage = leg.voyageId == null ? null : data.voyage(leg.voyageId!);
    final line = voyage == null ? null : data.line(voyage.lineId);
    final route = leg.busRouteId == null
        ? null
        : data.busRoutes.where((r) => r.id == leg.busRouteId).firstOrNull;
    final operator = route == null ? null : data.busOperator(route.operatorId);
    final stops = intermediateStops(data, leg);

    // The amount itself is shown on the right of the title.
    final fareText = leg.estimateMissing
        ? l10n.noEstimate
        : fare.max == 0
        ? l10n.freeLeg
        : [
            if (!leg.perPerson) l10n.perTripFare,
            if (leg.kind == LegKind.custom) l10n.yourEstimate,
          ].join(' · ');

    final details = <String>[
      if (line != null) '${line.name} · ${voyage!.vesselName}',
      if (leg.fareClass != null) fareClassLabel(l10n, leg.fareClass!),
      if (operator != null) operator.name,
      if (stops.isNotEmpty) l10n.stopsAt(stops.join(', ')),
      if (timing.departEarliest != null)
        l10n.departsAt(formatDateTime(l10n, timing.departEarliest!)),
      if (timing.wait.max > 0)
        l10n.waitTime(formatDurationRange(l10n, timing.wait)),
      if (leg.schedule case FixedDeparture(:final checkInMinutes))
        l10n.checkInNote(checkInMinutes),
      if (leg.feePerPerson > 0) l10n.feeIncluded(formatPesos(leg.feePerPerson)),
      if (leg.note != null) leg.note!.resolve(context.languageCode),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegIcon(leg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}. ${legTitle(l10n, data, leg, request: request)}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          leg.estimateMissing || fare.max == 0
                              ? ''
                              : formatPesoRange(fare),
                          key: Key('legFare-$index'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (fareText.isNotEmpty) fareText,
                        formatDurationRange(l10n, leg.duration),
                        if (leg.timeEstimated) l10n.timeEstimateSuffix,
                      ].join(' · ').replaceAll(' · (', ' ('),
                      style: theme.textTheme.bodyLarge,
                    ),
                    for (final d in details)
                      Text(d, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    VerifiedBadge(leg.verification),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
