import '../json.dart';

/// An inclusive min–max range of whole numbers.
///
/// Used for money (in centavos) and durations (in minutes). Travel in the
/// islands is never exact, so estimates are carried as ranges end to end.
final class IntRange {
  const IntRange(this.min, this.max)
    : assert(min <= max, 'min must not exceed max');

  const IntRange.exact(int value) : min = value, max = value;

  static const zero = IntRange.exact(0);

  final int min;
  final int max;

  bool get isExact => min == max;

  IntRange operator +(IntRange other) =>
      IntRange(min + other.min, max + other.max);

  IntRange operator *(int factor) => IntRange(min * factor, max * factor);

  IntRange map(int Function(int value) transform) =>
      IntRange(transform(min), transform(max));

  /// Reads a number or a `{"min": a, "max": b}` object.
  ///
  /// When [pesos] is true the values are peso amounts converted to centavos.
  static IntRange fromJson(Object? json, {bool pesos = false}) {
    int convert(Object? v) {
      if (v is! num) throw FormatException('Expected a number, got $v');
      return pesos ? pesosToCentavos(v) : v.round();
    }

    if (json is num) return IntRange.exact(convert(json));
    if (json is Json) {
      final min = convert(json['min']);
      final max = convert(json['max']);
      if (min > max) throw FormatException('Range min > max: $json');
      return IntRange(min, max);
    }
    throw FormatException('Expected a number or {min, max}, got $json');
  }

  @override
  bool operator ==(Object other) =>
      other is IntRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => isExact ? '$min' : '$min–$max';
}
