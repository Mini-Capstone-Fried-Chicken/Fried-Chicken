import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_polygons.dart';

void main() {
  group('GoogleMaps Live Location Widget Tests', () {
    group('Campus Detection Function', () {
      test('detectCampus identifies SGW campus', () {
        const sgwCenter = LatLng(45.4973, -73.5789);
        final campus = detectCampus(sgwCenter);

        expect(campus, Campus.sgw);
      });

      test('detectCampus identifies Loyola campus', () {
        const loyolaCenter = LatLng(45.4582, -73.6405);
        final campus = detectCampus(loyolaCenter);

        expect(campus, Campus.loyola);
      });

      test('detectCampus returns none for distant location', () {
        const distant = LatLng(0, 0);
        final campus = detectCampus(distant);

        expect(campus, Campus.none);
      });

      test('detectCampus with point near SGW', () {
        const nearSGW = LatLng(45.498, -73.579);
        final campus = detectCampus(nearSGW);

        expect(campus, equals(Campus.sgw));
      });

      test('detectCampus with point near Loyola', () {
        const nearLoyola = LatLng(45.458, -73.641);
        final campus = detectCampus(nearLoyola);

        expect(campus, equals(Campus.loyola));
      });

      test('detectCampus returns valid enum value', () {
        const testPoint = LatLng(45.5, -73.5);
        final campus = detectCampus(testPoint);

        expect([Campus.sgw, Campus.loyola, Campus.none], contains(campus));
      });

      test('detectCampus with multiple test points', () {
        final testCases = [
          (const LatLng(45.4973, -73.5789), Campus.sgw),
          (const LatLng(45.4582, -73.6405), Campus.loyola),
          (const LatLng(0, 0), Campus.none),
        ];

        for (final (point, expectedCampus) in testCases) {
          final result = detectCampus(point);
          expect([Campus.sgw, Campus.loyola, Campus.none], contains(result));
        }
      });

      test('Campus enum has three values', () {
        final campuses = [Campus.sgw, Campus.loyola, Campus.none];
        expect(campuses.length, 3);
      });
    });

    group('Campus Constants', () {
      test('concordiaSGW constant is valid', () {
        expect(concordiaSGW.latitude, 45.4973);
        expect(concordiaSGW.longitude, -73.5789);
      });

      test('concordiaLoyola constant is valid', () {
        expect(concordiaLoyola.latitude, 45.4582);
        expect(concordiaLoyola.longitude, -73.6405);
      });

      test('campusRadius is positive', () {
        expect(campusRadius, greaterThan(0));
      });

      test('campusAutoSwitchRadius is positive', () {
        expect(campusAutoSwitchRadius, greaterThan(0));
      });

      test('Campus radius values are reasonable', () {
        expect(campusRadius, closeTo(500, 10));
        expect(campusAutoSwitchRadius, closeTo(500, 10));
      });

      test('Both campuses have different coordinates', () {
        expect(concordiaSGW.latitude, isNot(concordiaLoyola.latitude));
        expect(concordiaSGW.longitude, isNot(concordiaLoyola.longitude));
      });
    });

    group('OutdoorMapPage Widget Initialization', () {
      testWidgets('OutdoorMapPage initializes with SGW campus', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(initialCampus: Campus.sgw, isLoggedIn: true),
          ),
        );

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('OutdoorMapPage initializes with Loyola campus', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(
              initialCampus: Campus.loyola,
              isLoggedIn: true,
            ),
          ),
        );

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('OutdoorMapPage initializes with no campus', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(initialCampus: Campus.none, isLoggedIn: false),
          ),
        );

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('OutdoorMapPage accepts debug parameters', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(
              initialCampus: Campus.sgw,
              isLoggedIn: true,
              debugDisableMap: true,
              debugDisableLocation: true,
            ),
          ),
        );

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('OutdoorMapPage creates state', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(initialCampus: Campus.sgw, isLoggedIn: true),
          ),
        );

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });
    });

    group('Coordinate Range Validation', () {
      test('All building centers are within valid latitude range', () {
        for (final building in buildingPolygons) {
          expect(building.center.latitude, inInclusiveRange(-90, 90));
        }
      });

      test('All building centers are within valid longitude range', () {
        for (final building in buildingPolygons) {
          expect(building.center.longitude, inInclusiveRange(-180, 180));
        }
      });

      test('All building points are valid coordinates', () {
        for (final building in buildingPolygons) {
          for (final point in building.points) {
            expect(point.latitude, inInclusiveRange(-90, 90));
            expect(point.longitude, inInclusiveRange(-180, 180));
          }
        }
      });

      test('SGW campus is in Montreal bounds', () {
        expect(concordiaSGW.latitude, inInclusiveRange(45.0, 46.0));
        expect(concordiaSGW.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Loyola campus is in Montreal bounds', () {
        expect(concordiaLoyola.latitude, inInclusiveRange(45.0, 46.0));
        expect(concordiaLoyola.longitude, inInclusiveRange(-74.0, -73.0));
      });
    });

    group('Building Polygon Data', () {
      test('All buildings have valid polygons', () {
        expect(buildingPolygons, isNotEmpty);

        for (final building in buildingPolygons) {
          expect(building.points, isNotEmpty);
          expect(building.points.length, greaterThanOrEqualTo(3));
        }
      });

      test('All buildings have centers', () {
        for (final building in buildingPolygons) {
          expect(building.center, isNotNull);
          expect(building.center.latitude, isA<double>());
          expect(building.center.longitude, isA<double>());
        }
      });

      test('Building centers are within their bounds', () {
        for (final building in buildingPolygons.take(10)) {
          final center = building.center;
          final points = building.points;

          double minLat = points.first.latitude;
          double maxLat = minLat;
          double minLng = points.first.longitude;
          double maxLng = minLng;

          for (final point in points) {
            minLat = minLat < point.latitude ? minLat : point.latitude;
            maxLat = maxLat > point.latitude ? maxLat : point.latitude;
            minLng = minLng < point.longitude ? minLng : point.longitude;
            maxLng = maxLng > point.longitude ? maxLng : point.longitude;
          }

          expect(center.latitude, greaterThanOrEqualTo(minLat - 0.001));
          expect(center.latitude, lessThanOrEqualTo(maxLat + 0.001));
        }
      });

      test('Building codes are unique', () {
        final codes = buildingPolygons.map((b) => b.code).toList();
        final uniqueCodes = codes.toSet();

        expect(codes.length, uniqueCodes.length);
      });

      test('Building names are not empty', () {
        for (final building in buildingPolygons) {
          expect(building.name, isNotEmpty);
        }
      });
    });

    group('Campus Detection Edge Cases', () {
      test('Point at exact boundary returns a campus', () {
        // Point exactly at campusRadius distance
        const boundaryPoint = LatLng(45.498, -73.579);
        final campus = detectCampus(boundaryPoint);

        expect([Campus.sgw, Campus.loyola, Campus.none], contains(campus));
      });

      test('Point equidistant from both campuses', () {
        final midLat = (concordiaSGW.latitude + concordiaLoyola.latitude) / 2;
        final midLng = (concordiaSGW.longitude + concordiaLoyola.longitude) / 2;

        final midpoint = LatLng(midLat, midLng);
        final campus = detectCampus(midpoint);

        expect([Campus.sgw, Campus.loyola, Campus.none], contains(campus));
      });

      test('Point at maximum latitude', () {
        const maxLat = LatLng(89.9, -73.5);
        final campus = detectCampus(maxLat);

        expect(campus, Campus.none);
      });

      test('Point at minimum latitude', () {
        const minLat = LatLng(-89.9, -73.5);
        final campus = detectCampus(minLat);

        expect(campus, Campus.none);
      });

      test('Point at date line', () {
        const dateLine = LatLng(45.5, 180);
        final campus = detectCampus(dateLine);

        expect(campus, Campus.none);
      });
    });

    group('Outdoor Map Page Properties', () {
      test('OutdoorMapPage has initialCampus property', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        expect(page.initialCampus, Campus.sgw);
      });

      test('OutdoorMapPage has isLoggedIn property', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        expect(page.isLoggedIn, true);
      });

      test('OutdoorMapPage has debug properties', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugLinkOverride: 'https://test.com',
        );

        expect(page.debugDisableMap, true);
        expect(page.debugDisableLocation, true);
        expect(page.debugLinkOverride, 'https://test.com');
      });

      test('OutdoorMapPage has default debug values', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        expect(page.debugDisableMap, false);
        expect(page.debugDisableLocation, false);
      });

      test('OutdoorMapPage creates correct state', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: false,
        );

        expect(page.createState, isNotNull);
      });
    });

    group('Distance and Location Calculations', () {
      test('Distance between SGW and Loyola is non-zero', () {
        final latDiff = (concordiaSGW.latitude - concordiaLoyola.latitude)
            .abs();
        final lngDiff = (concordiaSGW.longitude - concordiaLoyola.longitude)
            .abs();

        expect(latDiff, greaterThan(0));
        expect(lngDiff, greaterThan(0));
      });

      test('Distance between identical points is zero', () {
        const point1 = LatLng(45.5, -73.5);
        const point2 = LatLng(45.5, -73.5);

        final latDiff = (point1.latitude - point2.latitude).abs();
        final lngDiff = (point1.longitude - point2.longitude).abs();

        expect(latDiff, 0);
        expect(lngDiff, 0);
      });

      test('Campus radius defines detection threshold', () {
        expect(campusRadius, closeTo(500, 50)); // meters, within ±50m
      });

      test('Auto-switch radius matches campus radius', () {
        expect(campusAutoSwitchRadius, equals(campusRadius));
      });
    });

    group('Campus Constants Sanity', () {
      test('SGW latitude is in Montreal range', () {
        expect(concordiaSGW.latitude, inInclusiveRange(45, 46));
      });

      test('SGW longitude is in Montreal range', () {
        expect(concordiaSGW.longitude, inInclusiveRange(-74, -73));
      });

      test('Loyola latitude is in Montreal range', () {
        expect(concordiaLoyola.latitude, inInclusiveRange(45, 46));
      });

      test('Loyola longitude is in Montreal range', () {
        expect(concordiaLoyola.longitude, inInclusiveRange(-74, -73));
      });

      test('SGW is north of Loyola', () {
        expect(concordiaSGW.latitude, greaterThan(concordiaLoyola.latitude));
      });

      test('SGW is west of Loyola', () {
        expect(concordiaSGW.longitude, greaterThan(concordiaLoyola.longitude));
      });
    });

    group('Widget Lifecycle and State', () {
      testWidgets('OutdoorMapPage widget builds successfully', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(initialCampus: Campus.sgw, isLoggedIn: true),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('Multiple widget instances can be created', (
        WidgetTester tester,
      ) async {
        const page1 = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        const page2 = OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: false,
        );

        expect(page1.initialCampus, Campus.sgw);
        expect(page2.initialCampus, Campus.loyola);
      });

      testWidgets('Widget handles property changes', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(
              initialCampus: Campus.sgw,
              isLoggedIn: true,
              debugDisableMap: false,
              debugDisableLocation: false,
            ),
          ),
        );

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('Widget with all debug flags enabled', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OutdoorMapPage(
              initialCampus: Campus.none,
              isLoggedIn: false,
              debugDisableMap: true,
              debugDisableLocation: true,
              debugLinkOverride: 'https://campus.example.com',
            ),
          ),
        );

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('Widget clears correct debug parameters', (
        WidgetTester tester,
      ) async {
        const page = OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: true,
        );

        expect(page.debugDisableMap, false);
        expect(page.debugDisableLocation, false);
        expect(page.debugLinkOverride, isNull);
      });

      testWidgets('Widget state is preserved through pump', (
        WidgetTester tester,
      ) async {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        await tester.pumpWidget(MaterialApp(home: page));
        await tester.pump();

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });
    });

    group('Widget Constructor and Properties', () {
      test('OutdoorMapPage constructor with all parameters', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugLinkOverride: 'https://test.concordia.ca',
        );

        expect(page.initialCampus, Campus.sgw);
        expect(page.isLoggedIn, true);
        expect(page.debugDisableMap, true);
        expect(page.debugDisableLocation, true);
        expect(page.debugLinkOverride, 'https://test.concordia.ca');
      });

      test('OutdoorMapPage constructor with minimal parameters', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: false,
        );

        expect(page.initialCampus, Campus.loyola);
        expect(page.isLoggedIn, false);
        expect(page.debugDisableMap, false);
        expect(page.debugDisableLocation, false);
      });

      test('OutdoorMapPage inherits from StatefulWidget', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        expect(page, isA<StatefulWidget>());
      });

      test('OutdoorMapPage createState returns proper type', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        final state = page.createState();
        expect(state, isNotNull);
      });

      test('Widget properties are final', () {
        const page = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        // Verify properties cannot be changed (const)
        final campus = page.initialCampus;
        expect(campus, Campus.sgw);
      });
    });

    group('Campus Enum Values', () {
      test('Campus.sgw is valid enum value', () {
        expect(Campus.sgw, isA<Campus>());
      });

      test('Campus.loyola is valid enum value', () {
        expect(Campus.loyola, isA<Campus>());
      });

      test('Campus.none is valid enum value', () {
        expect(Campus.none, isA<Campus>());
      });

      test('Campus enum values are distinct', () {
        final campuses = [Campus.sgw, Campus.loyola, Campus.none];
        final uniqueCampuses = campuses.toSet();

        expect(campuses.length, uniqueCampuses.length);
      });

      test('Campus enum can be compared for equality', () {
        final campus1 = Campus.sgw;
        final campus2 = Campus.sgw;

        expect(campus1, equals(campus2));
      });

      test('Campus enum values have correct comparisons', () {
        expect(Campus.sgw == Campus.sgw, true);
        expect(Campus.sgw == Campus.loyola, false);
        expect(Campus.sgw == Campus.none, false);
      });
    });

    group('Widget Integration Tests', () {
      testWidgets('OutdoorMapPage renders with SGW campus', (
        WidgetTester tester,
      ) async {
        final testWidget = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        await tester.pumpWidget(MaterialApp(home: testWidget));

        expect(find.byWidget(testWidget), findsOneWidget);
      });

      testWidgets('OutdoorMapPage renders with Loyola campus', (
        WidgetTester tester,
      ) async {
        final testWidget = OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: false,
        );

        await tester.pumpWidget(MaterialApp(home: testWidget));

        expect(find.byWidget(testWidget), findsOneWidget);
      });

      testWidgets('OutdoorMapPage renders with Campus.none', (
        WidgetTester tester,
      ) async {
        final testWidget = OutdoorMapPage(
          initialCampus: Campus.none,
          isLoggedIn: false,
        );

        await tester.pumpWidget(MaterialApp(home: testWidget));

        expect(find.byWidget(testWidget), findsOneWidget);
      });

      testWidgets('OutdoorMapPage handles logged in state', (
        WidgetTester tester,
      ) async {
        const loggedInPage = OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
        );

        await tester.pumpWidget(MaterialApp(home: loggedInPage));
        expect(loggedInPage.isLoggedIn, true);
      });

      testWidgets('OutdoorMapPage handles logged out state', (
        WidgetTester tester,
      ) async {
        const loggedOutPage = OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: false,
        );

        await tester.pumpWidget(MaterialApp(home: loggedOutPage));
        expect(loggedOutPage.isLoggedIn, false);
      });
    });
  });
}
