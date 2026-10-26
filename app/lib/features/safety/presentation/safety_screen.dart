import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/services/device_services.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../planner/application/planner_providers.dart';
import '../../reports/presentation/report_screens.dart';

/// Emergency numbers, a "show this to staff" card and safety tips.
/// Everything here works offline.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final request = ref.watch(tripRequestProvider);
    final lang = context.languageCode;
    final hometown = request?.municipalityId;

    List<Hotline> scope(HotlineScope s) =>
        data.hotlines.where((h) => h.scope == s).toList();
    final national = scope(HotlineScope.national);
    final emergency = national
        .where((h) => h.numbers.contains('911'))
        .firstOrNull;
    final towns = [...data.municipalities]
      ..sort((a, b) => a.name.compareTo(b.name));
    if (hometown != null) {
      // The traveller's own town first.
      towns.sort(
        (a, b) =>
            (a.id == hometown ? 0 : 1).compareTo(b.id == hometown ? 0 : 1),
      );
    }
    final ports = [...data.ports]..sort((a, b) => a.name.compareTo(b.name));

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );

    Widget tips(TipCategory category, String title) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading(title),
        for (final tip in data.safetyTips.where((t) => t.category == category))
          Card(
            child: ExpansionTile(
              key: Key('tip-${tip.id}'),
              leading: Icon(switch (category) {
                TipCategory.scam => Icons.report_gmailerrorred,
                TipCategory.safety => Icons.health_and_safety_outlined,
                TipCategory.cancellation => Icons.event_busy,
              }),
              title: Text(tip.title.resolve(lang)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  tip.body.resolve(lang),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (emergency != null) _EmergencyCard(hotline: emergency),
          const SizedBox(height: 16),
          _SosCard(request: request),
          heading(l10n.hotlinesTitle),
          _HotlineGroup(
            title: l10n.hotlinesNational,
            hotlines: national,
            initiallyExpanded: true,
          ),
          _HotlineGroup(
            title: l10n.hotlinesProvince,
            hotlines: scope(HotlineScope.province),
          ),
          for (final port in ports)
            _HotlineGroup(
              title: '${l10n.hotlinesPorts}: ${port.name}',
              hotlines: scope(HotlineScope.port)
                  .where((h) => h.portId == port.id)
                  .toList(),
            ),
          for (final town in towns)
            _HotlineGroup(
              key: Key('town-${town.id}'),
              title: town.id == hometown
                  ? '${l10n.hotlinesYourTown}: ${town.name}'
                  : '${l10n.hotlinesTowns}: ${town.name}',
              hotlines: scope(HotlineScope.municipality)
                  .where((h) => h.municipalityId == town.id)
                  .toList(),
              initiallyExpanded: town.id == hometown,
            ),
          tips(TipCategory.scam, l10n.scamTitle),
          tips(TipCategory.safety, l10n.safetyTipsTitle),
          tips(TipCategory.cancellation, l10n.cancellationTitle),
        ],
      ),
    );
  }
}

Future<void> _call(BuildContext context, WidgetRef ref, String number) async {
  final ok = await ref.read(dialerProvider)(number);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.callFailed)));
  }
}

class _EmergencyCard extends ConsumerWidget {
  const _EmergencyCard({required this.hotline});

  final Hotline hotline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.emergencyCallout,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('call-911'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => _call(context, ref, '911'),
              icon: const Icon(Icons.call),
              label: Text(l10n.callNumber('911')),
            ),
            if (hotline.verification.isPlaceholder) ...[
              const SizedBox(height: 8),
              Text(
                l10n.hotlineUnverified,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SosCard extends ConsumerWidget {
  const _SosCard({required this.request});

  final TripRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final r = request;
    return SectionCard(
      title: l10n.sosTitle,
      child: r == null
          ? Text(l10n.sosNoTrip)
          : Text(
              l10n.sosBody(
                placeName(data, r.originId, request: r),
                placeName(data, r.destinationId, request: r),
              ),
              key: const Key('sosBody'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
    );
  }
}

class _HotlineGroup extends StatelessWidget {
  const _HotlineGroup({
    super.key,
    required this.title,
    required this.hotlines,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Hotline> hotlines;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (hotlines.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ExpansionTile(
        title: Text(title),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [for (final h in hotlines) _HotlineTile(hotline: h)],
      ),
    );
  }
}

class _HotlineTile extends ConsumerWidget {
  const _HotlineTile({required this.hotline});

  final Hotline hotline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hotline.agency, style: theme.textTheme.titleMedium),
          Text(hotline.label.resolve(context.languageCode)),
          const SizedBox(height: 6),
          if (!hotline.hasNumber)
            Text(
              l10n.numberNeeded,
              key: Key('needed-${hotline.id}'),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final number in hotline.numbers)
                  FilledButton.tonalIcon(
                    key: Key('call-${hotline.id}-$number'),
                    onPressed: () => _call(context, ref, number),
                    icon: const Icon(Icons.call),
                    label: Text(l10n.callNumber(number)),
                  ),
              ],
            ),
          if (hotline.hasNumber && hotline.verification.isPlaceholder)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.hotlineUnverified,
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (hotline.verification.isVerified)
            VerifiedBadge(hotline.verification),
          ReportButton(
            collection: 'hotlines',
            id: hotline.id,
            label: '${hotline.agency}: ${hotline.label.en}',
          ),
        ],
      ),
    );
  }
}
