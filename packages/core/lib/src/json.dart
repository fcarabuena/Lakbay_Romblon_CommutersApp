/// Small, strict helpers for reading decoded JSON.
///
/// Every reader throws a [FormatException] naming the offending key, so a
/// typo in a seed file or an admin edit fails loudly instead of silently
/// producing a zero fare.
library;

typedef Json = Map<String, Object?>;

extension JsonRead on Json {
  T req<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    throw FormatException(
      'Expected $T at "$key" but found ${value.runtimeType} ($value)',
    );
  }

  T? opt<T>(String key) {
    final Object? value = this[key];
    if (value is T?) return value;
    throw FormatException(
      'Expected $T? at "$key" but found ${value.runtimeType} ($value)',
    );
  }

  List<Json> objects(String key) => [
    for (final item in opt<List<Object?>>(key) ?? const <Object?>[])
      if (item is Json)
        item
      else
        throw FormatException('Expected an object inside "$key"'),
  ];

  List<String> strings(String key) => [
    for (final item in opt<List<Object?>>(key) ?? const <Object?>[])
      if (item is String)
        item
      else
        throw FormatException('Expected a string inside "$key"'),
  ];

  List<int> ints(String key) => [
    for (final item in opt<List<Object?>>(key) ?? const <Object?>[])
      if (item is int)
        item
      else
        throw FormatException('Expected an integer inside "$key"'),
  ];
}

/// Converts a peso amount from JSON (e.g. `650` or `650.5`) to centavos.
int pesosToCentavos(num pesos) => (pesos * 100).round();

/// Parses `"HH:mm"` into minutes after midnight.
int parseClock(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
  if (match == null) throw FormatException('Invalid time "$value"');
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  if (hours > 23 || minutes > 59) {
    throw FormatException('Invalid time "$value"');
  }
  return hours * 60 + minutes;
}

String formatClock(int minutesOfDay) {
  final h = (minutesOfDay ~/ 60).toString().padLeft(2, '0');
  final m = (minutesOfDay % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
