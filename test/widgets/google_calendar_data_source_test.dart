import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/ui/widgets/google_calendar_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCalendarDataSource', () {
    final event1 = GoogleCalendarEvent(
      id: '1',
      title: 'SOEN 341 Lecture',
      start: DateTime(2026, 3, 12, 10, 0),
      end: DateTime(2026, 3, 12, 11, 15),
      location: 'H-937',
      calendarId: 'cal_1',
      calendarName: 'SOEN 341',
      color: const Color(0xFF8B1E3F),
    );

    final event2 = GoogleCalendarEvent(
      id: '2',
      title: 'SOEN 357 Lab',
      start: DateTime(2026, 3, 13, 14, 0),
      end: null,
      location: 'H-831',
      calendarId: 'cal_2',
      calendarName: 'SOEN 357',
      color: const Color(0xFF2563EB),
    );

    test('stores appointments passed in constructor', () {
      final dataSource = GoogleCalendarDataSource([event1, event2]);

      expect(dataSource.appointments, isNotNull);
      expect(dataSource.appointments!.length, 2);
      expect(dataSource.appointments![0], equals(event1));
      expect(dataSource.appointments![1], equals(event2));
    });

    test('getStartTime returns event start time', () {
      final dataSource = GoogleCalendarDataSource([event1]);

      expect(dataSource.getStartTime(0), equals(event1.start));
    });

    test('getEndTime returns event end time when present', () {
      final dataSource = GoogleCalendarDataSource([event1]);

      expect(dataSource.getEndTime(0), equals(event1.end));
    });

    test('getEndTime falls back to start + 1 hour when end is null', () {
      final dataSource = GoogleCalendarDataSource([event2]);

      expect(
        dataSource.getEndTime(0),
        equals(event2.start!.add(const Duration(hours: 1))),
      );
    });

    test('getSubject returns event title', () {
      final dataSource = GoogleCalendarDataSource([event1]);

      expect(dataSource.getSubject(0), equals('SOEN 341 Lecture'));
    });

    test('getColor returns event color', () {
      final dataSource = GoogleCalendarDataSource([event2]);

      expect(dataSource.getColor(0), equals(const Color(0xFF2563EB)));
    });

    test('isAllDay always returns false', () {
      final dataSource = GoogleCalendarDataSource([event1, event2]);

      expect(dataSource.isAllDay(0), isFalse);
      expect(dataSource.isAllDay(1), isFalse);
    });

    test('works with multiple events at different indexes', () {
      final dataSource = GoogleCalendarDataSource([event1, event2]);

      expect(dataSource.getSubject(0), equals('SOEN 341 Lecture'));
      expect(dataSource.getSubject(1), equals('SOEN 357 Lab'));

      expect(dataSource.getStartTime(0), equals(event1.start));
      expect(dataSource.getStartTime(1), equals(event2.start));

      expect(dataSource.getColor(0), equals(const Color(0xFF8B1E3F)));
      expect(dataSource.getColor(1), equals(const Color(0xFF2563EB)));
    });
  });
}