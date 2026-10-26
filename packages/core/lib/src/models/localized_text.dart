import '../json.dart';

/// Text with translations keyed by locale code (`en`, `fil`, `bno`, ...).
///
/// Falls back to English, so a missing translation never shows a blank.
final class LocalizedText {
  const LocalizedText(this.values);

  final Map<String, String> values;

  String resolve(String languageCode) =>
      values[languageCode] ?? values['en'] ?? values.values.firstOrNull ?? '';

  String get en => resolve('en');

  bool has(String languageCode) => values.containsKey(languageCode);

  /// Accepts either a plain string (English) or a `{locale: text}` map.
  factory LocalizedText.fromJson(Object? json) {
    if (json is String) return LocalizedText({'en': json});
    if (json is Json) {
      return LocalizedText({
        for (final entry in json.entries)
          if (entry.value is String) entry.key: entry.value! as String,
      });
    }
    throw FormatException('Expected text or {locale: text}, got $json');
  }

  static LocalizedText? maybe(Object? json) =>
      json == null ? null : LocalizedText.fromJson(json);
}
