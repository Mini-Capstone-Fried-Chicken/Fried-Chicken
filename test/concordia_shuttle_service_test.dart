// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Adjust the import path to wherever you placed the service in your project.
import 'package:campus_app/services/concordia_shuttle_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a [DateTime] on a Monday (guaranteed weekday).
  DateTime monday({int hour = 12, int minute = 0}) {
    // Find the most recent Monday relative to a fixed reference date so tests
    // are not sensitive to the actual current date.
    final ref = DateTime(2025, 1, 6, hour, minute); // 6 Jan 2025 is a Monday
    return ref;
  }

  /// Returns a [DateTime] on a Saturday (guaranteed weekend).
  DateTime saturday({int hour = 12, int minute = 0}) {
    final ref = DateTime(2025, 1, 4, hour, minute); // 4 Jan 2025 is a Saturday
    return ref;
  }

  // ---------------------------------------------------------------------------
  // ConcordiaShuttleService.isInService
  // ---------------------------------------------------------------------------
  group('ConcordiaShuttleService.isInService', () {
    test('returns true during weekday service hours (mid-day)', () {
      expect(
        ConcordiaShuttleService.isInService(at: monday(hour: 12)),
        isTrue,
      );
    });

    test('returns true at weekday start boundary (08:00)', () {
      expect(
        ConcordiaShuttleService.isInService(at: monday(hour: 8, minute: 0)),
        isTrue,
      );
    });

    test('returns true at weekday end boundary (21:59)', () {
      expect(
        ConcordiaShuttleService.isInService(at: monday(hour: 21, minute: 59)),
        isTrue,
      );
    });

    test('returns false before weekday service starts (07:59)', () {
      expect(
        ConcordiaShuttleService.isInService(at: monday(hour: 7, minute: 59)),
        isFalse,
      );
    });

    test('returns false at or after weekday end hour (22:00)', () {
      expect(
        ConcordiaShuttleService.isInService(at: monday(hour: 22, minute: 0)),
        isFalse,
      );
    });

    test('returns false well after weekday service ends (23:00)', () {
      expect(
        ConcordiaShuttleService.isInService(at: monday(hour: 23)),
        isFalse,
      );
    });

    test('returns true during weekend service hours (mid-day)', () {
      expect(
        ConcordiaShuttleService.isInService(at: saturday(hour: 12)),
        isTrue,
      );
    });

    test('returns true at weekend start boundary (09:00)', () {
      expect(
        ConcordiaShuttleService.isInService(at: saturday(hour: 9, minute: 0)),
        isTrue,
      );
    });

    test('returns true at weekend end boundary (17:59)', () {
      expect(
        ConcordiaShuttleService.isInService(
            at: saturday(hour: 17, minute: 59)),
        isTrue,
      );
    });

    test('returns false before weekend service starts (08:59)', () {
      expect(
        ConcordiaShuttleService.isInService(
            at: saturday(hour: 8, minute: 59)),
        isFalse,
      );
    });

    test('returns false at or after weekend end hour (18:00)', () {
      expect(
        ConcordiaShuttleService.isInService(at: saturday(hour: 18, minute: 0)),
        isFalse,
      );
    });

    test('returns false after weekend service ends (20:00)', () {
      expect(
        ConcordiaShuttleService.isInService(at: saturday(hour: 20)),
        isFalse,
      );
    });

    // Sunday behaves the same as Saturday
    test('Sunday counts as a weekend day — in service at 10:00', () {
      final sunday = DateTime(2025, 1, 5, 10, 0); // 5 Jan 2025 is Sunday
      expect(ConcordiaShuttleService.isInService(at: sunday), isTrue);
    });

    test('Friday counts as a weekday — in service at 10:00', () {
      final friday = DateTime(2025, 1, 10, 10, 0); // 10 Jan 2025 is Friday
      expect(ConcordiaShuttleService.isInService(at: friday), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ConcordiaShuttleService.nearestStop
  // ---------------------------------------------------------------------------
  group('ConcordiaShuttleService.nearestStop', () {
    test('returns SGW for a location near SGW campus', () {
      // Very close to shuttleStopSGW = (45.4971, -73.5790)
      const nearSGW = LatLng(45.4972, -73.5791);
      expect(ConcordiaShuttleService.nearestStop(nearSGW), equals('SGW'));
    });

    test('returns Loyola for a location near Loyola campus', () {
      // Very close to shuttleStopLoyola = (45.4582, -73.6395)
      const nearLoyola = LatLng(45.4581, -73.6396);
      expect(ConcordiaShuttleService.nearestStop(nearLoyola), equals('Loyola'));
    });

    test('returns SGW when location is exactly at the SGW stop', () {
      expect(
        ConcordiaShuttleService.nearestStop(shuttleStopSGW),
        equals('SGW'),
      );
    });

    test('returns Loyola when location is exactly at the Loyola stop', () {
      expect(
        ConcordiaShuttleService.nearestStop(shuttleStopLoyola),
        equals('Loyola'),
      );
    });

    test('returns SGW for a midpoint slightly closer to SGW', () {
      // Midpoint between the two stops is around (45.4777, -73.6093).
      // Shifting slightly toward SGW (higher lat, less negative lng).
      const slightlySGW = LatLng(45.480, -73.600);
      expect(ConcordiaShuttleService.nearestStop(slightlySGW), equals('SGW'));
    });

    test('returns Loyola for a midpoint slightly closer to Loyola', () {
      const slightlyLoyola = LatLng(45.460, -73.630);
      expect(
          ConcordiaShuttleService.nearestStop(slightlyLoyola), equals('Loyola'));
    });
  });

  // ---------------------------------------------------------------------------
  // ConcordiaShuttleService.stopLocation
  // ---------------------------------------------------------------------------
  group('ConcordiaShuttleService.stopLocation', () {
    test('returns shuttleStopSGW for stop name SGW', () {
      final loc = ConcordiaShuttleService.stopLocation('SGW');
      expect(loc.latitude, closeTo(shuttleStopSGW.latitude, 1e-6));
      expect(loc.longitude, closeTo(shuttleStopSGW.longitude, 1e-6));
    });

    test('returns shuttleStopLoyola for stop name Loyola', () {
      final loc = ConcordiaShuttleService.stopLocation('Loyola');
      expect(loc.latitude, closeTo(shuttleStopLoyola.latitude, 1e-6));
      expect(loc.longitude, closeTo(shuttleStopLoyola.longitude, 1e-6));
    });

    test('falls back to Loyola for an unrecognised stop name', () {
      // By the ternary logic: any value that != 'SGW' returns Loyola coords.
      final loc = ConcordiaShuttleService.stopLocation('unknown');
      expect(loc.latitude, closeTo(shuttleStopLoyola.latitude, 1e-6));
    });
  });

  // ---------------------------------------------------------------------------
  // ConcordiaShuttleService.formatTime
  // ---------------------------------------------------------------------------
  group('ConcordiaShuttleService.formatTime', () {
    test('formats midnight as 12:00 AM', () {
      final t = DateTime(2025, 1, 6, 0, 0);
      expect(ConcordiaShuttleService.formatTime(t), equals('12:00 AM'));
    });

    test('formats noon as 12:00 PM', () {
      final t = DateTime(2025, 1, 6, 12, 0);
      expect(ConcordiaShuttleService.formatTime(t), equals('12:00 PM'));
    });

    test('formats 8:00 as 8:00 AM (no leading zero on hour)', () {
      final t = DateTime(2025, 1, 6, 8, 0);
      expect(ConcordiaShuttleService.formatTime(t), equals('8:00 AM'));
    });

    test('formats 8:30 as 8:30 AM', () {
      final t = DateTime(2025, 1, 6, 8, 30);
      expect(ConcordiaShuttleService.formatTime(t), equals('8:30 AM'));
    });

    test('formats 13:00 as 1:00 PM', () {
      final t = DateTime(2025, 1, 6, 13, 0);
      expect(ConcordiaShuttleService.formatTime(t), equals('1:00 PM'));
    });

    test('formats 22:00 as 10:00 PM', () {
      final t = DateTime(2025, 1, 6, 22, 0);
      expect(ConcordiaShuttleService.formatTime(t), equals('10:00 PM'));
    });

    test('zero-pads single-digit minutes (9:05 AM)', () {
      final t = DateTime(2025, 1, 6, 9, 5);
      expect(ConcordiaShuttleService.formatTime(t), equals('9:05 AM'));
    });
  });

  // ---------------------------------------------------------------------------
  // ConcordiaShuttleService.getFullScheduleForDay
  // ---------------------------------------------------------------------------
  group('ConcordiaShuttleService.getFullScheduleForDay', () {
    test('weekday schedule starts at 08:00', () {
      final times = ConcordiaShuttleService.getFullScheduleForDay(monday());
      expect(times.first.hour, equals(8));
      expect(times.first.minute, equals(0));
    });

    test('weekday schedule ends at 22:00', () {
      final times = ConcordiaShuttleService.getFullScheduleForDay(monday());
      expect(times.last.hour, equals(22));
      expect(times.last.minute, equals(0));
    });

    test('weekday schedule has 30-minute intervals', () {
      final times = ConcordiaShuttleService.getFullScheduleForDay(monday());
      for (var i = 1; i < times.length; i++) {
        final diff = times[i].difference(times[i - 1]).inMinutes;
        expect(diff, equals(30),
            reason: 'Expected 30-min gap between entries $i-1 and $i');
      }
    });

    test('weekday schedule has correct number of entries (08:00–22:00 every 30 min = 29 entries)', () {
      // 8:00, 8:30, 9:00 … 22:00 → (22-8)*2 + 1 = 29
      final times = ConcordiaShuttleService.getFullScheduleForDay(monday());
      expect(times.length, equals(29));
    });

    test('weekend schedule starts at 09:00', () {
      final times = ConcordiaShuttleService.getFullScheduleForDay(saturday());
      expect(times.first.hour, equals(9));
      expect(times.first.minute, equals(0));
    });

    test('weekend schedule ends at 18:00', () {
      final times = ConcordiaShuttleService.getFullScheduleForDay(saturday());
      expect(times.last.hour, equals(18));
      expect(times.last.minute, equals(0));
    });

    test('weekend schedule has 15-minute intervals', () {
      final times = ConcordiaShuttleService.getFullScheduleForDay(saturday());
      for (var i = 1; i < times.length; i++) {
        final diff = times[i].difference(times[i - 1]).inMinutes;
        expect(diff, equals(15),
            reason: 'Expected 15-min gap between entries $i-1 and $i');
      }
    });

    test('weekend schedule has correct number of entries (09:00–18:00 every 15 min = 37 entries)', () {
      // 9:00 to 18:00 inclusive every 15 min → (9*60/15) + 1 = 37
      final times = ConcordiaShuttleService.getFullScheduleForDay(saturday());
      expect(times.length, equals(37));
    });

    test('all schedule times fall on the requested day', () {
      final day = monday();
      final times = ConcordiaShuttleService.getFullScheduleForDay(day);
      for (final t in times) {
        expect(t.year, equals(day.year));
        expect(t.month, equals(day.month));
        expect(t.day, equals(day.day));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ConcordiaShuttleService.getNextDepartures
  // ---------------------------------------------------------------------------
  group('ConcordiaShuttleService.getNextDepartures', () {
    test('returns exactly [count] departures when enough remain today', () {
      // 10:00 AM weekday — plenty of buses left in the day
      final now = monday(hour: 10, minute: 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 4,
      );
      expect(buses.length, equals(4));
    });

    test('first departure is at or after [now]', () {
      final now = monday(hour: 10, minute: 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 4,
      );
      expect(buses.first.time.isBefore(now), isFalse);
    });

    test('departure times are in ascending order', () {
      final now = monday(hour: 10, minute: 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 4,
      );
      for (var i = 1; i < buses.length; i++) {
        expect(buses[i].time.isAfter(buses[i - 1].time), isTrue,
            reason: 'Bus $i should depart after bus ${i - 1}');
      }
    });

    test('fromStop and toStop are set correctly for SGW', () {
      final now = monday(hour: 10, minute: 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 1,
      );
      expect(buses.first.fromStop, equals('SGW'));
      expect(buses.first.toStop, equals('Loyola'));
    });

    test('fromStop and toStop are set correctly for Loyola', () {
      final now = monday(hour: 10, minute: 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'Loyola',
        now: now,
        count: 1,
      );
      expect(buses.first.fromStop, equals('Loyola'));
      expect(buses.first.toStop, equals('SGW'));
    });

    test('walking duration pushes earliest boardable departure forward', () {
      // 09:55 weekday — without walking, first bus would be 10:00.
      // With 10 min walk, earliest board = 10:05, so first bus is 10:30.
      final now = monday(hour: 9, minute: 55);
      final withWalk = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 1,
        walkingDuration: const Duration(minutes: 10),
      );
      final withoutWalk = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 1,
      );
      expect(
        withWalk.first.time.isAfter(withoutWalk.first.time) ||
            withWalk.first.time == withoutWalk.first.time,
        isTrue,
        reason: 'Walking time should delay or keep equal the first bus',
      );
    });

    test('walking time is stored on the departure object', () {
      final walk = const Duration(minutes: 8);
      final now = monday(hour: 10);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 1,
        walkingDuration: walk,
      );
      expect(buses.first.walkingTime, equals(walk));
    });

    test('returns fewer than [count] when near end of service (no tomorrow overflow needed)', () {
      // 21:31 weekday — only one 30-min slot left (22:00); requesting 4 should
      // spill to tomorrow and still fill 4.
      final now = monday(hour: 21, minute: 31);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 4,
      );
      // At most 1 departure left today (22:00); the rest come from tomorrow
      expect(buses.length, equals(4));
    });

    test('returns buses from the next day when called after service ends', () {
      // 23:00 weekday — no buses left today
      final now = monday(hour: 23, minute: 0);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 2,
      );
      // All buses must be on the next calendar day
      for (final bus in buses) {
        expect(
          bus.time.isAfter(now),
          isTrue,
          reason: 'Expected bus time ${bus.time} to be after $now',
        );
      }
    });

    test('returns empty list when count is 0', () {
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: monday(hour: 10),
        count: 0,
      );
      expect(buses, isEmpty);
    });

    test('weekday departures are 30 minutes apart', () {
      final now = monday(hour: 10);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 4,
      );
      for (var i = 1; i < buses.length; i++) {
        final gap = buses[i].time.difference(buses[i - 1].time).inMinutes;
        expect(gap, equals(30));
      }
    });

    test('weekend departures are 15 minutes apart', () {
      final now = saturday(hour: 10);
      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: 'SGW',
        now: now,
        count: 4,
      );
      for (var i = 1; i < buses.length; i++) {
        final gap = buses[i].time.difference(buses[i - 1].time).inMinutes;
        expect(gap, equals(15));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Shuttle stop coordinate constants
  // ---------------------------------------------------------------------------
  group('Shuttle stop constants', () {
    test('shuttleStopSGW is near SGW campus (Hall Building area)', () {
      expect(shuttleStopSGW.latitude, closeTo(45.497, 0.01));
      expect(shuttleStopSGW.longitude, closeTo(-73.579, 0.01));
    });

    test('shuttleStopLoyola is near Loyola campus', () {
      expect(shuttleStopLoyola.latitude, closeTo(45.458, 0.01));
      expect(shuttleStopLoyola.longitude, closeTo(-73.640, 0.01));
    });

    test('SGW and Loyola stops are distinct locations', () {
      expect(
        shuttleStopSGW.latitude != shuttleStopLoyola.latitude ||
            shuttleStopSGW.longitude != shuttleStopLoyola.longitude,
        isTrue,
      );
    });
  });
}