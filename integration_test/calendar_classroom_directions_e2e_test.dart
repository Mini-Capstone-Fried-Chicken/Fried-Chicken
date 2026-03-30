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
import 'package:syncfusion_flutter_calendar/calendar.dart';
// this completes e2e for 4.3 4.4 4.5
// run using: flutter run -d R5CWA1BZZSE integration_test/calendar_classroom_directions_e2e_test.dart --dart-define=GOOGLE_DIRECTIONS_API_KEY=AIzaSyAz7CcEsdorD_rQSq_fHruG5pvYuQAPu7U --dart-define=GOOGLE_PLACES_API_KEY=AIzaSyAz7CcEsdorD_rQSq_fHruG5pvYuQAPu7U

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

        if (emailField.evaluate().isNotEmpty &&
            passwordField.evaluate().isNotEmpty &&
            loginButton.evaluate().isNotEmpty) {
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

          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
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
      if (find.byType(CalendarConnectView).evaluate().isNotEmpty) {
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
      }

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

          // Check all text widgets for "class"
          final allTextWidgets = find.byType(Text);
          for (final widget in allTextWidgets.evaluate()) {
            final textWidget = widget.widget as Text;
            final text = textWidget.data?.toLowerCase() ?? '';
            if (text.contains('class')) {
              foundClassCalendar = true;
              // Tap on the calendar that contains "class"
              await tester.tap(find.text(textWidget.data!).first);
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
      }

      // FLOW 1: GO TO BUILDING
      // Check if we've reached the schedule view
      expect(find.byType(CalendarScheduleView), findsOneWidget);

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
        expect(find.byKey(const Key('calendar_schedule_view')), findsOneWidget);

        // Look for calendar events to click on
        final calendarWidget = find.byType(SfCalendar);
        expect(calendarWidget, findsOneWidget);

        // Tap on a known position where SOEN 357 is (Monday 8 45)
        final calendarBounds = tester.getRect(calendarWidget);

        // Adjust these values if needed
        final tapPosition = Offset(
          calendarBounds.left + 85, // Monday column
          calendarBounds.top + 150, // 9 to 10AM area
        );

        await tester.tapAt(tapPosition);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify the event popup appears
        expect(find.byKey(const Key('calendar_event_popup')), findsOneWidget);

        // Tap "Go to Building"
        final goToBuildingButton = find.byKey(
          const Key('calendar_popup_go_to_building_button'),
        );
        expect(goToBuildingButton, findsOneWidget);

        await tester.tap(goToBuildingButton);
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 6));
        });
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify directions flow opened
        final startField = find.byKey(const Key('start_field'));
        final destinationField = find.byKey(const Key('destination_field'));
        expect(startField, findsOneWidget);
        expect(destinationField, findsOneWidget);

        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 3));
        });
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify destination is filled
        final destinationTextWidget = tester.widget(destinationField);
        if (destinationTextWidget is TextField) {
          final destinationText = destinationTextWidget.controller?.text ?? '';
          // introduce delay to see that the route is displayed properly
          await tester.runAsync(() async {
            await Future.delayed(const Duration(seconds: 5));
          });
          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(
            destinationText.isNotEmpty,
            isTrue,
            reason:
                'Destination should be filled after pressing Go to Building',
          );
        }

        // Close route preview
        final clearRouteButton = find.byKey(const Key('clear_route_button'));
        if (clearRouteButton.evaluate().isNotEmpty) {
          await tester.tap(clearRouteButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Go back to Calendar tab
        final calendarTabAgain = find.text('Calendar');
        expect(calendarTabAgain, findsOneWidget);
        await tester.tap(calendarTabAgain);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify calendar screen
        expect(find.byType(CalendarScreen), findsOneWidget);

        // Verify connect view
        if (find.byType(CalendarConnectView).evaluate().isNotEmpty) {
          expect(find.byType(CalendarConnectView), findsOneWidget);

          // Find and tap the connect button
          final connectButton = find.byKey(
            const Key('calendar_connect_button'),
          );
          expect(connectButton, findsOneWidget);
          await tester.tap(connectButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Wait for potential connection restoration
          await tester.runAsync(() async {
            await Future.delayed(const Duration(seconds: 5));
          });
          await tester.pumpAndSettle();
        }

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
          expect(
            find.byKey(const Key('calendar_setup_button')),
            findsOneWidget,
          );

          // Look for calendar list items
          final calendarListItemsAgain = find.byType(ListTile);
          if (calendarListItemsAgain.evaluate().isNotEmpty) {
            // Try to find a calendar with "class" in the name
            bool foundClassCalendarAgain = false;

            // Check all text widgets for "class"
            final allTextWidgetsAgain = find.byType(Text);
            for (final widget in allTextWidgetsAgain.evaluate()) {
              final textWidget = widget.widget as Text;
              final text = textWidget.data?.toLowerCase() ?? '';
              if (text.contains('class')) {
                foundClassCalendarAgain = true;
                // Tap on the calendar that contains "class"
                await tester.tap(find.text(textWidget.data!).first);
                await tester.pumpAndSettle();
                break;
              }
            }

            if (foundClassCalendarAgain) {
              // Now tap continue to proceed to schedule view
              final continueButtonAgain = find.byKey(
                const Key('calendar_continue_button'),
              );
              if (continueButtonAgain.evaluate().isNotEmpty) {
                await tester.tap(continueButtonAgain);
                await tester.pumpAndSettle(const Duration(seconds: 3));
              }
            }
          }
        }

        // Check if we've reached the schedule view
        expect(find.byType(CalendarScheduleView), findsOneWidget);

        // FLOW 2: GO TO ROOM
        final calendarWidgetAgain = find.byType(SfCalendar);
        expect(calendarWidgetAgain, findsOneWidget);

        final calendarBoundsAgain = tester.getRect(calendarWidgetAgain);

        final tapPositionAgain = Offset(
          calendarBoundsAgain.left + 85, // Monday column
          calendarBoundsAgain.top + 150, // 9 to 10AM area
        );

        // Tap class again
        await tester.tapAt(tapPositionAgain);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Popup appears again
        expect(find.byKey(const Key('calendar_event_popup')), findsOneWidget);

        // Tap "Go to Room"
        final goToRoomButton = find.byKey(
          const Key('calendar_popup_go_to_room_button'),
        );
        expect(goToRoomButton, findsOneWidget);

        await tester.tap(goToRoomButton);
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 6));
        });
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify directions flow opened again
        final startFieldAfterRoom = find.byKey(const Key('start_field'));
        final destinationFieldAfterRoom = find.byKey(
          const Key('destination_field'),
        );
        expect(startFieldAfterRoom, findsOneWidget);
        expect(destinationFieldAfterRoom, findsOneWidget);

        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 3));
        });
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify destination is filled
        final destinationTextWidgetAfterRoom = tester.widget(
          destinationFieldAfterRoom,
        );
        if (destinationTextWidgetAfterRoom is TextField) {
          final destinationTextAfterRoom =
              destinationTextWidgetAfterRoom.controller?.text ?? '';

          // introduce delay to see that the route is displayed properly
          await tester.runAsync(() async {
            await Future.delayed(const Duration(seconds: 5));
          });
          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(
            destinationTextAfterRoom.isNotEmpty,
            isTrue,
            reason: 'Destination should be filled after pressing Go to Room',
          );
        }
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
