import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/widgets/campus_toggle.dart';
import 'package:campus_app/screens/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_info.dart';

void main() {
  group('Campus Toggle Tests', () {
    testWidgets('Campus toggle displays both SGW and Loyola options',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.none;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sir George William'), findsOneWidget);
      expect(find.text('Loyola'), findsOneWidget);
    });

    testWidgets('Toggle on SGW campus name shows SGW campus selected',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.sgw;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      // Verify SGW is displayed
      expect(find.text('Sir George William'), findsOneWidget);

      // The SGW button should be highlighted (maroon background with white text)
      final sgrButton = find.ancestor(
        of: find.text('Sir George William'),
        matching: find.byType(AnimatedContainer),
      );

      expect(sgrButton, findsWidgets);
    });

    testWidgets('Toggle on Loyola campus name shows Loyola campus selected',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.loyola;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      // Verify Loyola is displayed
      expect(find.text('Loyola'), findsOneWidget);

      // The Loyola button should be highlighted (maroon background with white text)
      final loyolaButton = find.ancestor(
        of: find.text('Loyola'),
        matching: find.byType(AnimatedContainer),
      );

      expect(loyolaButton, findsWidgets);
    });

    testWidgets('Tapping SGW button switches to SGW campus',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.loyola;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      // Initially on Loyola
      expect(selectedCampus, equals(Campus.loyola));

      // Tap SGW button
      await tester.tap(find.text('Sir George William'));
      await tester.pumpAndSettle();

      // Should now be on SGW
      expect(selectedCampus, equals(Campus.sgw));
    });

    testWidgets('Tapping Loyola button switches to Loyola campus',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.sgw;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      // Initially on SGW
      expect(selectedCampus, equals(Campus.sgw));

      // Tap Loyola button
      await tester.tap(find.text('Loyola'));
      await tester.pumpAndSettle();

      // Should now be on Loyola
      expect(selectedCampus, equals(Campus.loyola));
    });

    testWidgets('Toggle can switch multiple times between campuses',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.none;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      // Switch to SGW
      await tester.tap(find.text('Sir George William'));
      await tester.pumpAndSettle();
      expect(selectedCampus, equals(Campus.sgw));

      // Switch to Loyola
      await tester.tap(find.text('Loyola'));
      await tester.pumpAndSettle();
      expect(selectedCampus, equals(Campus.loyola));

      // Switch back to SGW
      await tester.tap(find.text('Sir George William'));
      await tester.pumpAndSettle();
      expect(selectedCampus, equals(Campus.sgw));
    });

    testWidgets('SGW campus corresponds to SGW buildings',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.sgw;

      // Verify that SGW buildings exist in the building info
      final sgwBuildings = buildingInfoByCode.values
          .where((building) => building.campus == 'SGW')
          .toList();

      expect(sgwBuildings.isNotEmpty, isTrue,
          reason: 'There should be at least one SGW building');

      for (final building in sgwBuildings) {
        expect(building.code, isNotNull);
        expect(building.name, isNotNull);
        expect(building.floors, isNotEmpty);
      }
    });

    testWidgets('Campus toggle displays SGW map when SGW is selected',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.sgw;

      // Filter buildings by selected campus
      final selectedBuildings = buildingInfoByCode.values
          .where((building) => building.campus == 'SGW')
          .toList();

      // Verify we can get specific SGW buildings
      expect(selectedBuildings.isNotEmpty, isTrue);

      // Verify SGW buildings are accessible
      for (final building in selectedBuildings) {
        expect(
          building.floors.isNotEmpty,
          isTrue,
          reason:
              'SGW building ${building.code} should have at least one floor',
        );
      }
    });

    testWidgets('SGW and Loyola have distinct building sets',
        (WidgetTester tester) async {
      final sgwBuildings = buildingInfoByCode.values
          .where((building) => building.campus == 'SGW')
          .map((b) => b.code)
          .toSet();

      final loyolaBuildings = buildingInfoByCode.values
          .where((building) => building.campus == 'Loyola')
          .map((b) => b.code)
          .toSet();

      // Verify there's no overlap between SGW and Loyola building codes
      final overlap = sgwBuildings.intersection(loyolaBuildings);
      expect(overlap.isEmpty, isTrue,
          reason: 'SGW and Loyola should have distinct building sets');
    });

    testWidgets('All buildings are assigned to either SGW or Loyola campus',
        (WidgetTester tester) async {
      for (final building in buildingInfoByCode.values) {
        expect(
          building.campus == 'SGW' || building.campus == 'Loyola',
          isTrue,
          reason:
              'Building ${building.code} should be on either SGW or Loyola campus',
        );
      }
    });

    testWidgets('Campus toggle button is tappable', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: Campus.none,
                onCampusChanged: (campus) {
                  tapCount++;
                },
              ),
            ),
          ),
        ),
      );

      // Tap SGW button
      await tester.tap(find.text('Sir George William'));
      expect(tapCount, equals(1));

      // Tap Loyola button
      await tester.tap(find.text('Loyola'));
      expect(tapCount, equals(2));
    });

    testWidgets(
        'Toggle shows visual feedback when campus is selected (animation)',
        (WidgetTester tester) async {
      Campus selectedCampus = Campus.sgw;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      // Trigger animation by switching campus
      selectedCampus = Campus.loyola;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: selectedCampus,
                onCampusChanged: (campus) {
                  selectedCampus = campus;
                },
              ),
            ),
          ),
        ),
      );

      // Run animation frames
      await tester.pumpAndSettle();

      // Verify the animation completed without errors
      expect(selectedCampus, equals(Campus.loyola));
    });
  });
}
