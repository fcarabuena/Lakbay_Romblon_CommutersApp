import 'dart:convert';

import 'package:lakbay_core/lakbay_core.dart';

import '../backend/dataset.dart';
import 'collection_specs.dart';
import 'field_specs.dart';

Json deepCopy(Json json) => jsonDecode(jsonEncode(json)) as Json;

/// JSON with object keys sorted, so equal data compares equal.
String canonicalJson(Object? value) {
  Object? sort(Object? v) => switch (v) {
    final Map<String, Object?> m => {
      for (final k in m.keys.toList()..sort()) k: sort(m[k]),
    },
    final List<Object?> l => [for (final x in l) sort(x)],
    _ => v,
  };
  return jsonEncode(sort(value));
}

/// Prepares a draft for saving: drops fields that are hidden by a show/hide
/// rule (e.g. a hotline's port when it covers a town) and empty phone boxes,
/// in nested groups too.
Json tidyForSave(List<FieldSpec> fields, Json item, {int? index, int? count}) {
  final result = {...item};
  final context = FieldContext(item, index: index, count: count);
  for (final f in fields) {
    if (!(f.visibleWhen?.call(context) ?? true)) {
      result.remove(f.key);
      continue;
    }
    final value = result[f.key];
    if (f is PhoneListSpec && value is List) {
      result[f.key] = [
        for (final n in value)
          if (n is String && n.trim().isNotEmpty) n.trim(),
      ];
    }
    if (f is ObjectListSpec && value is List) {
      final items = value.whereType<Json>().toList();
      result[f.key] = [
        for (final (i, x) in items.indexed)
          tidyForSave(f.fields, x, index: i, count: items.length),
      ];
    }
  }
  return result;
}

/// Drops empty optional values so stored items stay as tidy as the seed.
Json cleanItem(Json item) => {
  for (final MapEntry(:key, :value) in item.entries)
    if (value != null && value != '') key: value,
};

/// Applies the editor's verification choice.
///
/// Saving never marks a value verified by itself: [verified] must be ticked,
/// which stamps today's date and the editor. An unticked change turns the
/// value back into a placeholder, because what was verified has changed.
Json stampVerification(
  Json item, {
  required String key,
  required Json? before,
  required bool verified,
  required String source,
  required String uid,
  required DateTime today,
}) {
  final result = {...item};
  final trimmed = source.trim();
  if (verified) {
    result[key] = Verification(
      source: trimmed,
      isPlaceholder: false,
      lastVerified: DateTime.utc(today.year, today.month, today.day),
      verifiedBy: uid,
    ).toJson();
    return result;
  }
  Json withoutVerification(Json? j) => {...?j}..remove(key);
  final changed =
      before == null ||
      canonicalJson(withoutVerification(before)) !=
          canonicalJson(withoutVerification(item));
  final old = Verification.fromJson(before?[key] as Json?);
  if (changed || trimmed != old.source) {
    result[key] = Verification(
      source: trimmed.isEmpty ? 'PLACEHOLDER' : trimmed,
      isPlaceholder: true,
    ).toJson();
  }
  return result;
}

/// The outcome of checking an edit before it is saved.
class SaveCheck {
  const SaveCheck({
    required this.item,
    required this.docId,
    required this.problems,
  });

  final Json item;
  final String docId;

  /// Empty when the edit can be saved.
  final List<String> problems;

  bool get ok => problems.isEmpty;
}

final _idPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');

/// Checks an edit exactly as the app would read it: required fields, the
/// item on its own, then the whole dataset for new problems (a fare for a
/// voyage that does not exist, a voyage with one stop...).
SaveCheck checkEdit({
  required CollectionSpec spec,
  required Dataset data,
  required String? existingId,
  required Json draft,
}) {
  final item = cleanItem(draft);
  final problems = <String>[];

  for (final f in spec.fields) {
    final v = item[f.key];
    final empty =
        v == null ||
        (v is String && v.trim().isEmpty) ||
        (v is List && v.isEmpty && f is! MultiRefSpec);
    if (f.required && empty) problems.add('${f.label} is required');
    if (f is ObjectListSpec && (v is List ? v.length : 0) < f.minItems) {
      problems.add('${f.label}: add at least ${f.minItems}');
    }
  }

  final docId = existingId ?? spec.docIdOf(item);
  if (existingId == null) {
    if (spec.hasIdField && !_idPattern.hasMatch(docId)) {
      problems.add('ID must be lowercase letters, numbers, - or _');
    } else if (data.rows[spec.collection]?.containsKey(docId) ?? false) {
      problems.add('Another ${spec.singular} already uses "$docId"');
    }
  }
  if (problems.isNotEmpty) {
    return SaveCheck(item: item, docId: docId, problems: problems);
  }

  try {
    TravelData.checkItem(spec.collection, item);
  } on FormatException catch (e) {
    return SaveCheck(item: item, docId: docId, problems: [e.message]);
  }
  final after = data.withChange(spec.collection, docId, item);
  return SaveCheck(
    item: item,
    docId: docId,
    problems: problemsIntroduced(data.files(), after.files()),
  );
}

/// Problems a deletion would cause (e.g. removing a voyage that fares use).
List<String> checkDelete(CollectionSpec spec, Dataset data, String id) =>
    problemsIntroduced(
      data.files(),
      data.withChange(spec.collection, id, null).files(),
    );

// ---------- Philippine time ----------

const manilaOffset = Duration(hours: 8);

/// "2026-11-01 14:30" (Manila) → "2026-11-01T14:30:00+08:00"; null if invalid.
String? manilaInputToIso(String input) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{1,2}):(\d{2})$')
      .firstMatch(input.trim());
  if (m == null) return null;
  final parts = [for (var i = 1; i <= 5; i++) int.parse(m.group(i)!)];
  final local = DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4]);
  if (local.month != parts[1] ||
      local.day != parts[2] ||
      parts[3] > 23 ||
      parts[4] > 59) {
    return null;
  }
  String two(int n) => n.toString().padLeft(2, '0');
  return '${parts[0]}-${two(parts[1])}-${two(parts[2])}T${two(parts[3])}:${two(parts[4])}:00+08:00';
}

/// Any ISO time → "2026-11-01 14:30" in Manila time.
String isoToManilaInput(String iso) {
  final t = DateTime.parse(iso).toUtc().add(manilaOffset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

String nowManilaIso(DateTime now) =>
    manilaInputToIso(isoToManilaInput(now.toUtc().toIso8601String()))!;

/// Placeholder, verified (date) or stale, for list badges.
enum VerificationState { none, placeholder, verified, stale }

VerificationState verificationState(
  CollectionSpec spec,
  Json item,
  DateTime now,
) {
  final key = spec.verificationKey;
  if (key == null) return VerificationState.none;
  final v = Verification.fromJson(item[key] as Json?);
  if (!v.isVerified) return VerificationState.placeholder;
  return v.isStale(now) ? VerificationState.stale : VerificationState.verified;
}

const _plainPhrases = {
  'fare must be positive': 'the fare must be more than zero',
  'unknown voyage': 'the chosen voyage no longer exists',
  'stops not on voyage in this order':
      'the voyage does not stop at these ports in this order',
  'needs at least 2 stops':
      'needs at least 2 stops (where it leaves and where it arrives)',
  'first stop has no departure': 'the first stop needs a "Leaves" time',
  'last stop has no arrival': 'the last stop needs an "Arrives" time',
  'times go backwards at': 'a time is earlier than the stop before it, at',
  'no sailing days': 'choose at least one day it leaves',
  'is marked verified but has no lastVerified date':
      'is marked verified but has no date',
  'a number is not dialable': 'one of the phone numbers cannot be dialled',
  'first trip after last trip': 'the first bus is later than the last bus',
  'lies outside the layout': 'is outside the drawing',
  'ends before it starts': 'ends before it starts; check the dates',
};

/// Save problems in plain words: ids become names ("odiongan_port" →
/// "Odiongan Port") and checker phrases become everyday sentences.
List<String> friendlyProblems(List<String> problems, Dataset data) {
  final names = <String, String>{
    for (final c in [
      'municipalities',
      'ports',
      'bus_terminals',
      'hubs',
      'shipping_lines',
      'bus_operators',
    ])
      for (final MapEntry(:key, :value) in data.rows[c]!.entries)
        key: value['name'] as String? ?? key,
    for (final MapEntry(:key, :value) in data.rows['voyages']!.entries)
      key: '"${voyageLabel(value, data)}"',
  };
  final ids = names.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  final classes = {
    'economy': 'economy',
    'tourist': 'tourist',
    'cabin': 'cabin',
  };
  final fare = RegExp(r'^Ship fare (\S+) (\S+)-(\S+) (\S+):');

  String plain(String p) {
    var text = p.replaceFirstMapped(fare, (m) {
      final voyage = names[m[1]] ?? m[1];
      return 'The ${classes[m[4]] ?? m[4]} fare ${names[m[2]] ?? m[2]} → ${names[m[3]] ?? m[3]} on $voyage:';
    });
    for (final id in ids) {
      text = text.replaceAll(
        RegExp('(?<![A-Za-z0-9_])${RegExp.escape(id)}(?![A-Za-z0-9_])'),
        names[id]!,
      );
    }
    for (final MapEntry(:key, :value) in _plainPhrases.entries) {
      text = text.replaceAll(key, value);
    }
    return text;
  }

  return [for (final p in problems) plain(p)];
}
