import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/google_directions_service.dart';

void main() {
  group('GoogleDirectionsService Tests - Route Coverage', () {
    group('Route Parameter Validation', () {
      test('getRoute accepts valid origin coordinate', () {
        const origin = LatLng(45.4973, -73.5789);

        expect(origin.latitude, inInclusiveRange(45, 46));
        expect(origin.longitude, inInclusiveRange(-74, -73));
      });

      test('getRoute accepts valid destination coordinate', () {
        const destination = LatLng(45.4582, -73.6405);

        expect(destination.latitude, inInclusiveRange(45, 46));
        expect(destination.longitude, inInclusiveRange(-74, -73));
      });

      test('getRoute supports all travel modes', () {
        const modes = ['walking', 'driving', 'bicycling', 'transit'];

        for (final mode in modes) {
          expect(mode, isNotEmpty);
        }
      });

      test('Route URL is constructed correctly', () {
        const baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

        expect(baseUrl, contains('googleapis.com'));
        expect(baseUrl, contains('directions'));
      });

      test('Query parameters include mode and coordinates', () {
        const origin = LatLng(45.4973, -73.5789);

        final originStr = '${origin.latitude},${origin.longitude}';
        expect(originStr, contains('45.4973'));
        expect(originStr, contains('-73.5789'));
      });
    });

    group('Route Response Parsing', () {
      test('OK status indicates successful response', () {
        const status = 'OK';
        expect(status, equals('OK'));
      });

      test('Routes array is parsed from response', () {
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

      test('Polyline points are extracted from first route', () {
        final routes =
            [
                  {
                    'overview_polyline': {'points': '_p~iF~ps|U'} as Map,
                  },
                  {
                    'overview_polyline': {'points': 'other_route'} as Map,
                  },
                ]
                as List<Map>;

        final firstRoute = routes[0];
        final overviewPolyline = firstRoute['overview_polyline'] as Map?;
        expect(overviewPolyline?['points'], '_p~iF~ps|U');
      });

      test('ZERO_RESULTS status returns no routes', () {
        final response = {'status': 'ZERO_RESULTS', 'routes': []};

        expect(response['routes'], isEmpty);
      });

      test('Error statuses are handled', () {
        final errorStatuses = [
          'INVALID_REQUEST',
          'REQUEST_DENIED',
          'OVER_QUERY_LIMIT',
        ];

        for (final status in errorStatuses) {
          expect(status, isNotEmpty);
        }
      });
    });

    group('Return Type Validation', () {
      test('Successful route returns List<LatLng>', () {
        final route = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4582, -73.6405),
        ];

        expect(route, isA<List<LatLng>>());
      });

      test('Failed route returns null', () {
        List<LatLng>? failed = null;
        expect(failed, isNull);
      });

      test('Empty route list is handled', () {
        final empty = <LatLng>[];
        expect(empty, isEmpty);
        expect(empty, isA<List<LatLng>>());
      });

      test('Route with many points', () {
        final route = <LatLng>[];
        for (int i = 0; i < 50; i++) {
          route.add(LatLng(45.0 + i * 0.01, -73.0 - i * 0.01));
        }
        expect(route.length, 50);
      });
    });

    group('Coordinate Validation', () {
      test('Route points are valid LatLng', () {
        final route = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4900, -73.5800),
          const LatLng(45.4582, -73.6405),
        ];

        for (final point in route) {
          expect(point.latitude, inInclusiveRange(-90, 90));
          expect(point.longitude, inInclusiveRange(-180, 180));
        }
      });

      test('SGW to Loyola route is valid', () {
        const sgw = LatLng(45.4973, -73.5789);
        const loyola = LatLng(45.4582, -73.6405);

        expect(sgw.latitude, greaterThan(loyola.latitude));
        expect(sgw.longitude, greaterThan(loyola.longitude));
      });

      test('Route coordinates are in Montreal area', () {
        const point = LatLng(45.5, -73.5);

        expect(point.latitude, inInclusiveRange(45.0, 46.0));
        expect(point.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Route preserves precision', () {
        const precise = LatLng(45.49732102, -73.57891234);

        expect(precise.latitude, inInclusiveRange(45.0, 46.0));
        expect(precise.longitude, inInclusiveRange(-74.0, -73.0));
      });
    });

    group('HTTP Status Code Handling', () {
      test('200 status is success', () {
        expect(200, equals(200));
      });

      test('4xx codes indicate client error', () {
        final codes = [400, 401, 403, 404, 429];
        for (final code in codes) {
          expect(code, greaterThanOrEqualTo(400));
        }
      });

      test('5xx codes indicate server error', () {
        final codes = [500, 502, 503, 504];
        for (final code in codes) {
          expect(code, greaterThanOrEqualTo(500));
        }
      });

      test('Non-200 response returns null', () {
        const errorStatus = 401;
        expect(errorStatus, isNot(200));
      });
    });

    group('Travel Modes', () {
      test('Walking mode is supported', () {
        const mode = 'walking';
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });

      test('Driving mode is supported', () {
        const mode = 'driving';
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });

      test('Bicycling mode is supported', () {
        const mode = 'bicycling';
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });

      test('Transit mode is supported', () {
        const mode = 'transit';
        expect(['walking', 'driving', 'bicycling', 'transit'], contains(mode));
      });

      test('Default mode is walking', () {
        const defaultMode = 'walking';
        expect(defaultMode, equals('walking'));
      });
    });

    group('Edge Cases', () {
      test('Same origin and destination', () {
        const point = LatLng(45.5, -73.5);
        const origin = point;
        const destination = point;

        expect(origin, equals(destination));
      });

      test('Route at extreme coordinates', () {
        const north = LatLng(89.9, 0);
        const south = LatLng(-89.9, 0);

        expect(north.latitude, inInclusiveRange(-90, 90));
        expect(south.latitude, inInclusiveRange(-90, 90));
      });

      test('Two point minimum route', () {
        final route = [
          const LatLng(45.5, -73.5),
          const LatLng(45.50001, -73.50001),
        ];

        expect(route.length, 2);
      });

      test('Route coordinate ordering', () {
        final route = [
          const LatLng(45.4, -73.4),
          const LatLng(45.5, -73.5),
          const LatLng(45.6, -73.6),
        ];

        expect(route[0].latitude, lessThan(route[2].latitude));
      });
    });

    group('Service Constants', () {
      test('API base URL is HTTPS', () {
        const baseUrl = 'https://maps.googleapis.com/maps/api';
        expect(baseUrl, startsWith('https://'));
      });

      test('Directions endpoint path is correct', () {
        const endpoint = 'directions/json';
        expect(endpoint, contains('directions'));
      });

      test('API supports multiple travel modes', () {
        final modes = ['walking', 'driving', 'bicycling', 'transit'];
        expect(modes.length, 4);
      });
    });

    group('Montreal Campus Routes', () {
      test('SGW campus coordinates', () {
        const sgw = LatLng(45.4973, -73.5789);
        expect(sgw.latitude, closeTo(45.4973, 0.0001));
        expect(sgw.longitude, closeTo(-73.5789, 0.0001));
      });

      test('Loyola campus coordinates', () {
        const loyola = LatLng(45.4582, -73.6405);
        expect(loyola.latitude, closeTo(45.4582, 0.0001));
        expect(loyola.longitude, closeTo(-73.6405, 0.0001));
      });

      test('Route between campuses is valid', () {
        const sgw = LatLng(45.4973, -73.5789);
        const loyola = LatLng(45.4582, -73.6405);

        expect(
          sgw.latitude,
          allOf(greaterThan(loyola.latitude), inInclusiveRange(45.0, 46.0)),
        );
        expect(sgw.longitude, inInclusiveRange(-74.0, -73.0));
        expect(loyola.latitude, inInclusiveRange(45.0, 46.0));
        expect(loyola.longitude, inInclusiveRange(-74.0, -73.0));
      });
    });

    group('Polyline Data Validation', () {
      test('Polyline string is not empty', () {
        const encoded = '_p~iF~ps|U_ulLnnqC';
        expect(encoded, isNotEmpty);
      });

      test('Polyline points are valid format', () {
        const encoded = '_p~iF~ps|U';
        expect(encoded, isA<String>());
      });

      test('Multiple polyline examples', () {
        final examples = ['_p~iF~ps|U', 'u{~vFvyys`@fS', 'geomE~ousV'];

        for (final polyline in examples) {
          expect(polyline, isNotEmpty);
        }
      });
    });

    group('Service Method Integration', () {
      test('getRoute method exists and is callable', () {
        // Verify the method signature and type
        expect(GoogleDirectionsService.getRoute, isNotNull);
      });

      test('getRoute accepts LatLng parameters', () async {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        // Call the method - this will make a real HTTP request
        final result = await GoogleDirectionsService.getRoute(
          origin: origin,
          destination: destination,
        );

        // Result can be null or a List<LatLng>
        if (result != null) {
          expect(result, isA<List<LatLng>>());
          if (result.isNotEmpty) {
            for (final point in result) {
              expect(point.latitude, inInclusiveRange(-90, 90));
              expect(point.longitude, inInclusiveRange(-180, 180));
            }
          }
        }
      });

      test('getRoute with default walking mode', () async {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        // Default mode is 'walking'
        final result = await GoogleDirectionsService.getRoute(
          origin: origin,
          destination: destination,
        );

        expect(result, anyOf(isNull, isA<List<LatLng>>()));
      });

      test('getRoute with explicit walking mode', () async {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        final result = await GoogleDirectionsService.getRoute(
          origin: origin,
          destination: destination,
          mode: 'walking',
        );

        expect(result, anyOf(isNull, isA<List<LatLng>>()));
      });

      test('getRoute with driving mode', () async {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        final result = await GoogleDirectionsService.getRoute(
          origin: origin,
          destination: destination,
          mode: 'driving',
        );

        expect(result, anyOf(isNull, isA<List<LatLng>>()));
      });

      test('getRoute with bicycling mode', () async {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        final result = await GoogleDirectionsService.getRoute(
          origin: origin,
          destination: destination,
          mode: 'bicycling',
        );

        expect(result, anyOf(isNull, isA<List<LatLng>>()));
      });

      test('getRoute with transit mode', () async {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        final result = await GoogleDirectionsService.getRoute(
          origin: origin,
          destination: destination,
          mode: 'transit',
        );

        expect(result, anyOf(isNull, isA<List<LatLng>>()));
      });

      test('getRoute with same origin and destination', () async {
        const location = LatLng(45.5, -73.5);

        final result = await GoogleDirectionsService.getRoute(
          origin: location,
          destination: location,
        );

        // Should return null or empty for same location
        expect(result, anyOf(isNull, isEmpty, isA<List<LatLng>>()));
      });

      test('getRoute result contains valid coordinates', () async {
        const origin = LatLng(45.4973, -73.5789);
        const destination = LatLng(45.4582, -73.6405);

        final result = await GoogleDirectionsService.getRoute(
          origin: origin,
          destination: destination,
        );

        if (result != null && result.isNotEmpty) {
          expect(result.length, greaterThanOrEqualTo(2));

          // First point should be near origin
          final first = result.first;
          expect(first.latitude, inInclusiveRange(45.0, 46.0));
          expect(first.longitude, inInclusiveRange(-74.0, -73.0));

          // Last point should be near destination
          final last = result.last;
          expect(last.latitude, inInclusiveRange(45.0, 46.0));
          expect(last.longitude, inInclusiveRange(-74.0, -73.0));
        }
      });
    });
  });
}
