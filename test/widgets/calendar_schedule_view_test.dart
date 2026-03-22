import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_schedule_view.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_event_popup.dart';
import 'package:campus_app/features/saved/saved_directions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  final popupEvent = GoogleCalendarEvent(
    id: 'popup_1',
    title: 'SOEN 357 Lecture',
    start: DateTime(2026, 3, 12, 10, 0),
    end: DateTime(2026, 3, 12, 11, 15),
    location: 'Hall Building',
    description: 'H-937',
    calendarId: 'cal_popup',
    calendarName: 'SOEN 357',
    color: const Color(0xFF8B1E3F),
  );

  final sampleEvents = [
    GoogleCalendarEvent(
      id: '1',
      title: 'SOEN 341 Lecture',
      start: DateTime(2026, 3, 12, 10, 0),
      end: DateTime(2026, 3, 12, 11, 15),
      location: 'H-937',
      calendarId: 'cal_1',
      calendarName: 'SOEN 341',
      color: const Color(0xFF8B1E3F),
    ),
    GoogleCalendarEvent(
      id: '2',
      title: 'SOEN 357 Lab',
      start: DateTime(2026, 3, 13, 14, 0),
      end: DateTime(2026, 3, 13, 16, 0),
      location: 'H-831',
      calendarId: 'cal_2',
      calendarName: 'SOEN 357',
      color: const Color(0xFF2563EB),
    ),
  ];

  group('CalendarScheduleView', () {
    testWidgets('renders title, label, and chips', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: '2 calendars selected',
            events: sampleEvents,
            onBack: () {},
          ),
        ),
      );

      expect(find.text('My Class Schedule'), findsOneWidget);
      expect(find.text('2 calendars selected'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(4));
    });

    testWidgets('shows empty state when events list is empty', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'No calendar',
            events: const [],
            onBack: () {},
          ),
        ),
      );

      expect(find.text('No events found in this calendar.'), findsOneWidget);
      expect(find.text('My Class Schedule'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(4));
    });

    testWidgets('calls onBack when back button is pressed', (tester) async {
      var backPressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 341',
            events: sampleEvents,
            onBack: () {
              backPressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backPressed, isTrue);
    });

    testWidgets('week chip is selected by default', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 341',
            events: const [],
            onBack: () {},
          ),
        ),
      );

      final weekChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Week'),
      );
      final dayChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Day'),
      );
      final monthChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Month'),
      );
      final scheduleChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Schedule'),
      );

      expect(weekChip.selected, isTrue);
      expect(dayChip.selected, isFalse);
      expect(monthChip.selected, isFalse);
      expect(scheduleChip.selected, isFalse);
    });

    testWidgets('tapping day chip changes selected chip', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 341',
            events: const [],
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Day'));
      await tester.pump();

      final dayChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Day'),
      );
      final weekChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Week'),
      );

      expect(dayChip.selected, isTrue);
      expect(weekChip.selected, isFalse);
    });

    testWidgets('tapping month chip changes selected chip', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 341',
            events: const [],
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Month'));
      await tester.pump();

      final monthChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Month'),
      );
      final weekChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Week'),
      );

      expect(monthChip.selected, isTrue);
      expect(weekChip.selected, isFalse);
    });

    testWidgets('tapping schedule chip changes selected chip', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 341',
            events: const [],
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Schedule'));
      await tester.pump();

      final scheduleChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Schedule'),
      );
      final weekChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Week'),
      );

      expect(scheduleChip.selected, isTrue);
      expect(weekChip.selected, isFalse);
    });

    testWidgets(
      'high contrast mode applies expected calendar header and time label styles',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            CalendarScheduleView(
              selectedCalendarLabel: 'SOEN 341',
              events: sampleEvents,
              onBack: () {},
              highContrastMode: true,
            ),
          ),
        );

        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));

        expect(calendar.headerStyle.backgroundColor, const Color(0xFF89D9C2));
        expect(calendar.headerStyle.textStyle?.color, Colors.black);
        expect(
          calendar.viewHeaderStyle.backgroundColor,
          const Color(0xFF89D9C2),
        );
        expect(
          calendar.timeSlotViewSettings.timeTextStyle?.color,
          Colors.white,
        );
      },
    );

    testWidgets('showEventPopup displays popup with event title', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 357',
            events: [popupEvent],
            onBack: () {},
          ),
        ),
      );

      final state = tester.state(find.byType(CalendarScheduleView)) as dynamic;
      state.showEventPopup(popupEvent);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarEventPopup), findsOneWidget);
      expect(find.text('SOEN 357 Lecture'), findsOneWidget);
    });
    testWidgets('popup close button closes the popup', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 357',
            events: [popupEvent],
            onBack: () {},
          ),
        ),
      );

      final state = tester.state(find.byType(CalendarScheduleView)) as dynamic;
      state.showEventPopup(popupEvent);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarEventPopup), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarEventPopup), findsNothing);
    });
    testWidgets('popup Go to Building calls onGoToBuilding callback', (
      tester,
    ) async {
      GoogleCalendarEvent? receivedEvent;
      String? receivedBuildingCode;

      // Ensure clean state before the interaction.
      SavedDirectionsController.clear();
      expect(SavedDirectionsController.notifier.value, isNull);

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 357',
            events: [popupEvent],
            onBack: () {},
            onGoToBuilding: (event, buildingCode) {
              receivedEvent = event;
              receivedBuildingCode = buildingCode;
            },
          ),
        ),
      );

      final state = tester.state(find.byType(CalendarScheduleView)) as dynamic;
      state.showEventPopup(popupEvent);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Building'));
      await tester.pumpAndSettle();

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.id, 'popup_1');
      expect(receivedBuildingCode, isNotEmpty);

      // New behavior: tapping Go to Building requests directions in Explore flow.
      final requested = SavedDirectionsController.notifier.value;
      expect(requested, isNotNull);
      expect(
        requested!.id.toUpperCase(),
        receivedBuildingCode!.trim().toUpperCase(),
      );
    });
    testWidgets('popup Go to Room calls onGoToRoom callback', (tester) async {
      GoogleCalendarEvent? receivedEvent;
      String? receivedBuildingCode;
      String? receivedRoomNumber;

      // Ensure clean state before the interaction.
      SavedDirectionsController.clear();
      expect(SavedDirectionsController.notifier.value, isNull);

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 357',
            events: [popupEvent],
            onBack: () {},
            onGoToRoom: (event, buildingCode, roomNumber) {
              receivedEvent = event;
              receivedBuildingCode = buildingCode;
              receivedRoomNumber = roomNumber;
            },
          ),
        ),
      );

      final state = tester.state(find.byType(CalendarScheduleView)) as dynamic;
      state.showEventPopup(popupEvent);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Room'));
      await tester.pumpAndSettle();

      expect(receivedEvent, isNotNull);
      expect(receivedBuildingCode, isNotEmpty);
      expect(receivedRoomNumber, 'H-937');

      // New behavior: Go to Room requests directions (like Go to Building),
      // and carries the room code for Explore to prefill.
      final requested = SavedDirectionsController.notifier.value;
      expect(requested, isNotNull);
      expect(
        requested!.id.toUpperCase(),
        receivedBuildingCode!.trim().toUpperCase(),
      );
      expect(requested.roomCode, receivedRoomNumber);
      expect(requested.roomCode!.toLowerCase(), isNot('all'));
    });
    testWidgets('popup Save calls onSave callback', (tester) async {
      GoogleCalendarEvent? receivedEvent;
      String? receivedBuildingCode;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 357',
            events: [popupEvent],
            onBack: () {},
            onSave: (event, buildingCode) {
              receivedEvent = event;
              receivedBuildingCode = buildingCode;
            },
          ),
        ),
      );

      final state = tester.state(find.byType(CalendarScheduleView)) as dynamic;
      state.showEventPopup(popupEvent);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(receivedEvent, isNotNull);
      expect(receivedBuildingCode, isNotEmpty);
    });
    testWidgets('handleCalendarTap ignores non-appointment targets', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarScheduleView(
            selectedCalendarLabel: 'SOEN 357',
            events: [popupEvent],
            onBack: () {},
          ),
        ),
      );

      final state = tester.state(find.byType(CalendarScheduleView)) as dynamic;

      state.handleCalendarTap(
        CalendarTapDetails(
          null,
          DateTime(2026, 3, 12),
          CalendarElement.calendarCell,
          null,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalendarEventPopup), findsNothing);
    });
    testWidgets(
      'handleCalendarTap ignores appointment list with non calendar event object',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            CalendarScheduleView(
              selectedCalendarLabel: 'SOEN 357',
              events: [popupEvent],
              onBack: () {},
            ),
          ),
        );

        final state =
            tester.state(find.byType(CalendarScheduleView)) as dynamic;

        state.handleCalendarTap(
          CalendarTapDetails(
            <Object>['not an event'],
            DateTime(2026, 3, 12),
            CalendarElement.appointment,
            null,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CalendarEventPopup), findsNothing);
      },
    );
  });
}
