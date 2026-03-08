import 'dart:convert';

import 'package:campus_app/services/google_directions_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const encodedPolyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

  final origin = const LatLng(45.5017, -73.5673);
  final destination = const LatLng(45.5088, -73.5540);

  Map<String, dynamic> buildSuccessResponse({
    String status = 'OK',
    List<dynamic>? routes,
  }) {
    return {
      'status': status,
      'routes':
          routes ??
          [
            {
              'overview_polyline': {'points': encodedPolyline},
              'legs': [
                {
                  'duration': {'text': '18 min', 'value': 1080},
                  'distance': {'text': '2.4 km'},
                  'steps': [
                    {
                      'travel_mode': 'WALKING',
                      'html_instructions': '<b>Walk</b> to the stop',
                      'distance': {'text': '120 m'},
                      'duration': {'text': '2 min'},
                      'maneuver': 'turn-left',
                      'polyline': {'points': encodedPolyline},
                    },
                    {
                      'travel_mode': 'TRANSIT',
                      'html_instructions': '',
                      'distance': {'text': '4 stops'},
                      'duration': {'text': '10 min'},
                      'polyline': {'points': encodedPolyline},
                      'transit_details': {
                        'headsign': 'Downtown',
                        'line': {
                          'short_name': 'Orange',
                          'name': 'Orange Line',
                          'color': '#FF8800',
                          'vehicle': {'type': 'SUBWAY'},
                        },
                      },
                    },
                    {
                      'travel_mode': 'TRANSIT',
                      'html_instructions': '<div>Board bus</div>',
                      'distance': {'text': '3 stops'},
                      'duration': {'text': '6 min'},
                      'polyline': {'points': encodedPolyline},
                      'transit_details': {
                        'headsign': 'Westbound',
                        'line': {
                          'short_name': '24',
                          'name': 'Bus 24',
                          'color': '#0055AA',
                          'vehicle': {'type': 'BUS'},
                        },
                      },
                    },
                    {
                      'travel_mode': 'WALKING',
                      'html_instructions': '   ',
                      'distance': {'text': '50 m'},
                      'duration': {'text': '1 min'},
                      'polyline': {'points': encodedPolyline},
                    },
                    {
                      'travel_mode': 'DRIVING',
                      'html_instructions': '<b>Drive</b> straight',
                      'distance': {'text': '1 km'},
                      'duration': {'text': '3 min'},
                      'polyline': {'points': ''},
                    },
                  ],
                },
              ],
            },
          ],
    };
  }

  group('GoogleDirectionsService.getRouteDetails', () {
    test(
      'returns decoded route details, navigation steps, and transit segments',
      () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), contains('/directions/json'));
          expect(request.url.queryParameters['mode'], 'transit');
          expect(
            request.url.queryParameters['origin'],
            '${origin.latitude},${origin.longitude}',
          );
          expect(
            request.url.queryParameters['destination'],
            '${destination.latitude},${destination.longitude}',
          );

          return http.Response(
            jsonEncode(buildSuccessResponse()),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = GoogleDirectionsService(client: client);

        final result = await service.getRouteDetails(
          origin: origin,
          destination: destination,
          mode: 'transit',
        );

        expect(result, isNotNull);
        expect(result!.points.length, 3);
        expect(result.durationText, '18 min');
        expect(result.distanceText, '2.4 km');
        expect(result.durationSeconds, 1080);

        expect(result.transitHasBus, isTrue);
        expect(result.transitVehicleType, 'SUBWAY');
        expect(result.transitLineColorHex, '#FF8800');

        // Navigation steps:
        // - walking step kept
        // - transit empty instruction becomes "Continue"
        // - transit bus kept
        // - blank walking instruction skipped
        // - driving instruction kept even with empty polyline
        expect(result.steps.length, 4);

        expect(result.steps[0].instruction, 'Walk to the stop');
        expect(result.steps[0].travelMode, 'walking');
        expect(result.steps[0].distanceText, '120 m');
        expect(result.steps[0].durationText, '2 min');
        expect(result.steps[0].maneuver, 'turn-left');
        expect(result.steps[0].points.length, 3);

        expect(result.steps[1].instruction, 'Continue');
        expect(result.steps[1].travelMode, 'transit');
        expect(result.steps[1].transitVehicleType, 'SUBWAY');
        expect(result.steps[1].transitLineShortName, 'Orange');
        expect(result.steps[1].transitLineName, 'Orange Line');
        expect(result.steps[1].transitHeadsign, 'Downtown');

        expect(result.steps[2].instruction, 'Board bus');
        expect(result.steps[2].travelMode, 'transit');
        expect(result.steps[2].transitVehicleType, 'BUS');
        expect(result.steps[2].transitLineShortName, '24');
        expect(result.steps[2].transitHeadsign, 'Westbound');

        expect(result.steps[3].instruction, 'Drive straight');
        expect(result.steps[3].travelMode, 'driving');
        expect(result.steps[3].points, isEmpty);

        // Transit segments keep WALKING + TRANSIT steps with non-empty polyline
        expect(result.transitSegments.length, 4);

        expect(result.transitSegments[0].travelMode, 'WALKING');
        expect(result.transitSegments[0].distanceText, '120 m');
        expect(result.transitSegments[0].durationText, '2 min');
        expect(result.transitSegments[0].transitVehicleType, isNull);

        expect(result.transitSegments[1].travelMode, 'TRANSIT');
        expect(result.transitSegments[1].transitVehicleType, 'SUBWAY');
        expect(result.transitSegments[1].transitLineColorHex, '#FF8800');
        expect(result.transitSegments[1].transitLineShortName, 'Orange');
        expect(result.transitSegments[1].transitLineName, 'Orange Line');
        expect(result.transitSegments[1].transitHeadsign, 'Downtown');

        expect(result.transitSegments[2].travelMode, 'TRANSIT');
        expect(result.transitSegments[2].transitVehicleType, 'BUS');
        expect(result.transitSegments[2].transitLineShortName, '24');
        expect(result.transitSegments[2].transitHeadsign, 'Westbound');

        expect(result.transitSegments[3].travelMode, 'WALKING');
        expect(result.transitSegments[3].distanceText, '50 m');
        expect(result.transitSegments[3].durationText, '1 min');
        expect(result.transitSegments[3].transitVehicleType, isNull);
      },
    );

    test('does not build transit segments when mode is not transit', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(buildSuccessResponse()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GoogleDirectionsService(client: client);

      final result = await service.getRouteDetails(
        origin: origin,
        destination: destination,
        mode: 'walking',
      );

      expect(result, isNotNull);
      expect(result!.points.length, 3);
      expect(result.transitSegments, isEmpty);
      expect(result.steps, isNotEmpty);
    });

    test('returns null when API status is not OK', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(buildSuccessResponse(status: 'ZERO_RESULTS')),
          200,
        );
      });

      final service = GoogleDirectionsService(client: client);

      final result = await service.getRouteDetails(
        origin: origin,
        destination: destination,
      );

      expect(result, isNull);
    });

    test('returns null when routes list is empty', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(buildSuccessResponse(routes: [])), 200);
      });

      final service = GoogleDirectionsService(client: client);

      final result = await service.getRouteDetails(
        origin: origin,
        destination: destination,
      );

      expect(result, isNull);
    });

    test('returns null when response status code is not 200', () async {
      final client = MockClient((request) async {
        return http.Response('server error', 500);
      });

      final service = GoogleDirectionsService(client: client);

      final result = await service.getRouteDetails(
        origin: origin,
        destination: destination,
      );

      expect(result, isNull);
    });

    test('returns null when client throws exception', () async {
      final client = MockClient((request) async {
        throw Exception('network failed');
      });

      final service = GoogleDirectionsService(client: client);

      final result = await service.getRouteDetails(
        origin: origin,
        destination: destination,
      );

      expect(result, isNull);
    });

    test('handles response with no legs', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'OK',
            'routes': [
              {
                'overview_polyline': {'points': encodedPolyline},
              },
            ],
          }),
          200,
        );
      });

      final service = GoogleDirectionsService(client: client);

      final result = await service.getRouteDetails(
        origin: origin,
        destination: destination,
      );

      expect(result, isNotNull);
      expect(result!.points.length, 3);
      expect(result.durationText, isNull);
      expect(result.distanceText, isNull);
      expect(result.durationSeconds, isNull);
      expect(result.steps, isEmpty);
      expect(result.transitSegments, isEmpty);
      expect(result.transitVehicleType, isNull);
      expect(result.transitLineColorHex, isNull);
      expect(result.transitHasBus, isFalse);
    });
  });

  group('GoogleDirectionsService.getRoute', () {
    test('returns only points when route is found', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(buildSuccessResponse()), 200);
      });

      final service = GoogleDirectionsService(client: client);

      final points = await service.getRoute(
        origin: origin,
        destination: destination,
        mode: 'walking',
      );

      expect(points, isNotNull);
      expect(points!.length, 3);
      expect(points.first.latitude, closeTo(38.5, 0.00001));
      expect(points.first.longitude, closeTo(-120.2, 0.00001));
    });

    test('returns null when no route is found', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(buildSuccessResponse(status: 'ZERO_RESULTS')),
          200,
        );
      });

      final service = GoogleDirectionsService(client: client);

      final points = await service.getRoute(
        origin: origin,
        destination: destination,
      );

      expect(points, isNull);
    });
  });

  group('singleton instance', () {
    test('instance is available', () {
      expect(GoogleDirectionsService.instance, isA<GoogleDirectionsService>());
    });
  });
}
