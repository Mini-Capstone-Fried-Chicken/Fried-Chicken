import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents an autocomplete prediction from Google Places API
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>?;

    return PlacePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText:
          structuredFormatting?['main_text'] as String? ??
          json['description'] as String,
      secondaryText: structuredFormatting?['secondary_text'] as String?,
    );
  }
}

/// Represents a place result from Google Places API
class PlaceResult {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final LatLng location;

  PlaceResult({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    required this.location,
  });
}

/// Service for searching places using Google Maps Places API
class GooglePlacesService {
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );
  static const String _baseUrl = 'https://places.googleapis.com/v1';

  final http.Client _client;

  static final GooglePlacesService instance = GooglePlacesService();

  GooglePlacesService({http.Client? client})
      : _client = client ?? http.Client();

  static const String contentTypeHeader = 'Content-Type';
  static const String jsonMimeType = 'application/json';
  static const String apiKeyHeader = 'X-Goog-Api-Key';

  Future<List<PlaceResult>> searchPlaces(
    String query, {
    LatLng? location,
    int radius = 5000,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/places:searchText');
      final body = <String, dynamic>{'textQuery': query};

      if (location != null) {
        body['locationBias'] = {
          'circle': {
            'center': {
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
            'radius': radius.toDouble(),
          },
        };
      }

      final response = await _client.post(
        uri,
        headers: {
          contentTypeHeader: jsonMimeType,
          apiKeyHeader: _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['places'] != null) {
          final places = data['places'] as List<dynamic>;
          return places.map((place) {
            final placeData = place as Map<String, dynamic>;
            final location = placeData['location'] as Map<String, dynamic>?;
            final displayName =
                placeData['displayName'] as Map<String, dynamic>?;

            return PlaceResult(
              placeId: placeData['id'] as String? ?? '',
              name: displayName?['text'] as String? ?? 'Unknown',
              formattedAddress: placeData['formattedAddress'] as String?,
              location: LatLng(
                location?['latitude'] as double? ?? 0.0,
                location?['longitude'] as double? ?? 0.0,
              ),
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  Future<PlaceResult?> getPlaceDetails(String placeId) async {
    try {
      print('[DEBUG] Fetching place details for placeId: $placeId');

      String resourceName = placeId;
      if (!placeId.startsWith('places/')) {
        resourceName = 'places/$placeId';
        print('[DEBUG] Added places/ prefix: $resourceName');
      }

      final uri = Uri.parse('$_baseUrl/$resourceName');
      print('[DEBUG] Request URI: $uri');

      final response = await _client.get(
        uri,
        headers: {
          contentTypeHeader: jsonMimeType,
          apiKeyHeader: _apiKey,
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
        },
      );

      print('[DEBUG] Place details response status: ${response.statusCode}');
      print('[DEBUG] Place details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('[DEBUG] Parsed place details: $data');
        final location = data['location'] as Map<String, dynamic>?;
        final displayName = data['displayName'] as Map<String, dynamic>?;

        final result = PlaceResult(
          placeId: data['id'] as String? ?? placeId,
          name: displayName?['text'] as String? ?? 'Unknown',
          formattedAddress: data['formattedAddress'] as String?,
          location: LatLng(
            location?['latitude'] as double? ?? 0.0,
            location?['longitude'] as double? ?? 0.0,
          ),
        );
        print('[DEBUG] Created PlaceResult: ${result.name} at ${result.location}');
        return result;
      } else {
        print('[ERROR] HTTP error ${response.statusCode}: ${response.body}');
      }

      return null;
    } catch (e) {
      print('[ERROR] Error getting place details: $e');
      return null;
    }
  }

  // Helpers extracted to reduce cognitive complexity of getAutocompletePredictions

  /// Builds the request body for the autocomplete endpoint, including the location bias.  Falls back to a Concordia-area bias when [location] is null.
  Map<String, dynamic> _buildAutocompleteBody(String query, LatLng? location, int radius) {
    final body = <String, dynamic>{'input': query, 'languageCode': 'en'};

    if (location != null) {
      body['locationBias'] = {
        'circle': {
          'center': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': radius.toDouble(),
        },
      };
    } else {
      body['locationBias'] = {
        'circle': {
          'center': {
            'latitude': 45.4958,
            'longitude': -73.5711,
          },
          'radius': 15000.0,
        },
      };
    }

    return body;
  }

  /// Attempts to parse one entry from the `suggestions` array into a [PlacePrediction].  Returns null and logs a warning if the entry is missing the expected `placePrediction` field or cannot be parsed.
  PlacePrediction? _parseSuggestion(Map<String, dynamic> suggestion, int index) {
    try {
      final placePrediction = suggestion['placePrediction'] as Map<String, dynamic>?;
      if (placePrediction == null) {
        print('[DEBUG] Suggestion $index has no placePrediction field');
        return null;
      }

      print('[DEBUG] Suggestion $index placePrediction keys: ${placePrediction.keys.toList()}');
      print('[DEBUG] Suggestion $index full placePrediction: $placePrediction');

      final placeId =
          placePrediction['placeId'] as String? ??
          placePrediction['place'] as String? ??
          '';
      print('[DEBUG] Suggestion $index extracted placeId: $placeId');

      final text = placePrediction['text'] as Map<String, dynamic>?;
      final structuredFormat =
          placePrediction['structuredFormat'] as Map<String, dynamic>?;
      final mainText = structuredFormat?['mainText'] as Map<String, dynamic>?;
      final secondaryText =
          structuredFormat?['secondaryText'] as Map<String, dynamic>?;

      final prediction = PlacePrediction(
        placeId: placeId,
        description: text?['text'] as String? ?? '',
        mainText:
            mainText?['text'] as String? ?? text?['text'] as String? ?? '',
        secondaryText: secondaryText?['text'] as String?,
      );
      print('[DEBUG] Created prediction $index: ${prediction.mainText}');
      return prediction;
    } catch (e) {
      print('[ERROR] Error parsing suggestion $index: $e');
      return null;
    }
  }

  /// Decodes the 200 response body and converts every suggestion entry into a [PlacePrediction], skipping any that fail to parse.
  List<PlacePrediction> _parsePredictionsFromBody(String responseBody) {
    final data = json.decode(responseBody) as Map<String, dynamic>;
    print('[DEBUG] Google Places API response received');
    print('[DEBUG] Response keys: ${data.keys.toList()}');

    final suggestions = data['suggestions'] as List<dynamic>?;
    if (suggestions == null) {
      print('[DEBUG] No suggestions in response. Available keys: ${data.keys.toList()}');
      if (data['error'] != null) {
        print('[ERROR] API returned error: ${data['error']}');
      }
      return [];
    }

    print('[DEBUG] Found ${suggestions.length} Google Places predictions');

    final predictions = <PlacePrediction>[];
    for (int i = 0; i < suggestions.length; i++) {
      final prediction = _parseSuggestion(
        suggestions[i] as Map<String, dynamic>,
        i,
      );
      if (prediction != null) predictions.add(prediction);
    }

    print('[DEBUG] Returning ${predictions.length} predictions');
    return predictions;
  }


  Future<List<PlacePrediction>> getAutocompletePredictions(
    String query, {
    LatLng? location,
    int radius = 5000,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/places:autocomplete');
      final body = _buildAutocompleteBody(query, location, radius);

      print('[DEBUG] Fetching Google Places predictions for: $query');
      print('[DEBUG] Location bias: $location');
      print('[DEBUG] Request body: ${json.encode(body)}');

      final response = await _client.post(
        uri,
        headers: {
          contentTypeHeader: jsonMimeType,
          apiKeyHeader: _apiKey,
        },
        body: json.encode(body),
      );

      print('[DEBUG] API Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('[ERROR] HTTP error: ${response.statusCode}');
        print('[ERROR] Response body: ${response.body}');
        return [];
      }

      try {
        return _parsePredictionsFromBody(response.body);
      } catch (e) {
        print('[ERROR] Error parsing response JSON: $e');
        print('[DEBUG] Raw response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ERROR] Error getting autocomplete predictions: $e');
      return [];
    }
  }
}
