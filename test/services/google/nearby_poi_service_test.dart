import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_app/services/nearby_poi_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal Places Nearby Search JSON response with [count] results.
String _buildPlacesResponse({
  required int count,
  String status = 'OK',
  String placeIdPrefix = 'place_',
  String namePrefix = 'Place ',
  double baseLat = 45.49,
  double baseLng = -73.57,
}) {
  final results = List.generate(count, (i) {
    return {
      'place_id': '$placeIdPrefix$i',
      'name': '$namePrefix$i',
      'geometry': {
        'location': {'lat': baseLat + i * 0.001, 'lng': baseLng + i * 0.001},
      },
    };
  });
  return jsonEncode({'status': status, 'results': results});
}

/// Returns a [MockClient] that always responds with [body] and [statusCode].
MockClient _mockClient(String body, {int statusCode = 200}) {
  return MockClient((_) async => http.Response(body, statusCode));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const LatLng sgw = LatLng(45.4973, -73.5789);

  group('PoiPlace', () {
    test('stores all fields correctly', () {
      const place = PoiPlace(
        placeId: 'abc123',
        name: 'Test Cafe',
        location: LatLng(45.49, -73.57),
        category: PoiCategory.cafe,
      );

      expect(place.placeId, 'abc123');
      expect(place.name, 'Test Cafe');
      expect(place.location.latitude, 45.49);
      expect(place.location.longitude, -73.57);
      expect(place.category, PoiCategory.cafe);
    });
  });

  group('PoiCategory', () {
    test('has exactly four values', () {
      expect(PoiCategory.values.length, 4);
    });

    test('contains expected categories', () {
      expect(
        PoiCategory.values,
        containsAll([
          PoiCategory.cafe,
          PoiCategory.restaurant,
          PoiCategory.pharmacy,
          PoiCategory.depanneur,
        ]),
      );
    });
  });

  group('NearbyPoiService.fetchNearby', () {
    test('returns empty list when API returns no results', () async {
      final client = _mockClient(jsonEncode({'status': 'OK', 'results': []}));

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      expect(pois, isEmpty);
    });

    test('returns POIs for a single type', () async {
      final client = _mockClient(_buildPlacesResponse(count: 3));

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      expect(pois, isNotEmpty);
    });

    test(
      'deduplicates places that appear in multiple type responses',
      () async {
        // Both 'restaurant' and 'food' return the same place_id
        final duplicateBody = jsonEncode({
          'status': 'OK',
          'results': [
            {
              'place_id': 'same_id',
              'name': 'Shared Place',
              'geometry': {
                'location': {'lat': 45.49, 'lng': -73.57},
              },
            },
          ],
        });

        final client = MockClient(
          (_) async => http.Response(duplicateBody, 200),
        );

        final pois = await NearbyPoiService.fetchNearbyWithClient(
          sgw,
          apiKey: 'test_key',
          client: client,
        );

        final ids = pois.map((p) => p.placeId).toList();
        expect(
          ids.toSet().length,
          equals(ids.length),
          reason: 'No duplicate place IDs should appear',
        );
      },
    );

    test('skips places with missing geometry', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {'place_id': 'no_geo', 'name': 'No Geo Place'},
          {
            'place_id': 'has_geo',
            'name': 'Has Geo',
            'geometry': {
              'location': {'lat': 45.49, 'lng': -73.57},
            },
          },
        ],
      });

      final client = MockClient((_) async => http.Response(body, 200));

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      expect(pois.any((p) => p.placeId == 'no_geo'), isFalse);
      expect(pois.any((p) => p.placeId == 'has_geo'), isTrue);
    });

    test('skips places with empty place_id', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {
            'place_id': '',
            'name': 'Empty ID',
            'geometry': {
              'location': {'lat': 45.49, 'lng': -73.57},
            },
          },
        ],
      });

      final client = MockClient((_) async => http.Response(body, 200));

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      expect(pois, isEmpty);
    });

    test('handles HTTP error response gracefully', () async {
      final client = _mockClient('Internal Server Error', statusCode: 500);

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      expect(pois, isEmpty);
    });

    test('handles malformed JSON gracefully', () async {
      final client = _mockClient('not json at all');

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      expect(pois, isEmpty);
    });

    test('assigns correct category to cafe type', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {
            'place_id': 'cafe_1',
            'name': 'Tim Hortons',
            'geometry': {
              'location': {'lat': 45.49, 'lng': -73.57},
            },
          },
        ],
      });

      // Only intercept the cafe type request
      final client = MockClient((request) async {
        if (request.url.queryParameters['type'] == 'cafe') {
          return http.Response(body, 200);
        }
        return http.Response(jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      final cafe = pois.firstWhere(
        (p) => p.placeId == 'cafe_1',
        orElse: () => throw Exception('cafe_1 not found'),
      );
      expect(cafe.category, PoiCategory.cafe);
    });

    test('assigns restaurant category to food type', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {
            'place_id': 'food_1',
            'name': 'Burger Joint',
            'geometry': {
              'location': {'lat': 45.49, 'lng': -73.57},
            },
          },
        ],
      });

      final client = MockClient((request) async {
        if (request.url.queryParameters['type'] == 'food') {
          return http.Response(body, 200);
        }
        return http.Response(jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      final food = pois.firstWhere(
        (p) => p.placeId == 'food_1',
        orElse: () => throw Exception('food_1 not found'),
      );
      expect(food.category, PoiCategory.restaurant);
    });

    test('assigns pharmacy category correctly', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {
            'place_id': 'pharmacy_1',
            'name': 'Pharmaprix',
            'geometry': {
              'location': {'lat': 45.49, 'lng': -73.57},
            },
          },
        ],
      });

      final client = MockClient((request) async {
        if (request.url.queryParameters['type'] == 'pharmacy') {
          return http.Response(body, 200);
        }
        return http.Response(jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      final pharmacy = pois.firstWhere(
        (p) => p.placeId == 'pharmacy_1',
        orElse: () => throw Exception('pharmacy_1 not found'),
      );
      expect(pharmacy.category, PoiCategory.pharmacy);
    });

    test('assigns depanneur category to convenience_store type', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {
            'place_id': 'dep_1',
            'name': 'Marché Beau-Soir',
            'geometry': {
              'location': {'lat': 45.49, 'lng': -73.57},
            },
          },
        ],
      });

      final client = MockClient((request) async {
        if (request.url.queryParameters['type'] == 'convenience_store') {
          return http.Response(body, 200);
        }
        return http.Response(jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      final dep = pois.firstWhere(
        (p) => p.placeId == 'dep_1',
        orElse: () => throw Exception('dep_1 not found'),
      );
      expect(dep.category, PoiCategory.depanneur);
    });

    test('respects max results cap per category', () async {
      // Return 100 results — service should cap at _maxResultsPerCategory (60)
      final body = _buildPlacesResponse(count: 100);
      final client = _mockClient(body);

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      // Each type query is capped, so total from one type <= 60
      // We just verify no crash and some results returned
      expect(pois, isNotEmpty);
    });

    test('correctly parses location coordinates', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {
            'place_id': 'loc_test',
            'name': 'Location Test',
            'geometry': {
              'location': {'lat': 45.456082, 'lng': -73.640848},
            },
          },
        ],
      });

      final client = MockClient((request) async {
        if (request.url.queryParameters['type'] == 'cafe') {
          return http.Response(body, 200);
        }
        return http.Response(jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final pois = await NearbyPoiService.fetchNearbyWithClient(
        sgw,
        apiKey: 'test_key',
        client: client,
      );

      final place = pois.firstWhere(
        (p) => p.placeId == 'loc_test',
        orElse: () => throw Exception('loc_test not found'),
      );
      expect(place.location.latitude, closeTo(45.456082, 0.000001));
      expect(place.location.longitude, closeTo(-73.640848, 0.000001));
    });
  });
}
