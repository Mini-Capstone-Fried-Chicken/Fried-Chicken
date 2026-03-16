import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';
import 'package:campus_app/features/calendar/services/google_calendar_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart';

class FakeAuthClient extends AuthClient {
  @override
  void close() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleCalendarApi implements IGoogleCalendarApi {
  gcal.CalendarList calendarsResponse;
  gcal.Events eventsResponse;

  FakeGoogleCalendarApi({
    gcal.CalendarList? calendarsResponse,
    gcal.Events? eventsResponse,
  }) : calendarsResponse = calendarsResponse ?? gcal.CalendarList(),
       eventsResponse = eventsResponse ?? gcal.Events();

  @override
  Future<gcal.CalendarList> listCalendars() async {
    return calendarsResponse;
  }

  @override
  Future<gcal.Events> listEvents(String calendarId) async {
    return eventsResponse;
  }
}

void main() {
  group('GoogleCalendarApiService', () {
    late FakeAuthClient client;

    setUp(() {
      client = FakeAuthClient();
    });

    test('fetchCalendars maps calendars and filters empty ids', () async {
      final response = gcal.CalendarList()
        ..items = [
          (gcal.CalendarListEntry()
            ..id = 'cal1'
            ..summary = 'SOEN 341'
            ..primary = true),
          (gcal.CalendarListEntry()
            ..id = ''
            ..summary = 'Invalid'
            ..primary = false),
          (gcal.CalendarListEntry()
            ..id = 'cal2'
            ..primary = false),
        ];

      final fakeApi = FakeGoogleCalendarApi(calendarsResponse: response);

      final service = GoogleCalendarApiService(apiFactory: (_) => fakeApi);

      final result = await service.fetchCalendars(client);

      expect(result.length, 2);

      expect(
        result[0],
        isA<GoogleCalendarInfo>()
            .having((c) => c.id, 'id', 'cal1')
            .having((c) => c.name, 'name', 'SOEN 341')
            .having((c) => c.isPrimary, 'isPrimary', true),
      );

      expect(
        result[1],
        isA<GoogleCalendarInfo>()
            .having((c) => c.id, 'id', 'cal2')
            .having((c) => c.name, 'name', 'Untitled calendar')
            .having((c) => c.isPrimary, 'isPrimary', false),
      );
    });

    test(
      'fetchCalendars returns empty list when response items are null',
      () async {
        final response = gcal.CalendarList();

        final fakeApi = FakeGoogleCalendarApi(calendarsResponse: response);

        final service = GoogleCalendarApiService(apiFactory: (_) => fakeApi);

        final result = await service.fetchCalendars(client);

        expect(result, isEmpty);
      },
    );

    test(
      'fetchUpcomingEvents maps events correctly including description',
      () async {
        final event1 = gcal.Event()
          ..id = 'event1'
          ..summary = 'SOEN 357 Lecture'
          ..location = 'Hall Building'
          ..description = 'H-937'
          ..start = (gcal.EventDateTime()
            ..dateTime = DateTime(2026, 3, 12, 18, 45))
          ..end = (gcal.EventDateTime()
            ..dateTime = DateTime(2026, 3, 12, 20, 0));

        final event2 = gcal.Event()
          ..id = 'event2'
          ..start = (gcal.EventDateTime()..date = DateTime(2026, 3, 13))
          ..end = (gcal.EventDateTime()..date = DateTime(2026, 3, 14));

        final response = gcal.Events()..items = [event1, event2];

        final fakeApi = FakeGoogleCalendarApi(eventsResponse: response);

        final service = GoogleCalendarApiService(apiFactory: (_) => fakeApi);

        final result = await service.fetchUpcomingEvents(
          client,
          calendarId: 'class_calendar',
        );

        expect(result.length, 2);

        expect(
          result[0],
          isA<GoogleCalendarEvent>()
              .having((e) => e.id, 'id', 'event1')
              .having((e) => e.title, 'title', 'SOEN 357 Lecture')
              .having((e) => e.location, 'location', 'Hall Building')
              .having((e) => e.description, 'description', 'H-937')
              .having((e) => e.calendarId, 'calendarId', 'class_calendar')
              .having((e) => e.calendarName, 'calendarName', '')
              .having((e) => e.color, 'color', const Color(0xFF8B1E3F)),
        );

        expect(result[1].title, 'Untitled event');
        expect(result[1].location, isNull);
        expect(result[1].description, isNull);
        expect(result[1].calendarId, 'class_calendar');
      },
    );

    test(
      'fetchUpcomingEvents converts dateTime values to local time',
      () async {
        final utcStart = DateTime.utc(2026, 3, 12, 20, 15);
        final utcEnd = DateTime.utc(2026, 3, 12, 21, 55);

        final event = gcal.Event()
          ..id = 'event1'
          ..summary = 'SOEN 357 Lecture'
          ..description = 'H-937'
          ..start = (gcal.EventDateTime()..dateTime = utcStart)
          ..end = (gcal.EventDateTime()..dateTime = utcEnd);

        final response = gcal.Events()..items = [event];

        final fakeApi = FakeGoogleCalendarApi(eventsResponse: response);

        final service = GoogleCalendarApiService(apiFactory: (_) => fakeApi);

        final result = await service.fetchUpcomingEvents(
          client,
          calendarId: 'class_calendar',
        );

        expect(result.length, 1);
        expect(result.first.start, utcStart.toLocal());
        expect(result.first.end, utcEnd.toLocal());
        expect(result.first.start!.isUtc, isFalse);
        expect(result.first.end!.isUtc, isFalse);
        expect(result.first.description, 'H-937');
      },
    );

    test('fetchUpcomingEvents filters out events with empty ids', () async {
      final validEvent = gcal.Event()
        ..id = 'event1'
        ..summary = 'Valid event'
        ..description = 'MB-2.130'
        ..start = (gcal.EventDateTime()..dateTime = DateTime(2026, 3, 12, 10))
        ..end = (gcal.EventDateTime()..dateTime = DateTime(2026, 3, 12, 11));

      final invalidEvent = gcal.Event()
        ..id = ''
        ..summary = 'Invalid event'
        ..start = (gcal.EventDateTime()..dateTime = DateTime(2026, 3, 12, 12))
        ..end = (gcal.EventDateTime()..dateTime = DateTime(2026, 3, 12, 13));

      final response = gcal.Events()..items = [validEvent, invalidEvent];

      final fakeApi = FakeGoogleCalendarApi(eventsResponse: response);

      final service = GoogleCalendarApiService(apiFactory: (_) => fakeApi);

      final result = await service.fetchUpcomingEvents(
        client,
        calendarId: 'class_calendar',
      );

      expect(result.length, 1);
      expect(result.first.id, 'event1');
      expect(result.first.description, 'MB-2.130');
    });

    test(
      'fetchUpcomingEvents returns empty list when response items are null',
      () async {
        final response = gcal.Events();

        final fakeApi = FakeGoogleCalendarApi(eventsResponse: response);

        final service = GoogleCalendarApiService(apiFactory: (_) => fakeApi);

        final result = await service.fetchUpcomingEvents(
          client,
          calendarId: 'class_calendar',
        );

        expect(result, isEmpty);
      },
    );
  });
}
