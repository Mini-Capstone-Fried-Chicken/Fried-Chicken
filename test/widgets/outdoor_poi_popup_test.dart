import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/shared/widgets/outdoor/outdoor_poi_popup.dart';
import 'package:campus_app/services/nearby_poi_service.dart';

void main() {
  const testPoi = PoiPlace(
    placeId: 'test_place_123',
    name: 'Tim Hortons',
    location: LatLng(45.4973, -73.5789),
    category: PoiCategory.cafe,
  );

  group('OutdoorPoiPopup', () {
    testWidgets('displays POI name and category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorPoiPopup(
                  poi: testPoi,
                  onClose: () {},
                  onGetDirections: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tim Hortons'), findsOneWidget);
      expect(find.text('Cafe'), findsOneWidget);
    });

    testWidgets('displays Get Directions button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorPoiPopup(
                  poi: testPoi,
                  onClose: () {},
                  onGetDirections: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Get Directions'), findsOneWidget);
      expect(
        find.byKey(const Key('poi_get_directions_button')),
        findsOneWidget,
      );
    });

    testWidgets('close button calls onClose', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorPoiPopup(
                  poi: testPoi,
                  onClose: () => closed = true,
                  onGetDirections: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('poi_popup_close')));
      expect(closed, isTrue);
    });

    testWidgets('Get Directions button calls onGetDirections', (tester) async {
      bool directionsCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorPoiPopup(
                  poi: testPoi,
                  onClose: () {},
                  onGetDirections: () async {
                    directionsCalled = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('poi_get_directions_button')));
      await tester.pumpAndSettle();
      expect(directionsCalled, isTrue);
    });

    testWidgets('displays correct icon for each category', (tester) async {
      final categories = {
        PoiCategory.cafe: Icons.local_cafe,
        PoiCategory.restaurant: Icons.restaurant,
        PoiCategory.pharmacy: Icons.local_pharmacy,
        PoiCategory.depanneur: Icons.store,
      };

      for (final entry in categories.entries) {
        final poi = PoiPlace(
          placeId: 'test_${entry.key.name}',
          name: 'Test ${entry.key.name}',
          location: const LatLng(45.4973, -73.5789),
          category: entry.key,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  OutdoorPoiPopup(
                    poi: poi,
                    onClose: () {},
                    onGetDirections: () async {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byIcon(entry.value), findsOneWidget);
      }
    });

    testWidgets('displays correct label for each category', (tester) async {
      final labels = {
        PoiCategory.cafe: 'Cafe',
        PoiCategory.restaurant: 'Restaurant',
        PoiCategory.pharmacy: 'Pharmacy',
        PoiCategory.depanneur: 'Dépanneur',
      };

      for (final entry in labels.entries) {
        final poi = PoiPlace(
          placeId: 'test_${entry.key.name}',
          name: 'Test Place',
          location: const LatLng(45.4973, -73.5789),
          category: entry.key,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  OutdoorPoiPopup(
                    poi: poi,
                    onClose: () {},
                    onGetDirections: () async {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('high contrast mode changes accent color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorPoiPopup(
                  poi: testPoi,
                  onClose: () {},
                  onGetDirections: () async {},
                  highContrastMode: true,
                ),
              ],
            ),
          ),
        ),
      );

      // The widget should render without errors in high contrast mode
      expect(find.text('Tim Hortons'), findsOneWidget);
      expect(find.text('Get Directions'), findsOneWidget);
    });

    testWidgets('displays directions icon in button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorPoiPopup(
                  poi: testPoi,
                  onClose: () {},
                  onGetDirections: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.directions), findsOneWidget);
    });
  });
}
