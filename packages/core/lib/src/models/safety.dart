import '../json.dart';
import 'localized_text.dart';
import 'verification.dart';

enum HotlineScope { national, province, port, municipality }

/// An emergency or help number.
///
/// [numbers] may be empty: the entry then shows "Number needed" until a
/// verified number is added. Never guess an emergency number.
final class Hotline {
  const Hotline({
    required this.id,
    required this.agency,
    required this.label,
    required this.scope,
    required this.numbers,
    required this.verification,
    this.portId,
    this.municipalityId,
    this.note,
  });

  final String id;
  final String agency;
  final LocalizedText label;
  final HotlineScope scope;
  final List<String> numbers;
  final String? portId;
  final String? municipalityId;
  final LocalizedText? note;
  final Verification verification;

  bool get hasNumber => numbers.isNotEmpty;

  factory Hotline.fromJson(Json json) => Hotline(
    id: json.req<String>('id'),
    agency: json.req<String>('agency'),
    label: LocalizedText.fromJson(json['label']),
    scope: HotlineScope.values.byName(json.req<String>('scope')),
    numbers: json.strings('numbers'),
    portId: json.opt<String>('portId'),
    municipalityId: json.opt<String>('municipalityId'),
    note: LocalizedText.maybe(json['note']),
    verification: Verification.fromJson(json.opt<Json>('verification')),
  );
}

enum TipCategory { scam, safety, cancellation }

/// A scam warning or safety tip for first-time travellers.
final class SafetyTip {
  const SafetyTip({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
  });

  final String id;
  final TipCategory category;
  final LocalizedText title;
  final LocalizedText body;

  factory SafetyTip.fromJson(Json json) => SafetyTip(
    id: json.req<String>('id'),
    category: TipCategory.values.byName(json.req<String>('category')),
    title: LocalizedText.fromJson(json['title']),
    body: LocalizedText.fromJson(json['body']),
  );
}

/// Digits and a leading + only, for `tel:` links ("(02) 8-123" → "028123").
String dialableNumber(String display) =>
    display.replaceAll(RegExp(r'[^0-9+]'), '');
