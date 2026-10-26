import '../models/discounts.dart';
import '../models/int_range.dart';
import '../models/land.dart';
import '../models/localized_text.dart';
import '../models/verification.dart';

enum LegKind { localRide, ship, bus, custom }

/// When a leg can be started.
sealed class LegSchedule {
  const LegSchedule();
}

/// A ship leg: departs at a fixed time on the voyage's sailing days.
final class FixedDeparture extends LegSchedule {
  const FixedDeparture({
    required this.departAbs,
    required this.daysOfWeek,
    required this.checkInMinutes,
  });

  /// Minutes from midnight of the voyage's first day to this stop's departure.
  final int departAbs;

  /// ISO weekdays the voyage starts on.
  final List<int> daysOfWeek;
  final int checkInMinutes;
}

/// A bus leg: departs every [headwayMinutes] between [firstTrip] and [lastTrip].
final class FrequentDeparture extends LegSchedule {
  const FrequentDeparture({
    required this.firstTrip,
    required this.lastTrip,
    required this.headwayMinutes,
  });

  final int firstTrip;
  final int lastTrip;
  final int headwayMinutes;
}

/// One step of a door-to-door plan.
final class Leg {
  const Leg({
    required this.id,
    required this.kind,
    required this.fromId,
    required this.toId,
    required this.baseFare,
    required this.duration,
    required this.verification,
    this.perPerson = true,
    this.discountable = false,
    this.feePerPerson = 0,
    this.feeVerification,
    this.schedule,
    this.rideMode,
    this.voyageId,
    this.fareClass,
    this.busRouteId,
    this.estimateMissing = false,
    this.note,
    this.typePrices = const {},
    this.timeEstimated = false,
  });

  /// Stable id of the underlying edge; plan ids are built from these.
  final String id;
  final LegKind kind;
  final String fromId;
  final String toId;

  /// Regular fare in centavos, per person when [perPerson], else per trip.
  final IntRange baseFare;
  final bool perPerson;

  /// Whether student/senior/PWD discounts apply to this leg's fare.
  final bool discountable;

  /// Terminal or port fee per person, in centavos (never discounted).
  final int feePerPerson;
  final Verification? feeVerification;

  final IntRange duration;
  final LegSchedule? schedule;
  final Verification verification;

  final RideMode? rideMode;
  final String? voyageId;
  final String? fareClass;
  final String? busRouteId;

  /// True for a custom last leg the user gave no estimate for.
  final bool estimateMissing;

  /// Practical tip for this leg (e.g. where to find the bus area).
  final LocalizedText? note;

  /// Prices the operator publishes per passenger type, in centavos; used
  /// instead of the discount percentages when present.
  final Map<PassengerType, int> typePrices;

  /// The travel time is an estimate (e.g. "about 10 hours"), not a schedule.
  final bool timeEstimated;

  bool get isWalk => rideMode == RideMode.walk;

  /// Fixed minutes to spend before this leg even without a schedule
  /// (e.g. ship check-in).
  int get prepMinutes => switch (schedule) {
    FixedDeparture(:final checkInMinutes) => checkInMinutes,
    _ => 0,
  };

  Iterable<Verification> get verifications sync* {
    yield verification;
    if (feeVerification != null && feePerPerson > 0) yield feeVerification!;
  }
}
