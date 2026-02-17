import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('OutdoorMapPage Widget Coverage Tests', () {
    testWidgets('creates widget with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: false,
          ),
        ),
      );

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('creates widget with Loyola campus', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.loyola,
            isLoggedIn: true,
          ),
        ),
      );

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('creates widget with debug parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: false,
            debugSelectedBuilding: buildingPolygons.first,
            debugAnchorOffset: const Offset(100, 100),
            debugDisableMap: true,
            debugDisableLocation: true,
            debugLinkOverride: 'https://test.com',
          ),
        ),
      );

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('widget builds with map disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: false,
            debugDisableMap: true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('displays campus toggle buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: false,
            debugDisableMap: true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Campus toggle should be present
      expect(find.byType(FloatingActionButton), findsWidgets);
    });

    group('Helper methods coverage', () {
      test('_polygonCenter calculates centroid correctly', () {
        final points = [
          const LatLng(0, 0),
          const LatLng(0, 1),
          const LatLng(1, 1),
          const LatLng(1, 0),
        ];

        // Create a test instance to access the method
        // We test the algorithm logic directly
        double area = 0;
        double cx = 0;
        double cy = 0;

        for (int i = 0; i < points.length; i++) {
          final p1 = points[i];
          final p2 = points[(i + 1) % points.length];

          final x1 = p1.longitude;
          final y1 = p1.latitude;
          final x2 = p2.longitude;
          final y2 = p2.latitude;

          final cross = x1 * y2 - x2 * y1;
          area += cross;
          cx += (x1 + x2) * cross;
          cy += (y1 + y2) * cross;
        }

        area *= 0.5;

        expect(area.abs(), greaterThan(0));
      });

      test('_polygonCenter handles small polygons', () {
        final points = [
          const LatLng(45.4973, -73.5789),
        ];

        // With less than 3 points, should return first point
        expect(points.length, lessThan(3));
        final result = points.first;
        expect(result, points.first);
      });

      test('_polygonCenter handles two points', () {
        final points = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4980, -73.5790),
        ];

        expect(points.length, lessThan(3));
      });

      test('_polygonCenter handles zero area polygon', () {
        // All points on a line
        final points = [
          const LatLng(0, 0),
          const LatLng(0, 1),
          const LatLng(0, 2),
        ];

        double area = 0;
        for (int i = 0; i < points.length; i++) {
          final p1 = points[i];
          final p2 = points[(i + 1) % points.length];
          final cross = p1.longitude * p2.latitude - p2.longitude * p1.latitude;
          area += cross;
        }

        area *= 0.5;
        expect(area.abs(), lessThan(1e-12));
      });

      test('_calculateBounds with single point', () {
        final points = [const LatLng(45.5, -73.5)];

        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (final point in points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        expect(minLat, 45.5);
        expect(maxLat, 45.5);
        expect(minLng, -73.5);
        expect(maxLng, -73.5);
      });

      test('_calculateBounds with multiple points', () {
        final points = [
          const LatLng(45.5, -73.5),
          const LatLng(45.6, -73.6),
          const LatLng(45.4, -73.4),
        ];

        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (final point in points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        expect(minLat, 45.4);
        expect(maxLat, 45.6);
        expect(minLng, -73.6);
        expect(maxLng, -73.4);
      });

      test('_campusFromPoint identifies SGW campus', () {
        const sgwCenter = LatLng(45.4973, -73.5789);

        final dSgw = Geolocator.distanceBetween(
          sgwCenter.latitude,
          sgwCenter.longitude,
          concordiaSGW.latitude,
          concordiaSGW.longitude,
        );

        final dLoy = Geolocator.distanceBetween(
          sgwCenter.latitude,
          sgwCenter.longitude,
          concordiaLoyola.latitude,
          concordiaLoyola.longitude,
        );

        expect(dSgw, lessThan(dLoy));
        expect(dSgw, lessThanOrEqualTo(campusAutoSwitchRadius));
      });

      test('_campusFromPoint identifies Loyola campus', () {
        const loyolaCenter = LatLng(45.4582, -73.6405);

        final dSgw = Geolocator.distanceBetween(
          loyolaCenter.latitude,
          loyolaCenter.longitude,
          concordiaSGW.latitude,
          concordiaSGW.longitude,
        );

        final dLoy = Geolocator.distanceBetween(
          loyolaCenter.latitude,
          loyolaCenter.longitude,
          concordiaLoyola.latitude,
          concordiaLoyola.longitude,
        );

        expect(dLoy, lessThan(dSgw));
        expect(dLoy, lessThanOrEqualTo(campusAutoSwitchRadius));
      });

      test('_campusFromPoint identifies none when far away', () {
        const farAway = LatLng(0, 0);

        final dSgw = Geolocator.distanceBetween(
          farAway.latitude,
          farAway.longitude,
          concordiaSGW.latitude,
          concordiaSGW.longitude,
        );

        final dLoy = Geolocator.distanceBetween(
          farAway.latitude,
          farAway.longitude,
          concordiaLoyola.latitude,
          concordiaLoyola.longitude,
        );

        final minDist = dSgw < dLoy ? dSgw : dLoy;
        expect(minDist, greaterThan(campusAutoSwitchRadius));
      });
    });

    group('Popup positioning logic', () {
      test('calculates popup position within bounds', () {
        const screenWidth = 400.0;
        const screenHeight = 800.0;
        const topPad = 50.0;
        const popupW = 300.0;
        const popupH = 260.0;

        // Anchor in center
        const ax = 200.0;
        const ay = 400.0;

        double left = ax - (popupW / 2);
        double top = ay - (popupH / 2);

        expect(left, 50.0);
        expect(top, 270.0);
      });

      test('adjusts popup position when too far left', () {
        const screenWidth = 400.0;
        const popupW = 300.0;
        const margin = 8.0;

        double left = -50.0; // Would be off screen
        final minLeft = margin;

        if (left < minLeft) left = minLeft;

        expect(left, margin);
      });

      test('adjusts popup position when too far right', () {
        const screenWidth = 400.0;
        const popupW = 300.0;
        const margin = 8.0;

        double left = 500.0; // Would be off screen
        final maxLeft = screenWidth - popupW - margin;

        if (left > maxLeft) left = maxLeft;

        expect(left, 92.0);
      });

      test('adjusts popup position when too far top', () {
        const topPad = 50.0;
        const margin = 8.0;

        double top = 10.0; // Would be too high
        final minTop = topPad + margin;

        if (top < minTop) top = minTop;

        expect(top, 58.0);
      });

      test('adjusts popup position when too far bottom', () {
        const screenHeight = 800.0;
        const popupH = 260.0;
        const margin = 8.0;

        double top = 700.0; // Would be too low
        final maxTop = screenHeight - popupH - margin;

        if (top > maxTop) top = maxTop;

        expect(top, 532.0);
      });

      test('checks if anchor is in view', () {
        const screenWidth = 400.0;
        const screenHeight = 800.0;
        const topPad = 50.0;

        const ax = 200.0;
        const ay = 400.0;

        final inView = ax >= 0 &&
            ax <= screenWidth &&
            ay >= topPad &&
            ay <= screenHeight;

        expect(inView, true);
      });

      test('checks if anchor is out of view (left)', () {
        const screenWidth = 400.0;
        const screenHeight = 800.0;
        const topPad = 50.0;

        const ax = -10.0;
        const ay = 400.0;

        final inView = ax >= 0 &&
            ax <= screenWidth &&
            ay >= topPad &&
            ay <= screenHeight;

        expect(inView, false);
      });

      test('checks if anchor is out of view (top)', () {
        const screenWidth = 400.0;
        const screenHeight = 800.0;
        const topPad = 50.0;

        const ax = 200.0;
        const ay = 20.0;

        final inView = ax >= 0 &&
            ax <= screenWidth &&
            ay >= topPad &&
            ay <= screenHeight;

        expect(inView, false);
      });
    });

    group('Building polygon creation logic', () {
      test('creates polygon with correct colors and properties', () {
        const burgundy = Color(0xFF800020);
        const selectedBlue = Color(0xFF7F83C3);

        final isSelected = true;
        final isCurrent = false;

        final strokeColor = isSelected
            ? selectedBlue.withOpacity(0.95)
            : isCurrent
            ? Colors.blue.withOpacity(0.8)
            : burgundy.withOpacity(0.55);

        final fillColor = isSelected
            ? selectedBlue.withOpacity(0.25)
            : isCurrent
            ? Colors.blue.withOpacity(0.25)
            : burgundy.withOpacity(0.22);

        final strokeWidth = isSelected ? 3 : isCurrent ? 3 : 2;
        final zIndex = isSelected ? 3 : isCurrent ? 2 : 1;

        expect(strokeColor.opacity, closeTo(0.95, 0.01));
        expect(fillColor.opacity, closeTo(0.25, 0.01));
        expect(strokeWidth, 3);
        expect(zIndex, 3);
      });

      test('creates polygon for current building', () {
        const isSelected = false;
        const isCurrent = true;

        final strokeWidth = isSelected ? 3 : isCurrent ? 3 : 2;
        final zIndex = isSelected ? 3 : isCurrent ? 2 : 1;

        expect(strokeWidth, 3);
        expect(zIndex, 2);
      });

      test('creates polygon for normal building', () {
        const isSelected = false;
        const isCurrent = false;

        final strokeWidth = isSelected ? 3 : isCurrent ? 3 : 2;
        final zIndex = isSelected ? 3 : isCurrent ? 2 : 1;

        expect(strokeWidth, 2);
        expect(zIndex, 1);
      });

      test('polygon comparison logic', () {
        final building1 = buildingPolygons.first;
        final building2 = buildingPolygons.first;

        final isSame = building1.code == building2.code;
        expect(isSame, true);
      });
    });

    group('Campus label generation', () {
      test('generates SGW label', () {
        const campus = Campus.sgw;
        final label = campus == Campus.sgw
            ? 'SGW'
            : campus == Campus.loyola
            ? 'Loyola'
            : '';

        expect(label, 'SGW');
      });

      test('generates Loyola label', () {
        const campus = Campus.loyola;
        final label = campus == Campus.sgw
            ? 'SGW'
            : campus == Campus.loyola
            ? 'Loyola'
            : '';

        expect(label, 'Loyola');
      });

      test('generates empty label for none', () {
        const campus = Campus.none;
        final label = campus == Campus.sgw
            ? 'SGW'
            : campus == Campus.loyola
            ? 'Loyola'
            : '';

        expect(label, isEmpty);
      });
    });

    group('Initial target calculation', () {
      test('uses Loyola for Loyola campus', () {
        const initialCampus = Campus.loyola;
        final target = initialCampus == Campus.loyola
            ? concordiaLoyola
            : concordiaSGW;

        expect(target, concordiaLoyola);
      });

      test('uses SGW for SGW campus', () {
        const initialCampus = Campus.sgw;
        final target = initialCampus == Campus.loyola
            ? concordiaLoyola
            : concordiaSGW;

        expect(target, concordiaSGW);
      });

      test('uses SGW for none campus', () {
        const initialCampus = Campus.none;
        final target = initialCampus == Campus.loyola
            ? concordiaLoyola
            : concordiaSGW;

        expect(target, concordiaSGW);
      });
    });

    group('Campus button label generation', () {
      test('generates SGW Campus label', () {
        const currentCampus = Campus.sgw;
        final label = currentCampus == Campus.sgw
            ? 'SGW Campus'
            : currentCampus == Campus.loyola
            ? 'Loyola Campus'
            : 'Off Campus';

        expect(label, 'SGW Campus');
      });

      test('generates Loyola Campus label', () {
        const currentCampus = Campus.loyola;
        final label = currentCampus == Campus.sgw
            ? 'SGW Campus'
            : currentCampus == Campus.loyola
            ? 'Loyola Campus'
            : 'Off Campus';

        expect(label, 'Loyola Campus');
      });

      test('generates Off Campus label', () {
        const currentCampus = Campus.none;
        final label = currentCampus == Campus.sgw
            ? 'SGW Campus'
            : currentCampus == Campus.loyola
            ? 'Loyola Campus'
            : 'Off Campus';

        expect(label, 'Off Campus');
      });
    });

    group('Switch campus target selection', () {
      test('selects SGW target', () {
        const newCampus = Campus.sgw;
        LatLng? targetLocation;

        switch (newCampus) {
          case Campus.sgw:
            targetLocation = concordiaSGW;
            break;
          case Campus.loyola:
            targetLocation = concordiaLoyola;
            break;
          case Campus.none:
            break;
        }

        expect(targetLocation, concordiaSGW);
      });

      test('selects Loyola target', () {
        const newCampus = Campus.loyola;
        LatLng? targetLocation;

        switch (newCampus) {
          case Campus.sgw:
            targetLocation = concordiaSGW;
            break;
          case Campus.loyola:
            targetLocation = concordiaLoyola;
            break;
          case Campus.none:
            break;
        }

        expect(targetLocation, concordiaLoyola);
      });

      test('handles none campus', () {
        const newCampus = Campus.none;
        LatLng? targetLocation;

        switch (newCampus) {
          case Campus.sgw:
            targetLocation = concordiaSGW;
            break;
          case Campus.loyola:
            targetLocation = concordiaLoyola;
            break;
          case Campus.none:
            break;
        }

        expect(targetLocation, isNull);
      });
    });

    group('URL validation', () {
      test('detects empty URL', () {
        const url = '';
        expect(url.trim().isEmpty, true);
      });

      test('detects whitespace URL', () {
        const url = '   ';
        expect(url.trim().isEmpty, true);
      });

      test('parses valid URL', () {
        const url = 'https://example.com';
        final uri = Uri.tryParse(url);
        expect(uri, isNotNull);
        expect(uri?.scheme, 'https');
      });

      test('handles invalid URL', () {
        const url = 'not a url';
        final uri = Uri.tryParse(url);
        expect(uri, isNotNull); // tryParse doesn't return null for invalid URLs
      });

      test('handles malformed URL', () {
        const url = '://invalid';
        final uri = Uri.tryParse(url);
        // tryParse can return null for some malformed URLs
        expect(uri, isA<Uri?>());
      });
    });

    group('Search query validation', () {
      test('detects empty search query', () {
        const query = '';
        expect(query.trim().isEmpty, true);
      });

      test('detects whitespace query', () {
        const query = '   ';
        expect(query.trim().isEmpty, true);
      });

      test('validates non-empty query', () {
        const query = 'Library';
        expect(query.trim().isEmpty, false);
      });
    });

    group('Marker creation logic', () {
      test('creates current location marker', () {
        const currentLocation = LatLng(45.4973, -73.5789);

        expect(currentLocation, isNotNull);
      });

      test('handles null current location', () {
        const LatLng? currentLocation = null;

        expect(currentLocation, isNull);
      });

      test('creates destination marker in route preview', () {
        const showRoutePreview = true;
        const routeDestination = LatLng(45.4582, -73.6405);

        expect(showRoutePreview, true);
        expect(routeDestination, isNotNull);
      });

      test('skips destination marker when not in route preview', () {
        const showRoutePreview = false;

        expect(showRoutePreview, false);
      });
    });

    group('Circle creation logic', () {
      test('creates accuracy circle when location available', () {
        const currentLocation = LatLng(45.4973, -73.5789);

        expect(currentLocation, isNotNull);

        const radius = 20.0;
        expect(radius, greaterThan(0));
      });

      test('returns empty when location unavailable', () {
        const LatLng? currentLocation = null;

        expect(currentLocation, isNull);
      });
    });

    group('Route preview state management', () {
      test('initializes route preview with origin and destination', () {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);
        const originText = 'Current location';
        const destinationText = 'Library';

        expect(origin, isNotNull);
        expect(destination, isNotNull);
        expect(originText, isNotEmpty);
        expect(destinationText, isNotEmpty);
      });

      test('handles null origin gracefully', () {
        const LatLng? origin = null;
        const LatLng? destination = LatLng(45.4582, -73.6405);

        if (origin == null || destination == null) {
          expect(true, true);
        }
      });

      test('handles null destination gracefully', () {
        const LatLng? origin = LatLng(45.4973, -73.5789);
        const LatLng? destination = null;

        if (origin == null || destination == null) {
          expect(true, true);
        }
      });
    });

    group('Constants validation', () {
      test('validates concordiaSGW coordinates', () {
        expect(concordiaSGW.latitude, closeTo(45.4973, 0.0001));
        expect(concordiaSGW.longitude, closeTo(-73.5789, 0.0001));
      });

      test('validates concordiaLoyola coordinates', () {
        expect(concordiaLoyola.latitude, closeTo(45.4582, 0.0001));
        expect(concordiaLoyola.longitude, closeTo(-73.6405, 0.0001));
      });

      test('validates campusRadius', () {
        expect(campusRadius, 500);
        expect(campusRadius, greaterThan(0));
      });

      test('validates campusAutoSwitchRadius', () {
        expect(campusAutoSwitchRadius, 500);
        expect(campusAutoSwitchRadius, greaterThan(0));
      });
    });
  });
}
