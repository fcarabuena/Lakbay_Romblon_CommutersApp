import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/data/user_repositories.dart';
import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../advisories/presentation/advisory_widgets.dart';
import '../../planner/application/planner_providers.dart';

final savedTripsProvider = FutureProvider<List<SavedTrip>>(
  (ref) => ref.watch(savedTripsRepositoryProvider).all(),
);

/// Active advisories for a saved trip's plan (recomputed from its request).
final savedTripAdvisoriesProvider = Provider.autoDispose
    .family<List<Advisory>, SavedTrip>((ref, trip) {
      final plan = ref
          .watch(routePlannerProvider)
          .plan(trip.request)
          .where((p) => p.id == trip.planId)
          .firstOrNull;
      if (plan == null) return const [];
      final now = ref.watch(clockProvider)();
      return advisoriesForPlan(
        plan,
        ref.watch(travelDataProvider),
        advisoryCheckTime(trip.request, now),
      );
    });

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trips = ref.watch(savedTripsProvider);

    void open(SavedTrip trip) {
      ref.read(tripRequestProvider.notifier).set(trip.request);
      context.go(
        Uri(
          path: '/plan/detail',
          queryParameters: {'id': trip.planId},
        ).toString(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripsTitle)),
      body: switch (trips) {
        AsyncData(:final value) when value.isEmpty => Padding(
          padding: const EdgeInsets.all(16),
          child: Notice(l10n.noTrips),
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final trip = value[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text(trip.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDateTime(
                        l10n,
                        trip.request.departure ?? trip.createdAt,
                      ),
                    ),
                    PlanAdvisoryWarning(
                      ref.watch(savedTripAdvisoriesProvider(trip)),
                    ),
                  ],
                ),
                onTap: () => open(trip),
                trailing: IconButton(
                  tooltip: l10n.deleteTrip,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref
                        .read(savedTripsRepositoryProvider)
                        .delete(trip.id);
                    ref.invalidate(savedTripsProvider);
                  },
                ),
              ),
            );
          },
        ),
        AsyncError() => Padding(
          padding: const EdgeInsets.all(16),
          child: Notice(l10n.loadError, tone: NoticeTone.error),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
