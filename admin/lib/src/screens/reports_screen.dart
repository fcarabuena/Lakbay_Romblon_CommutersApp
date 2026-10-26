import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../backend/admin_backend.dart';
import '../editing/collection_specs.dart';
import '../state/providers.dart';

final _date = DateFormat('d MMM y, HH:mm');

/// The review queue for traveller reports.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _pendingOnly = true;

  Future<void> _reject(ReportItem item) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject report'),
        content: TextField(
          key: const Key('rejectReason'),
          controller: reason,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Reason (shown to the traveller)',
            hintText: 'e.g. Fare confirmed unchanged with the operator',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmReject'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(backendProvider)
        .reviewReport(
          item.report.id,
          status: ReportStatus.rejected,
          rejectReason: reason.text.trim().isEmpty ? null : reason.text.trim(),
        );
    ref.invalidate(reportsProvider);
  }

  Future<void> _approveAsIs(ReportItem item) async {
    await ref
        .read(backendProvider)
        .reviewReport(item.report.id, status: ReportStatus.approved);
    ref.invalidate(reportsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider(_pendingOnly));
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Traveller reports', style: theme.textTheme.headlineSmall),
        const Text(
          'Reports never change data by themselves. Check each one, then open the '
          'editor to make (and verify) the change, or reject it.',
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('To review')),
            ButtonSegment(value: false, label: Text('All')),
          ],
          selected: {_pendingOnly},
          onSelectionChanged: (s) => setState(() => _pendingOnly = s.first),
        ),
        const SizedBox(height: 12),
        switch (reports) {
          AsyncData(value: final list) when list.isEmpty => const Text(
            'Nothing to review.',
          ),
          AsyncData(value: final list) => Column(
            children: [
              for (final item in list)
                _ReportCard(
                  item: item,
                  onReject: () => _reject(item),
                  onApproveAsIs: () => _approveAsIs(item),
                ),
            ],
          ),
          AsyncError(:final error) => Text('Could not load reports: $error'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.item,
    required this.onReject,
    required this.onApproveAsIs,
  });

  final ReportItem item;
  final VoidCallback onReject;
  final VoidCallback onApproveAsIs;

  @override
  Widget build(BuildContext context) {
    final r = item.report;
    final spec = specFor(r.targetCollection);
    final canEdit = spec != null && r.targetId.isNotEmpty;
    return Card(
      key: Key('report-${r.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.targetLabel.isEmpty ? '(general report)' : r.targetLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${r.kind.name} · ${_date.format(r.submittedAt.toLocal())} · ${r.language}'
              '${item.appVersion == null ? '' : ' · app ${item.appVersion}'}',
            ),
            if (r.suggestedValue.isNotEmpty)
              Text('Suggested: ${r.suggestedValue}'),
            if (r.note.isNotEmpty) Text('Note: ${r.note}'),
            if (r.status != ReportStatus.pending)
              Text(
                'Status: ${r.status.name}${r.rejectReason == null ? '' : ' (${r.rejectReason})'}',
              ),
            if (r.status == ReportStatus.pending) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canEdit)
                    FilledButton.icon(
                      key: Key('openEditor-${r.id}'),
                      onPressed: () => context.go(
                        Uri(
                          path:
                              '/data/${r.targetCollection}/${Uri.encodeComponent(r.targetId)}',
                          queryParameters: {'report': r.id},
                        ).toString(),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Open in editor'),
                    ),
                  OutlinedButton(
                    key: Key('approveAsIs-${r.id}'),
                    onPressed: onApproveAsIs,
                    child: const Text('Already fixed'),
                  ),
                  OutlinedButton(
                    key: Key('reject-${r.id}'),
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
