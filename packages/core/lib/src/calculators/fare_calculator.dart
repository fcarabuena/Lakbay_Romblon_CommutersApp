import '../models/discounts.dart';
import '../models/int_range.dart';
import '../planner/leg.dart';

/// Applies a percentage discount to a centavo amount, rounding half up.
int applyDiscount(int centavos, int percent) {
  final p = percent.clamp(0, 100);
  return (centavos * (100 - p) + 50) ~/ 100;
}

/// Totals for a plan: fares (range) plus fixed terminal fees.
final class FareBreakdown {
  const FareBreakdown({
    required this.perLeg,
    required this.fares,
    required this.fees,
  });

  /// Fare for the whole group, per leg, in plan order.
  final List<IntRange> perLeg;
  final IntRange fares;

  /// Terminal / port fees for the whole group.
  final int fees;

  IntRange get total => fares + IntRange.exact(fees);
}

final class FareCalculator {
  const FareCalculator(this.discounts);

  final DiscountRules discounts;

  /// Group fare for one leg.
  IntRange legFare(Leg leg, TravellerGroup group) {
    if (!leg.perPerson) return group.total == 0 ? IntRange.zero : leg.baseFare;
    var sum = IntRange.zero;
    for (final type in PassengerType.values) {
      final count = group.count(type);
      if (count == 0) continue;
      if (leg.typePrices[type] case final price?) {
        sum += IntRange.exact(price) * count;
        continue;
      }
      final percent = leg.discountable ? discounts.percentFor(type) : 0;
      sum += leg.baseFare.map((a) => applyDiscount(a, percent)) * count;
    }
    return sum;
  }

  int legFees(Leg leg, TravellerGroup group) => leg.feePerPerson * group.total;

  FareBreakdown plan(List<Leg> legs, TravellerGroup group) {
    final perLeg = [for (final leg in legs) legFare(leg, group)];
    return FareBreakdown(
      perLeg: perLeg,
      fares: perLeg.fold(IntRange.zero, (a, b) => a + b),
      fees: legs.fold(0, (sum, leg) => sum + legFees(leg, group)),
    );
  }
}
