import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../advisories/presentation/advisory_widgets.dart';
import '../../planner/application/planner_providers.dart';
import '../application/checklist_progress.dart';

/// Guided checklist from home to destination, built from the traveller's plan.
class FirstTimerScreen extends ConsumerWidget {
  const FirstTimerScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final plan = ref.watch(planByIdProvider(planId));
    final request = ref.watch(tripRequestProvider);
    final template = request == null
        ? null
        : data.checklistFor(request.direction);

    if (plan == null || template == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.firstTimerTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Notice(l10n.planNotFound, tone: NoticeTone.warning),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/plan'),
                child: Text(l10n.planAgain),
              ),
            ],
          ),
        ),
      );
    }

    final guide = FirstTimerGuide.build(template, plan);
    final done =
        ref.watch(checklistProgressProvider(planId)).value ?? const <String>{};
    final controller = ref.read(checklistProgressProvider(planId).notifier);
    final current = guide.currentSection(done);
    final lang = context.languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.firstTimerTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.firstTimerProgress(
                    guide.completedCount(done),
                    guide.totalCount,
                  ),
                  key: const Key('firstTimerProgress'),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: guide.progress(done),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  semanticsLabel: l10n.firstTimerProgress(
                    guide.completedCount(done),
                    guide.totalCount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final a in ref.watch(planAdvisoriesProvider(plan))) ...[
            PlanAdvisoryWarning([a]),
            const SizedBox(height: 8),
          ],
          if (current == null) ...[
            Notice(l10n.firstTimerAllDone, tone: NoticeTone.success),
            const SizedBox(height: 12),
          ],
          for (var s = 0; s < guide.sections.length; s++) ...[
            _SectionCard(
              number: s + 1,
              section: guide.sections[s],
              isCurrent: s == current,
              done: done,
              entryTitle: (entry) => switch (entry) {
                TemplateEntry(:final item) => item.text.resolve(lang),
                LegEntry(:final leg) => legTitle(
                  l10n,
                  data,
                  leg,
                  request: request,
                ),
              },
              entrySubtitle: (entry) => switch (entry) {
                TemplateEntry(:final item) => item.detail?.resolve(lang),
                LegEntry(:final leg, :final legIndex) => [
                  if (!leg.estimateMissing)
                    formatPesoRange(plan.fare.perLeg[legIndex]),
                  formatDurationRange(l10n, leg.duration),
                ].join(' · '),
              },
              onToggle: (id, value) => controller.toggle(id, done: value),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.section,
    required this.isCurrent,
    required this.done,
    required this.entryTitle,
    required this.entrySubtitle,
    required this.onToggle,
  });

  final int number;
  final ChecklistSection section;
  final bool isCurrent;
  final Set<String> done;
  final String Function(ChecklistEntry) entryTitle;
  final String? Function(ChecklistEntry) entrySubtitle;
  final void Function(String id, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lang = context.languageCode;
    final complete = section.isComplete(done);

    return Card(
      shape: isCurrent
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 3),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: complete ? const Icon(Icons.check) : Text('$number'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.phase.title.resolve(lang),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (isCurrent) Chip(label: Text(l10n.firstTimerCurrent)),
                ],
              ),
            ),
            for (final entry in section.entries)
              CheckboxListTile(
                key: Key('check-${entry.id}'),
                value: done.contains(entry.id),
                onChanged: (v) => onToggle(entry.id, v ?? false),
                title: Text(entryTitle(entry)),
                subtitle: switch (entrySubtitle(entry)) {
                  final String text => Text(text),
                  null => null,
                },
                secondary: entry is LegEntry ? Icon(legIcon(entry.leg)) : null,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Notice(
                '${l10n.whatHappensNext}: ${section.phase.whatHappensNext.resolve(lang)}',
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
