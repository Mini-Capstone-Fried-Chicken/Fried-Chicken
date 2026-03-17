import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_places_controller.dart';
import 'package:campus_app/features/saved/ui/saved_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    SavedPlacesController.notifier.value = const <SavedPlace>[];
  });

  testWidgets('renders single All dropdown option even when a place category is all', (
    WidgetTester tester,
  ) async {
    SavedPlacesController.notifier.value = const <SavedPlace>[
      SavedPlace(
        id: 'p1',
        name: 'General Place',
        category: 'all',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: SavedScreen(isLoggedIn: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    final allItems = find.text('All');
    expect(allItems, findsAtLeast(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows dynamic categories from saved list', (WidgetTester tester) async {
    SavedPlacesController.notifier.value = const <SavedPlace>[
      SavedPlace(
        id: 'p1',
        name: 'Dinner Spot',
        category: 'restaurant',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Open today: 8:00 AM - 8:00 PM',
      ),
      SavedPlace(
        id: 'p2',
        name: 'MB Building',
        category: 'concordia building',
        latitude: 45.1,
        longitude: -73.1,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: SavedScreen(isLoggedIn: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('Concordia Building'), findsOneWidget);
  });

  testWidgets('does not show removed current-location icon in header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SavedScreen(isLoggedIn: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.my_location), findsNothing);
    expect(find.byTooltip('Refresh location'), findsNothing);
  });
}
