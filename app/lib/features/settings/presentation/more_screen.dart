import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';

/// My trips, settings, privacy summary, and about / data disclaimers.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final meta = ref.watch(travelDataProvider).meta;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const Key('more-trips'),
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(l10n.myTrips),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/more/trips'),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('more-advisories'),
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(l10n.advisoriesTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/advisories'),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('more-reports'),
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(l10n.myReportsTitle),
                  subtitle: Text(l10n.myReportsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/more/reports'),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('more-settings'),
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.settingsTitle),
                  subtitle: Text(
                    '${l10n.languageLabel} · ${l10n.textSizeLabel}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/more/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.privacyTitle,
            child: Text(l10n.privacyBody, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.aboutTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.aboutBody, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 12),
                Notice(l10n.aboutDisclaimer, tone: NoticeTone.warning),
                const SizedBox(height: 12),
                Text(l10n.dataVersion(meta.dataVersion)),
                if (meta.generatedAt != null)
                  Text(l10n.dataPrepared(formatDate(l10n, meta.generatedAt!))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
