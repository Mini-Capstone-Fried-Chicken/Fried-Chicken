import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_app/main.dart' as app;
import 'package:campus_app/features/explore/ui/explore_screen.dart';

// run using:
// flutter run -d R5CWA1BZZSE integration_test/epic6_outdoor_poi_e2e_test.dart --dart-define=GOOGLE_DIRECTIONS_API_KEY=AIzaSyAz7CcEsdorD_rQSq_fHruG5pvYuQAPu7U --dart-define=GOOGLE_PLACES_API_KEY=AIzaSyAz7CcEsdorD_rQSq_fHruG5pvYuQAPu7U

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPIC-6 Outdoor POI E2E Test', () {
    testWidgets('View outdoor POIs and get directions to selected POI', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Continue as guest
      final continueAsGuestButton = find.byKey(
        const Key('continue_as_guest_button'),
      );
      final continueAsGuestText = find.textContaining('Continue as Guest');

      if (continueAsGuestButton.evaluate().isNotEmpty) {
        await tester.tap(continueAsGuestButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else if (continueAsGuestText.evaluate().isNotEmpty) {
        await tester.tap(continueAsGuestText.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Open Explore
      final exploreTab = find.text('Explore');
      expect(exploreTab, findsOneWidget);
      await tester.tap(exploreTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(ExploreScreen), findsOneWidget);

      final allowButton = find.text('Allow');
      if (allowButton.evaluate().isNotEmpty) {
        await tester.tap(allowButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // FLOW 1: SEARCH FOR AN OUTDOOR POI
      final searchBar = find.byKey(const Key('destination_search_bar'));
      final searchInput = find.byKey(const Key('map_search_input'));

      expect(searchBar, findsOneWidget, reason: 'Search bar should exist');
      expect(searchInput, findsOneWidget, reason: 'Search input should exist');

      await tester.tap(searchInput);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.enterText(searchInput, 'Pharmaprix');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Press done on keyboard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // FLOW 2: ROUTE PLANNER OPENED
      final startField = find.byKey(const Key('start_field'));
      final destinationField = find.byKey(const Key('destination_field'));

      expect(startField, findsOneWidget, reason: 'Start field should exist');
      expect(
        destinationField,
        findsOneWidget,
        reason: 'Destination field should exist',
      );

      // Wait for routes to load visually
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 5));
      });
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final destinationText =
          tester.widget<TextField>(destinationField).controller?.text ?? '';
      expect(
        destinationText.isNotEmpty,
        isTrue,
        reason: 'Destination should be populated after searching for a POI.',
      );

      // FLOW 3: TOGGLE TRANSPORT MODES AND VERIFY ROUTES UPDATE

      Future<void> _tapAndWait(Finder finder) async {
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first);
          await tester.pumpAndSettle();

          // Wait for route recalculation
          await tester.runAsync(() async {
            await Future.delayed(const Duration(seconds: 3));
          });
          await tester.pumpAndSettle();
        }
      }

      final walkMode = find.byKey(const Key('transport_walk'));
      final transitMode = find.byKey(const Key('transport_bus'));
      final carMode = find.byKey(const Key('transport_car'));
      final bikeMode = find.byKey(const Key('transport_bike'));

      // Try multiple modes
      await _tapAndWait(walkMode);
      await _tapAndWait(transitMode);
      await _tapAndWait(carMode);
      await _tapAndWait(bikeMode);

      // Final verification: route planner still active
      expect(find.byKey(const Key('start_field')), findsOneWidget);
      expect(find.byKey(const Key('destination_field')), findsOneWidget);
    });
  });
}
