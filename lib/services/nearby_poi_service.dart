import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

//Categories of points of interest displayed on the outdoor map.
enum PoiCategory { cafe, restaurant, pharmacy, depanneur }

//A single point of interest returned from the Places API.
class PoiPlace {
  final String placeId;
  final String name;
  final LatLng location;
  final PoiCategory category;

  const PoiPlace({
    required this.placeId,
    required this.name,
    required this.location,
    required this.category,
  });
}

// Fetches top 60 POI (cafes, restaurants, pharmacies, depanneurs) within 5km of user location
class NearbyPoiService {
  NearbyPoiService._();

  // Key is injected at build time via --dart-define=GOOGLE_PLACES_API_KEY=...
  // Never hardcode the key here — read it from local.properties via run.ps1
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  //Maximum number of results per category.
  static const int _maxResultsPerCategory = 60;

  //Radius in metres. Matches the 5 km requirement in the story.
  static const double radiusMeters = 5000;

  //Maps google maps places by icon category
  static const Map<String, PoiCategory> _categoryTypes = {
    'cafe': PoiCategory.cafe,
    'restaurant': PoiCategory.restaurant,
    'food': PoiCategory.restaurant,
    'meal_takeaway': PoiCategory.restaurant,
    'meal_delivery': PoiCategory.restaurant,
    'bakery': PoiCategory.restaurant,
    'sushi_restaurant': PoiCategory.restaurant,
    'mexican_restaurant': PoiCategory.restaurant,
    'chinese_restaurant': PoiCategory.restaurant,
    'japanese_restaurant': PoiCategory.restaurant,
    'italian_restaurant': PoiCategory.restaurant,
    'thai_restaurant': PoiCategory.restaurant,
    'indian_restaurant': PoiCategory.restaurant,
    'korean_restaurant': PoiCategory.restaurant,
    'vietnamese_restaurant': PoiCategory.restaurant,
    'american_restaurant': PoiCategory.restaurant,
    'greek_restaurant': PoiCategory.restaurant,
    'pizza_restaurant': PoiCategory.restaurant,
    'fast_food_restaurant': PoiCategory.restaurant,
    'hamburger_restaurant': PoiCategory.restaurant,
    'sandwich_shop': PoiCategory.restaurant,
    'ramen_restaurant': PoiCategory.restaurant,
    'bar': PoiCategory.restaurant,
    'pharmacy': PoiCategory.pharmacy,
    'convenience_store': PoiCategory.depanneur,
  };

  //Fetches POIs for all categories using the injected API key.
  static Future<List<PoiPlace>> fetchNearby(
    LatLng center, {
    required String apiKey,
  }) async {
    return fetchNearbyWithClient(center, apiKey: apiKey, client: http.Client());
  }

  /// Testable entry point — accepts an injected [http.Client].
  static Future<List<PoiPlace>> fetchNearbyWithClient(
    LatLng center, {
    required String apiKey,
    required http.Client client,
  }) async {
    final results = <PoiPlace>[];
    final seenPlaceIds = <String>{};

    await Future.wait(
      _categoryTypes.entries.map(
        (entry) => _fetchCategory(
          center: center,
          category: entry.value,
          type: entry.key,
          apiKey: apiKey,
          sink: results,
          seen: seenPlaceIds,
          client: client,
        ),
      ),
    );

    return results;
  }

  static Future<void> _fetchCategory({
    required LatLng center,
    required PoiCategory category,
    required String type,
    required String apiKey,
    required List<PoiPlace> sink,
    required Set<String> seen,
    required http.Client client,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl'
        '?location=${center.latitude},${center.longitude}'
        '&radius=${radiusMeters.toInt()}'
        '&type=$type'
        '&key=$apiKey',
      );

      final response = await client.get(uri);
      if (response.statusCode != 200) {
        print('[POI] HTTP ${response.statusCode} for type=$type');
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final places = (body['results'] as List<dynamic>?) ?? [];

      int count = 0;
      for (final place in places) {
        if (count >= _maxResultsPerCategory) break;

        final placeId = place['place_id'] as String? ?? '';
        if (placeId.isEmpty || seen.contains(placeId)) continue;

        final geo = place['geometry']?['location'];
        if (geo == null) continue;

        seen.add(placeId);
        sink.add(
          PoiPlace(
            placeId: placeId,
            name: place['name'] as String? ?? '',
            location: LatLng(
              (geo['lat'] as num).toDouble(),
              (geo['lng'] as num).toDouble(),
            ),
            category: category,
          ),
        );
        count++;
      }
    } catch (e) {
      print('[POI] Error fetching $type: $e');
    }
  }
}
