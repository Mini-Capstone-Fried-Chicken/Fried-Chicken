import 'package:campus_app/features/calendar/data/models/calendar_connection_state.dart';
import 'package:campus_app/features/calendar/services/google_calendar_session.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:campus_app/features/calendar/ui/google_calendar_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  setUp(() {
    GoogleCalendarSession.instance.clear();
  });

  group('CalendarScreen', () {
    testWidgets('shows login message when user is not logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: false),
        ),
      );

      expect(find.text('Please log in first'), findsOneWidget);
    });

    testWidgets('shows connect view when step is connect', (tester) async {
      final session = GoogleCalendarSession.instance;
      session.clear();
      session.step = CalendarConnectionStep.connect;

      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      expect(find.text('Connect to Google Calendar'), findsNWidgets(2));
      expect(
        find.text(
          'Connect your Google Calendar to import your class events and get directions to your next class.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows selection view when step is selectCalendar', (
      tester,
    ) async {
      final session = GoogleCalendarSession.instance;
      session.clear();
      session.step = CalendarConnectionStep.selectCalendar;

      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      expect(find.text('Successfully Connected!'), findsOneWidget);
      expect(find.text('Select Calendar(s)'), findsOneWidget);
      expect(find.text('How to set up calendar'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('navigates to setup screen from selection view', (
      tester,
    ) async {
      final session = GoogleCalendarSession.instance;
      session.clear();
      session.step = CalendarConnectionStep.selectCalendar;

      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      await tester.tap(find.text('How to set up calendar'));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleCalendarSetupScreen), findsOneWidget);
      expect(find.text('How to set up your Google Calendar'), findsOneWidget);
    });

    testWidgets('shows schedule view when step is schedule', (tester) async {
      final session = GoogleCalendarSession.instance;
      session.clear();
      session.step = CalendarConnectionStep.schedule;

      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      expect(find.text('My Class Schedule'), findsOneWidget);
      expect(find.text('No events found in this calendar.'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('schedule view back button returns to selection view', (
      tester,
    ) async {
      final session = GoogleCalendarSession.instance;
      session.clear();
      session.step = CalendarConnectionStep.schedule;

      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      expect(find.text('My Class Schedule'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Successfully Connected!'), findsOneWidget);
      expect(find.text('Select Calendar(s)'), findsOneWidget);
    });
  });
}