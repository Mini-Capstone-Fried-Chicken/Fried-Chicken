import 'package:campus_app/features/calendar/services/google_calendar_session.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GoogleCalendarSession.instance.clear();
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
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows connect view by default when user is logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      // Let async initState work finish
      await tester.pumpAndSettle();

      expect(find.text('Connect to Google Calendar'), findsNWidgets(2));
      expect(
        find.text(
          'Connect your Google Calendar to import your class events and get directions to your next class.',
        ),
        findsOneWidget,
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders connect button when logged in', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Connect to Google Calendar'), findsOneWidget);
    });

    testWidgets('does not show login message when user is logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const CalendarScreen(isLoggedIn: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Please log in first'), findsNothing);
    });
  });
}