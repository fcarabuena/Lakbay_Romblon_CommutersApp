import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbay_ui/lakbay_ui.dart';

import '../state/providers.dart';
import 'collection_specs.dart';
import 'delete_flow.dart';
import 'edit_logic.dart';

class CollectionListScreen extends ConsumerStatefulWidget {
  const CollectionListScreen({super.key, required this.collection});

  final String collection;

  @override
  ConsumerState<CollectionListScreen> createState() =>
      _CollectionListScreenState();
}

class _CollectionListScreenState extends ConsumerState<CollectionListScreen> {
  String _query = '';
  bool _needsWorkOnly = false;

  @override
  Widget build(BuildContext context) {
    final spec = specFor(widget.collection);
    if (spec == null) return const Center(child: Text('Unknown data type'));
    final data = ref.watch(datasetProvider).value;
    if (data == null) return const Center(child: CircularProgressIndicator());
    final now = ref.watch(clockProvider)();
    final theme = Theme.of(context);

    final entries = [
      for (final MapEntry(key: id, value: item)
          in data.rows[spec.collection]!.entries)
        (
          id: id,
          item: item,
          title: spec.titleOf(item, data),
          state: verificationState(spec, item, now),
        ),
    ]..sort((a, b) => a.title.compareTo(b.title));
    final q = _query.toLowerCase();
    final shown = entries.where((e) {
      if (q.isNotEmpty &&
          !e.title.toLowerCase().contains(q) &&
          !e.id.toLowerCase().contains(q)) {
        return false;
      }
      return !_needsWorkOnly ||
          e.state == VerificationState.placeholder ||
          e.state == VerificationState.stale;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addItem'),
        onPressed: () => context.go('/data/${spec.collection}/new'),
        icon: const Icon(Icons.add),
        label: Text(
          spec.collection == 'advisories'
              ? 'New advisory'
              : 'Add ${spec.singular}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        children: [
          Text(spec.title, style: theme.textTheme.headlineSmall),
          if (spec.collection == 'hotlines') ...[
            const SizedBox(height: 8),
            const Text(
              'Checklist (docs/hotlines-to-verify.md): only enter numbers you confirmed by '
              'calling or from an official notice, then tick "I verified" when saving.',
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  key: const Key('search'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (spec.verificationKey != null)
                FilterChip(
                  key: const Key('needsWork'),
                  label: const Text('Not checked yet, or needs re-checking'),
                  selected: _needsWorkOnly,
                  onSelected: (v) => setState(() => _needsWorkOnly = v),
                ),
              Text('${shown.length} of ${entries.length}'),
            ],
          ),
          const SizedBox(height: 12),
          for (final e in shown)
            Card(
              child: ListTile(
                key: Key('row-${e.id}'),
                title: Text(e.title),
                subtitle: Text(
                  spec.collection == 'advisories'
                      ? _advisoryStatus(e.item, now)
                      : spec.collection == 'hotlines'
                      ? _hotlineStatus(e.item, e.state)
                      : e.id,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StateChip(e.state, checkedOn: _checkedOn(spec, e.item)),
                    IconButton(
                      key: Key('deleteRow-${e.id}'),
                      tooltip: 'Delete ${e.title}',
                      color: Theme.of(context).colorScheme.error,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          confirmAndDelete(context, ref, spec, e.id),
                    ),
                  ],
                ),
                onTap: () => context.go(
                  '/data/${spec.collection}/${Uri.encodeComponent(e.id)}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _advisoryStatus(Json item, DateTime now) {
    try {
      final a = Advisory.fromJson(item);
      if (a.hasEndedAt(now)) return 'Ended';
      if (a.isActiveAt(now)) {
        return 'In effect · from ${isoToManilaInput(item['validFrom']! as String)}';
      }
      return 'Starts ${isoToManilaInput(item['validFrom']! as String)}';
    } on Object {
      return 'Check this advisory';
    }
  }

  static String _hotlineStatus(Json item, VerificationState state) {
    final numbers = (item['numbers'] as List<Object?>? ?? const []);
    if (numbers.isEmpty) return 'Number needed';
    return '${numbers.join(', ')} · ${state == VerificationState.verified ? 'checked' : 'not checked yet'}';
  }
}

DateTime? _checkedOn(CollectionSpec spec, Json item) {
  final key = spec.verificationKey;
  return key == null
      ? null
      : Verification.fromJson(item[key] as Json?).lastVerified;
}

String _day(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.state, {this.checkedOn});

  final DateTime? checkedOn;

  final VerificationState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final caution = AdvisoryColors.of(context).caution;
    final (label, bg, fg) = switch (state) {
      VerificationState.none => (null, null, null),
      VerificationState.placeholder => (
        'Not checked yet',
        caution.background,
        caution.foreground,
      ),
      VerificationState.stale => (
        'Needs re-checking',
        caution.background,
        caution.foreground,
      ),
      VerificationState.verified => (
        checkedOn == null ? 'Checked' : 'Checked ${_day(checkedOn!)}',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };
    if (label == null) return const SizedBox.shrink();
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bg,
    );
  }
}
