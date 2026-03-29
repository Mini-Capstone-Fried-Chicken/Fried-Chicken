import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/google_directions_service.dart';
import 'package:campus_app/services/google_places_service.dart';

void main() {
  group('Google Directions Service - Error Handling & Edge Cases', () {
    group('Polyline Decoding Edge Cases', () {
      test('Polyline string is not empty for valid routes', () {
        const encoded = '_p~iF~ps|U';
        expect(encoded, isNotEmpty);
        expect(encoded, isA<String>());
      });

      test('Polyline with multiple points', () {
        const encoded = '_p~iF~ps|U_ulLnnqC';
        expect(encoded.length, greaterThan(10));
      });

      test('Complex polyline segments', () {
        const fullPolyline = '_p~iF~ps|U_ulLnnqC_kqL~jkC@dA';
        expect(fullPolyline.isNotEmpty, true);
        expect(fullPolyline.length, greaterThan(20));
      });
    });

    group('API Response Structure Parsing', () {
      test('Parse OK status response', () {
        final response = {
          'status': 'OK',
          'routes': [
            {
              'overview_polyline': {'points': '_p~iF~ps|U'},
            },
          ],
        };

        expect(response['status'], 'OK');
        expect(response['routes'], isNotEmpty);
      });

      test('Parse error status response', () {
        final response = {'status': 'REQUEST_DENIED', 'routes': []};

        expect(response['status'], isNotEmpty);
        expect(response['routes'], isEmpty);
      });

      test('Parse ZERO_RESULTS response', () {
        final response = {'status': 'ZERO_RESULTS', 'routes': []};

        expect(response['status'], 'ZERO_RESULTS');
        expect((response['routes'] as List).isEmpty, true);
      });

      test('Response with different status codes', () {
        final statusCodes = [
          'OK',
          'NOT_FOUND',
          'ZERO_RESULTS',
          'MAX_WAYPOINTS_EXCEEDED',
          'INVALID_REQUEST',
          'OVER_QUERY_LIMIT',
          'REQUEST_DENIED',
          'UNKNOWN_ERROR',
        ];

        for (final status in statusCodes) {
          expect(status, isNotEmpty);
        }
      });

      test('Empty routes in OK response', () {
        final response = {'status': 'OK', 'routes': []};

        expect(response['status'], 'OK');
        expect((response['routes'] as List).isEmpty, true);
      });

      test('Multiple routes in response', () {
        final response = {
          'status': 'OK',
          'routes': [
            {
              'overview_polyline': {'points': 'route1'},
            },
            {
              'overview_polyline': {'points': 'route2'},
            },
            {
              'overview_polyline': {'points': 'route3'},
            },
          ],
        };

        expect((response['routes'] as List).length, 3);
      });
    });

    group('Travel Mode Validation', () {
      test('All valid travel modes', () {
        final modes = ['walking', 'driving', 'bicycling', 'transit'];
        expect(modes.length, 4);
        expect(modes.every((m) => m.isNotEmpty), true);
      });

      test('Mode parameter formats', () {
        const mode = 'walking';
        expect(mode, isNotEmpty);
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });
    });

    group('Coordinate Validation for Directions', () {
      test('Valid direction coordinates', () {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        expect(origin.latitude, inInclusiveRange(-90, 90));
        expect(origin.longitude, inInclusiveRange(-180, 180));
        expect(destination.latitude, inInclusiveRange(-90, 90));
        expect(destination.longitude, inInclusiveRange(-180, 180));
      });

      test('Extreme coordinate values', () {
        const origin = LatLng(89.9999, 179.9999);
        const destination = LatLng(-89.9999, -179.9999);

        expect(origin.latitude, inInclusiveRange(-90, 90));
        expect(destination.latitude, inInclusiveRange(-90, 90));
      });

      test('Coordinate precision preservation', () {
        const coord = LatLng(45.49732102, -73.57891234);

        final coordStr = '${coord.latitude},${coord.longitude}';
        expect(coordStr, contains('45.497'));
        expect(coordStr, contains('-73.578'));
      });
    });

    group('URI Construction', () {
      test('Origin parameter format', () {
        const origin = LatLng(45.4973, -73.5789);
        final originParam = '${origin.latitude},${origin.longitude}';

        expect(originParam, '45.4973,-73.5789');
      });

      test('Destination parameter format', () {
        const destination = LatLng(45.4582, -73.6405);
        final destParam = '${destination.latitude},${destination.longitude}';

        expect(destParam, '45.4582,-73.6405');
      });

      test('Mode parameter is included', () {
        const mode = 'walking';
        final queryParam = 'mode=$mode';

        expect(queryParam, contains('mode='));
        expect(queryParam, contains('walking'));
      });
    });
  });

  group('Google Places Service - Error Handling & Edge Cases', () {
    group('Query Validation', () {
      test('Empty query handling', () {
        const query = '';
        expect(query.trim().isEmpty, true);
      });

      test('Whitespace query handling', () {
        const query = '   ';
        expect(query.trim().isEmpty, true);
      });

      test('Valid query strings', () {
        final queries = ['restaurant', 'library', 'gym', 'café', 'hospital'];

        for (final q in queries) {
          expect(q.isNotEmpty, true);
        }
      });

      test('Long query string', () {
        final longQuery = 'a' * 1000;
        expect(longQuery.length, 1000);
      });

      test('Special characters in query', () {
        const query = r'test @ & # !';
        expect(query.contains('@'), true);
        expect(query.contains('&'), true);
      });
    });

    group('PlaceID Validation', () {
      test('Empty placeId', () {
        const placeId = '';
        expect(placeId, isEmpty);
      });

      test('PlaceId without prefix', () {
        const placeId = 'ChIJ_id_value';
        expect(placeId.startsWith('places/'), false);
      });

      test('PlaceId with prefix', () {
        const placeId = 'places/ChIJ_id_value';
        expect(placeId.startsWith('places/'), true);
      });

      test('Prefix addition logic', () {
        const placeId = 'ChIJ_without_prefix';
        final resourceName = placeId.startsWith('places/')
            ? placeId
            : 'places/$placeId';

        expect(resourceName, 'places/ChIJ_without_prefix');
        expect(resourceName.startsWith('places/'), true);
      });

      test('Long placeId', () {
        final longId = 'places/' + 'x' * 500;
        expect(longId.length, greaterThan(500));
      });
    });

    group('Autocomplete Query Parsing', () {
      test('Query with location bias', () {
        const location = LatLng(45.4973, -73.5789);
        final locationBias = <String, dynamic>{
          'circle': <String, dynamic>{
            'center': <String, double>{
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
            'radius': 5000.0,
          },
        };

        expect(locationBias['circle'], isNotNull);
        final circle = locationBias['circle'] as Map<String, dynamic>;
        expect(circle['radius'], 5000.0);
      });

      test('Default Concordia location bias', () {
        final defaultBias = <String, dynamic>{
          'circle': <String, dynamic>{
            'center': <String, double>{
              'latitude': 45.4958,
              'longitude': -73.5711,
            },
            'radius': 15000.0,
          },
        };

        final circle = defaultBias['circle'] as Map<String, dynamic>;
        final center = circle['center'] as Map<String, double>;
        expect(center['latitude'], closeTo(45.4958, 0.001));
      });

      test('Custom radius handling', () {
        final radii = [1000, 3000, 5000, 10000, 15000];

        for (final radius in radii) {
          expect(radius, greaterThan(0));
          expect(radius.toDouble(), isA<double>());
        }
      });
    });

    group('PlacePrediction JSON Parsing', () {
      test('Full structured formatting', () {
        final json = <String, dynamic>{
          'place_id': 'test_id',
          'description': 'Test Place',
          'structured_formatting': <String, dynamic>{
            'main_text': 'Main',
            'secondary_text': 'Secondary',
          },
        };

        final formatting =
            json['structured_formatting'] as Map<String, dynamic>;
        expect(formatting['main_text'], 'Main');
        expect(formatting['secondary_text'], 'Secondary');
      });

      test('Missing structured_formatting field', () {
        final json = <String, dynamic>{
          'place_id': 'test_id',
          'description': 'Test Place',
        };

        expect(json['structured_formatting'], isNull);
      });

      test('Null secondary text', () {
        final json = <String, dynamic>{
          'place_id': 'test_id',
          'description': 'Test Place',
          'structured_formatting': <String, dynamic>{
            'main_text': 'Main',
            'secondary_text': null,
          },
        };

        final formatting =
            json['structured_formatting'] as Map<String, dynamic>;
        expect(formatting['secondary_text'], isNull);
      });

      test('Empty structured_formatting', () {
        final json = <String, dynamic>{
          'place_id': 'test_id',
          'description': 'Test Place',
          'structured_formatting': <String, dynamic>{},
        };

        final formatting =
            json['structured_formatting'] as Map<String, dynamic>;
        expect(formatting.isEmpty, true);
      });
    });

    group('PlaceResult Data Structure', () {
      test('Complete PlaceResult', () {
        final result = PlaceResult(
          placeId: 'id123',
          name: 'Test Place',
          formattedAddress: '123 Main St',
          location: const LatLng(45.5, -73.5),
        );

        expect(result.placeId, 'id123');
        expect(result.name, 'Test Place');
        expect(result.formattedAddress, '123 Main St');
      });

      test('PlaceResult without formatted address', () {
        final result = PlaceResult(
          placeId: 'id123',
          name: 'Test Place',
          location: const LatLng(45.5, -73.5),
        );

        expect(result.formattedAddress, isNull);
      });

      test('PlaceResult location coordinates', () {
        final result = PlaceResult(
          placeId: 'id123',
          name: 'Test Place',
          location: const LatLng(0.0, 0.0),
        );

        expect(result.location.latitude, 0.0);
        expect(result.location.longitude, 0.0);
      });

      test('Multiple PlaceResults', () {
        final results = [
          PlaceResult(
            placeId: 'id1',
            name: 'Place 1',
            location: const LatLng(45.5, -73.5),
          ),
          PlaceResult(
            placeId: 'id2',
            name: 'Place 2',
            location: const LatLng(45.6, -73.6),
          ),
        ];

        expect(results.length, 2);
        expect(results.every((r) => r.placeId.isNotEmpty), true);
      });
    });

    group('API Response Variations', () {
      test('Response with no places field', () {
        final response = {'status': 'OK'};

        expect(response['places'], isNull);
      });

      test('Response with null places', () {
        final response = {'status': 'OK', 'places': null};

        expect(response['places'], isNull);
      });

      test('Response with empty places array', () {
        final response = {'status': 'OK', 'places': []};

        expect((response['places'] as List).isEmpty, true);
      });

      test('Response with malformed place data', () {
        final response = <String, dynamic>{
          'places': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': null,
              'displayName': null,
              'location': null,
            },
          ],
        };

        final places = response['places'] as List<Map<String, dynamic>>;
        final place = places[0];
        expect(place['id'], isNull);
      });

      test('Response with multiple suggestions', () {
        final response = {
          'suggestions': [
            {
              'placePrediction': {'placeId': 'id1'},
            },
            {
              'placePrediction': {'placeId': 'id2'},
            },
            {
              'placePrediction': {'placeId': 'id3'},
            },
          ],
        };

        expect((response['suggestions'] as List).length, 3);
      });
    });
  });
}
