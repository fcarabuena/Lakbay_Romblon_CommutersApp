import 'package:lakbay_core/lakbay_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

Leg _leg(IntRange duration, {LegSchedule? schedule}) => Leg(
  id: 'leg',
  kind: LegKind.localRide,
  fromId: 'a',
  toId: 'b',
  baseFare: IntRange.zero,
  duration: duration,
  schedule: schedule,
  verification: Verification.placeholder,
);

void main() {
  const calc = TimeCalculator();

  group('nextDeparture – ships', () {
    const mondayThursday8pm = FixedDeparture(
      departAbs: 20 * 60,
      daysOfWeek: [1, 4],
      checkInMinutes: 60,
    );

    test('catches the same-day sailing when there is time to check in', () {
      final d = TimeCalculator.nextDeparture(
        mondayThursday8pm,
        monday(10),
        worstCase: false,
      );
      expect(d, monday(20));
    });

    test('misses the sailing when check-in has closed', () {
      final d = TimeCalculator.nextDeparture(
        mondayThursday8pm,
        monday(19, 30),
        worstCase: false,
      );
      expect(d, DateTime.utc(2027, 10, 28, 20)); // Thursday
    });

    test('handles stops that are a day into the voyage', () {
      // Voyage leaves Mondays; this stop departs at 02:00 the next day.
      const nextDayStop = FixedDeparture(
        departAbs: 1440 + 120,
        daysOfWeek: [1],
        checkInMinutes: 60,
      );
      final d = TimeCalculator.nextDeparture(
        nextDayStop,
        DateTime.utc(2027, 10, 26, 0, 30), // Tuesday 00:30
        worstCase: false,
      );
      expect(d, DateTime.utc(2027, 10, 26, 2));
    });
  });

  group('nextDeparture – buses', () {
    const bus = FrequentDeparture(
      firstTrip: 4 * 60,
      lastTrip: 21 * 60,
      headwayMinutes: 30,
    );

    test('waits for the first trip before service starts', () {
      expect(
        TimeCalculator.nextDeparture(bus, monday(2), worstCase: true),
        monday(4),
      );
    });

    test('waits for tomorrow after the last trip', () {
      expect(
        TimeCalculator.nextDeparture(bus, monday(22), worstCase: false),
        DateTime.utc(2027, 10, 26, 4),
      );
    });

    test('best case leaves now, worst case waits a full headway', () {
      expect(
        TimeCalculator.nextDeparture(bus, monday(10), worstCase: false),
        monday(10),
      );
      expect(
        TimeCalculator.nextDeparture(bus, monday(10), worstCase: true),
        monday(10, 30),
      );
    });

    test('worst case never waits past the last trip', () {
      expect(
        TimeCalculator.nextDeparture(bus, monday(20, 50), worstCase: true),
        monday(21),
      );
    });
  });

  group('estimate', () {
    final ship = _leg(
      const IntRange(300, 360),
      schedule: const FixedDeparture(
        departAbs: 20 * 60,
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        checkInMinutes: 60,
      ),
    );
    final tricycle = _leg(const IntRange(15, 20));

    test('without a departure, adds only check-in time', () {
      final e = calc.estimate([tricycle, ship]);
      expect(e.schedulesApplied, isFalse);
      expect(e.travel, const IntRange(315, 380));
      expect(e.waiting, const IntRange.exact(60));
      expect(e.total, const IntRange(375, 440));
      expect(e.arriveEarliest, isNull);
    });

    test('with a departure, includes waiting for the sailing', () {
      // Leave home 18:00, at the pier by 18:15–18:20, ship sails at 20:00.
      final e = calc.estimate([tricycle, ship], departure: monday(18));
      expect(e.schedulesApplied, isTrue);
      expect(e.arriveEarliest, DateTime.utc(2027, 10, 26, 1));
      expect(e.arriveLatest, DateTime.utc(2027, 10, 26, 2));
      expect(e.total, const IntRange(420, 480));
      expect(e.legs[1].wait, const IntRange(100, 105));
      expect(e.legs[1].departEarliest, monday(20));
    });

    test('an empty plan takes no time', () {
      final e = calc.estimate(const [], departure: monday(8));
      expect(e.total, IntRange.zero);
    });
  });
}
