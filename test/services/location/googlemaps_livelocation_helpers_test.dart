import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation_helpers.dart';

void main() {
  group('campusFromPoint', () {
    test('returns SGW when point is at SGW coordinates', () {
      final result = campusFromPoint(LatLng(45.4973, -73.5789));
      expect(result, Campus.sgw);
    });

    test('returns Loyola when point is at Loyola coordinates', () {
      final result = campusFromPoint(LatLng(45.4582, -73.6405));
      expect(result, Campus.loyola);
    });

    test('returns none when point is too far from both campuses', () {
      final result = campusFromPoint(LatLng(45.5, -73.5));
      expect(result, Campus.none);
    });

    test('returns SGW when closer to SGW than Loyola', () {
      final result = campusFromPoint(LatLng(45.498, -73.579));
      expect(result, Campus.sgw);
    });

    test('returns Loyola when closer to Loyola than SGW', () {
      final result = campusFromPoint(LatLng(45.459, -73.641));
      expect(result, Campus.loyola);
    });

    test('returns none for equator coordinates', () {
      final result = campusFromPoint(LatLng(0, 0));
      expect(result, Campus.none);
    });

    test('returns none for north pole', () {
      final result = campusFromPoint(LatLng(90, 0));
      expect(result, Campus.none);
    });

    test('returns none for south pole', () {
      final result = campusFromPoint(LatLng(-90, 0));
      expect(result, Campus.none);
    });
  });

  group('validateUrl', () {
    test('returns null for empty string', () {
      final result = validateUrl('');
      expect(result, isNull);
    });

    test('returns null for whitespace-only string', () {
      final result = validateUrl('   ');
      expect(result, isNull);
    });

    test('returns null for invalid URI', () {
      final result = validateUrl(':::invalid:::');
      expect(result, isNull);
    });

    test('returns URI for valid http URL', () {
      final result = validateUrl('http://example.com');
      expect(result, isNotNull);
      expect(result.toString(), 'http://example.com');
    });

    test('returns URI for valid https URL', () {
      final result = validateUrl('https://example.com');
      expect(result, isNotNull);
      expect(result.toString(), 'https://example.com');
    });

    test('returns URI for valid URL with path', () {
      final result = validateUrl('https://example.com/path/to/page');
      expect(result, isNotNull);
      expect(result?.path, '/path/to/page');
    });

    test('handles URLs with query parameters', () {
      final result = validateUrl('https://example.com?key=value');
      expect(result, isNotNull);
      expect(result?.queryParameters['key'], 'value');
    });
  });
}
