import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_app/services/google_directions_service.dart';

/// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final http.Response Function(http.Request request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('GoogleDirectionsService Coverage Tests', () {
    group('getRoute method - successful responses', () {
      test('returns polyline points when API returns OK status', () async {
        final mockClient = MockHttpClient((request) {
          expect(request.url.path, contains('/directions/json'));
          expect(request.url.queryParameters['origin'], '45.5,-73.5');
          expect(request.url.queryParameters['destination'], '45.6,-73.6');
          expect(request.url.queryParameters['mode'], 'walking');

          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
          mode: 'walking',
        );

        expect(result, isNotNull);
        expect(result, isA<List<LatLng>>());
        expect(result!.isNotEmpty, true);
      });

      test('decodes polyline correctly with multiple points', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': 'u{_vFj|xiVnB?',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNotNull);
        expect(result!.length, greaterThan(0));
      });

      test('handles different travel modes', () async {
        for (final mode in ['walking', 'driving', 'bicycling', 'transit']) {
          final mockClient = MockHttpClient((request) {
            expect(request.url.queryParameters['mode'], mode);
            return http.Response(
              json.encode({
                'status': 'OK',
                'routes': [
                  {
                    'overview_polyline': {
                      'points': '_p~iF~ps|U_ulLnnqC',
                    },
                  },
                ],
              }),
              200,
            );
          });

          final service = GoogleDirectionsService(client: mockClient);
          final result = await service.getRoute(
            origin: const LatLng(45.5, -73.5),
            destination: const LatLng(45.6, -73.6),
            mode: mode,
          );

          expect(result, isNotNull);
        }
      });
    });

    group('getRoute method - error handling', () {
      test('returns null when status is not OK', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'ZERO_RESULTS',
              'routes': [],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNull);
      });

      test('returns null when routes array is empty', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNull);
      });

      test('returns null when HTTP status code is not 200', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response('Error', 404);
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNull);
      });

      test('returns null when HTTP status code is 500', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response('Server Error', 500);
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNull);
      });

      test('handles malformed JSON response', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response('Not valid JSON', 200);
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNull);
      });

      test('handles exception during request', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Network error');
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNull);
      });
    });

    group('Polyline decoding algorithm', () {
      test('decodes simple polyline', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': '_p~iF~ps|U',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNotNull);
        expect(result!.isNotEmpty, true);
      });

      test('decodes complex polyline', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': 'mbjzF`sjiVcAuAwCuDyA_BqAuAcA{@w@k@}@i@',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNotNull);
        expect(result!.length, greaterThan(1));
      });

      test('handles negative coordinate deltas', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': '????',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNotNull);
      });
    });

    group('Edge cases', () {
      test('handles very long routes', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@_p~iF~ps|U_ulLnnqC',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNotNull);
      });

      test('handles origin and destination at same location', () async {
        final mockClient = MockHttpClient((request) {
          expect(request.url.queryParameters['origin'], '45.5,-73.5');
          expect(request.url.queryParameters['destination'], '45.5,-73.5');
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': '_p~iF~ps|U',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.5, -73.5),
        );

        expect(result, isNotNull);
      });

      test('handles extreme coordinates', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'overview_polyline': {
                    'points': '_p~iF~ps|U',
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(89.9, -179.9),
          destination: const LatLng(-89.9, 179.9),
        );

        expect(result, isNotNull);
      });
    });

    group('API response variations', () {
      test('handles missing overview_polyline', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'status': 'OK',
              'routes': [
                {
                  'summary': 'Route summary',
                },
              ],
            }),
            200,
          );
        });

        final service = GoogleDirectionsService(client: mockClient);
        final result = await service.getRoute(
          origin: const LatLng(45.5, -73.5),
          destination: const LatLng(45.6, -73.6),
        );

        expect(result, isNull);
      });

      test('handles different API error statuses', () async {
        final errorStatuses = [
          'ZERO_RESULTS',
          'NOT_FOUND',
          'MAX_WAYPOINTS_EXCEEDED',
          'INVALID_REQUEST',
          'OVER_QUERY_LIMIT',
          'REQUEST_DENIED',
          'UNKNOWN_ERROR',
        ];

        for (final status in errorStatuses) {
          final mockClient = MockHttpClient((request) {
            return http.Response(
              json.encode({
                'status': status,
                'routes': [],
              }),
              200,
            );
          });

          final service = GoogleDirectionsService(client: mockClient);
          final result = await service.getRoute(
            origin: const LatLng(45.5, -73.5),
            destination: const LatLng(45.6, -73.6),
          );

          expect(result, isNull, reason: 'Should return null for status: $status');
        }
      });
    });
  });
}
