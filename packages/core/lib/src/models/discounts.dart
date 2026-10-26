import '../json.dart';
import 'verification.dart';

enum PassengerType { regular, student, senior, pwd }

/// Fare discount percentages by passenger type.
///
/// Philippine law grants students, seniors and PWDs fare discounts, but how
/// each operator applies them varies, so the rates are data, not constants.
final class DiscountRules {
  const DiscountRules(
    this.percent, {
    this.verification = Verification.placeholder,
  });

  static const none = DiscountRules({});

  final Map<PassengerType, int> percent;
  final Verification verification;

  int percentFor(PassengerType type) => percent[type] ?? 0;

  factory DiscountRules.fromJson(Json? json) {
    if (json == null) return none;
    final rates = json.opt<Json>('percent') ?? const <String, Object?>{};
    return DiscountRules({
      for (final type in PassengerType.values)
        if (rates[type.name] case final int rate) type: rate,
    }, verification: Verification.fromJson(json.opt<Json>('verification')));
  }
}

/// How many travellers of each type are in the group.
final class TravellerGroup {
  const TravellerGroup({
    this.regular = 1,
    this.student = 0,
    this.senior = 0,
    this.pwd = 0,
  });

  final int regular;
  final int student;
  final int senior;
  final int pwd;

  int get total => regular + student + senior + pwd;

  int count(PassengerType type) => switch (type) {
    PassengerType.regular => regular,
    PassengerType.student => student,
    PassengerType.senior => senior,
    PassengerType.pwd => pwd,
  };

  TravellerGroup withCount(PassengerType type, int value) => TravellerGroup(
    regular: type == PassengerType.regular ? value : regular,
    student: type == PassengerType.student ? value : student,
    senior: type == PassengerType.senior ? value : senior,
    pwd: type == PassengerType.pwd ? value : pwd,
  );

  Map<String, int> toJson() => {
    for (final t in PassengerType.values) t.name: count(t),
  };

  factory TravellerGroup.fromJson(Json json) => TravellerGroup(
    regular: json.opt<int>('regular') ?? 0,
    student: json.opt<int>('student') ?? 0,
    senior: json.opt<int>('senior') ?? 0,
    pwd: json.opt<int>('pwd') ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is TravellerGroup &&
      other.regular == regular &&
      other.student == student &&
      other.senior == senior &&
      other.pwd == pwd;

  @override
  int get hashCode => Object.hash(regular, student, senior, pwd);
}
