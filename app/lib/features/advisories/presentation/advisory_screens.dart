import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../application/advisory_providers.dart';
import 'advisory_widgets.dart';

class AdvisoryListScreen extends ConsumerWidget {
  const AdvisoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final all = ref.watch(advisoryListProvider);
    final active = all.where((a) => a.isActiveAt(now)).toList();
    final upcoming = all.where((a) => a.validFrom.isAfter(now)).toList();
    final ended = all.where((a) => a.hasEndedAt(now)).toList();

    List<Widget> section(String title, List<Advisory> items) => [
      if (items.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final a in items) _AdvisoryCard(advisory: a),
      ],
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advisoriesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Notice(l10n.advisoryConfirm, tone: NoticeTone.warning),
          if (all.isEmpty) ...[
            const SizedBox(height: 16),
            Notice(l10n.advisoriesNone, icon: Icons.check_circle_outline),
          ],
          ...section(l10n.advisoriesActive, active),
          ...section(l10n.advisoriesUpcoming, upcoming),
          ...section(l10n.advisoriesEnded, ended),
        ],
      ),
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  const _AdvisoryCard({required this.advisory});

  final Advisory advisory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.languageCode;
    final (bg, fg) = severityColors(context, advisory.severity);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('advisory-${advisory.id}'),
        leading: CircleAvatar(
          backgroundColor: bg,
          child: Icon(severityIcon(advisory.severity), color: fg),
        ),
        title: Text(advisory.title.resolve(lang)),
        subtitle: Text(
          '${severityLabel(context, advisory.severity)} · '
          '${l10n.advisoryFrom(formatDateTime(l10n, advisory.validFrom.toLocal()))}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/advisories/${advisory.id}'),
      ),
    );
  }
}

class AdvisoryDetailScreen extends ConsumerWidget {
  const AdvisoryDetailScreen({super.key, required this.advisoryId});

  final String advisoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.languageCode;
    final data = ref.watch(travelDataProvider);
    final now = ref.watch(clockProvider)();
    final advisory = data.advisory(advisoryId);
    final theme = Theme.of(context);

    if (advisory == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.advisoriesTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Notice(l10n.advisoryGone),
        ),
      );
    }

    final (bg, fg) = severityColors(context, advisory.severity);
    final until = advisory.validUntil;
    final voyages = [
      for (final id in advisory.affectedVoyageIds) ?data.voyage(id),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advisoriesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(severityIcon(advisory.severity), color: fg),
              label: Text(
                severityLabel(context, advisory.severity),
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
              backgroundColor: bg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            advisory.title.resolve(lang),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            advisory.message.resolve(lang),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (advisory.hasEndedAt(now))
            Notice(l10n.advisoryHasEnded, icon: Icons.history),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AmountRow(
                  l10n.advisoryValidFrom,
                  formatDateTime(l10n, advisory.validFrom.toLocal()),
                ),
                AmountRow(
                  l10n.advisoryValidUntil,
                  until == null
                      ? l10n.advisoryUntilFurtherNotice
                      : formatDateTime(l10n, until.toLocal()),
                ),
                AmountRow(l10n.advisorySource, advisory.source),
                if (advisory.publishedAt != null)
                  AmountRow(
                    l10n.advisoryPublished,
                    formatDateTime(l10n, advisory.publishedAt!.toLocal()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.advisoryAffects,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (advisory.isProvinceWide)
                  Text(l10n.advisoryAllTrips, style: theme.textTheme.bodyLarge),
                for (final id in advisory.affectedPortIds)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.anchor),
                    title: Text(placeName(data, id)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/guide/$id'),
                  ),
                for (final v in voyages)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.directions_boat_filled),
                    title: Text(
                      '${v.vesselName}: ${placeName(data, v.stops.first.portId)} → '
                      '${placeName(data, v.stops.last.portId)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/schedules/voyage/${v.id}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Notice(l10n.advisoryConfirm, tone: NoticeTone.warning),
        ],
      ),
    );
  }
}
