import 'models/int_range.dart';

/// Formats centavos as pesos: `₱1,250` or `₱1,250.50`.
String formatPesos(int centavos) {
  final negative = centavos < 0;
  final abs = centavos.abs();
  final whole = abs ~/ 100;
  final cents = abs % 100;
  final digits = whole.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final fraction = cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}₱$grouped$fraction';
}

/// `₱500` or `₱500–₱650`.
String formatPesoRange(IntRange range) => range.isExact
    ? formatPesos(range.min)
    : '${formatPesos(range.min)}–${formatPesos(range.max)}';
