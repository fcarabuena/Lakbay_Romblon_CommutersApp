import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../app/theme.dart';
import '../../../core/ui/formatters.dart';
import '../application/advisory_providers.dart';

/// Background, text and border for a severity: red for suspensions, amber
/// for cautions, blue for notices (from the theme's [AdvisoryColors]).
AdvisoryTone severityTone(BuildContext context, AdvisorySeverity severity) {
  final colors = AdvisoryColors.of(context);
  return switch (severity) {
    AdvisorySeverity.suspended => colors.suspended,
    AdvisorySeverity.caution => colors.caution,
    AdvisorySeverity.info => colors.notice,
  };
}

(Color, Color) severityColors(BuildContext context, AdvisorySeverity severity) {
  final t = severityTone(context, severity);
  return (t.background, t.foreground);
}

IconData severityIcon(AdvisorySeverity severity) => switch (severity) {
  AdvisorySeverity.suspended => Icons.block,
  AdvisorySeverity.caution => Icons.warning_amber_rounded,
  AdvisorySeverity.info => Icons.info_outline,
};

String severityLabel(BuildContext context, AdvisorySeverity severity) {
  final l10n = context.l10n;
  return switch (severity) {
    AdvisorySeverity.suspended => l10n.severitySuspended,
    AdvisorySeverity.caution => l10n.severityCaution,
    AdvisorySeverity.info => l10n.severityInfo,
  };
}

/// Shown on the Plan, Schedules and Guide tabs while any advisory is active.
/// It cannot be dismissed; it goes away when the advisory ends.
class AdvisoryBanner extends ConsumerWidget {
  const AdvisoryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeAdvisoriesProvider);
    if (active.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final top = active.first;
    final tone = severityTone(context, top.severity);
    final (bg, fg) = (tone.background, tone.foreground);

    return Material(
      color: bg,
      shape: Border(bottom: BorderSide(color: tone.border)),
      child: InkWell(
        key: const Key('advisoryBanner'),
        onTap: () => context.push('/advisories'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(severityIcon(top.severity), color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    '${severityLabel(context, top.severity)}: '
                        '${top.title.resolve(context.languageCode)}',
                    if (active.length > 1)
                      l10n.advisoriesMore(active.length - 1),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact warning for a trip affected by [advisories] (results, plan
/// detail, saved trips, First-Timer mode). Tapping opens the advisory.
class PlanAdvisoryWarning extends StatelessWidget {
  const PlanAdvisoryWarning(this.advisories, {super.key});

  final List<Advisory> advisories;

  @override
  Widget build(BuildContext context) {
    if (advisories.isEmpty) return const SizedBox.shrink();
    final top = advisories.first;
    final tone = severityTone(context, top.severity);
    final (bg, fg) = (tone.background, tone.foreground);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tone.border),
      ),
      child: InkWell(
        key: Key('planAdvisory-${top.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/advisories/${top.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(severityIcon(top.severity), size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.l10n.tripAffected(
                    top.title.resolve(context.languageCode),
                  ),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: fg, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
