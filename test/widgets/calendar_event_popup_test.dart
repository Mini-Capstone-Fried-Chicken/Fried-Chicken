import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_event_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  GoogleCalendarEvent makeEvent() {
    return GoogleCalendarEvent(
      id: 'e1',
      title: 'SOEN 341 Lecture',
      start: DateTime(2026, 3, 12, 10, 0),
      end: DateTime(2026, 3, 12, 11, 15),
      location: 'Hall Building',
      description: 'H-937',
      calendarId: 'cal1',
      calendarName: 'SOEN 341',
      color: const Color(0xFF8B1E3F),
    );
  }

  group('CalendarEventPopup', () {
    testWidgets('renders title and current location label format', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CalendarEventPopup(
            event: makeEvent(),
            buildingCode: 'HALL',
            roomNumber: 'H-937',
            onGoToBuilding: () {},
            onGoToRoom: () {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('SOEN 341 Lecture'), findsOneWidget);
      expect(find.text('HALL-H-937'), findsOneWidget);
      expect(find.text('Go to Building'), findsOneWidget);
      expect(find.text('Go to Room'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onClose when close icon is tapped', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        wrap(
          CalendarEventPopup(
            event: makeEvent(),
            buildingCode: 'HALL',
            roomNumber: 'H-937',
            onGoToBuilding: () {},
            onGoToRoom: () {},
            onClose: () {
              closed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('calls building and room callbacks', (tester) async {
      var buildingTapped = false;
      var roomTapped = false;

      await tester.pumpWidget(
        wrap(
          CalendarEventPopup(
            event: makeEvent(),
            buildingCode: 'HALL',
            roomNumber: 'H-937',
            onGoToBuilding: () {
              buildingTapped = true;
            },
            onGoToRoom: () {
              roomTapped = true;
            },
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.text('Go to Building'));
      await tester.pump();
      await tester.tap(find.text('Go to Room'));
      await tester.pump();

      expect(buildingTapped, isTrue);
      expect(roomTapped, isTrue);
    });

    testWidgets(
      'shows fallback text and disables invalid actions when data is missing',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            CalendarEventPopup(
              event: makeEvent(),
              buildingCode: '',
              roomNumber: '',
              onGoToBuilding: () {},
              onGoToRoom: () {},
              onClose: () {},
            ),
          ),
        );

        expect(find.text('Location unavailable'), findsOneWidget);

        final buttons = tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .toList();

        expect(buttons, hasLength(2));
        expect(buttons[0].onPressed, isNull);
        expect(buttons[1].onPressed, isNull);
      },
    );

    testWidgets(
      'allows building action but disables room action when room is missing',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            CalendarEventPopup(
              event: makeEvent(),
              buildingCode: 'HALL',
              roomNumber: '',
              onGoToBuilding: () {},
              onGoToRoom: () {},
              onClose: () {},
            ),
          ),
        );

        expect(find.text('HALL - No room'), findsOneWidget);

        final buttons = tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .toList();

        expect(buttons, hasLength(2));
        expect(buttons[0].onPressed, isNotNull);
        expect(buttons[1].onPressed, isNull);
      },
    );

    testWidgets('shows unknown building fallback when only room exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CalendarEventPopup(
            event: makeEvent(),
            buildingCode: '',
            roomNumber: 'H-937',
            onGoToBuilding: () {},
            onGoToRoom: () {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('Unknown building-H-937'), findsOneWidget);
    });
  });
}
