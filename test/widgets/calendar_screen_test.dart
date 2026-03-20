import 'package:campus_app/features/calendar/data/models/calendar_connection_state.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:campus_app/features/calendar/services/google_calendar_session.dart';
import 'package:campus_app/features/calendar/ui/google_calendar_setup_screen.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeCalendarRepository implements CalendarRepositoryContract {
  @override
  List<GoogleCalendarInfo> cachedCalendars = [];

  @override
  List<GoogleCalendarEvent> cachedEvents = [];

  bool restoreResult = false;
  bool connectResult = true;
  bool throwOnRestore = false;
  bool throwOnConnect = false;
  bool throwOnContinue = false;

  int restoreCalls = 0;
  int connectCalls = 0;
  int getCalendarsCalls = 0;
  int updateSelectedCalls = 0;
  int continueCalls = 0;
  int goToSelectionCalls = 0;

  List<String> lastUpdatedIds = [];
  List<GoogleCalendarInfo> calendarsToReturn = [];
  List<GoogleCalendarEvent> eventsToReturn = [];

  @override
  Future<bool> restoreConnection() async {
    restoreCalls++;
    if (throwOnRestore) throw Exception('restore failed');
    return restoreResult;
  }

  @override
  Future<bool> connect() async {
    connectCalls++;
    if (throwOnConnect) throw Exception('connect failed');
    return connectResult;
  }

  @override
  Future<List<GoogleCalendarInfo>> getCalendars() async {
    getCalendarsCalls++;
    cachedCalendars = List.from(calendarsToReturn);
    return calendarsToReturn;
  }

  @override
  void updateSelectedCalendars(List<String> ids) {
    updateSelectedCalls++;
    lastUpdatedIds = ids;
  }

  @override
  Future<List<GoogleCalendarEvent>> getUpcomingEventsForCalendars(
    List<GoogleCalendarInfo> calendars,
  ) async {
    continueCalls++;
    if (throwOnContinue) throw Exception('continue failed');
    cachedEvents = List.from(eventsToReturn);
    return eventsToReturn;
  }

  @override
  void goToSelection() {
    goToSelectionCalls++;
  }
}

class FakeCalendarSession implements CalendarSessionContract {
  @override
  bool isConnected = false;

  @override
  CalendarConnectionStep step = CalendarConnectionStep.connect;

  @override
  List<GoogleCalendarInfo> calendars = [];

  @override
  Set<String> selectedCalendarIds = {};

  @override
  List<GoogleCalendarEvent> events = [];

  int restoreCalls = 0;
  int persistCalls = 0;

  @override
  Future<void> restore() async {
    restoreCalls++;
  }

  @override
  Future<void> persist() async {
    persistCalls++;
  }
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  group('CalendarScreen', () {
    late FakeCalendarRepository repo;
    late FakeCalendarSession session;

    setUp(() {
      repo = FakeCalendarRepository();
      session = FakeCalendarSession();
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    tearDown(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    testWidgets('shows connect state when not logged in', (tester) async {
      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: false, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Please log in first'), findsOneWidget);
      expect(repo.restoreCalls, 0);
      expect(session.restoreCalls, 1);
    });

    testWidgets('stays on connect when restore returns false', (tester) async {
      repo.restoreResult = false;

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connect to Google Calendar'), findsNWidgets(2));
      expect(repo.restoreCalls, 1);
      expect(session.restoreCalls, 1);
    });

    testWidgets('stays on connect when restore throws', (tester) async {
      repo.throwOnRestore = true;

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connect to Google Calendar'), findsNWidgets(2));
    });

    testWidgets(
      'stays on connect when restore succeeds but has no cached data',
      (tester) async {
        repo.restoreResult = true;

        await tester.pumpWidget(
          wrap(
            CalendarScreen(
              isLoggedIn: true,
              repository: repo,
              session: session,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Connect to Google Calendar'), findsNWidgets(2));
        expect(repo.restoreCalls, 1);
      },
    );

    testWidgets('goes to selection when restore succeeds with calendars only', (
      tester,
    ) async {
      repo.restoreResult = true;
      repo.cachedCalendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];
      session.selectedCalendarIds = {'cal1'};

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select Calendar(s)'), findsOneWidget);
      expect(find.text('How to set up calendar'), findsOneWidget);
    });

    testWidgets('goes to schedule when restore succeeds with events', (
      tester,
    ) async {
      repo.restoreResult = true;
      repo.cachedCalendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];
      repo.cachedEvents = [
        GoogleCalendarEvent(
          id: 'e1',
          title: 'Lecture',
          start: DateTime(2026, 3, 12, 10),
          end: DateTime(2026, 3, 12, 11),
          location: 'H-937',
          calendarId: 'cal1',
          calendarName: 'SOEN 341',
          color: Colors.red,
        ),
      ];
      session.selectedCalendarIds = {'cal1'};

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Class Schedule'), findsOneWidget);
      expect(find.text('SOEN 341'), findsOneWidget);
    });

    testWidgets('connect button success goes to selection', (tester) async {
      repo.connectResult = true;
      repo.calendarsToReturn = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect to Google Calendar').last);
      await tester.pumpAndSettle();

      expect(find.text('Select Calendar(s)'), findsOneWidget);
      expect(repo.connectCalls, 1);
      expect(repo.getCalendarsCalls, 1);
      expect(session.persistCalls, greaterThan(0));
    });

    testWidgets(
      'connect button shows cancelled error when connect returns false',
      (tester) async {
        repo.connectResult = false;

        await tester.pumpWidget(
          wrap(
            CalendarScreen(
              isLoggedIn: true,
              repository: repo,
              session: session,
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Connect to Google Calendar').last);
        await tester.pumpAndSettle();

        expect(find.text('Connection cancelled.'), findsOneWidget);
      },
    );

    testWidgets('connect button shows failure error when connect throws', (
      tester,
    ) async {
      repo.throwOnConnect = true;

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect to Google Calendar').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Failed to connect Google Calendar:'),
        findsOneWidget,
      );
    });

    testWidgets('can toggle calendar selection and continue to schedule', (
      tester,
    ) async {
      repo.restoreResult = true;
      repo.cachedCalendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
        GoogleCalendarInfo(id: 'cal2', name: 'SOEN 357', isPrimary: false),
      ];
      repo.eventsToReturn = [
        GoogleCalendarEvent(
          id: 'e1',
          title: 'Lecture',
          start: DateTime(2026, 3, 12, 10),
          end: DateTime(2026, 3, 12, 11),
          location: 'H-937',
          calendarId: 'cal1',
          calendarName: 'SOEN 341',
          color: Colors.red,
        ),
      ];

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('SOEN 341'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdatedIds, ['cal1']);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('My Class Schedule'), findsOneWidget);
      expect(repo.continueCalls, 1);
      expect(session.persistCalls, greaterThan(0));
    });

    testWidgets('deselecting last selected calendar disables continue action', (
      tester,
    ) async {
      repo.restoreResult = true;
      repo.cachedCalendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];
      session.selectedCalendarIds = {'cal1'};

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('SOEN 341'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdatedIds, isEmpty);

      final continueButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(continueButton.onPressed, isNull);
      expect(repo.continueCalls, 0);
    });

    testWidgets('continue shows error when fetching events fails', (
      tester,
    ) async {
      repo.restoreResult = true;
      repo.cachedCalendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];
      repo.throwOnContinue = true;

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('SOEN 341'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Failed to load class schedule:'),
        findsOneWidget,
      );
    });

    testWidgets('setup button navigates to setup screen', (tester) async {
      repo.restoreResult = true;
      repo.cachedCalendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('How to set up calendar'));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleCalendarSetupScreen), findsOneWidget);
    });

    testWidgets('back from schedule goes to selection and saves session', (
      tester,
    ) async {
      repo.restoreResult = true;
      repo.cachedCalendars = const [
        GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
      ];
      repo.cachedEvents = [
        GoogleCalendarEvent(
          id: 'e1',
          title: 'Lecture',
          start: DateTime(2026, 3, 12, 10),
          end: DateTime(2026, 3, 12, 11),
          location: 'H-937',
          calendarId: 'cal1',
          calendarName: 'SOEN 341',
          color: Colors.red,
        ),
      ];
      session.selectedCalendarIds = {'cal1'};

      await tester.pumpWidget(
        wrap(
          CalendarScreen(isLoggedIn: true, repository: repo, session: session),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(repo.goToSelectionCalls, 1);
      expect(find.text('Select Calendar(s)'), findsOneWidget);
      expect(session.persistCalls, greaterThan(0));
    });

    testWidgets(
      'schedule label shows count when multiple calendars are selected',
      (tester) async {
        repo.restoreResult = true;
        repo.cachedCalendars = const [
          GoogleCalendarInfo(id: 'cal1', name: 'SOEN 341', isPrimary: false),
          GoogleCalendarInfo(id: 'cal2', name: 'SOEN 357', isPrimary: false),
        ];
        repo.cachedEvents = [
          GoogleCalendarEvent(
            id: 'e1',
            title: 'Lecture',
            start: DateTime(2026, 3, 12, 10),
            end: DateTime(2026, 3, 12, 11),
            location: 'H-937',
            calendarId: 'cal1',
            calendarName: 'SOEN 341',
            color: Colors.red,
          ),
        ];
        session.selectedCalendarIds = {'cal1', 'cal2'};

        await tester.pumpWidget(
          wrap(
            CalendarScreen(
              isLoggedIn: true,
              repository: repo,
              session: session,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('2 calendars selected'), findsOneWidget);
      },
    );

    testWidgets(
      'shows calendar access disabled message when permission is off',
      (tester) async {
        AppSettingsController.setCalendarAccess(false);

        await tester.pumpWidget(
          wrap(
            CalendarScreen(
              isLoggedIn: true,
              repository: repo,
              session: session,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Calendar access is disabled'), findsOneWidget);
        expect(
          find.text(
            'To use the calendar, enable Calendar Access in the Settings tab.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'calendar access disabled view uses black background in high contrast mode',
      (tester) async {
        AppSettingsController.setAccessibilityMode(true);
        AppSettingsController.setHighContrastMode(true);
        AppSettingsController.setCalendarAccess(false);

        await tester.pumpWidget(
          wrap(
            CalendarScreen(
              isLoggedIn: true,
              repository: repo,
              session: session,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.black);
        expect(find.text('Calendar access is disabled'), findsOneWidget);
      },
    );

    testWidgets('uses default repository adapter when repository is omitted', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(CalendarScreen(isLoggedIn: false, session: session)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Please log in first'), findsOneWidget);
      expect(session.restoreCalls, 1);
    });

    testWidgets('uses default session adapter when session is omitted', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await GoogleCalendarSession.instance.clear();

      await tester.pumpWidget(
        wrap(CalendarScreen(isLoggedIn: false, repository: repo)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Please log in first'), findsOneWidget);
    });
  });
}
