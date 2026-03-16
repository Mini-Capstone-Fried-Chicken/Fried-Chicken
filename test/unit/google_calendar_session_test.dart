import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_app/features/calendar/data/models/calendar_connection_state.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';
import 'package:campus_app/features/calendar/services/google_calendar_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCalendarSession', () {
    late GoogleCalendarSession session;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      session = GoogleCalendarSession.instance;
      await session.clear();
    });

    test('starts with default values after clear', () async {
      expect(session.isConnected, false);
      expect(session.step, CalendarConnectionStep.connect);
      expect(session.calendars, isEmpty);
      expect(session.selectedCalendarIds, isEmpty);
      expect(session.events, isEmpty);
    });

    test('persist saves isConnected, step, and selectedCalendarIds', () async {
      session.isConnected = true;
      session.step = CalendarConnectionStep.schedule;
      session.selectedCalendarIds = {'cal1', 'cal2'};

      await session.persist();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('calendar_is_connected'), isTrue);
      expect(
        prefs.getInt('calendar_step'),
        CalendarConnectionStep.schedule.index,
      );

      final ids = prefs.getStringList('calendar_selected_ids');
      expect(ids, isNotNull);
      expect(ids!.toSet(), {'cal1', 'cal2'});
    });

    test('restore loads persisted values', () async {
      SharedPreferences.setMockInitialValues({
        'calendar_is_connected': true,
        'calendar_step': CalendarConnectionStep.selectCalendar.index,
        'calendar_selected_ids': ['calA', 'calB'],
      });

      session = GoogleCalendarSession.instance;
      await session.restore();

      expect(session.isConnected, isTrue);
      expect(session.step, CalendarConnectionStep.selectCalendar);
      expect(session.selectedCalendarIds, {'calA', 'calB'});
    });

    test('restore falls back to defaults when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});

      session = GoogleCalendarSession.instance;
      await session.restore();

      expect(session.isConnected, isFalse);
      expect(session.step, CalendarConnectionStep.connect);
      expect(session.selectedCalendarIds, isEmpty);
    });

    test('restore falls back to connect step when saved step is invalid', () async {
      SharedPreferences.setMockInitialValues({
        'calendar_is_connected': true,
        'calendar_step': 999,
        'calendar_selected_ids': ['cal1'],
      });

      session = GoogleCalendarSession.instance;
      await session.restore();

      expect(session.isConnected, isTrue);
      expect(session.step, CalendarConnectionStep.connect);
      expect(session.selectedCalendarIds, {'cal1'});
    });

    test('clear resets in-memory state and removes persisted values', () async {
      session.isConnected = true;
      session.step = CalendarConnectionStep.schedule;
      session.calendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];
      session.selectedCalendarIds = {'cal1'};
      session.events = [
        GoogleCalendarEvent(
          id: 'event1',
          title: 'Lecture',
          start: DateTime(2026, 3, 12, 10, 0),
          end: DateTime(2026, 3, 12, 11, 0),
          location: 'H-937',
          calendarId: 'cal1',
          calendarName: 'SOEN 341',
          color: const Color(0xFF8B1E3F),
        ),
      ];

      await session.persist();
      await session.clear();

      expect(session.isConnected, isFalse);
      expect(session.step, CalendarConnectionStep.connect);
      expect(session.calendars, isEmpty);
      expect(session.selectedCalendarIds, isEmpty);
      expect(session.events, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('calendar_is_connected'), isNull);
      expect(prefs.getInt('calendar_step'), isNull);
      expect(prefs.getStringList('calendar_selected_ids'), isNull);
    });
  });
}