/// Declarative descriptions of the form fields for each collection.
///
/// Editors render these generically (see `form_fields.dart`), writing into
/// the same JSON shape as the seed files so the app parses edits unchanged.
/// What staff see (labels, plain-word choices) is separate from what is
/// stored (codes such as `romblon` or `ticket_office`).
library;

import 'package:lakbay_core/lakbay_core.dart';

import '../backend/dataset.dart';

/// Where a field sits, for show/hide rules: the whole draft, or one item of
/// a repeated group (with its position, e.g. the first or last stop).
class FieldContext {
  const FieldContext(this.item, {this.index, this.count});

  final Json item;
  final int? index;
  final int? count;

  bool get isFirst => index == 0;
  bool get isLast => index != null && count != null && index == count! - 1;
}

typedef VisibleWhen = bool Function(FieldContext context);

sealed class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.required = false,
    this.help,
    this.example,
    this.advanced = false,
    this.visibleWhen,
  });

  final String key;
  final String label;
  final bool required;

  /// One short plain sentence under the field.
  final String? help;

  /// Shown after the help as "e.g. …".
  final String? example;

  /// Shown only under "Advanced (for technical staff)".
  final bool advanced;

  /// Hidden (and not saved) when this returns false.
  final VisibleWhen? visibleWhen;

  String? get helpLine => switch ((help, example)) {
    (null, null) => null,
    (final h?, null) => h,
    (null, final e?) => 'e.g. $e',
    (final h?, final e?) => '$h  e.g. $e',
  };
}

/// A stored value with the words staff see, and optionally a longer
/// description (for the large choice cards).
class Choice {
  const Choice(this.value, this.label, {this.description, this.tone});

  final Object value;
  final String label;
  final String? description;

  /// Advisory colour for the choice card: `suspended`, `caution` or `notice`.
  final String? tone;
}

enum ChoiceStyle { dropdown, radio, cards }

class TextSpec extends FieldSpec {
  const TextSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.multiline = false,
  });

  final bool multiline;
}

/// The document id: made from other fields when creating (in the style of the
/// existing ids, e.g. `odiongan_port`), editable only under Advanced and only
/// before the first save.
class IdSpec extends FieldSpec {
  const IdSpec({this.from})
    : super(
        'id',
        'ID',
        required: true,
        advanced: true,
        help: 'Made from the name automatically. Change it only if you have a reason; it cannot be changed after saving.',
      );

  /// Builds the id text from the draft; null uses the name or title.
  final String? Function(Json draft, Dataset data)? from;
}

class IntSpec extends FieldSpec {
  const IntSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.min = 0,
    this.minutes = false,
  });

  final int min;

  /// Also shows the value in hours and minutes ("150 minutes = 2 h 30 min").
  final bool minutes;
}

/// A peso amount, stored as a number (650, or 650.5 if centavos are needed).
class PesoSpec extends FieldSpec {
  const PesoSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
  });
}

/// Several peso amounts stored together, e.g. a fare's published student,
/// senior and child prices: `{"student": 960, "senior": 860}`.
class PesoTableSpec extends FieldSpec {
  const PesoTableSpec(
    super.key,
    super.label,
    this.rows, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
  });

  /// Stored key and the words staff see.
  final List<Choice> rows;
}

/// A usual amount, or a from–to range when "It varies" is on.
class RangeSpec extends FieldSpec {
  const RangeSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.pesos = false,
  });

  /// Pesos; otherwise minutes (shown in hours too).
  final bool pesos;
}

/// A time of day, chosen with a clock picker; stored as "HH:mm".
class ClockSpec extends FieldSpec {
  const ClockSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
  });
}

/// A date and time in Philippine time, chosen with pickers; stored as ISO 8601
/// with +08:00. With [openEndedLabel], a switch leaves it empty.
class DateTimeSpec extends FieldSpec {
  const DateTimeSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.openEndedLabel,
  });

  final String? openEndedLabel;
}

class BoolSpec extends FieldSpec {
  const BoolSpec(
    super.key,
    super.label, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.defaultValue = false,
  });

  final bool defaultValue;
}

class ChoiceSpec extends FieldSpec {
  const ChoiceSpec(
    super.key,
    super.label,
    this.choices, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.style = ChoiceStyle.dropdown,
    this.defaultValue,
  });

  final List<Choice> choices;
  final ChoiceStyle style;

  /// What a missing value means (e.g. day 0 = "Same day").
  final Object? defaultValue;
}

/// What a reference can point to.
enum RefTarget {
  places,
  ports,
  voyages,
  shippingLines,
  busOperators,
  municipalities,
}

class RefSpec extends FieldSpec {
  const RefSpec(
    super.key,
    super.label,
    this.target, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.only,
  });

  final RefTarget target;

  /// Limits the choices (e.g. a fare's ports to its voyage's stops).
  final List<String>? Function(Json draft, Dataset data)? only;
}

class MultiRefSpec extends FieldSpec {
  const MultiRefSpec(
    super.key,
    super.label,
    this.target, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
  });

  final RefTarget target;
}

/// English plus Tagalog. Other languages fall back to English in the app.
class LocalizedSpec extends FieldSpec {
  const LocalizedSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.multiline = false,
  });

  final bool multiline;
}

class LocalizedListSpec extends FieldSpec {
  const LocalizedListSpec(
    super.key,
    super.label, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.itemLabel = 'Item',
  });

  final String itemLabel;
}

/// Tick boxes storing a list of codes. Codes in the data that are not in
/// [choices] still show (ticked) so nothing is lost.
class CheckboxListSpec extends FieldSpec {
  const CheckboxListSpec(
    super.key,
    super.label,
    this.choices, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
  });

  final List<Choice> choices;
}

/// One box per phone number, with "+ Add another number".
class PhoneListSpec extends FieldSpec {
  const PhoneListSpec(
    super.key,
    super.label, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
  });
}

/// ISO weekdays 1 (Mon) to 7 (Sun), with an "Every day" button.
class DaysSpec extends FieldSpec {
  const DaysSpec(
    super.key,
    super.label, {
    super.required,
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
  });
}

/// A map location chosen with "Pick on map"; raw coordinates under Advanced.
class GeoSpec extends FieldSpec {
  const GeoSpec(
    super.key,
    super.label, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.townKey,
  });

  /// A field holding a town id; the map starts there when nothing is picked.
  final String? townKey;
}

/// A repeated group, e.g. voyage stops or bus drop-offs.
class ObjectListSpec extends FieldSpec {
  const ObjectListSpec(
    super.key,
    super.label,
    this.fields, {
    super.help,
    super.example,
    super.advanced,
    super.visibleWhen,
    this.itemLabel = 'Item',
    this.minItems = 0,
    this.itemId,
  });

  final List<FieldSpec> fields;
  final String itemLabel;
  final int minItems;

  /// Gives each new item an `id` (e.g. map points).
  final String Function(Json item, int index)? itemId;
}

/// Raw JSON for nested data without a dedicated form (layouts, checklists).
class JsonSpec extends FieldSpec {
  const JsonSpec(
    super.key,
    super.label, {
    super.help,
    super.example,
    super.visibleWhen,
    this.emptyValue,
  }) : super(advanced: true);

  final Object? emptyValue;
}

/// Lowercase words joined by `_`, like the existing ids ("Odiongan Port" →
/// `odiongan_port`).
String slugId(String text) {
  final slug = text
      .toLowerCase()
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return slug.length > 50
      ? slug.substring(0, 50).replaceAll(RegExp(r'_+$'), '')
      : slug;
}

/// [base], or `base_2`, `base_3`… if already used.
String uniqueId(String base, Iterable<String> taken) {
  final used = taken.toSet();
  if (!used.contains(base)) return base;
  for (var n = 2; ; n++) {
    if (!used.contains('${base}_$n')) return '${base}_$n';
  }
}

/// Hours and minutes for a number of minutes: "2 h 30 min".
String hoursAndMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}
