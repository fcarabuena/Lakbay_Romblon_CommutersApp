import '../models/int_range.dart';
import '../planner/leg.dart';

/// Timing of one leg. Dates are null when no departure time was given.
final class LegTiming {
  const LegTiming({
    required this.wait,
    this.departEarliest,
    this.departLatest,
    this.arriveEarliest,
    this.arriveLatest,
  });

  /// Minutes spent before boarding (schedule wait or ship check-in).
  final IntRange wait;
  final DateTime? departEarliest;
  final DateTime? departLatest;
  final DateTime? arriveEarliest;
  final DateTime? arriveLatest;
}

final class TimeEstimate {
  const TimeEstimate({
    required this.travel,
    required this.waiting,
    required this.total,
    required this.schedulesApplied,
    required this.legs,
  });

  /// Time spent moving.
  final IntRange travel;

  /// Time spent waiting. Without a departure time this is only the required
  /// ship check-in, and [schedulesApplied] is false.
  final IntRange waiting;
  final bool schedulesApplied;
  final List<LegTiming> legs;

  /// Door-to-door minutes, best case to worst case.
  final IntRange total;

  DateTime? get arriveEarliest => legs.lastOrNull?.arriveEarliest;
  DateTime? get arriveLatest => legs.lastOrNull?.arriveLatest;
}

/// Estimates door-to-door time as a best-case / worst-case range.
///
/// With a departure time it simulates the trip twice, once with the shortest
/// durations and once with the longest, waiting for real departures each time.
final class TimeCalculator {
  const TimeCalculator();

  TimeEstimate estimate(List<Leg> legs, {DateTime? departure}) {
    final travel = legs.fold(IntRange.zero, (sum, leg) => sum + leg.duration);

    if (departure == null) {
      final waits = [for (final leg in legs) IntRange.exact(leg.prepMinutes)];
      final waiting = waits.fold(IntRange.zero, (a, b) => a + b);
      return TimeEstimate(
        travel: travel,
        waiting: waiting,
        total: travel + waiting,
        schedulesApplied: false,
        legs: [for (final w in waits) LegTiming(wait: w)],
      );
    }

    final best = _simulate(legs, departure, worstCase: false);
    final worst = _simulate(legs, departure, worstCase: true);
    final timings = [
      for (var i = 0; i < legs.length; i++)
        LegTiming(
          wait: _ordered(best[i].wait, worst[i].wait),
          departEarliest: best[i].depart,
          departLatest: worst[i].depart,
          arriveEarliest: best[i].arrive,
          arriveLatest: worst[i].arrive,
        ),
    ];
    int span(List<_Step> steps) =>
        steps.isEmpty ? 0 : steps.last.arrive.difference(departure).inMinutes;
    int waits(List<_Step> steps) => steps.fold(0, (sum, s) => sum + s.wait);

    // Arriving later can mean a shorter wait for the same ship, so the waits
    // are reported as a plain range while the total comes from the two runs.
    return TimeEstimate(
      travel: travel,
      waiting: _ordered(waits(best), waits(worst)),
      total: _ordered(span(best), span(worst)),
      schedulesApplied: true,
      legs: timings,
    );
  }

  static IntRange _ordered(int a, int b) =>
      a <= b ? IntRange(a, b) : IntRange(b, a);

  List<_Step> _simulate(
    List<Leg> legs,
    DateTime start, {
    required bool worstCase,
  }) {
    final steps = <_Step>[];
    var t = start;
    for (final leg in legs) {
      final depart = nextDeparture(leg.schedule, t, worstCase: worstCase);
      final minutes = worstCase ? leg.duration.max : leg.duration.min;
      final arrive = depart.add(Duration(minutes: minutes));
      steps.add(_Step(depart.difference(t).inMinutes, depart, arrive));
      t = arrive;
    }
    return steps;
  }

  /// The departure a traveller ready at [ready] can catch.
  ///
  /// For ships the traveller must be at the port [FixedDeparture.checkInMinutes]
  /// before sailing. For buses the best case is an immediate departure and the
  /// worst case is a full headway (never past the last trip).
  static DateTime nextDeparture(
    LegSchedule? schedule,
    DateTime ready, {
    required bool worstCase,
  }) {
    switch (schedule) {
      case null:
        return ready;
      case FixedDeparture(
        :final departAbs,
        :final daysOfWeek,
        :final checkInMinutes,
      ):
        DateTime? best;
        // A stop can be days into the voyage, so look back as well as ahead.
        final daysBack = departAbs ~/ 1440 + 1;
        for (var k = -daysBack; k <= 8; k++) {
          final day0 = _midnight(ready, k);
          if (!daysOfWeek.contains(day0.weekday)) continue;
          final depart = day0.add(Duration(minutes: departAbs));
          final mustArrive = depart.subtract(Duration(minutes: checkInMinutes));
          if (mustArrive.isBefore(ready)) continue;
          if (best == null || depart.isBefore(best)) best = depart;
        }
        if (best == null) {
          throw StateError('Voyage has no sailing days: $daysOfWeek');
        }
        return best;
      case FrequentDeparture(
        :final firstTrip,
        :final lastTrip,
        :final headwayMinutes,
      ):
        final minuteOfDay = ready.hour * 60 + ready.minute;
        if (minuteOfDay <= firstTrip) {
          return _midnight(ready, 0).add(Duration(minutes: firstTrip));
        }
        if (minuteOfDay > lastTrip) {
          return _midnight(ready, 1).add(Duration(minutes: firstTrip));
        }
        if (!worstCase) return ready;
        final last = _midnight(ready, 0).add(Duration(minutes: lastTrip));
        final next = ready.add(Duration(minutes: headwayMinutes));
        return next.isAfter(last) ? last : next;
    }
  }

  static DateTime _midnight(DateTime t, int addDays) => t.isUtc
      ? DateTime.utc(t.year, t.month, t.day + addDays)
      : DateTime(t.year, t.month, t.day + addDays);
}

final class _Step {
  const _Step(this.wait, this.depart, this.arrive);

  final int wait;
  final DateTime depart;
  final DateTime arrive;
}
