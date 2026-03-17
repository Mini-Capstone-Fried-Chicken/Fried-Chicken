import 'package:campus_app/features/calendar/data/models/calendar_connection_state.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';
import 'package:campus_app/features/calendar/data/repositories/google_calendar_repository.dart';
import 'package:campus_app/features/calendar/services/google_calendar_api_service.dart';
import 'package:campus_app/features/calendar/services/google_calendar_auth_service.dart';
import 'package:campus_app/features/calendar/services/google_calendar_session.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSignInGateway implements GoogleSignInGateway {
  @override
  Future<void> initialize({String? clientId, String? serverClientId}) async {}

  @override
  Future<GoogleSignedInUserGateway?> authenticate({
    required List<String> scopeHint,
  }) async {
    return null;
  }

  @override
  Future<GoogleSignedInUserGateway?> attemptLightweightAuthentication() async {
    return null;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> disconnect() async {}
}

class _FakeAuthService extends GoogleCalendarAuthService {
  _FakeAuthService() : super(signInGateway: _FakeSignInGateway());

  bool connectResult = true;
  bool restoreResult = false;

  @override
  Future<void> initialize({String? clientId, String? serverClientId}) async {}

  @override
  Future<bool> signIn() async => connectResult;

  @override
  Future<bool> restorePreviousSignIn() async => restoreResult;

  @override
  Future<AuthClient?> getAuthenticatedClient() async => null;

  @override
  Future<void> disconnect() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar screen adapters', () {
    test('DefaultCalendarRepositoryAdapter forwards calls', () async {
      SharedPreferences.setMockInitialValues({});
      await GoogleCalendarSession.instance.clear();

      final authService = _FakeAuthService();
      final repository = GoogleCalendarRepository(
        authService: authService,
        apiService: GoogleCalendarApiService(),
      );
      final adapter = DefaultCalendarRepositoryAdapter(repository);

      expect(adapter.cachedCalendars, isEmpty);
      expect(adapter.cachedEvents, isEmpty);

      expect(await adapter.connect(), isTrue);
      expect(await adapter.getCalendars(), isEmpty);
      expect(await adapter.getUpcomingEventsForCalendars(const []), isEmpty);

      adapter.updateSelectedCalendars(['cal1']);
      adapter.goToSelection();

      expect(await adapter.restoreConnection(), isFalse);
    });

    test(
      'DefaultCalendarSessionAdapter forwards state and persistence',
      () async {
        SharedPreferences.setMockInitialValues({});
        final session = GoogleCalendarSession.instance;
        await session.clear();

        final adapter = DefaultCalendarSessionAdapter(session);
        final sampleCalendar = const GoogleCalendarInfo(
          id: 'cal1',
          name: 'SOEN 341',
          isPrimary: false,
        );
        final sampleEvent = GoogleCalendarEvent(
          id: 'e1',
          title: 'Lecture',
          start: DateTime(2026, 3, 12, 10),
          end: DateTime(2026, 3, 12, 11),
          location: 'H-937',
          calendarId: 'cal1',
          calendarName: 'SOEN 341',
          color: Colors.red,
        );

        adapter.isConnected = true;
        adapter.step = CalendarConnectionStep.schedule;
        adapter.calendars = [sampleCalendar];
        adapter.selectedCalendarIds = {'cal1'};
        adapter.events = [sampleEvent];

        expect(adapter.isConnected, isTrue);
        expect(adapter.step, CalendarConnectionStep.schedule);
        expect(adapter.calendars, hasLength(1));
        expect(adapter.selectedCalendarIds, {'cal1'});
        expect(adapter.events, hasLength(1));

        await adapter.persist();

        adapter.isConnected = false;
        adapter.step = CalendarConnectionStep.connect;
        adapter.selectedCalendarIds = {};

        await adapter.restore();

        expect(adapter.isConnected, isTrue);
        expect(adapter.step, CalendarConnectionStep.schedule);
        expect(adapter.selectedCalendarIds, {'cal1'});
      },
    );
  });
}
