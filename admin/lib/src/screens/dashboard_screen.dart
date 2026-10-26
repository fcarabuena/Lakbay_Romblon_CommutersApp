import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbay_ui/lakbay_ui.dart';

import '../backend/admin_backend.dart';
import '../backend/dataset.dart';
import '../editing/collection_specs.dart';
import '../editing/edit_logic.dart';
import '../state/providers.dart';

/// Loads the starter (seed) data bundled with the panel; overridable in tests.
final seedLoaderProvider = Provider<Future<Map<String, Object?>> Function()>(
  (ref) =>
      () async => {
        for (final name in TravelData.collections)
          name: jsonDecode(
            await rootBundle.loadString('assets/seed/$name.json'),
          ),
      },
);

/// Starter-data writes for an empty project: every seed item, each with its
/// own change-log entry. Values stay marked PLACEHOLDER.
List<AuditedWrite> starterWrites(
  Map<String, Object?> seed,
  String Function() newId,
) => [
  AuditedWrite(
    collection: 'config',
    docId: 'meta',
    auditId: newId(),
    before: null,
    after: {...seed['meta']! as Json}..remove('_note'),
    note: 'Starter data import',
  ),
  for (final c in travelCollections)
    for (final (i, item)
        in ((seed[c] as Json?)?.objects('items') ?? const <Json>[]).indexed)
      AuditedWrite(
        collection: c,
        docId: TravelData.documentId(c, item, i),
        auditId: newId(),
        before: null,
        after: item,
        note: 'Starter data import',
      ),
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(datasetProvider);
    final staff = ref.watch(currentStaffProvider);
    final pending = ref.watch(reportsProvider(true)).value;
    final now = ref.watch(clockProvider)();
    final theme = Theme.of(context);

    return switch (data) {
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Dashboard', style: theme.textTheme.headlineSmall),
          Text('Signed in as ${staff.email} (${staff.role.name})'),
          const SizedBox(height: 16),
          if (value.isEmpty) _StarterData(isAdmin: staff.isAdmin),
          if (_steps.any(
            (step) => (value.rows[step.collection]?.length ?? 0) == 0,
          )) ...[
            const SizedBox(height: 16),
            _StepCards(data: value),
          ],
          if (!value.isEmpty) ...[
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _Tile(
                  key: const Key('tile-advisories'),
                  label: 'Active advisories',
                  value: '${_activeAdvisories(value, now)}',
                  onTap: () => context.go('/data/advisories'),
                ),
                _Tile(
                  key: const Key('tile-reports'),
                  label: 'Reports to review',
                  value: pending == null ? '…' : '${pending.length}',
                  onTap: () => context.go('/reports'),
                ),
                _Tile(
                  key: const Key('tile-placeholders'),
                  label: 'Not verified yet',
                  value: '${_count(value, now, VerificationState.placeholder)}',
                ),
                _Tile(
                  key: const Key('tile-stale'),
                  label: 'Verified over 90 days ago',
                  value: '${_count(value, now, VerificationState.stale)}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Needs attention', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final spec in collectionSpecs)
              if (spec.verificationKey != null)
                if (_needsWork(value, now, spec) case final n when n > 0)
                  ListTile(
                    key: Key('attention-${spec.collection}'),
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: Text(spec.title),
                    subtitle: Text('$n not verified or outdated'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/data/${spec.collection}'),
                  ),
          ],
        ],
      ),
      AsyncError(:final error) => Center(
        child: Text('Could not load data: $error'),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  static int _activeAdvisories(Dataset d, DateTime now) =>
      (d.parse()?.advisories ?? const <Advisory>[])
          .where((a) => a.isActiveAt(now))
          .length;

  static int _count(Dataset d, DateTime now, VerificationState state) => [
    for (final spec in collectionSpecs)
      for (final item in d.rows[spec.collection]!.values)
        if (verificationState(spec, item, now) == state) 1,
  ].length;

  static int _needsWork(Dataset d, DateTime now, CollectionSpec spec) =>
      d.rows[spec.collection]!.values.where((i) {
        final s = verificationState(spec, i, now);
        return s == VerificationState.placeholder ||
            s == VerificationState.stale;
      }).length;
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.displaySmall),
              Text(label),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The first things to add, in order, when starting without starter data.
const _steps = [
  (collection: 'ports', title: 'Ports', add: 'Add a port'),
  (
    collection: 'shipping_lines',
    title: 'Shipping lines',
    add: 'Add a shipping line',
  ),
  (collection: 'voyages', title: 'Voyages & fares', add: 'Add a voyage'),
  (collection: 'hotlines', title: 'Hotlines', add: 'Add a hotline'),
];

class _StepCards extends StatelessWidget {
  const _StepCards({required this.data});

  final Dataset data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final (i, step) in _steps.indexed)
          SizedBox(
            width: 240,
            child: Card(
              key: Key('step-${step.collection}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${i + 1}',
                      style: text.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(step.title, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      step.collection == 'voyages'
                          ? '${data.rows['voyages']!.length} voyages · ${data.rows['ship_fares']!.length} fares added'
                          : '${data.rows[step.collection]!.length} added',
                      style: text.bodyMedium?.copyWith(
                        fontFeatures: tabularFigures,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          context.go('/data/${step.collection}/new'),
                      icon: const Icon(Icons.add),
                      label: Text(step.add),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StarterData extends ConsumerStatefulWidget {
  const _StarterData({required this.isAdmin});

  final bool isAdmin;

  @override
  ConsumerState<_StarterData> createState() => _StarterDataState();
}

class _StarterDataState extends ConsumerState<_StarterData> {
  bool _busy = false;
  String? _error;

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final seed = await ref.read(seedLoaderProvider)();
      await ref
          .read(backendProvider)
          .saveAll(starterWrites(seed, ref.read(idGeneratorProvider)));
      await ref.read(datasetProvider.notifier).reload();
    } on Object catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('emptyDashboard'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The app has no travel information yet',
              style: text.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Start with the starter data that comes with the app, then check and correct it. '
              'Or add your own information step by step.',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: scheme.onPrimaryContainer),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starter data adds:',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('• All 17 towns of Romblon'),
                    Text('• Ports and bus terminals, with simple pier guides'),
                    Text(
                      '• Ship fares and schedules (sample ones marked "not checked yet", plus Starhorse and Starlite)',
                    ),
                    Text(
                      '• Emergency hotlines (most numbers still to be filled in)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isAdmin)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    key: const Key('importStarter'),
                    onPressed: _busy ? null : _import,
                    child: Text(_busy ? 'Loading…' : 'Load starter data'),
                  ),
                  OutlinedButton(
                    key: const Key('addOwn'),
                    onPressed: _busy
                        ? null
                        : () => context.go('/data/ports/new'),
                    child: const Text("I'll add my own"),
                  ),
                ],
              )
            else
              const Text(
                'Ask an admin to load the starter data, or add your own using the steps below.',
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Failed: $_error',
                  style: TextStyle(color: scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
