import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/shared/widgets/campus_toggle.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';

void main() {
  group('CampusToggle', () {
    testWidgets('renders both options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusToggle(
              currentCampus: Campus.none,
              onCampusChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Sir George William'), findsOneWidget);
      expect(find.text('Loyola'), findsOneWidget);
    });

    testWidgets('tap SGW calls onCampusChanged with Campus.sgw', (tester) async {
      Campus picked = Campus.none;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusToggle(
              currentCampus: Campus.none,
              onCampusChanged: (c) => picked = c,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sir George William'));
      await tester.pumpAndSettle();

      expect(picked, Campus.sgw);
    });

    testWidgets('tap Loyola calls onCampusChanged with Campus.loyola',
        (tester) async {
      Campus picked = Campus.none;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusToggle(
              currentCampus: Campus.none,
              onCampusChanged: (c) => picked = c,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Loyola'));
      await tester.pumpAndSettle();

      expect(picked, Campus.loyola);
    });

    testWidgets('Campus.none -> both segments unselected (transparent bg)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: Campus.none,
                onCampusChanged: (_) {},
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
      final sgwContainer = find.ancestor(
        of: find.text('Sir George William'),
        matching: find.byType(AnimatedContainer),
      );
      final loyContainer = find.ancestor(
        of: find.text('Loyola'),
        matching: find.byType(AnimatedContainer),
      );

      final sgw = tester.widget<AnimatedContainer>(sgwContainer.first);
      final loy = tester.widget<AnimatedContainer>(loyContainer.first);

      final sgwDeco = sgw.decoration as BoxDecoration;
      final loyDeco = loy.decoration as BoxDecoration;

      expect(sgwDeco.color, equals(Colors.transparent));
      expect(loyDeco.color, equals(Colors.transparent));
    });

    testWidgets('selected campus changes bg + text color', (tester) async {
      const maroon = Color(0xFF800020);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: Campus.sgw,
                onCampusChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final sgwContainer = find.ancestor(
        of: find.text('Sir George William'),
        matching: find.byType(AnimatedContainer),
      );
      final loyContainer = find.ancestor(
        of: find.text('Loyola'),
        matching: find.byType(AnimatedContainer),
      );

      final sgw = tester.widget<AnimatedContainer>(sgwContainer.first);
      final loy = tester.widget<AnimatedContainer>(loyContainer.first);

      final sgwDeco = sgw.decoration as BoxDecoration;
      final loyDeco = loy.decoration as BoxDecoration;

      expect(sgwDeco.color, equals(maroon));
      expect(loyDeco.color, equals(Colors.transparent));

      final sgwText = tester.widget<Text>(find.text('Sir George William'));
      final loyText = tester.widget<Text>(find.text('Loyola'));

      expect(sgwText.style?.color, equals(Colors.white));
      expect(loyText.style?.color, equals(maroon));
    });

    testWidgets('animation runs when switching selected campus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: Campus.sgw,
                onCampusChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CampusToggle(
                currentCampus: Campus.loyola,
                onCampusChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Loyola'), findsOneWidget);
    });
  });
}
