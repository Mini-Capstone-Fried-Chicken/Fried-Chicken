import 'package:campus_app/features/calendar/ui/google_calendar_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('GoogleCalendarSetupScreen', () {
    testWidgets('renders title, intro text, and steps', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const GoogleCalendarSetupScreen(),
        ),
      );

      expect(find.text('How to set up your Google Calendar'), findsOneWidget);
      expect(
        find.text(
          'Follow these steps to properly set up your Google Calendar to work with the Campus App.',
        ),
        findsOneWidget,
      );

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);

      expect(
        find.text(
          'Click on the + sign at the bottom right of your screen and choose event.',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Set the location of the event as the building name/code your class is in and the description as the room number.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const GoogleCalendarSetupScreen(),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('renders two images', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const GoogleCalendarSetupScreen(),
        ),
      );

      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('can pop screen when back button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GoogleCalendarSetupScreen(),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleCalendarSetupScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleCalendarSetupScreen), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('screen is scrollable', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const GoogleCalendarSetupScreen(),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}