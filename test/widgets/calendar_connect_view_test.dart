import 'package:campus_app/features/calendar/ui/widgets/calendar_connect_view.dart';
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

  group('CalendarConnectView', () {
    testWidgets('renders static content correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarConnectView(
            isLoading: false,
            error: null,
            onConnect: () {},
          ),
        ),
      );

      expect(find.text('Connect to Google Calendar'), findsNWidgets(2));
      expect(
        find.text(
          'Connect your Google Calendar to import your class events and get directions to your next class.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error message when error is provided', (tester) async {
      const errorMessage = 'Failed to connect Google Calendar.';

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarConnectView(
            isLoading: false,
            error: errorMessage,
            onConnect: () {},
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('does not show error message when error is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarConnectView(
            isLoading: false,
            error: null,
            onConnect: () {},
          ),
        ),
      );

      expect(find.textContaining('Failed to connect'), findsNothing);
    });

    testWidgets('calls onConnect when button is pressed and not loading', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarConnectView(
            isLoading: false,
            error: null,
            onConnect: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('disables button and shows loader when loading', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        makeTestableWidget(
          CalendarConnectView(
            isLoading: true,
            error: null,
            onConnect: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Connect to Google Calendar'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('contains two Image widgets', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarConnectView(
            isLoading: false,
            error: null,
            onConnect: () {},
          ),
        ),
      );

      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('applies high contrast colors to title and action button', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          CalendarConnectView(
            isLoading: false,
            error: null,
            onConnect: () {},
            highContrastMode: true,
          ),
        ),
      );

      final titleText = tester
          .widgetList<Text>(find.text('Connect to Google Calendar'))
          .firstWhere((text) => text.style?.fontSize == 28);
      expect(titleText.style?.color, Colors.white);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        const Color(0xFF89D9C2),
      );
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        Colors.black,
      );
    });
  });
}