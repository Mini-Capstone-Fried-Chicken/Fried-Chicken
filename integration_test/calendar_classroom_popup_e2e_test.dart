import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:campus_app/app/app_shell.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_connect_view.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_selection_view.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_schedule_view.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_event_popup.dart';

// run using: flutter run -d R5CWA1BZZSE integration_test/calendar_classroom_popup_e2e_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Google Calendar Classroom Directions E2E Test', () {
    testWidgets('Complete classroom directions flow', (tester) async {
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

      // Navigate to calendar tab (index 1 in bottom navigation)
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

        // Look for calendar list items
        final calendarListItems = find.byType(ListTile);
        if (calendarListItems.evaluate().isNotEmpty) {
          // Try to find a calendar with "class" in the name
          bool foundClassCalendar = false;

          // Check all text widgets for "class" (case insensitive)
          final allTextWidgets = find.byType(Text);
          for (final widget in allTextWidgets.evaluate()) {
            final textWidget = widget.widget as Text;
            final text = textWidget.data?.toLowerCase() ?? '';
            if (text.contains('class')) {
              foundClassCalendar = true;
              // Tap on the calendar that contains "class"
              await tester.tap(find.text(textWidget.data!));
              await tester.pumpAndSettle();
              break;
            }
          }

          if (foundClassCalendar) {
            // Now tap continue to proceed to schedule view
            final continueButton = find.byKey(
              const Key('calendar_continue_button'),
            );
            if (continueButton.evaluate().isNotEmpty) {
              await tester.tap(continueButton);
              await tester.pumpAndSettle(const Duration(seconds: 3));
            }
          }
        }

        // Check if we've reached the schedule view
        if (find.byType(CalendarScheduleView).evaluate().isNotEmpty) {
          expect(find.byType(CalendarScheduleView), findsOneWidget);

          // Verify schedule view UI elements
          expect(
            find.byKey(const Key('calendar_schedule_title')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('calendar_back_button')), findsOneWidget);

          // Verify view selection buttons are present
          expect(find.byKey(const Key('calendar_day_view')), findsOneWidget);
          expect(find.byKey(const Key('calendar_week_view')), findsOneWidget);
          expect(find.byKey(const Key('calendar_month_view')), findsOneWidget);
          expect(
            find.byKey(const Key('calendar_schedule_view')),
            findsOneWidget,
          );

          // Test switching to different calendar views using keys

          // Switch to Day view
          final dayChip = find.byKey(const Key('calendar_day_view'));
          await tester.tap(dayChip);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Switch to Week view
          final weekChip = find.byKey(const Key('calendar_week_view'));
          await tester.tap(weekChip);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Switch to Month view
          final monthChip = find.byKey(const Key('calendar_month_view'));
          await tester.tap(monthChip);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Switch to Schedule view
          final scheduleChip = find.byKey(const Key('calendar_schedule_view'));
          await tester.tap(scheduleChip);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Look for calendar events to click on
          final calendarEvents = find.byType(InkWell);
          if (calendarEvents.evaluate().isNotEmpty) {
            // Tap on the first calendar event
            await tester.tap(calendarEvents.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Verify the event popup appears
            expect(
              find.byKey(const Key('calendar_event_popup')),
              findsOneWidget,
            );

            // Verify popup UI elements using keys
            expect(
              find.byKey(const Key('calendar_popup_close_button')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('calendar_popup_go_to_building_button')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('calendar_popup_go_to_room_button')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('calendar_popup_save_button')),
              findsOneWidget,
            );

            // Test "Go to Building" button
            final goToBuildingButton = find.byKey(
              const Key('calendar_popup_go_to_building_button'),
            );
            if (goToBuildingButton.evaluate().isNotEmpty) {
              expect(goToBuildingButton, findsOneWidget);
              await tester.tap(goToBuildingButton);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            }

            // Test "Go to Room" button (if available)
            final goToRoomButton = find.byKey(
              const Key('calendar_popup_go_to_room_button'),
            );
            if (goToRoomButton.evaluate().isNotEmpty) {
              expect(goToRoomButton, findsOneWidget);
              await tester.tap(goToRoomButton);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            }

            // Test "Save" button
            final saveButton = find.byKey(
              const Key('calendar_popup_save_button'),
            );
            if (saveButton.evaluate().isNotEmpty) {
              expect(saveButton, findsOneWidget);
              await tester.tap(saveButton);
              await tester.pumpAndSettle(const Duration(seconds: 2));
            }

            // Test close button
            final closeButton = find.byKey(
              const Key('calendar_popup_close_button'),
            );
            expect(closeButton, findsOneWidget);
            await tester.tap(closeButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
        }

        // Test back navigation
        final backButton = find.byKey(const Key('calendar_back_button'));
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Should return to selection view
        expect(find.byType(CalendarSelectionView), findsOneWidget);
        expect(find.byType(CalendarScheduleView), findsNothing);
        expect(find.byType(CalendarEventPopup), findsNothing);
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
      final hasScheduleView = find
          .byType(CalendarScheduleView)
          .evaluate()
          .isNotEmpty;

      expect(hasConnectView || hasSelectionView || hasScheduleView, isTrue);
    });
  });
}
