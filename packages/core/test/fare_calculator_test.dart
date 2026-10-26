import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

Leg _leg({
  IntRange fare = const IntRange.exact(10000),
  bool perPerson = true,
  bool discountable = true,
  int fee = 0,
}) => Leg(
  id: 'leg',
  kind: LegKind.ship,
  fromId: 'a',
  toId: 'b',
  baseFare: fare,
  perPerson: perPerson,
  discountable: discountable,
  feePerPerson: fee,
  duration: const IntRange.exact(60),
  verification: Verification.placeholder,
);

void main() {
  const rules = DiscountRules({
    PassengerType.student: 20,
    PassengerType.senior: 20,
    PassengerType.pwd: 20,
  });
  const calc = FareCalculator(rules);

  group('applyDiscount', () {
    test('takes the percentage off', () {
      expect(applyDiscount(10000, 20), 8000);
      expect(applyDiscount(10000, 0), 10000);
    });

    test('rounds half a centavo up', () {
      expect(applyDiscount(337, 50), 169); // 168.5
      expect(applyDiscount(333, 20), 266); // 266.4
    });

    test('clamps percentages outside 0–100', () {
      expect(applyDiscount(10000, 150), 0);
      expect(applyDiscount(10000, -10), 10000);
    });
  });

  group('legFare', () {
    test('one regular passenger pays the base fare', () {
      expect(
        calc.legFare(_leg(), const TravellerGroup()),
        const IntRange.exact(10000),
      );
    });

    test('applies discounts per passenger type', () {
      const group = TravellerGroup(regular: 1, student: 1, senior: 1);
      // 100 + 80 + 80 pesos
      expect(calc.legFare(_leg(), group), const IntRange.exact(26000));
    });

    test('ignores discounts on non-discountable legs', () {
      const group = TravellerGroup(regular: 0, senior: 2);
      expect(
        calc.legFare(_leg(discountable: false), group),
        const IntRange.exact(20000),
      );
    });

    test('charges a per-trip fare once for the whole group', () {
      const group = TravellerGroup(regular: 3);
      expect(
        calc.legFare(
          _leg(perPerson: false, fare: const IntRange(15000, 20000)),
          group,
        ),
        const IntRange(15000, 20000),
      );
    });

    test('keeps ranges as ranges', () {
      const group = TravellerGroup(regular: 2);
      expect(
        calc.legFare(_leg(fare: const IntRange(5000, 6000)), group),
        const IntRange(10000, 12000),
      );
    });

    test('an empty group pays nothing', () {
      const group = TravellerGroup(regular: 0);
      expect(calc.legFare(_leg(), group), IntRange.zero);
      expect(calc.legFare(_leg(perPerson: false), group), IntRange.zero);
    });
  });

  group('plan', () {
    test('sums fares and adds undiscounted fees per person', () {
      const group = TravellerGroup(regular: 1, student: 1);
      final result = calc.plan([
        _leg(fee: 3000),
        _leg(fare: const IntRange(5000, 7000)),
      ], group);
      expect(result.perLeg, [
        const IntRange.exact(18000),
        const IntRange(9000, 12600),
      ]);
      expect(result.fares, const IntRange(27000, 30600));
      expect(result.fees, 6000);
      expect(result.total, const IntRange(33000, 36600));
    });
  });

  group('formatPesos', () {
    test('formats whole pesos with separators', () {
      expect(formatPesos(125000), '₱1,250');
      expect(formatPesos(123456789), '₱1,234,567.89');
      expect(formatPesos(5), '₱0.05');
      expect(formatPesos(-50000), '-₱500');
    });

    test('formats ranges', () {
      expect(formatPesoRange(const IntRange(50000, 65000)), '₱500–₱650');
      expect(formatPesoRange(const IntRange.exact(50000)), '₱500');
    });
  });
}
