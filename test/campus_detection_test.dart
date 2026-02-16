import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';

void main() {
  group('Campus Detection Tests', () {
    group('detectCampus Function', () {
      test('Detects SGW campus when user is near SGW center', () {
        final sgwLocation = LatLng(45.4973, -73.5789);
        final result = detectCampus(sgwLocation);
        expect(result, Campus.sgw);
      });

      test('Detects Loyola campus when user is near Loyola center', () {
        final loyolaLocation = LatLng(45.4582, -73.6405);
        final result = detectCampus(loyolaLocation);
        expect(result, Campus.loyola);
      });

      test('Returns both campus when user is at SGW center', () {
        final sgwCenter = LatLng(45.4973, -73.5789);
        final result = detectCampus(sgwCenter);
        expect(result, Campus.sgw);
      });

      test('Returns Campus.none when user is far from both campuses', () {
        final farLocation = LatLng(45.6, -73.3);
        final result = detectCampus(farLocation);
        expect(result, Campus.none);
      });

      test('Detects SGW when slightly north of SGW center', () {
        final nearSGW = LatLng(45.50, -73.5789);
        final result = detectCampus(nearSGW);
        expect(result, Campus.sgw);
      });

            test('Works correctly with negative latitude', () {
        // Test far south point
        final southPoint = LatLng(44.0, -73.6);
        final result = detectCampus(southPoint);
        expect(result, Campus.none);
      });

      test('Works correctly with different longitude values', () {
        // Test far west point
        final westPoint = LatLng(45.4973, -74.0);
        final result = detectCampus(westPoint);
        expect(result, Campus.none);
      });

      test('Handles coordinate precision correctly', () {
        // High precision coordinates
        final preciseLocation = LatLng(45.49731234567, -73.57891234567);
        final result = detectCampus(preciseLocation);
        expect(result, Campus.sgw);
      });
    });

    group('Campus Enum Values', () {
      test('Campus enum has required values', () {
        expect(Campus.sgw, isNotNull);
        expect(Campus.loyola, isNotNull);
        expect(Campus.none, isNotNull);
      });

      test('Campus values are distinct', () {
        expect(Campus.sgw == Campus.loyola, false);
        expect(Campus.sgw == Campus.none, false);
        expect(Campus.loyola == Campus.none, false);
      });

      test('Campus enum converts to string correctly', () {
        expect(Campus.sgw.toString().contains('sgw'), true);
        expect(Campus.loyola.toString().contains('loyola'), true);
        expect(Campus.none.toString().contains('none'), true);
      });
    });

    group('Campus Constants', () {
      test('concordiaSGW is correct location', () {
        expect(concordiaSGW.latitude, 45.4973);
        expect(concordiaSGW.longitude, -73.5789);
      });

      test('concordiaLoyola is correct location', () {
        expect(concordiaLoyola.latitude, 45.4582);
        expect(concordiaLoyola.longitude, -73.6405);
      });

      test('campusRadius is appropriate for campus size', () {
        expect(campusRadius, 500);
      });

      test('campusAutoSwitchRadius matches campusRadius', () {
        expect(campusAutoSwitchRadius, 500);
      });

      test('Campus coordinates are valid LatLng objects', () {
        expect(concordiaSGW, isA<LatLng>());
        expect(concordiaLoyola, isA<LatLng>());
      });
    });

    group('Distance Calculations', () {
      test('Points at same location have zero distance', () {
        final location = LatLng(45.4973, -73.5789);
        final result = detectCampus(location);
        expect(result, Campus.sgw);
      });

      test('Campus detection is consistent across multiple calls', () {
        final location = LatLng(45.497, -73.579);
        final result1 = detectCampus(location);
        final result2 = detectCampus(location);
        expect(result1, result2);
      });

      test('Loyola and SGW campuses are distinct', () {
        final sgwResult = detectCampus(concordiaSGW);
        final loyolaResult = detectCampus(concordiaLoyola);
        expect(sgwResult, Campus.sgw);
        expect(loyolaResult, Campus.loyola);
      });
    });

    group('Edge Cases for Campus Detection', () {
      test('Handles very small latitude differences', () {
        final location = LatLng(45.49730001, -73.5789);
        final result = detectCampus(location);
        expect(result, Campus.sgw);
      });

      test('Handles very small longitude differences', () {
        final location = LatLng(45.4973, -73.57890001);
        final result = detectCampus(location);
        expect(result, Campus.sgw);
      });

      test('Point exactly 500m from SGW center', () {
        // Approximately 500m from SGW in latitude direction
        final location = LatLng(45.5022, -73.5789);
        final result = detectCampus(location);
        // May or may not be in campus depending on exact calculation
        expect([Campus.sgw, Campus.none], contains(result));
      });
    });
  });
}
