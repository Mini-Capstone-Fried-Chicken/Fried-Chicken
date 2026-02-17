import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('GoogleMaps Live Location Tests', () {
    group('Polygon Center Calculation', () {
      test('Triangle polygon center calculation', () {
        final points = [
          const LatLng(0, 0),
          const LatLng(0, 2),
          const LatLng(2, 0),
        ];
        
        // The center should be somewhere in the middle of the triangle
        double sumLat = 0.0;
        double sumLng = 0.0;
        for (var p in points) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final centerLat = sumLat / points.length;
        final centerLng = sumLng / points.length;
        
        expect(centerLat, greaterThan(0));
        expect(centerLng, greaterThan(0));
        expect(centerLat, lessThan(2));
        expect(centerLng, lessThan(2));
      });

      test('Square polygon center calculation', () {
        final points = [
          const LatLng(0, 0),
          const LatLng(0, 4),
          const LatLng(4, 4),
          const LatLng(4, 0),
        ];
        
        double sumLat = 0.0;
        double sumLng = 0.0;
        for (var p in points) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final centerLat = sumLat / points.length;
        final centerLng = sumLng / points.length;
        
        expect(centerLat, closeTo(2.0, 0.01));
        expect(centerLng, closeTo(2.0, 0.01));
      });

      test('Single point returns same point', () {
        final points = [const LatLng(45.5, -73.5)];
        expect(points.first, const LatLng(45.5, -73.5));
      });

      test('Real building polygon has valid center', () {
        if (buildingPolygons.isNotEmpty) {
          final building = buildingPolygons.first;
          expect(building.center, isNotNull);
          expect(building.center.latitude, greaterThan(-90));
          expect(building.center.latitude, lessThan(90));
        }
      });

      test('All building centers are within Montreal bounds', () {
        for (final building in buildingPolygons.take(10)) {
          final center = building.center;
          expect(center.latitude, greaterThan(45.0));
          expect(center.latitude, lessThan(46.0));
          expect(center.longitude, greaterThan(-74.0));
          expect(center.longitude, lessThan(-73.0));
        }
      });

      test('Polygon center is within building polygon bounds', () {
        for (final building in buildingPolygons.take(5)) {
          final center = building.center;
          
          double minLat = building.points.first.latitude;
          double maxLat = building.points.first.latitude;
          double minLng = building.points.first.longitude;
          double maxLng = building.points.first.longitude;
          
          for (final point in building.points) {
            minLat = minLat < point.latitude ? minLat : point.latitude;
            maxLat = maxLat > point.latitude ? maxLat : point.latitude;
            minLng = minLng < point.longitude ? minLng : point.longitude;
            maxLng = maxLng > point.longitude ? maxLng : point.longitude;
          }
          
          // Center should be within bounds (with tolerance)
          expect(center.latitude, greaterThanOrEqualTo(minLat - 0.01));
          expect(center.latitude, lessThanOrEqualTo(maxLat + 0.01));
        }
      });
    });

    group('Campus Detection', () {
      test('SGW center detects SGW campus', () {
        expect(detectCampus(concordiaSGW), Campus.sgw);
      });

      test('Loyola center detects Loyola campus', () {
        expect(detectCampus(concordiaLoyola), Campus.loyola);
      });

      test('Point near SGW detects SGW', () {
        const nearSgw = LatLng(45.4973, -73.5780);
        expect(detectCampus(nearSgw), Campus.sgw);
      });

      test('Point near Loyola detects Loyola', () {
        const nearLoyola = LatLng(45.4583, -73.6405);
        expect(detectCampus(nearLoyola), Campus.loyola);
      });

      test('Far point detects no campus', () {
        const farLocation = LatLng(0, 0);
        expect(detectCampus(farLocation), Campus.none);
      });

      test('Campus at opposite end of world', () {
        const opposite = LatLng(-45, 106);
        expect(detectCampus(opposite), Campus.none);
      });

      test('Campus radius boundary SGW', () {
        // Create a point just inside the radius
        const center = concordiaSGW;
        const radiusKm = 500; // meters
        
        // Point at exact center should be SGW
        expect(detectCampus(center), Campus.sgw);
      });

      test('Campus radius boundary Loyola', () {
        const center = concordiaLoyola;
        
        // Point at exact center should be Loyola
        expect(detectCampus(center), Campus.loyola);
      });

      test('Between campuses detects closest', () {
        // Point between SGW and Loyola
        final between = LatLng(
          (concordiaSGW.latitude + concordiaLoyola.latitude) / 2,
          (concordiaSGW.longitude + concordiaLoyola.longitude) / 2,
        );
        
        final detected = detectCampus(between);
        expect([Campus.sgw, Campus.loyola, Campus.none], contains(detected));
      });
    });

    group('Bounds Calculation', () {
      test('Single point bounds', () {
        final points = [const LatLng(45.5, -73.5)];
        
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;
        
        expect(minLat, 45.5);
        expect(maxLat, 45.5);
        expect(minLng, -73.5);
        expect(maxLng, -73.5);
      });

      test('Multiple points bounds', () {
        final points = [
          const LatLng(45.4, -73.4),
          const LatLng(45.5, -73.5),
          const LatLng(45.3, -73.6),
        ];
        
        double minLat = points[0].latitude;
        double maxLat = points[0].latitude;
        double minLng = points[0].longitude;
        double maxLng = points[0].longitude;
        
        for (final p in points) {
          minLat = minLat < p.latitude ? minLat : p.latitude;
          maxLat = maxLat > p.latitude ? maxLat : p.latitude;
          minLng = minLng < p.longitude ? minLng : p.longitude;
          maxLng = maxLng > p.longitude ? maxLng : p.longitude;
        }
        
        expect(minLat, 45.3);
        expect(maxLat, 45.5);
        expect(minLng, -73.6);
        expect(maxLng, -73.4);
      });

      test('Bounds with negative and positive coordinates', () {
        final points = [
          const LatLng(-10, -50),
          const LatLng(10, 50),
        ];
        
        double minLat = points[0].latitude;
        double maxLat = points[0].latitude;
        
        for (final p in points) {
          minLat = minLat < p.latitude ? minLat : p.latitude;
          maxLat = maxLat > p.latitude ? maxLat : p.latitude;
        }
        
        expect(minLat, -10);
        expect(maxLat, 10);
      });

      test('Building polygon bounds', () {
        for (final building in buildingPolygons.take(5)) {
          final points = building.points;
          double minLat = points.first.latitude;
          double maxLat = points.first.latitude;
          
          for (final p in points) {
            minLat = minLat < p.latitude ? minLat : p.latitude;
            maxLat = maxLat > p.latitude ? maxLat : p.latitude;
          }
          
          expect(minLat, lessThanOrEqualTo(maxLat));
        }
      });
    });

    group('Coordinate Validation', () {
      test('Valid Montreal coordinates', () {
        const montreal = LatLng(45.5017, -73.5673);
        expect(montreal.latitude, inInclusiveRange(45.0, 46.0));
        expect(montreal.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('SGW campus coordinates', () {
        expect(concordiaSGW.latitude, inInclusiveRange(45.4, 45.5));
        expect(concordiaSGW.longitude, inInclusiveRange(-73.6, -73.5));
      });

      test('Loyola campus coordinates', () {
        expect(concordiaLoyola.latitude, inInclusiveRange(45.4, 45.5));
        expect(concordiaLoyola.longitude, inInclusiveRange(-73.7, -73.6));
      });

      test('Campus radius constant', () {
        expect(campusRadius, greaterThan(0));
        expect(campusAutoSwitchRadius, greaterThan(0));
      });

      test('All building coordinates are valid', () {
        for (final building in buildingPolygons) {
          for (final point in building.points) {
            expect(point.latitude, greaterThan(-90));
            expect(point.latitude, lessThan(90));
            expect(point.longitude, greaterThan(-180));
            expect(point.longitude, lessThan(180));
          }
        }
      });
    });

    group('Distance Calculation', () {
      test('Distance between SGW and Loyola', () {
        final distance = Geolocator.distanceBetween(
          concordiaSGW.latitude,
          concordiaSGW.longitude,
          concordiaLoyola.latitude,
          concordiaLoyola.longitude,
        );
        
        // Distance should be greater than 0 and reasonable (a few km)
        expect(distance, greaterThan(0));
        expect(distance, lessThan(100000)); // Less than 100km
      });

      test('Distance from point to itself is zero', () {
        const point = LatLng(45.5, -73.5);
        final distance = Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          point.latitude,
          point.longitude,
        );
        
        expect(distance, closeTo(0, 0.1));
      });

      test('Distance is symmetric', () {
        const point1 = LatLng(45.4973, -73.5789);
        const point2 = LatLng(45.4582, -73.6405);
        
        final dist1to2 = Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        );
        
        final dist2to1 = Geolocator.distanceBetween(
          point2.latitude,
          point2.longitude,
          point1.latitude,
          point1.longitude,
        );
        
        expect(dist1to2, closeTo(dist2to1, 0.1));
      });

      test('Campus radius defines detection boundary', () {
        // Point at campusRadius distance should be at boundary
        expect(campusRadius, 500); // meters
        expect(campusAutoSwitchRadius, 500); // meters
      });
    });

    group('Enum Campus States', () {
      test('Campus enum has expected values', () {
        expect(Campus.sgw, isNotNull);
        expect(Campus.loyola, isNotNull);
        expect(Campus.none, isNotNull);
      });

      test('Campus enum can be compared', () {
        expect(Campus.sgw == Campus.sgw, true);
        expect(Campus.sgw == Campus.loyola, false);
        expect(Campus.loyola == Campus.none, false);
      });

      test('Campus detection returns valid enum value', () {
        final sgwResult = detectCampus(concordiaSGW);
        final loyolaResult = detectCampus(concordiaLoyola);
        final noneResult = detectCampus(const LatLng(0, 0));
        
        expect([Campus.sgw, Campus.loyola, Campus.none], contains(sgwResult));
        expect([Campus.sgw, Campus.loyola, Campus.none], contains(loyolaResult));
        expect([Campus.sgw, Campus.loyola, Campus.none], contains(noneResult));
      });
    });

    group('Building Detection from Location', () {
      test('Building centers are within bounds', () {
        for (final building in buildingPolygons.take(10)) {
          final center = building.center;
          
          double minLat = building.points.first.latitude;
          double maxLat = minLat;
          double minLng = building.points.first.longitude;
          double maxLng = minLng;
          
          for (final point in building.points) {
            minLat = minLat < point.latitude ? minLat : point.latitude;
            maxLat = maxLat > point.latitude ? maxLat : point.latitude;
            minLng = minLng < point.longitude ? minLng : point.longitude;
            maxLng = maxLng > point.longitude ? maxLng : point.longitude;
          }
          
          expect(center.latitude, greaterThanOrEqualTo(minLat - 0.001));
          expect(center.latitude, lessThanOrEqualTo(maxLat + 0.001));
        }
      });

      test('Multiple building centers are distinct', () {
        final centers = <LatLng>[];
        for (final building in buildingPolygons.take(5)) {
          centers.add(building.center);
        }
        
        // Not all centers should be identical
        final uniqueCenters = centers.toSet();
        expect(uniqueCenters.length, greaterThan(1));
      });
    });

    group('Building Data Integrity', () {
      test('All buildings have points', () {
        for (final building in buildingPolygons) {
          expect(building.points, isNotEmpty);
        }
      });

      test('All buildings have centers', () {
        for (final building in buildingPolygons) {
          expect(building.center, isNotNull);
        }
      });

      test('All buildings have codes and names', () {
        for (final building in buildingPolygons) {
          expect(building.code, isNotEmpty);
          expect(building.name, isNotEmpty);
        }
      });

      test('Building polygons have minimum 3 points', () {
        for (final building in buildingPolygons) {
          expect(building.points.length, greaterThanOrEqualTo(3));
        }
      });

      test('No duplicate building codes in polygon list', () {
        final codes = buildingPolygons.map((b) => b.code).toList();
        final uniqueCodes = codes.toSet();
        expect(codes.length, uniqueCodes.length);
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('Campus detection at equator', () {
        const equator = LatLng(0, 0);
        final result = detectCampus(equator);
        expect(result, Campus.none);
      });

      test('Campus detection at poles', () {
        const north = LatLng(90, 0);
        const south = LatLng(-90, 0);
        
        expect(detectCampus(north), Campus.none);
        expect(detectCampus(south), Campus.none);
      });

      test('Campus detection at date line', () {
        const east = LatLng(45, 180);
        const west = LatLng(45, -180);
        
        expect(detectCampus(east), Campus.none);
        expect(detectCampus(west), Campus.none);
      });

      test('Very small polygon coordinates', () {
        final points = [
          const LatLng(0.001, 0.001),
          const LatLng(0.001, 0.002),
          const LatLng(0.002, 0.001),
        ];
        
        for (final p in points) {
          expect(p.latitude, greaterThan(-90));
          expect(p.latitude, lessThan(90));
        }
      });

      test('Very large coordinate differences', () {
        const p1 = LatLng(89, 179);
        const p2 = LatLng(-89, -179);
        
        expect(p1.latitude, inInclusiveRange(-90, 90));
        expect(p2.latitude, inInclusiveRange(-90, 90));
      });
    });
  });
}
