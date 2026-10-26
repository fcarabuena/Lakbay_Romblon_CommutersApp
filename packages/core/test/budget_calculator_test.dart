import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

BudgetInput _input({
  required int cash,
  int fares = 100000,
  int fees = 10000,
  int travellers = 1,
  int meals = 2,
  int foodPerMeal = 15000,
  int bufferPercent = 20,
  int bufferMinimum = 50000,
  int extras = 0,
}) => BudgetInput(
  cashOnHand: cash,
  fares: fares,
  fees: fees,
  travellers: travellers,
  meals: meals,
  foodPerMeal: foodPerMeal,
  bufferPercent: bufferPercent,
  bufferMinimum: bufferMinimum,
  extras: extras,
);

void main() {
  const calc = BudgetCalculator();

  // Base: ₱1,000 fares + ₱100 fees + 2 × ₱150 food = ₱1,400.
  // Buffer: 20% = ₱280, below the ₱500 minimum → ₱500. Total ₱1,900.

  test('breaks the cost down', () {
    final r = calc.calculate(_input(cash: 0));
    expect(r.food, 30000);
    expect(r.baseNeeded, 140000);
    expect(r.buffer, 50000);
    expect(r.totalNeeded, 190000);
  });

  test('covered when cash meets the total exactly', () {
    final r = calc.calculate(_input(cash: 190000));
    expect(r.status, BudgetStatus.covered);
    expect(r.difference, 0);
  });

  test('covered with money left over', () {
    final r = calc.calculate(_input(cash: 250000));
    expect(r.status, BudgetStatus.covered);
    expect(r.difference, 60000);
  });

  test('tight when cash covers the trip but not the full buffer', () {
    final r = calc.calculate(_input(cash: 150000));
    expect(r.status, BudgetStatus.tight);
    expect(r.difference, -40000);
  });

  test('short when cash does not cover fares, fees and food', () {
    final r = calc.calculate(_input(cash: 139999));
    expect(r.status, BudgetStatus.short);
  });

  test('zero cash is short', () {
    expect(calc.calculate(_input(cash: 0)).status, BudgetStatus.short);
  });

  test(
    'uses the percentage buffer when it exceeds the minimum, rounding up',
    () {
      final r = calc.calculate(
        _input(cash: 0, fares: 1000001, fees: 0, meals: 0, bufferMinimum: 0),
      );
      expect(r.buffer, 200001); // 20% of 10,000.01 = 2,000.002 → rounded up
    },
  );

  test('food scales with travellers and meals', () {
    final r = calc.calculate(_input(cash: 0, travellers: 3, meals: 4));
    expect(r.food, 15000 * 4 * 3);
  });

  test('extras are part of the base cost', () {
    final r = calc.calculate(_input(cash: 0, extras: 20000));
    expect(r.baseNeeded, 160000);
  });

  test('nothing to pay needs no buffer', () {
    final r = calc.calculate(_input(cash: 0, fares: 0, fees: 0, meals: 0));
    expect(r.totalNeeded, 0);
    expect(r.status, BudgetStatus.covered);
  });

  test('suggests a meal for every started five hours', () {
    expect(BudgetCalculator.suggestedMeals(0), 1);
    expect(BudgetCalculator.suggestedMeals(300), 1);
    expect(BudgetCalculator.suggestedMeals(301), 2);
    expect(BudgetCalculator.suggestedMeals(14 * 60), 3);
  });
}
