/// Whether the traveller's cash covers the trip.
enum BudgetStatus {
  /// Covers everything including the emergency buffer.
  covered,

  /// Covers fares, fees and food, but not the full buffer.
  tight,

  /// Does not cover fares, fees and food.
  short,
}

/// Inputs in centavos. Fares should be the upper estimate of the plan.
final class BudgetInput {
  const BudgetInput({
    required this.cashOnHand,
    required this.fares,
    required this.fees,
    required this.travellers,
    required this.meals,
    required this.foodPerMeal,
    this.bufferPercent = 20,
    this.bufferMinimum = 50000,
    this.extras = 0,
  });

  final int cashOnHand;
  final int fares;
  final int fees;
  final int travellers;
  final int meals;

  /// Food cost per meal, per person.
  final int foodPerMeal;

  /// Emergency buffer as a percent of the base cost.
  final int bufferPercent;

  /// Smallest buffer to recommend, regardless of percent (default ₱500).
  final int bufferMinimum;

  /// Anything else the traveller plans to spend (pasalubong, load, etc.).
  final int extras;
}

final class BudgetResult {
  const BudgetResult({
    required this.cashOnHand,
    required this.fares,
    required this.fees,
    required this.food,
    required this.extras,
    required this.buffer,
  });

  final int cashOnHand;
  final int fares;
  final int fees;
  final int food;
  final int extras;
  final int buffer;

  int get baseNeeded => fares + fees + food + extras;
  int get totalNeeded => baseNeeded + buffer;

  /// Positive: money left over after everything. Negative: amount short.
  int get difference => cashOnHand - totalNeeded;

  BudgetStatus get status {
    if (cashOnHand >= totalNeeded) return BudgetStatus.covered;
    if (cashOnHand >= baseNeeded) return BudgetStatus.tight;
    return BudgetStatus.short;
  }
}

final class BudgetCalculator {
  const BudgetCalculator();

  BudgetResult calculate(BudgetInput input) {
    final food = input.foodPerMeal * input.meals * input.travellers;
    final base = input.fares + input.fees + food + input.extras;
    final percentBuffer = (base * input.bufferPercent + 99) ~/ 100;
    final buffer = base == 0
        ? 0
        : (percentBuffer > input.bufferMinimum
              ? percentBuffer
              : input.bufferMinimum);
    return BudgetResult(
      cashOnHand: input.cashOnHand,
      fares: input.fares,
      fees: input.fees,
      food: food,
      extras: input.extras,
      buffer: buffer,
    );
  }

  /// One meal for every started five hours on the road, at least one.
  static int suggestedMeals(int travelMinutes) {
    if (travelMinutes <= 0) return 1;
    final meals = (travelMinutes + 299) ~/ 300;
    return meals < 1 ? 1 : meals;
  }
}
