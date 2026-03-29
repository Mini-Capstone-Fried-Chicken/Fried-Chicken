import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';

void main() {
  group('GoogleCalendarEvent', () {
    final start = DateTime(2025, 1, 1, 10);
    final end = DateTime(2025, 1, 1, 11);

    const color = Color(0xFF8B1E3F);

    test('constructor assigns values correctly', () {
      final event = GoogleCalendarEvent(
        id: '1',
        title: 'Lecture',
        start: start,
        end: end,
        location: 'Hall A',
        description: 'H-937',
        calendarId: 'calendar1',
        calendarName: 'School',
        color: color,
      );

      expect(event.id, '1');
      expect(event.title, 'Lecture');
      expect(event.start, start);
      expect(event.end, end);
      expect(event.location, 'Hall A');
      expect(event.description, 'H-937');
      expect(event.calendarId, 'calendar1');
      expect(event.calendarName, 'School');
      expect(event.color, color);
    });

    test('copyWith overrides provided fields', () {
      final event = GoogleCalendarEvent(
        id: '1',
        title: 'Lecture',
        start: start,
        end: end,
        location: 'Hall A',
        description: 'H-937',
        calendarId: 'calendar1',
        calendarName: 'School',
        color: color,
      );

      final updated = event.copyWith(
        title: 'Updated Lecture',
        location: 'Hall B',
        description: 'MB-2.130',
      );

      expect(updated.title, 'Updated Lecture');
      expect(updated.location, 'Hall B');
      expect(updated.description, 'MB-2.130');

      expect(updated.id, event.id);
      expect(updated.start, event.start);
      expect(updated.calendarId, event.calendarId);
    });

    test('copyWith keeps existing values when parameters are null', () {
      final event = GoogleCalendarEvent(
        id: '1',
        title: 'Lecture',
        start: start,
        end: end,
        location: 'Hall A',
        description: 'H-937',
        calendarId: 'calendar1',
        calendarName: 'School',
        color: color,
      );

      final updated = event.copyWith();

      expect(updated.id, event.id);
      expect(updated.title, event.title);
      expect(updated.start, event.start);
      expect(updated.end, event.end);
      expect(updated.location, event.location);
      expect(updated.description, event.description);
      expect(updated.calendarId, event.calendarId);
      expect(updated.calendarName, event.calendarName);
      expect(updated.color, event.color);
    });
  });
}
