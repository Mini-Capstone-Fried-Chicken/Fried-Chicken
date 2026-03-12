import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/features/calendar/services/google_calendar_session.dart';
import 'package:campus_app/features/calendar/data/models/calendar_connection_state.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';
import 'package:flutter/material.dart';

void main() {
  group('GoogleCalendarSession', () {
    test('initial state is correct', () {
      final session = GoogleCalendarSession.instance;

      session.clear(); // ensure clean state

      expect(session.isConnected, false);
      expect(session.step, CalendarConnectionStep.connect);
      expect(session.calendars, isEmpty);
      expect(session.selectedCalendarIds, isEmpty);
      expect(session.events, isEmpty);
    });

    test('session stores calendars correctly', () {
      final session = GoogleCalendarSession.instance;
      session.clear();

      final calendars = [
        const GoogleCalendarInfo(
          id: 'cal1',
          name: 'SOEN 341',
          isPrimary: false,
        ),
        const GoogleCalendarInfo(
          id: 'cal2',
          name: 'SOEN 357',
          isPrimary: true,
        ),
      ];

      session.calendars = calendars;

      expect(session.calendars.length, 2);
      expect(session.calendars.first.name, 'SOEN 341');
      expect(session.calendars.last.id, 'cal2');
    });

    test('session stores selected calendar ids', () {
      final session = GoogleCalendarSession.instance;
      session.clear();

      session.selectedCalendarIds = {'cal1', 'cal2'};

      expect(session.selectedCalendarIds.contains('cal1'), true);
      expect(session.selectedCalendarIds.contains('cal2'), true);
      expect(session.selectedCalendarIds.length, 2);
    });

    test('session stores events correctly', () {
      final session = GoogleCalendarSession.instance;
      session.clear();

      final event = GoogleCalendarEvent(
        id: 'event1',
        title: 'SOEN 341 Lecture',
        start: DateTime(2026, 3, 12, 10),
        end: DateTime(2026, 3, 12, 11),
        location: 'H-937',
        calendarId: 'cal1',
        calendarName: 'SOEN 341',
        color: const Color(0xFF8B1E3F),
      );

      session.events = [event];

      expect(session.events.length, 1);
      expect(session.events.first.title, 'SOEN 341 Lecture');
    });

    test('clear resets the session state', () {
      final session = GoogleCalendarSession.instance;

      session.isConnected = true;
      session.step = CalendarConnectionStep.selectCalendar;

      session.calendars = [
        const GoogleCalendarInfo(
          id: 'cal1',
          name: 'SOEN 341',
          isPrimary: false,
        )
      ];

      session.selectedCalendarIds = {'cal1'};

      session.events = [
        GoogleCalendarEvent(
          id: 'event1',
          title: 'Lecture',
          start: DateTime(2026, 3, 12, 10),
          end: DateTime(2026, 3, 12, 11),
          location: 'H-937',
          calendarId: 'cal1',
          calendarName: 'SOEN 341',
          color: const Color(0xFF8B1E3F),
        )
      ];

      session.clear();

      expect(session.isConnected, false);
      expect(session.step, CalendarConnectionStep.connect);
      expect(session.calendars, isEmpty);
      expect(session.selectedCalendarIds, isEmpty);
      expect(session.events, isEmpty);
    });
  });
}