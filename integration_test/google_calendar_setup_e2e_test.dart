import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:campus_app/app/app_shell.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_connect_view.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_selection_view.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_schedule_view.dart';
import 'package:campus_app/features/calendar/ui/google_calendar_setup_screen.dart';

// run using: flutter run -d R5CWA1BZZSE integration_test/google_calendar_setup_e2e_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Google Calendar Setup Instructions E2E Test', () {
    testWidgets('Complete setup instructions flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Login (if not already done)
      if (!find.byType(AppShell).evaluate().isNotEmpty) {
        final emailField = find.byKey(const Key('login_email'));
        final passwordField = find.byKey(const Key('login_password'));
        final loginButton = find.byKey(const Key('login_button'));

        // Enter login credentials
        await tester.enterText(emailField, 'hiba.tal05@gmail.com');
        await tester.enterText(passwordField, '123456');
        await tester.pumpAndSettle();
        await tester.ensureVisible(loginButton);

        // Tap login button
        await tester.tap(loginButton);

        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 5));
        });

        await tester.pump();
      }

      // Verify we're on the main app shell
      expect(find.byType(AppShell), findsOneWidget);

      // Navigate to calendar tab
      final calendarTab = find.text('Calendar');
      expect(calendarTab, findsOneWidget);
      await tester.tap(calendarTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify calendar screen
      expect(find.byType(CalendarScreen), findsOneWidget);

      // Verify connect view
      expect(find.byType(CalendarConnectView), findsOneWidget);

      // Find and tap the connect button
      final connectButton = find.byKey(const Key('calendar_connect_button'));
      expect(connectButton, findsOneWidget);
      await tester.tap(connectButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for potential connection restoration
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 5));
      });
      await tester.pumpAndSettle();

      // Check if we've reached the selection view
      if (find.byType(CalendarSelectionView).evaluate().isNotEmpty) {
        expect(find.byType(CalendarSelectionView), findsOneWidget);

        // if the "class" option is selected, disable it by tapping again
        final allTextWidgets = find.byType(Text);
        for (final widget in allTextWidgets.evaluate()) {
          final textWidget = widget.widget as Text;
          final text = textWidget.data?.toLowerCase() ?? '';
          if (text.contains('class')) {
            // If the calendar is selected, tap to deselect
            // This toggles the selection state
            await tester.tap(find.text(textWidget.data!));
            await tester.pumpAndSettle();
            break;
          }
        }

        // If calendar view is accidentally shown, just go back
        if (find.byType(CalendarScheduleView).evaluate().isNotEmpty) {
          final backButton = find.byKey(const Key('calendar_back_button'));
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
        }

        // Verify selection view UI elements
        expect(
          find.byKey(const Key('calendar_success_banner')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('calendar_selection_title')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('calendar_setup_button')), findsOneWidget);

        //  "How to set up calendar" button
        final setupButton = find.byKey(const Key('calendar_setup_button'));
        expect(setupButton, findsOneWidget);
        await tester.tap(setupButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify we're on the setup screen
        expect(find.byType(GoogleCalendarSetupScreen), findsOneWidget);

        // Verify setup screen UI elements using keys
        expect(find.byKey(const Key('setup_back_button')), findsOneWidget);
        expect(find.byKey(const Key('setup_title')), findsOneWidget);
        expect(find.byKey(const Key('setup_description')), findsOneWidget);
        expect(find.byKey(const Key('setup_step1')), findsOneWidget);
        expect(find.byKey(const Key('setup_step2')), findsOneWidget);

        // Verify the title text
        expect(find.text('How to set up your Google Calendar'), findsOneWidget);

        // Verify the description text
        expect(
          find.text(
            'Follow these steps to properly set up your Google Calendar to work with the Campus App.',
          ),
          findsOneWidget,
        );

        // Verify Step 1
        expect(find.text('Step 1'), findsOneWidget);
        expect(
          find.text(
            'Click on the + sign at the bottom right of your screen and choose event.',
          ),
          findsOneWidget,
        );

        // Verify Step 2
        expect(find.text('Step 2'), findsOneWidget);
        expect(
          find.text(
            'Set the location of the event as the building name/code your class is in and the description as the room number.',
          ),
          findsOneWidget,
        );

        // Scroll to end of page to show all steps
        await tester.fling(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
          1000,
        );
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Scroll back to top to access back button
        await tester.fling(
          find.byType(SingleChildScrollView),
          const Offset(0, 500),
          1000,
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Test back navigation
        final backButton = find.byKey(const Key('setup_back_button'));
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // Verify we returned to the selection view
        expect(find.byType(CalendarSelectionView), findsOneWidget);
        expect(find.byType(GoogleCalendarSetupScreen), findsNothing);
      }

      // Final verification: The app should be in a valid state
      expect(find.byType(CalendarScreen), findsOneWidget);

      final hasConnectView = find
          .byType(CalendarConnectView)
          .evaluate()
          .isNotEmpty;
      final hasSelectionView = find
          .byType(CalendarSelectionView)
          .evaluate()
          .isNotEmpty;

      expect(hasConnectView || hasSelectionView, isTrue);
    });
  });
}
