import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/services/device_services.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../buses/presentation/buses_screens.dart';
import '../../reports/presentation/report_screens.dart';

/// Ships and buses in one tab.
class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.schedulesTitle),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.directions_boat_filled),
                text: l10n.tabShips,
              ),
              Tab(
                icon: const Icon(Icons.directions_bus_filled),
                text: l10n.tabBuses,
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [ShipsList(), BusRoutesList()]),
      ),
    );
  }
}

class ShipsList extends ConsumerStatefulWidget {
  const ShipsList({super.key});

  @override
  ConsumerState<ShipsList> createState() => _ShipsListState();
}

class _ShipsListState extends ConsumerState<ShipsList> {
  String? _portId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final voyages = data.voyages
        .where(
          (v) => _portId == null || v.stops.any((s) => s.portId == _portId),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _portId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.filterPort),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.allPorts)),
            for (final p in data.ports)
              DropdownMenuItem(value: p.id, child: Text(p.name)),
          ],
          onChanged: (v) => setState(() => _portId = v),
        ),
        const SizedBox(height: 16),
        if (voyages.isEmpty) Notice(l10n.noSchedules),
        for (final v in voyages) ...[
          _VoyageCard(voyage: v),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _VoyageCard extends ConsumerWidget {
  const _VoyageCard({required this.voyage});

  final Voyage voyage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final theme = Theme.of(context);
    final first = voyage.stops.first;
    final last = voyage.stops.last;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/schedules/voyage/${voyage.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.viaPorts(
                  placeName(data, first.portId),
                  placeName(data, last.portId),
                ),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${data.line(voyage.lineId)?.name ?? voyage.lineId} · ${voyage.vesselName}',
              ),
              Text(l10n.sailingDays(formatWeekdays(l10n, voyage.daysOfWeek))),
              if (first.depart != null)
                Text(l10n.departsAt(formatClock(first.depart!))),
              const SizedBox(height: 8),
              VerifiedBadge(voyage.verification),
            ],
          ),
        ),
      ),
    );
  }
}

class VoyageDetailScreen extends ConsumerWidget {
  const VoyageDetailScreen({super.key, required this.voyageId});

  final String voyageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final voyage = data.voyage(voyageId);
    final theme = Theme.of(context);
    if (voyage == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noSchedules)),
      );
    }
    final fares = data.shipFares.where((f) => f.voyageId == voyage.id).toList();

    String clock(int? minutes, int dayOffset, {bool estimated = false}) {
      if (minutes == null) {
        return voyage.timesToConfirm ? l10n.timeToConfirm : '—';
      }
      return [
        formatClock(minutes),
        if (dayOffset > 0) '(${l10n.dayLater(dayOffset)})',
        if (estimated) l10n.timeEstimateSuffix,
      ].join(' ');
    }

    final line = data.line(voyage.lineId);
    final dial = ref.read(dialerProvider);
    final open = ref.read(urlOpenerProvider);
    String priceLabel(String key) => switch (key) {
      FarePriceKey.student => l10n.passengerStudent,
      FarePriceKey.senior => l10n.passengerSenior,
      FarePriceKey.pwd => l10n.passengerPwd,
      FarePriceKey.halfFare => l10n.priceHalfFare,
      FarePriceKey.minor => l10n.priceMinor,
      FarePriceKey.infant => l10n.priceInfant,
      _ => key,
    };

    return Scaffold(
      appBar: AppBar(title: Text(line?.name ?? voyage.vesselName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(voyage.vesselName, style: theme.textTheme.titleLarge),
          Text(l10n.sailingDays(formatWeekdays(l10n, voyage.daysOfWeek))),
          Text('${l10n.checkIn}: ${l10n.checkInNote(voyage.checkInMinutes)}'),
          const SizedBox(height: 8),
          VerifiedBadge(voyage.verification),
          ReportButton(
            collection: 'voyages',
            id: voyage.id,
            label:
                '${voyage.vesselName}: ${placeName(data, voyage.stops.first.portId)} → '
                '${placeName(data, voyage.stops.last.portId)}',
          ),
          if (voyage.timesToConfirm) ...[
            Notice(l10n.timesToConfirmNotice, tone: NoticeTone.warning),
            const SizedBox(height: 8),
          ],
          if (voyage.note case final note?) ...[
            Notice(note.resolve(context.languageCode)),
            const SizedBox(height: 8),
          ],
          SectionCard(
            title: l10n.voyageStops,
            child: Column(
              children: [
                for (final stop in voyage.stops)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.anchor),
                    title: Text(placeName(data, stop.portId)),
                    subtitle: Text(
                      [
                        if (stop.arrive != null ||
                            (voyage.timesToConfirm &&
                                stop != voyage.stops.first))
                          '↓ ${clock(stop.arrive, stop.dayOffset, estimated: stop.estimated)}',
                        if (stop.depart != null ||
                            (voyage.timesToConfirm &&
                                stop != voyage.stops.last))
                          '↑ ${clock(stop.depart, stop.dayOffset, estimated: stop.estimated)}',
                      ].join('   '),
                    ),
                  ),
              ],
            ),
          ),
          if (line != null &&
              (line.phones.isNotEmpty ||
                  line.office != null ||
                  line.website != null ||
                  line.bookingUrl != null)) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: l10n.contactTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.name, style: theme.textTheme.titleSmall),
                  if (line.contactLabel != null) Text(line.contactLabel!),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final number in line.phones)
                        FilledButton.tonalIcon(
                          key: Key('callLine-$number'),
                          onPressed: () => dial(number),
                          icon: const Icon(Icons.call),
                          label: Text(l10n.callNumber(number)),
                        ),
                    ],
                  ),
                  if (line.office != null) ...[
                    const SizedBox(height: 8),
                    Text(l10n.officeLabel(line.office!)),
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      if (line.website case final url?)
                        TextButton.icon(
                          onPressed: () => open(Uri.parse(url)),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(l10n.openOfficialPage),
                        ),
                      if (line.bookingUrl case final url?)
                        TextButton.icon(
                          onPressed: () => open(Uri.parse(url)),
                          icon: const Icon(Icons.confirmation_number_outlined),
                          label: Text(l10n.openBooking),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.fareTable,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in fares) ...[
                  AmountRow(
                    '${l10n.viaPorts(placeName(data, f.fromPortId), placeName(data, f.toPortId))}\n'
                    '${fareClassLabel(l10n, f.fareClass)}',
                    f.isRoom
                        ? l10n.roomPrice(formatPesos(f.amount), f.roomFor!)
                        : formatPesos(f.amount),
                  ),
                  for (final key in FarePriceKey.all)
                    if (f.prices[key] case final price?)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: AmountRow(priceLabel(key), formatPesos(price)),
                      ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: VerifiedBadge(f.verification),
                  ),
                  if (f.pricesVerification case final pv?)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(l10n.discountPricesLabel),
                            VerifiedBadge(pv),
                          ],
                        ),
                      ),
                    ),
                  ReportButton(
                    collection: 'ship_fares',
                    id: TravelData.documentId('ship_fares', {
                      'voyageId': f.voyageId,
                      'fromPortId': f.fromPortId,
                      'toPortId': f.toPortId,
                      'fareClass': f.fareClass,
                    }),
                    label:
                        '${placeName(data, f.fromPortId)} → ${placeName(data, f.toPortId)}, '
                        '${fareClassLabel(l10n, f.fareClass)}',
                  ),
                  const Divider(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
