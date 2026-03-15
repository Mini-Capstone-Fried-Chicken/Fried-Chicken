import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

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

      final weekChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Week'));
      final dayChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Day'));
      final monthChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Month'));
      final scheduleChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Schedule'));

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

      final dayChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Day'));
      final weekChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Week'));

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

      final monthChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Month'));
      final weekChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Week'));

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

      final scheduleChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Schedule'));
      final weekChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Week'));

      expect(scheduleChip.selected, isTrue);
      expect(weekChip.selected, isFalse);
    });
    
  });
}