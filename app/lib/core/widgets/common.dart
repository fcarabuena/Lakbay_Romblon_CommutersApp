import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../app/theme.dart';
import '../providers.dart';
import '../ui/formatters.dart';

/// Shows whether a value is a sample, verified, or possibly outdated.
class VerifiedBadge extends ConsumerWidget {
  const VerifiedBadge(this.verification, {super.key});

  final Verification verification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider)();
    final date = verification.lastVerified;

    final (label, icon, bg, fg) = switch (verification) {
      Verification(source: 'USER_ESTIMATE') => (
        l10n.badgeUserEstimate,
        Icons.edit_note,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      Verification(isPlaceholder: true) || Verification(lastVerified: null) => (
        l10n.badgePlaceholder,
        Icons.warning_amber_rounded,
        scheme.warningContainer,
        scheme.onWarningContainer,
      ),
      _ when verification.isStale(now) => (
        l10n.badgeStale(formatDate(l10n, date!)),
        Icons.history,
        scheme.warningContainer,
        scheme.onWarningContainer,
      ),
      _ => (
        l10n.badgeVerified(formatDate(l10n, date!)),
        Icons.verified_outlined,
        scheme.successContainer,
        scheme.onSuccessContainer,
      ),
    };

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NoticeTone { info, warning, success, error }

/// A full-width coloured notice with an icon.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.tone = NoticeTone.info, this.icon});

  final String text;
  final NoticeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, defaultIcon) = switch (tone) {
      NoticeTone.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.info_outline,
      ),
      NoticeTone.warning => (
        scheme.warningContainer,
        scheme.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      NoticeTone.success => (
        scheme.successContainer,
        scheme.onSuccessContainer,
        Icons.check_circle_outline,
      ),
      NoticeTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label / value row used in totals and breakdowns.
class AmountRow extends StatelessWidget {
  const AmountRow(
    this.label,
    this.value, {
    super.key,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;

  /// Text colour on coloured cards (e.g. white on the trip summary).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final style = (emphasize ? theme.titleMedium : theme.bodyLarge)?.copyWith(
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: style?.copyWith(fontFeatures: tabularFigures),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// A − count + control with large buttons.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 20,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        IconButton.outlined(
          tooltip: l10n.decrease(label),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.outlined(
          tooltip: l10n.increase(label),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Shared card padding for screen sections.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A rounded square icon for a trip leg: marine blue for sea legs, island
/// green for land legs.
class LegIcon extends StatelessWidget {
  const LegIcon(this.leg, {super.key, this.size = 34});

  final Leg leg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sea = leg.kind == LegKind.ship || leg.rideMode == RideMode.pumpboat;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: sea ? scheme.primary : scheme.secondary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        legIcon(leg),
        size: size * 0.6,
        color: sea ? scheme.onPrimary : scheme.onSecondary,
      ),
    );
  }
}

IconData legIcon(Leg leg) => switch (leg.kind) {
  LegKind.ship => Icons.directions_boat_filled,
  LegKind.bus => Icons.directions_bus_filled,
  LegKind.custom => Icons.place,
  LegKind.localRide => switch (leg.rideMode) {
    RideMode.walk => Icons.directions_walk,
    RideMode.pumpboat => Icons.sailing,
    RideMode.taxi => Icons.local_taxi,
    _ => Icons.electric_rickshaw,
  },
};
