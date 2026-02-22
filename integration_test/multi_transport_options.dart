import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  //  run using:
  // flutter run integration_test/multi_transport_options.dart -d R5CWA1BZZSE

  testWidgets('Multi-transport options are displayed correctly', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 1- find the continue as guest button on the login screen
    final continueAsGuestButton = find.byKey(
      const Key('continue_as_guest_button'),
    );
    // tap
    await tester.tap(continueAsGuestButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2- Skip permission dialog if present
    final allowButton = find.text('Allow');
    if (allowButton.evaluate().isNotEmpty) {
      await tester.tap(allowButton);
      await tester.pumpAndSettle();
    }

    // 3- open search bar for destination
    final searchBar = find.byKey(const Key('destination_search_bar'));
    expect(
      searchBar,
      findsOneWidget,
      reason: 'Destination search bar should exist',
    );
    await tester.tap(searchBar);
    await tester.pumpAndSettle();

    // 4- Type the destination building name
    const destinationName = 'EV';
    await tester.enterText(searchBar, destinationName);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 5- Select the suggested result
    final suggestion = find.text('EV Building');
    expect(
      suggestion,
      findsOneWidget,
      reason: 'EV Building suggestion should appear',
    );
    await tester.pumpAndSettle();

    // Tap the suggestion
    await tester.tap(suggestion);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 6- Tap "Get Directions" button to show route planner
    final getDirectionsButton = find.byKey(const Key('get_directions_button'));
    if (getDirectionsButton.evaluate().isNotEmpty) {
      await tester.tap(getDirectionsButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // 7- Verify the route planner shows start and destination
    final startField = find.byKey(const Key('start_field'));
    final destinationField = find.byKey(const Key('destination_field'));
    expect(startField, findsOneWidget, reason: 'Start field should exist');
    expect(
      destinationField,
      findsOneWidget,
      reason: 'Destination field should exist',
    );

    // 7- Ensure start defaults to current location
    final startText =
        tester.widget<TextField>(startField).controller?.text ?? '';
    expect(
      startText,
      'Current location',
      reason: 'Start field should default to current location',
    );

    // 8- Ensure destination field is auto-filled
    final destinationText =
        tester.widget<TextField>(destinationField).controller?.text ?? '';
    expect(
      destinationText,
      contains('EV'),
      reason: 'Destination field should contain EV building',
    );

    // 9- Optionally, tap the X to clear selection and verify fields reset
    final clearButton = find.byKey(const Key('clear_route_button'));
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    // Verify route preview panel is closed (fields no longer exist)
    expect(
      find.byKey(const Key('start_field')),
      findsNothing,
      reason: 'Start field should be cleared',
    );
    expect(
      find.byKey(const Key('destination_field')),
      findsNothing,
      reason: 'Destination field should be cleared',
    );
  });
}
