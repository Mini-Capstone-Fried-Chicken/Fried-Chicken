import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';
import 'package:campus_app/features/calendar/ui/widgets/calendar_selection_view.dart';
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

  const calendar1 = GoogleCalendarInfo(
    id: 'cal_1',
    name: 'SOEN 341',
    isPrimary: false,
  );

  const calendar2 = GoogleCalendarInfo(
    id: 'cal_2',
    name: 'SOEN 357',
    isPrimary: true,
  );

  group('CalendarSelectionView', () {
    testWidgets('renders static text and calendars', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: null,
            calendars: const [calendar1, calendar2],
            selectedCalendarIds: const {},
            onCalendarToggled: (_) {},
            onContinue: () {},
            onSetupPressed: () {},
          ),
        ),
      );

      expect(find.text('Successfully Connected!'), findsOneWidget);
      expect(find.text('Select Calendar(s)'), findsOneWidget);
      expect(
        find.text('Select one or more calendars that contain your class schedule'),
        findsOneWidget,
      );
      expect(find.text('SOEN 341'), findsOneWidget);
      expect(find.text('SOEN 357'), findsOneWidget);
      expect(find.text('How to set up calendar'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: true,
            error: null,
            calendars: const [calendar1, calendar2],
            selectedCalendarIds: const {},
            onCalendarToggled: (_) {},
            onContinue: () {},
            onSetupPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SOEN 341'), findsNothing);
      expect(find.text('SOEN 357'), findsNothing);
    });

    testWidgets('shows error text when error is provided', (tester) async {
      const errorMessage = 'Something went wrong';

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: errorMessage,
            calendars: const [calendar1],
            selectedCalendarIds: const {},
            onCalendarToggled: (_) {},
            onContinue: () {},
            onSetupPressed: () {},
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('does not show error text when error is null', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: null,
            calendars: const [calendar1],
            selectedCalendarIds: const {},
            onCalendarToggled: (_) {},
            onContinue: () {},
            onSetupPressed: () {},
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('calls onCalendarToggled when a calendar is tapped', (
      tester,
    ) async {
      GoogleCalendarInfo? tappedCalendar;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: null,
            calendars: const [calendar1, calendar2],
            selectedCalendarIds: const {},
            onCalendarToggled: (calendar) {
              tappedCalendar = calendar;
            },
            onContinue: () {},
            onSetupPressed: () {},
          ),
        ),
      );

      await tester.tap(find.text('SOEN 341'));
      await tester.pump();

      expect(tappedCalendar, isNotNull);
      expect(tappedCalendar!.id, 'cal_1');
      expect(tappedCalendar!.name, 'SOEN 341');
    });

    testWidgets('shows check icon for selected calendars', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: null,
            calendars: const [calendar1, calendar2],
            selectedCalendarIds: const {'cal_2'},
            onCalendarToggled: (_) {},
            onContinue: () {},
            onSetupPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('SOEN 357'), findsOneWidget);
    });

    testWidgets('continue button is disabled when no calendars are selected', (
      tester,
    ) async {
      var continued = false;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: null,
            calendars: const [calendar1],
            selectedCalendarIds: const {},
            onCalendarToggled: (_) {},
            onContinue: () {
              continued = true;
            },
            onSetupPressed: () {},
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(continued, isFalse);
    });

    testWidgets('continue button works when at least one calendar is selected', (
      tester,
    ) async {
      var continued = false;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: null,
            calendars: const [calendar1],
            selectedCalendarIds: const {'cal_1'},
            onCalendarToggled: (_) {},
            onContinue: () {
              continued = true;
            },
            onSetupPressed: () {},
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(continued, isTrue);
    });

    testWidgets('continue button is disabled when loading', (tester) async {
      var continued = false;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: true,
            error: null,
            calendars: const [calendar1],
            selectedCalendarIds: const {'cal_1'},
            onCalendarToggled: (_) {},
            onContinue: () {
              continued = true;
            },
            onSetupPressed: () {},
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(continued, isFalse);
    });

    testWidgets('setup button calls onSetupPressed', (tester) async {
      var setupPressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarSelectionView(
            isLoading: false,
            error: null,
            calendars: const [calendar1],
            selectedCalendarIds: const {},
            onCalendarToggled: (_) {},
            onContinue: () {},
            onSetupPressed: () {
              setupPressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('How to set up calendar'));
      await tester.pump();

      expect(setupPressed, isTrue);
    });
  });
}