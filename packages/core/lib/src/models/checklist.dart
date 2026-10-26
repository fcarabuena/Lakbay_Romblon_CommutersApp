import '../json.dart';
import 'localized_text.dart';

enum TripDirection { toManila, toRomblon }

/// Which plan legs a checklist phase shows, relative to the sea crossing.
enum LegSlot { none, beforeShip, ship, afterShip }

final class ChecklistItem {
  const ChecklistItem({required this.id, required this.text, this.detail});

  final String id;
  final LocalizedText text;
  final LocalizedText? detail;

  factory ChecklistItem.fromJson(Json json) => ChecklistItem(
    id: json.req<String>('id'),
    text: LocalizedText.fromJson(json['text']),
    detail: LocalizedText.maybe(json['detail']),
  );
}

final class ChecklistPhase {
  const ChecklistPhase({
    required this.id,
    required this.title,
    required this.whatHappensNext,
    required this.items,
    this.legSlot = LegSlot.none,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText whatHappensNext;
  final List<ChecklistItem> items;
  final LegSlot legSlot;

  factory ChecklistPhase.fromJson(Json json) => ChecklistPhase(
    id: json.req<String>('id'),
    title: LocalizedText.fromJson(json['title']),
    whatHappensNext: LocalizedText.fromJson(json['whatHappensNext']),
    items: json.objects('items').map(ChecklistItem.fromJson).toList(),
    legSlot: LegSlot.values.byName(json.opt<String>('legSlot') ?? 'none'),
  );
}

final class ChecklistTemplate {
  const ChecklistTemplate({
    required this.id,
    required this.direction,
    required this.phases,
  });

  final String id;
  final TripDirection direction;
  final List<ChecklistPhase> phases;

  factory ChecklistTemplate.fromJson(Json json) => ChecklistTemplate(
    id: json.req<String>('id'),
    direction: TripDirection.values.byName(json.req<String>('direction')),
    phases: json.objects('phases').map(ChecklistPhase.fromJson).toList(),
  );
}
