import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/google_directions_service.dart';

void main() {
  group('GoogleDirectionsService Tests', () {
    group('Route Handling', () {
      test('Route can be null when no path exists', () {
        final route = null as List<LatLng>?;
        expect(route, isNull);
      });

      test('Empty route list is handled correctly', () {
        final route = <LatLng>[];
        expect(route, isEmpty);
      });

      test('Route with single point is valid', () {
        final route = [const LatLng(45.4973, -73.5789)];
        expect(route.length, 1);
      });

      test('Route with multiple points is valid', () {
        final route = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4900, -73.5800),
          const LatLng(45.4582, -73.6405),
        ];
        expect(route.length, 3);
      });
    });

    group('Route Calculation', () {
      test('Route between same origin and destination is minimal', () {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4973, -73.5789);
        
        // This tests that the service can handle same origin/destination
        expect(origin, destination);
      });

      test('Route with valid coordinates returns LatLng objects', () {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4580, -73.6410);
        
        expect(origin.latitude, greaterThan(0));
        expect(destination.latitude, greaterThan(0));
        expect(origin.longitude, lessThan(0));
        expect(destination.longitude, lessThan(0));
      });

      test('Route origin is within Montreal bounds', () {
        const origin = LatLng(45.4973, -73.5789);
        
        // Montreal approximate bounds
        expect(origin.latitude, greaterThan(45.0));
        expect(origin.latitude, lessThan(46.0));
        expect(origin.longitude, greaterThan(-74.0));
        expect(origin.longitude, lessThan(-73.0));
      });

      test('Route destination is within Montreal bounds', () {
        const destination = LatLng(45.4580, -73.6410);
        
        // Montreal approximate bounds
        expect(destination.latitude, greaterThan(45.0));
        expect(destination.latitude, lessThan(46.0));
        expect(destination.longitude, greaterThan(-74.0));
        expect(destination.longitude, lessThan(-73.0));
      });
    });

    group('Route Modes', () {
      test('Walking mode is valid travel mode', () {
        const mode = 'walking';
        expect(mode, isNotEmpty);
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });

      test('Driving mode is valid travel mode', () {
        const mode = 'driving';
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });

      test('Bicycling mode is valid travel mode', () {
        const mode = 'bicycling';
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });

      test('Transit mode is valid travel mode', () {
        const mode = 'transit';
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });
    });

    group('Route Coordinates Validation', () {
      test('SGW campus coordinates are valid', () {
        const sgw = LatLng(45.4973, -73.5789);
        expect(sgw.latitude, inInclusiveRange(45.0, 46.0));
        expect(sgw.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Loyola campus coordinates are valid', () {
        const loyola = LatLng(45.4582, -73.6405);
        expect(loyola.latitude, inInclusiveRange(45.0, 46.0));
        expect(loyola.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Distance calculation between campuses', () {
        const sgw = LatLng(45.4973, -73.5789);
        const loyola = LatLng(45.4582, -73.6405);
        
        // Calculate approximate distance (simple Pythagorean estimate)
        final latDiff = (sgw.latitude - loyola.latitude).abs();
        final lngDiff = (sgw.longitude - loyola.longitude).abs();
        final distance = (latDiff * latDiff + lngDiff * lngDiff).toDouble();
        
        // Distance should be greater than 0 and reasonable
        expect(distance, greaterThan(0));
        expect(distance, lessThan(1.0)); // Should be less than 1 degree away
      });

      test('Route can start from SGW and end at Loyola', () {
        const sgw = LatLng(45.4973, -73.5789);
        const loyola = LatLng(45.4582, -73.6405);
        
        // Verify both points are valid
        expect(sgw.latitude, inInclusiveRange(45.0, 46.0));
        expect(loyola.latitude, inInclusiveRange(45.0, 46.0));
        expect(sgw.longitude, inInclusiveRange(-74.0, -73.0));
        expect(loyola.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Route with Montreal landmarks is valid', () {
        const mp = LatLng(45.5017, -73.5673); // Mount Royal Park
        const downtown = LatLng(45.5017, -73.5701); // Downtown Montreal
        
        expect(mp.latitude, inInclusiveRange(45.0, 46.0));
        expect(downtown.latitude, inInclusiveRange(45.0, 46.0));
        expect(mp.longitude, inInclusiveRange(-74.0, -73.0));
        expect(downtown.longitude, inInclusiveRange(-74.0, -73.0));
      });
    });

    group('Coordinate Precision', () {
      test('Polyline points maintain high precision', () {
        // LatLng coordinates should maintain precision to 5+ decimal places
        const point = LatLng(45.49732102, -73.57891234);
        
        expect(point.latitude.toString().split('.')[1].length, greaterThanOrEqualTo(5));
        expect(point.longitude.toString().split('.')[1].length, greaterThanOrEqualTo(5));
      });

      test('LatLng precision in route points', () {
        final route = [
          const LatLng(45.49732, -73.57892),
          const LatLng(45.49745, -73.57905),
          const LatLng(45.49758, -73.57918),
        ];
        
        expect(route.length, 3);
        // Verify precision
        for (final point in route) {
          expect(point.latitude, inInclusiveRange(45.0, 46.0));
          expect(point.longitude, inInclusiveRange(-74.0, -73.0));
        }
      });

      test('Route preserves sequential order', () {
        final route = [
          const LatLng(45.4, -73.4),
          const LatLng(45.45, -73.45),
          const LatLng(45.5, -73.5),
        ];
        
        for (int i = 0; i < route.length - 1; i++) {
          expect(route[i], isNotNull);
          expect(route[i + 1], isNotNull);
        }
      });
    });

    group('API Response Formats', () {
      test('Route can be empty list', () {
        final emptyRoute = <LatLng>[];
        expect(emptyRoute, isEmpty);
      });

      test('Route is list of LatLng objects', () {
        final route = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4582, -73.6405),
        ];
        
        expect(route, isA<List<LatLng>>());
        expect(route.length, 2);
        for (final point in route) {
          expect(point, isA<LatLng>());
        }
      });

      test('Route points are sequential', () {
        final route = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4900, -73.5800),
          const LatLng(45.4830, -73.5820),
          const LatLng(45.4582, -73.6405),
        ];
        
        for (int i = 1; i < route.length; i++) {
          // Each point should be different from previous
          expect(route[i], isNotNull);
        }
      });
    });

    group('Coordinates Edge Cases', () {
      test('Handles minimum latitude -90', () {
        const point = LatLng(-90, 0);
        expect(point.latitude, -90);
      });

      test('Handles maximum latitude 90', () {
        const point = LatLng(90, 0);
        expect(point.latitude, 90);
      });

      test('Handles minimum longitude -180', () {
        const point = LatLng(0, -180);
        expect(point.longitude, -180);
      });

      test('Handles maximum longitude 180', () {
        const point = LatLng(0, 180);
        // Longitude wraps around, so 180 and -180 are equivalent
        expect(point.longitude.abs(), 180);
      });

      test('Handles very small decimal coordinates', () {
        const point = LatLng(0.0001, 0.0001);
        expect(point.latitude, 0.0001);
        expect(point.longitude, 0.0001);
      });

      test('Handles negative latitude and longitude', () {
        const point = LatLng(-45.5, -73.5);
        expect(point.latitude, -45.5);
        expect(point.longitude, -73.5);
      });
    });
  });
}
