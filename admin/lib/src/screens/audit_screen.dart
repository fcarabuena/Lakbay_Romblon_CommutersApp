import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../backend/admin_backend.dart';
import '../editing/collection_specs.dart';
import '../editing/delete_flow.dart';
import '../state/providers.dart';

final _date = DateFormat('d MMM y, HH:mm');
const _pretty = JsonEncoder.withIndent('  ');

/// The change log: who changed what, when, with before and after values.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  String? _collection;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(auditProvider(_collection));
    final isAdmin = ref.watch(currentStaffProvider).isAdmin;
    final theme = Theme.of(context);

    Future<void> restore(AuditEntry entry) async {
      final messenger = ScaffoldMessenger.of(context);
      final problem = await restoreFromLog(ref, entry);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            problem ?? 'Restored. Phones get it back at their next update.',
          ),
        ),
      );
    }

    Future<void> delete(String id) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete this log entry?'),
          content: const Text(
            'This cannot be undone. Only do this for entries that must not be kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(backendProvider).deleteAudit(id);
      ref.invalidate(auditProvider);
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Change log', style: theme.textTheme.headlineSmall),
        const Text(
          'Every save is recorded here. Editors cannot change or delete entries.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 320,
          child: DropdownButtonFormField<String?>(
            initialValue: _collection,
            decoration: const InputDecoration(
              labelText: 'Show',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(child: Text('Everything')),
              for (final s in collectionSpecs)
                DropdownMenuItem(value: s.collection, child: Text(s.title)),
              const DropdownMenuItem(
                value: 'reports',
                child: Text('Report reviews'),
              ),
              const DropdownMenuItem(value: 'admins', child: Text('Users')),
            ],
            onChanged: (v) => setState(() => _collection = v),
          ),
        ),
        const SizedBox(height: 12),
        switch (entries) {
          AsyncData(value: final list) when list.isEmpty => const Text(
            'No changes yet.',
          ),
          AsyncData(value: final list) => Column(
            children: [
              for (final e in list)
                Card(
                  key: Key('audit-${e.id}'),
                  child: ExpansionTile(
                    title: Text('${e.action} · ${e.collection}/${e.docId}'),
                    subtitle: Text(
                      '${e.email} · ${e.at == null ? '' : _date.format(e.at!.toLocal())}'
                      '${e.note == null ? '' : ' · ${e.note}'}',
                    ),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e.before != null) ...[
                        const Text('Before'),
                        SelectableText(_pretty.convert(e.before)),
                      ],
                      if (e.after != null) ...[
                        const SizedBox(height: 8),
                        const Text('After'),
                        SelectableText(_pretty.convert(e.after)),
                      ],
                      if (isAdmin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (e.action == 'delete' && e.before != null)
                                FilledButton.icon(
                                  key: Key('restore-${e.id}'),
                                  onPressed: () => restore(e),
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Restore'),
                                ),
                              TextButton.icon(
                                key: Key('deleteAudit-${e.id}'),
                                onPressed: () => delete(e.id),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete entry'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          AsyncError(:final error) => Text('Could not load the log: $error'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}
