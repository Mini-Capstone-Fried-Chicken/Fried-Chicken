import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_app/features/calendar/data/models/calendar_connection_state.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';
import 'package:campus_app/features/calendar/data/repositories/google_calendar_repository.dart';
import 'package:campus_app/features/calendar/services/google_calendar_api_service.dart';
import 'package:campus_app/features/calendar/services/google_calendar_auth_service.dart';
import 'package:campus_app/features/calendar/services/google_calendar_session.dart';

class FakeAuthClient extends AuthClient {
  bool closed = false;

  @override
  void close() {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeGoogleCalendarAuthService extends GoogleCalendarAuthService {
  bool initializeCalled = false;
  bool signInCalled = false;
  bool disconnectCalled = false;
  bool restorePreviousSignInCalled = false;

  bool signInResult = true;
  bool restoreResult = true;
  AuthClient? clientToReturn;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
  }) async {
    initializeCalled = true;
  }

  @override
  Future<bool> signIn() async {
    signInCalled = true;
    return signInResult;
  }

  @override
  Future<AuthClient?> getAuthenticatedClient() async {
    return clientToReturn;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }

  @override
  Future<bool> restorePreviousSignIn() async {
    restorePreviousSignInCalled = true;
    return restoreResult;
  }
}

class FakeGoogleCalendarApiService extends GoogleCalendarApiService {
  int fetchCalendarsCallCount = 0;
  int fetchUpcomingEventsCallCount = 0;

  List<GoogleCalendarInfo> calendarsToReturn = [];
  Map<String, List<GoogleCalendarEvent>> eventsByCalendarId = {};

  @override
  Future<List<GoogleCalendarInfo>> fetchCalendars(AuthClient client) async {
    fetchCalendarsCallCount++;
    return calendarsToReturn;
  }

  @override
  Future<List<GoogleCalendarEvent>> fetchUpcomingEvents(
    AuthClient client, {
    required String calendarId,
  }) async {
    fetchUpcomingEventsCallCount++;
    return eventsByCalendarId[calendarId] ?? [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCalendarRepository', () {
    late FakeGoogleCalendarAuthService fakeAuthService;
    late FakeGoogleCalendarApiService fakeApiService;
    late GoogleCalendarRepository repository;
    late FakeAuthClient fakeClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GoogleCalendarSession.instance.clear();

      fakeAuthService = FakeGoogleCalendarAuthService();
      fakeApiService = FakeGoogleCalendarApiService();
      fakeClient = FakeAuthClient();

      repository = GoogleCalendarRepository(
        authService: fakeAuthService,
        apiService: fakeApiService,
      );
    });

    test('connect initializes auth and updates session on success', () async {
      fakeAuthService.signInResult = true;

      final result = await repository.connect();

      expect(result, isTrue);
      expect(fakeAuthService.initializeCalled, isTrue);
      expect(fakeAuthService.signInCalled, isTrue);
      expect(repository.session.isConnected, isTrue);
      expect(repository.session.step, CalendarConnectionStep.selectCalendar);
    });

    test('connect does not update session when sign-in fails', () async {
      fakeAuthService.signInResult = false;

      final result = await repository.connect();

      expect(result, isFalse);
      expect(repository.session.isConnected, isFalse);
      expect(repository.session.step, CalendarConnectionStep.connect);
    });

    test(
      'getCalendars returns empty list when authenticated client is null',
      () async {
        fakeAuthService.clientToReturn = null;

        final calendars = await repository.getCalendars();

        expect(calendars, isEmpty);
        expect(fakeApiService.fetchCalendarsCallCount, 0);
      },
    );

    test('getCalendars fetches calendars and caches them', () async {
      fakeAuthService.clientToReturn = fakeClient;

      fakeApiService.calendarsToReturn = const [
        GoogleCalendarInfo(id: '1', name: 'SOEN 341', isPrimary: false),
        GoogleCalendarInfo(id: '2', name: 'SOEN 357', isPrimary: true),
      ];

      final firstResult = await repository.getCalendars();
      final secondResult = await repository.getCalendars();

      expect(firstResult.length, 2);
      expect(secondResult.length, 2);
      expect(repository.cachedCalendars.length, 2);
      expect(fakeApiService.fetchCalendarsCallCount, 1);
      expect(fakeClient.closed, isTrue);
    });

    test(
      'getUpcomingEventsForCalendars returns empty list when client is null',
      () async {
        fakeAuthService.clientToReturn = null;

        final events = await repository.getUpcomingEventsForCalendars(const []);

        expect(events, isEmpty);
        expect(fakeApiService.fetchUpcomingEventsCallCount, 0);
      },
    );

    test(
      'getUpcomingEventsForCalendars merges, sorts, colors, and caches events',
      () async {
        fakeAuthService.clientToReturn = fakeClient;

        const calendars = [
          GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
          GoogleCalendarInfo(id: 'cal2', name: 'SOEN 357', isPrimary: false),
        ];

        fakeApiService.eventsByCalendarId = {
          'cal1': [
            GoogleCalendarEvent(
              id: 'e2',
              title: 'Event 2',
              start: DateTime(2026, 3, 20, 10),
              end: DateTime(2026, 3, 20, 11),
              location: 'H-937',
              calendarId: '',
              calendarName: '',
              color: Colors.black,
            ),
          ],
          'cal2': [
            GoogleCalendarEvent(
              id: 'e1',
              title: 'Event 1',
              start: DateTime(2026, 3, 18, 9),
              end: DateTime(2026, 3, 18, 10),
              location: 'H-831',
              calendarId: '',
              calendarName: '',
              color: Colors.black,
            ),
          ],
        };

        final events = await repository.getUpcomingEventsForCalendars(
          calendars,
        );

        expect(events.length, 2);
        expect(events.first.id, 'e1');
        expect(events.last.id, 'e2');

        expect(events[0].calendarId, 'cal2');
        expect(events[0].calendarName, 'SOEN 357');

        expect(events[1].calendarId, 'cal1');
        expect(events[1].calendarName, 'SOEN 341');

        expect(repository.cachedEvents.length, 2);
        expect(repository.session.step, CalendarConnectionStep.schedule);
        expect(repository.session.selectedCalendarIds, ['cal1', 'cal2']);
        expect(fakeApiService.fetchUpcomingEventsCallCount, 2);
        expect(fakeClient.closed, isTrue);
      },
    );

    test('updateSelectedCalendars updates session selected ids', () {
      repository.updateSelectedCalendars(['a', 'b']);

      expect(repository.session.selectedCalendarIds, ['a', 'b']);
    });

    test('goToSelection updates session step', () {
      repository.goToSelection();

      expect(repository.session.step, CalendarConnectionStep.selectCalendar);
    });

    test('disconnect clears repository caches and persisted session', () async {
      fakeAuthService.clientToReturn = fakeClient;
      fakeApiService.calendarsToReturn = const [
        GoogleCalendarInfo(id: '1', name: 'SOEN 341', isPrimary: false),
      ];

      await repository.getCalendars();

      final session = GoogleCalendarSession.instance;
      session.isConnected = true;
      session.step = CalendarConnectionStep.schedule;
      session.selectedCalendarIds = {'1'};
      await session.persist();

      await repository.disconnect();

      expect(fakeAuthService.disconnectCalled, isTrue);
      expect(repository.cachedCalendars, isEmpty);
      expect(repository.cachedEvents, isEmpty);
      expect(repository.session.isConnected, isFalse);
      expect(repository.session.step, CalendarConnectionStep.connect);
      expect(repository.session.selectedCalendarIds, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('calendar_is_connected'), isNull);
      expect(prefs.getInt('calendar_step'), isNull);
      expect(prefs.getStringList('calendar_selected_ids'), isNull);
    });

    test('restoreConnection returns false when auth restore fails', () async {
      fakeAuthService.restoreResult = false;

      final result = await repository.restoreConnection();

      expect(result, isFalse);
      expect(fakeAuthService.restorePreviousSignInCalled, isTrue);
      expect(repository.session.isConnected, isFalse);
    });

    test(
      'restoreConnection restores session and fetches selected calendars/events',
      () async {
        SharedPreferences.setMockInitialValues({
          'calendar_is_connected': true,
          'calendar_step': CalendarConnectionStep.selectCalendar.index,
          'calendar_selected_ids': ['cal1'],
        });

        fakeAuthService.restoreResult = true;
        fakeAuthService.clientToReturn = fakeClient;

        fakeApiService.calendarsToReturn = const [
          GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
          GoogleCalendarInfo(id: 'cal2', name: 'SOEN 357', isPrimary: false),
        ];

        fakeApiService.eventsByCalendarId = {
          'cal1': [
            GoogleCalendarEvent(
              id: 'e1',
              title: 'Lecture',
              start: DateTime(2026, 3, 18, 9),
              end: DateTime(2026, 3, 18, 10),
              location: 'H-937',
              calendarId: '',
              calendarName: '',
              color: Colors.black,
            ),
          ],
        };

        final result = await repository.restoreConnection();

        expect(result, isTrue);
        expect(fakeAuthService.restorePreviousSignInCalled, isTrue);
        expect(repository.session.isConnected, isTrue);
        expect(repository.session.step, CalendarConnectionStep.schedule);
        expect(repository.session.selectedCalendarIds, ['cal1']);

        expect(repository.cachedCalendars.length, 2);
        expect(repository.cachedEvents.length, 1);
        expect(fakeApiService.fetchCalendarsCallCount, 1);
        expect(fakeApiService.fetchUpcomingEventsCallCount, 1);
      },
    );

    test(
      'restoreConnection restores connection even when no selected calendars exist',
      () async {
        SharedPreferences.setMockInitialValues({
          'calendar_is_connected': true,
          'calendar_step': CalendarConnectionStep.connect.index,
          'calendar_selected_ids': <String>[],
        });

        fakeAuthService.restoreResult = true;
        fakeAuthService.clientToReturn = fakeClient;

        fakeApiService.calendarsToReturn = const [
          GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
        ];

        final result = await repository.restoreConnection();

        expect(result, isTrue);
        expect(repository.session.isConnected, isTrue);
        expect(repository.cachedCalendars.length, 1);
        expect(repository.cachedEvents, isEmpty);
        expect(fakeApiService.fetchUpcomingEventsCallCount, 0);
      },
    );
  });
}