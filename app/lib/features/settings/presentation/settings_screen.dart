import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/settings_controller.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/languages.dart';
import '../../alerts/application/alerts_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    String? status(TranslationStatus s) => switch (s) {
      TranslationStatus.complete => null,
      TranslationStatus.draft => l10n.translationDraft,
      TranslationStatus.untranslated => l10n.translationInProgress,
    };

    Widget option({
      required Key key,
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) => ListTile(
      key: key,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      selected: selected,
      trailing: selected
          ? const Icon(Icons.check_circle)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: l10n.languageLabel,
            child: Column(
              children: [
                option(
                  key: const Key('lang-system'),
                  title: l10n.languageSystem,
                  selected: settings.languageCode == null,
                  onTap: () => controller.setLanguage(null),
                ),
                for (final lang in appLanguages)
                  option(
                    key: Key('lang-${lang.code}'),
                    title: lang.name,
                    subtitle: status(lang.status),
                    selected: settings.languageCode == lang.code,
                    onTap: () => controller.setLanguage(lang.code),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.textSizeLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<double>(
                  segments: [
                    for (final (scale, label) in [
                      (textScaleOptions[0], l10n.textSizeNormal),
                      (textScaleOptions[1], l10n.textSizeLarge),
                      (textScaleOptions[2], l10n.textSizeExtraLarge),
                    ])
                      ButtonSegment(
                        value: scale,
                        label: Text(label, key: Key('textScale-$scale')),
                      ),
                  ],
                  selected: {settings.textScale},
                  onSelectionChanged: (s) => controller.setTextScale(s.first),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.textSizePreview,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _DataSection(),
          if (ref.watch(alertsServiceProvider) != null) ...[
            const SizedBox(height: 16),
            const _AlertsSection(),
          ],
        ],
      ),
    );
  }
}

/// When the data was last refreshed from the server, with a refresh button.
class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sync = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final last = sync.lastSyncAt;

    Future<void> refresh() async {
      final messenger = ScaffoldMessenger.of(context);
      final outcome = await controller.syncNow();
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (outcome) {
            SyncOutcome.updated => l10n.syncUpdated,
            SyncOutcome.upToDate => l10n.syncUpToDate,
            SyncOutcome.notConfigured => l10n.syncNotConfigured,
            SyncOutcome.failed => l10n.syncFailed,
          }),
        ),
      );
    }

    return SectionCard(
      title: l10n.dataTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            last == null
                ? l10n.dataNeverUpdated
                : l10n.dataLastUpdated(formatDateTime(l10n, last)),
            key: const Key('lastSync'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (sync.lastOutcome == SyncOutcome.failed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Notice(l10n.syncFailed, tone: NoticeTone.warning),
            ),
          const SizedBox(height: 12),
          if (controller.isAvailable)
            OutlinedButton.icon(
              key: const Key('syncNow'),
              onPressed: sync.running ? null : refresh,
              icon: sync.running
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l10n.syncNow),
            )
          else
            Text(l10n.syncNotConfigured),
        ],
      ),
    );
  }
}

/// Opt-in push alerts for caution and suspension advisories.
class _AlertsSection extends ConsumerWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(alertsControllerProvider);
    final controller = ref.read(alertsControllerProvider.notifier);
    final ports = ref
        .watch(travelDataProvider)
        .ports
        .where((p) => p.side == PortSide.romblon)
        .toList();

    Future<void> run(Future<AlertChangeResult> Function() change) async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await change();
      final message = switch (result) {
        AlertChangeResult.done => null,
        AlertChangeResult.permissionDenied => l10n.alertsPermissionDenied,
        AlertChangeResult.failed => l10n.alertsFailed,
      };
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }

    return SectionCard(
      title: l10n.alertsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('alertsEnabled'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.alertsEnable),
            subtitle: Text(l10n.alertsExplain),
            value: prefs.enabled,
            onChanged: (on) => run(() => controller.setEnabled(on)),
          ),
          if (prefs.enabled) ...[
            RadioGroup<bool>(
              groupValue: prefs.allPorts,
              onChanged: (all) {
                if (all == true) run(controller.setAllPorts);
                if (all == false && ports.isNotEmpty) {
                  run(() => controller.togglePort(ports.first.id, on: true));
                }
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    key: const Key('alertsAll'),
                    contentPadding: EdgeInsets.zero,
                    value: true,
                    title: Text(l10n.alertsAllRomblon),
                  ),
                  RadioListTile<bool>(
                    key: const Key('alertsPorts'),
                    contentPadding: EdgeInsets.zero,
                    value: false,
                    title: Text(l10n.alertsChosenPorts),
                  ),
                ],
              ),
            ),
            if (!prefs.allPorts)
              for (final port in ports)
                CheckboxListTile(
                  key: Key('alertPort-${port.id}'),
                  title: Text(port.name),
                  value: prefs.portIds.contains(port.id),
                  onChanged: (on) => run(
                    () => controller.togglePort(port.id, on: on ?? false),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
