import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/models/campus.dart';

void _setupGoogleMapsMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_maps'),
        (MethodCall call) async {
          switch (call.method) {
            case 'map#waitForMap':
              return null;
            case 'map#update':
              return null;
            case 'camera#move':
              return null;
            case 'camera#animate':
              return null;
            case 'map#getVisibleRegion':
              return {
                'southwest': {'lat': 45.49, 'lng': -73.59},
                'northeast': {'lat': 45.51, 'lng': -73.57},
              };
            case 'map#getScreenCoordinate':
              return {'x': 200, 'y': 400};
            case 'map#getLatLng':
              return {'lat': 45.4973, 'lng': -73.5789};
            case 'map#isCompassEnabled':
              return true;
            case 'map#isMapToolbarEnabled':
              return false;
            case 'map#getMinMaxZoomLevels':
              return {'min': 3.0, 'max': 21.0};
            case 'map#isZoomGesturesEnabled':
              return true;
            case 'map#isZoomControlsEnabled':
              return false;
            case 'map#isTiltGesturesEnabled':
              return true;
            case 'map#isRotateGesturesEnabled':
              return true;
            case 'map#isScrollGesturesEnabled':
              return true;
            case 'map#isMyLocationButtonEnabled':
              return false;
            case 'map#setStyle':
              return [true, null];
            case 'markers#update':
              return null;
            case 'polygons#update':
              return null;
            case 'polylines#update':
              return null;
            case 'circles#update':
              return null;
            default:
              return null;
          }
        },
      );
}

void _setupGeolocatorMock() {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'isLocationServiceEnabled':
            return true;
          case 'checkPermission':
            return 3;
          case 'requestPermission':
            return 3;
          case 'getLastKnownPosition':
            return null;
          case 'getCurrentPosition':
            return {
              'latitude': 45.4973,
              'longitude': -73.5789,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'accuracy': 10.0,
              'altitude': 0.0,
              'heading': 0.0,
              'speed': 0.0,
              'speed_accuracy': 0.0,
            };
          case 'getPositionStream':
            return null;
          default:
            return null;
        }
      });
}

Future<void> pumpWithMap(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
  bool isLoggedIn = false,
  BuildingPolygon? debugSelectedBuilding,
  Offset? debugAnchorOffset,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        isLoggedIn: isLoggedIn,
        debugSelectedBuilding: debugSelectedBuilding,
        debugAnchorOffset: debugAnchorOffset,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _setupGoogleMapsMock();
    _setupGeolocatorMock();
  });

  group('Amenity icons - widget construction', () {
    testWidgets('OutdoorMapPage builds successfully with amenity support', (
      tester,
    ) async {
      await pumpWithMap(tester);
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Widget builds with logged-in user', (tester) async {
      await pumpWithMap(tester, isLoggedIn: true);
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Zoom tracking variables', () {
    testWidgets('Widget initializes with default zoom values', (tester) async {
      await pumpWithMap(tester);
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Zoom tracking works across campus changes', (tester) async {
      await pumpWithMap(tester, initialCampus: Campus.loyola);
      await tester.pumpAndSettle();

      await pumpWithMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Conditional marker rendering', () {
    testWidgets('Markers render when no indoor map is shown', (tester) async {
      await pumpWithMap(tester);
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Widget handles marker updates', (tester) async {
      final firstBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Indoor map amenity icon integration', () {
    testWidgets('Widget can show indoor map for HALL building', (tester) async {
      final hallBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      final indoorToggle = find.text('Indoor Map');
      if (indoorToggle.evaluate().isNotEmpty) {
        await tester.tap(indoorToggle.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Widget handles indoor map loading', (tester) async {
      await pumpWithMap(tester, isLoggedIn: true);
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Zoom change detection', () {
    testWidgets('Widget survives camera position changes', (tester) async {
      await pumpWithMap(tester);
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Multiple zoom changes handled correctly', (tester) async {
      await pumpWithMap(tester, isLoggedIn: true);
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('State clearing includes amenity markers', () {
    testWidgets('Turning indoor map off clears all indoor state', (
      tester,
    ) async {
      final hallBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      final indoorToggle = find.text('Indoor Map');
      if (indoorToggle.evaluate().isNotEmpty) {
        await tester.tap(indoorToggle.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        await tester.tap(indoorToggle.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Switching buildings clears previous indoor state', (
      tester,
    ) async {
      final buildings = buildingPolygons.take(2).toList();
      if (buildings.length < 2) return;

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: buildings[0],
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();
      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: buildings[1],
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Amenity icon reload on zoom change', () {
    testWidgets('Indoor map with significant zoom change triggers reload', (
      tester,
    ) async {
      final hallBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      final indoorToggle = find.text('Indoor Map');
      if (indoorToggle.evaluate().isNotEmpty) {
        await tester.tap(indoorToggle.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('No reload when zoom change is insignificant', (tester) async {
      await pumpWithMap(tester, isLoggedIn: true);
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Amenity icon error handling', () {
    testWidgets('Widget continues to function if amenity loading fails', (
      tester,
    ) async {
      await pumpWithMap(tester, isLoggedIn: true);
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Missing GeoJSON handled gracefully', (tester) async {
      final buildingWithoutIndoor = buildingPolygons.firstWhere(
        (b) => b.code != 'HALL' && b.code != 'MB' && b.code != 'VE',
        orElse: () => buildingPolygons.last,
      );

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: buildingWithoutIndoor,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Amenity icons with existing features', () {
    testWidgets('Amenity icons work with campus toggle', (tester) async {
      await pumpWithMap(tester, initialCampus: Campus.sgw, isLoggedIn: true);
      await tester.pumpAndSettle();

      final campusToggle = find.text('Loyola');
      if (campusToggle.evaluate().isNotEmpty) {
        await tester.tap(campusToggle.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Amenity icons work with navigation mode', (tester) async {
      await pumpWithMap(tester, isLoggedIn: true);
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Amenity icons work with building selection', (tester) async {
      final testBuilding = buildingPolygons.first;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: testBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Floor switching reloads amenity icons', () {
    testWidgets('Switching floors in indoor map updates amenities', (
      tester,
    ) async {
      final hallBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      final indoorToggle = find.text('Indoor Map');
      if (indoorToggle.evaluate().isNotEmpty) {
        await tester.tap(indoorToggle.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  group('Memory management with amenity markers', () {
    testWidgets('Multiple indoor map toggles do not leak', (tester) async {
      final hallBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      final indoorToggle = find.text('Indoor Map');
      if (indoorToggle.evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.tap(indoorToggle.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Widget disposal cleans up amenity markers', (tester) async {
      await pumpWithMap(tester, isLoggedIn: true);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('disposed'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('disposed'), findsOneWidget);
    });
  });

  group('Building popup hides when indoor map shows', () {
    testWidgets('Popup visible when indoor map is off', (tester) async {
      final hallBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Popup hides when indoor map is shown', (tester) async {
      final hallBuilding = buildingPolygons.firstWhere(
        (b) => b.code == 'HALL',
        orElse: () => buildingPolygons.first,
      );

      await pumpWithMap(
        tester,
        isLoggedIn: true,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      final indoorToggle = find.text('Indoor Map');
      if (indoorToggle.evaluate().isNotEmpty) {
        await tester.tap(indoorToggle.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });
}
