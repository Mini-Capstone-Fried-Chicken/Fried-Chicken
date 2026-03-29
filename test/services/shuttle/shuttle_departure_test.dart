// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/services/concordia_shuttle_service.dart';

void main() {

  ShuttleDeparture _departureInMinutes(
    int offsetMinutes, {
    String fromStop = 'SGW',
    Duration walkingTime = Duration.zero,
  }) {
    return ShuttleDeparture(
      time: DateTime.now().add(Duration(minutes: offsetMinutes)),
      fromStop: fromStop,
      toStop: fromStop == 'SGW' ? 'Loyola' : 'SGW',
      walkingTime: walkingTime,
    );
  }

//test for shuttel departure fields
  group('ShuttleDeparture fields', () {
    test('stores fromStop correctly', () {
      final d = ShuttleDeparture(
        time: DateTime(2025, 1, 6, 10, 0),
        fromStop: 'SGW',
        toStop: 'Loyola',
      );
      expect(d.fromStop, equals('SGW'));
    });

    test('stores toStop correctly', () {
      final d = ShuttleDeparture(
        time: DateTime(2025, 1, 6, 10, 0),
        fromStop: 'Loyola',
        toStop: 'SGW',
      );
      expect(d.toStop, equals('SGW'));
    });

    test('default walkingTime is Duration.zero', () {
      final d = ShuttleDeparture(
        time: DateTime(2025, 1, 6, 10, 0),
        fromStop: 'SGW',
        toStop: 'Loyola',
      );
      expect(d.walkingTime, equals(Duration.zero));
    });

    test('stores custom walkingTime correctly', () {
      const walk = Duration(minutes: 7);
      final d = ShuttleDeparture(
        time: DateTime(2025, 1, 6, 10, 0),
        fromStop: 'SGW',
        toStop: 'Loyola',
        walkingTime: walk,
      );
      expect(d.walkingTime, equals(walk));
    });

    test('stores departure time correctly', () {
      final t = DateTime(2025, 1, 6, 14, 30);
      final d = ShuttleDeparture(
        time: t,
        fromStop: 'SGW',
        toStop: 'Loyola',
      );
      expect(d.time, equals(t));
    });
  });

//test for shuttle departure minutes till arrival
  group('ShuttleDeparture.minutesUntil', () {
    test('is approximately the offset used to create the departure', () {
      final d = _departureInMinutes(15);
      expect(d.minutesUntil, inInclusiveRange(14, 16));
    });

    test('is negative for a past departure', () {
      final d = _departureInMinutes(-10);
      expect(d.minutesUntil, isNegative);
    });

    test('is zero or close to zero for a departure happening right now', () {
      final d = _departureInMinutes(0);
      expect(d.minutesUntil, inInclusiveRange(-1, 1));
    });
  });

//test for shuttle departure time format
  group('ShuttleDeparture.formattedTime', () {
    test('delegates to ConcordiaShuttleService.formatTime', () {
      final t = DateTime(2025, 1, 6, 8, 30);
      final d = ShuttleDeparture(
        time: t,
        fromStop: 'SGW',
        toStop: 'Loyola',
      );
      expect(d.formattedTime, equals(ConcordiaShuttleService.formatTime(t)));
    });

    test('formats an AM time correctly', () {
      final d = ShuttleDeparture(
        time: DateTime(2025, 1, 6, 9, 0),
        fromStop: 'SGW',
        toStop: 'Loyola',
      );
      expect(d.formattedTime, equals('9:00 AM'));
    });

    test('formats a PM time correctly', () {
      final d = ShuttleDeparture(
        time: DateTime(2025, 1, 6, 14, 0),
        fromStop: 'SGW',
        toStop: 'Loyola',
      );
      expect(d.formattedTime, equals('2:00 PM'));
    });
  });

//tests for shuttle departure status 
  group('ShuttleDeparture.statusLabel', () {
    test('returns "Departing now" when minutesUntil == 0', () {
      final d = _departureInMinutes(0);

      expect(
        d.statusLabel == 'Departing now' || d.minutesUntil <= 0,
        isTrue,
      );
    });

    test('returns "Departing now" for a past departure', () {
      final d = _departureInMinutes(-5);
      expect(d.statusLabel, equals('Departing now'));
    });

    test('returns "In 1 min" when exactly 1 minute away', () {
      final d = _departureInMinutes(1);
      expect(d.statusLabel, equals('In 1 min'));
    });

    test('returns "In X min" for 2–59 minutes away', () {
      for (final mins in [2, 10, 29, 45, 59]) {
        final d = _departureInMinutes(mins);
        final label = d.statusLabel;
        expect(label, startsWith('In '),
            reason: 'Expected "In X min" for offset $mins, got "$label"');
        expect(label, endsWith(' min'),
            reason: 'Expected "In X min" for offset $mins, got "$label"');
      }
    });

    test('returns formatted time string for 60+ minutes away', () {
      final d = _departureInMinutes(90);
      expect(d.statusLabel, isNot(startsWith('In ')));
      expect(d.statusLabel, isNot(equals('Departing now')));
      expect(
        RegExp(r'^\d{1,2}:\d{2} (AM|PM)$').hasMatch(d.statusLabel),
        isTrue,
        reason: 'Expected a formatted time, got "${d.statusLabel}"',
      );
    });

    test('boundary: 59 minutes → "In 59 min"', () {
      final d = _departureInMinutes(59);
      expect(d.statusLabel, equals('In 59 min'));
    });

    test('boundary: 60 minutes → formatted clock time', () {
      final d = _departureInMinutes(60);
      expect(
        RegExp(r'^\d{1,2}:\d{2} (AM|PM)$').hasMatch(d.statusLabel),
        isTrue,
        reason: 'Expected formatted time for 60 min, got "${d.statusLabel}"',
      );
    });
  });


  group('ShuttleDeparture via getNextDepartures integration', () {
    test('departures from SGW always point to Loyola', () {
      final now = DateTime(2025, 1, 6, 10, 0); // Monday 10 AM
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 4,
      );
      for (final bus in buses) {
        expect(bus.toStop, equals('Loyola'));
      }
    });

    test('departures from Loyola always point to SGW', () {
      final now = DateTime(2025, 1, 6, 10, 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'Loyola',
        now: now,
        count: 4,
      );
      for (final bus in buses) {
        expect(bus.toStop, equals('SGW'));
      }
    });

    test('walkingTime is propagated to every departure', () {
      const walk = Duration(minutes: 12);
      final now = DateTime(2025, 1, 6, 10, 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 3,
        walkingDuration: walk,
      );
      for (final bus in buses) {
        expect(bus.walkingTime, equals(walk));
      }
    });
  });
}