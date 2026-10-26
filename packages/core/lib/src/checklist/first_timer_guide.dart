import '../models/checklist.dart';
import '../planner/leg.dart';
import '../planner/trip.dart';

sealed class ChecklistEntry {
  String get id;
}

/// A fixed item from the checklist template ("Bring a valid ID").
final class TemplateEntry implements ChecklistEntry {
  const TemplateEntry(this.item);

  final ChecklistItem item;

  @override
  String get id => item.id;
}

/// A step generated from the traveller's own plan ("Ride to Odiongan Port").
final class LegEntry implements ChecklistEntry {
  const LegEntry(this.leg, this.legIndex);

  final Leg leg;
  final int legIndex;

  @override
  String get id => 'leg:${leg.id}';
}

final class ChecklistSection {
  const ChecklistSection(this.phase, this.entries);

  final ChecklistPhase phase;
  final List<ChecklistEntry> entries;

  bool isComplete(Set<String> done) =>
      entries.every((e) => done.contains(e.id));
}

/// The First-Timer Mode checklist for one plan, with progress helpers.
final class FirstTimerGuide {
  const FirstTimerGuide(this.sections);

  /// Merges the template with the plan: each phase gets the legs that fall in
  /// its slot (before, during or after the sea crossing), listed first.
  factory FirstTimerGuide.build(ChecklistTemplate template, TripPlan plan) {
    final legs = plan.legs;
    final firstShip = legs.indexWhere((l) => l.kind == LegKind.ship);
    final lastShip = legs.lastIndexWhere((l) => l.kind == LegKind.ship);

    bool inSlot(int i, LegSlot slot) => switch (slot) {
      LegSlot.none => false,
      LegSlot.beforeShip => firstShip >= 0 && i < firstShip,
      LegSlot.ship => firstShip >= 0 && i >= firstShip && i <= lastShip,
      LegSlot.afterShip => firstShip >= 0 && i > lastShip,
    };

    return FirstTimerGuide([
      for (final phase in template.phases)
        ChecklistSection(phase, [
          for (var i = 0; i < legs.length; i++)
            if (inSlot(i, phase.legSlot)) LegEntry(legs[i], i),
          for (final item in phase.items) TemplateEntry(item),
        ]),
    ]);
  }

  final List<ChecklistSection> sections;

  Iterable<String> get allIds =>
      sections.expand((s) => s.entries.map((e) => e.id));

  int get totalCount => sections.fold(0, (n, s) => n + s.entries.length);

  int completedCount(Set<String> done) => allIds.where(done.contains).length;

  /// Progress from 0.0 to 1.0. Ids not in this guide are ignored.
  double progress(Set<String> done) {
    final total = totalCount;
    return total == 0 ? 0 : completedCount(done) / total;
  }

  /// Index of the first section that still has unchecked items, or null when
  /// everything is done.
  int? currentSection(Set<String> done) {
    final i = sections.indexWhere((s) => !s.isComplete(done));
    return i < 0 ? null : i;
  }
}
