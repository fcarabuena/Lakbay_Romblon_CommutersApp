import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../reports/presentation/report_screens.dart';

class BusRoutesList extends ConsumerWidget {
  const BusRoutesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final route in data.busRoutes) ...[
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/schedules/bus/${route.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.viaPorts(
                        placeName(data, route.originId),
                        route.dropOffs
                            .map((d) => placeName(data, d.placeId))
                            .join(', '),
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      data.busOperator(route.operatorId)?.name ??
                          route.operatorId,
                    ),
                    Text(_hours(l10n, route)),
                    const SizedBox(height: 8),
                    VerifiedBadge(route.verification),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

String _hours(AppLocalizations l10n, BusRoute route) => l10n.busHours(
  formatClock(route.firstTrip),
  formatClock(route.lastTrip),
  route.headwayMinutes,
);

class BusRouteDetailScreen extends ConsumerWidget {
  const BusRouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final route = data.busRoutes.where((r) => r.id == routeId).firstOrNull;
    final theme = Theme.of(context);
    if (route == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noSchedules)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.busOperator(route.operatorId)?.name ?? route.operatorId,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            placeName(data, route.originId),
            style: theme.textTheme.titleLarge,
          ),
          Text(_hours(l10n, route)),
          if (route.aircon) Text(l10n.aircon),
          const SizedBox(height: 8),
          VerifiedBadge(route.verification),
          ReportButton(
            collection: 'bus_routes',
            id: route.id,
            label:
                '${data.busOperator(route.operatorId)?.name ?? route.operatorId}: '
                '${placeName(data, route.originId)}',
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: l10n.dropOffs,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in route.dropOffs)
                  AmountRow(
                    '${placeName(data, d.placeId)}\n${formatDurationRange(l10n, d.minutes)}',
                    formatPesoRange(d.fare),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
