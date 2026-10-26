import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../application/reports_controller.dart';

/// "Report an update" link shown on fares, schedules, guides and hotlines.
class ReportButton extends StatelessWidget {
  const ReportButton({
    super.key,
    required this.collection,
    required this.id,
    required this.label,
  });

  final String collection;
  final String id;
  final String label;

  static String location({
    String collection = '',
    String id = '',
    String label = '',
  }) => Uri(
    path: '/report',
    queryParameters: {
      if (collection.isNotEmpty) 'collection': collection,
      if (id.isNotEmpty) 'id': id,
      if (label.isNotEmpty) 'label': label,
    },
  ).toString();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      key: Key('report-$collection-$id'),
      onPressed: () =>
          context.push(location(collection: collection, id: id, label: label)),
      icon: const Icon(Icons.flag_outlined),
      label: Text(context.l10n.reportUpdate),
    ),
  );
}

String reportKindLabel(BuildContext context, ReportKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    ReportKind.fareChange => l10n.reportKindFare,
    ReportKind.scheduleChange => l10n.reportKindSchedule,
    ReportKind.delayOrCancellation => l10n.reportKindDelay,
    ReportKind.wrongInfo => l10n.reportKindWrong,
    ReportKind.other => l10n.reportKindOther,
  };
}

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    super.key,
    this.collection = '',
    this.targetId = '',
    this.label = '',
  });

  final String collection;
  final String targetId;
  final String label;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _suggested = TextEditingController();
  final _note = TextEditingController();
  late ReportKind _kind = switch (widget.collection) {
    'ship_fares' || 'bus_routes' || 'local_rides' => ReportKind.fareChange,
    'voyages' => ReportKind.scheduleChange,
    _ => ReportKind.wrongInfo,
  };
  bool _sending = false;
  List<String> _problems = const [];

  @override
  void dispose() {
    _suggested.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final report = CommunityReport(
      id: 'draft',
      kind: _kind,
      targetCollection: widget.collection,
      targetId: widget.targetId,
      targetLabel: widget.label.length > ReportLimits.maxLabel
          ? widget.label.substring(0, ReportLimits.maxLabel)
          : widget.label,
      submittedAt: ref.read(clockProvider)().toUtc(),
      suggestedValue: _suggested.text.trim(),
      note: _note.text.trim(),
      language: context.languageCode,
    );
    final problems = report.problems();
    setState(() => _problems = problems);
    if (problems.isNotEmpty) return;

    setState(() => _sending = true);
    final controller = ref.read(reportsControllerProvider.notifier);
    final sent = await controller.submit(report);
    if (!mounted) return;
    final limit =
        ref.read(reportsControllerProvider).value?.limitReached ?? false;
    final message = sent
        ? l10n.reportSent
        : limit
        ? l10n.reportLimit
        : l10n.reportQueued;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    // Opened as the first page there is nothing to go back to.
    context.canPop() ? context.pop() : context.go('/more/reports');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.label.isNotEmpty) ...[
            Text(l10n.reportAbout, style: theme.textTheme.labelLarge),
            Text(widget.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
          ],
          Text(l10n.reportWhat, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in ReportKind.values)
                ChoiceChip(
                  key: Key('reportKind-${kind.name}'),
                  label: Text(reportKindLabel(context, kind)),
                  selected: kind == _kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('reportSuggested'),
            controller: _suggested,
            maxLength: ReportLimits.maxSuggested,
            decoration: InputDecoration(
              labelText: l10n.reportSuggested,
              hintText: l10n.reportSuggestedHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('reportNote'),
            controller: _note,
            maxLength: ReportLimits.maxNote,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n.reportNote,
              hintText: l10n.reportNoteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_problems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Notice(l10n.reportNeedsText, tone: NoticeTone.error),
          ],
          const SizedBox(height: 8),
          Notice(l10n.reportPrivacy, icon: Icons.privacy_tip_outlined),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('reportSubmit'),
            onPressed: _sending ? null : _submit,
            icon: const Icon(Icons.send),
            label: Text(l10n.reportSend),
          ),
        ],
      ),
    );
  }
}

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final controller = ref.read(reportsControllerProvider.notifier);
    await controller.flush();
    await controller.refreshStatuses();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(reportsControllerProvider);

    Widget tile(CommunityReport r, {required bool waiting}) {
      final (label, tone) = waiting
          ? (l10n.reportStatusWaiting, NoticeTone.info)
          : switch (r.status) {
              ReportStatus.pending => (
                l10n.reportStatusPending,
                NoticeTone.info,
              ),
              ReportStatus.approved => (
                l10n.reportStatusApproved,
                NoticeTone.success,
              ),
              ReportStatus.rejected => (
                l10n.reportStatusRejected,
                NoticeTone.warning,
              ),
            };
      return Card(
        key: Key('myReport-${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                r.targetLabel.isEmpty
                    ? reportKindLabel(context, r.kind)
                    : r.targetLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${reportKindLabel(context, r.kind)} · '
                '${formatDateTime(l10n, r.submittedAt.toLocal())}',
              ),
              if (r.suggestedValue.isNotEmpty) Text('→ ${r.suggestedValue}'),
              const SizedBox(height: 8),
              Notice(label, tone: tone),
              if (r.rejectReason != null && r.rejectReason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.reportRejectReason(r.rejectReason!)),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myReportsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newReport'),
        onPressed: () => context.push(ReportButton.location()),
        icon: const Icon(Icons.flag_outlined),
        label: Text(l10n.reportUpdate),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: switch (state) {
          AsyncData(:final value) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (value.limitReached) ...[
                Notice(l10n.reportLimit, tone: NoticeTone.warning),
                const SizedBox(height: 8),
              ],
              if (value.outbox.isEmpty && value.sent.isEmpty)
                Notice(l10n.myReportsNone),
              for (final r in value.outbox) tile(r, waiting: true),
              for (final r in value.sent) tile(r, waiting: false),
            ],
          ),
          AsyncError() => ListView(
            padding: const EdgeInsets.all(16),
            children: [Notice(l10n.loadError, tone: NoticeTone.error)],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
