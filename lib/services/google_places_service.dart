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
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;
    
    return PlacePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText: structuredFormatting?['main_text'] as String? ?? json['description'] as String,
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

/// Service for searching places using Google Maps Places API (New)
class GooglePlacesService {
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '', // Use empty string if not provided for safety
  );
  static const String _baseUrl = 'https://places.googleapis.com/v1';

  /// Search for places using Google Places API Text Search
  /// Returns a list of PlaceResult
  static Future<List<PlaceResult>> searchPlaces(
    String query, {
    LatLng? location,
    int radius = 5000,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/places:searchText');
      
      final body = <String, dynamic>{
        'textQuery': query,
      };
      
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

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location',
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
            final displayName = placeData['displayName'] as Map<String, dynamic>?;
            
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

  /// Get place details by place ID
  static Future<PlaceResult?> getPlaceDetails(String placeId) async {
    try {
      print('[DEBUG] Fetching place details for placeId: $placeId');
      
      // Ensure we have the full resource name format (places/ChIJ...)
      String resourceName = placeId;
      if (!placeId.startsWith('places/')) {
        resourceName = 'places/$placeId';
        print('[DEBUG] Added places/ prefix: $resourceName');
      }
      
      final uri = Uri.parse('$_baseUrl/$resourceName');
      print('[DEBUG] Request URI: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
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

  /// Get autocomplete predictions for a query
  /// Returns a list of PlacePrediction
  static Future<List<PlacePrediction>> getAutocompletePredictions(
    String query, {
    LatLng? location,
    int radius = 5000,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/places:autocomplete');
      
      final body = <String, dynamic>{
        'input': query,
        'languageCode': 'en',
      };
      
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
        // If no location specified, use a default bias towards Montreal/Concordia area
        body['locationBias'] = {
          'circle': {
            'center': {
              'latitude': 45.4958,  // Concordia's latitude
              'longitude': -73.5711, // Concordia's longitude
            },
            'radius': 15000.0,
          },
        };
      }

      print('[DEBUG] Fetching Google Places predictions for: $query');
      print('[DEBUG] Location bias: $location');
      print('[DEBUG] Request body: ${json.encode(body)}');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: json.encode(body),
      );

      print('[DEBUG] API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          
          print('[DEBUG] Google Places API response received');
          print('[DEBUG] Response keys: ${data.keys.toList()}');

          if (data['suggestions'] != null) {
            final suggestions = data['suggestions'] as List<dynamic>;
            print('[DEBUG] Found ${suggestions.length} Google Places predictions');
            
            final predictions = <PlacePrediction>[];
            for (int i = 0; i < suggestions.length; i++) {
              try {
                final suggestion = suggestions[i] as Map<String, dynamic>;
                if (suggestion['placePrediction'] != null) {
                  final placePrediction = suggestion['placePrediction'] as Map<String, dynamic>;
                  print('[DEBUG] Suggestion $i placePrediction keys: ${placePrediction.keys.toList()}');
                  print('[DEBUG] Suggestion $i full placePrediction: $placePrediction');
                  
                  // Try multiple ways to get the place ID/resource name
                  String placeId = placePrediction['placeId'] as String? ?? 
                                   placePrediction['place'] as String? ?? '';
                  print('[DEBUG] Suggestion $i extracted placeId: $placeId');
                  
                  final text = placePrediction['text'] as Map<String, dynamic>?;
                  final structuredFormat = placePrediction['structuredFormat'] as Map<String, dynamic>?;
                  
                  final mainText = structuredFormat?['mainText'] as Map<String, dynamic>?;
                  final secondaryText = structuredFormat?['secondaryText'] as Map<String, dynamic>?;
                  
                  final prediction = PlacePrediction(
                    placeId: placeId,
                    description: text?['text'] as String? ?? '',
                    mainText: mainText?['text'] as String? ?? text?['text'] as String? ?? '',
                    secondaryText: secondaryText?['text'] as String?,
                  );
                  print('[DEBUG] Created prediction $i: ${prediction.mainText}');
                  predictions.add(prediction);
                } else {
                  print('[DEBUG] Suggestion $i has no placePrediction field');
                }
              } catch (e) {
                print('[ERROR] Error parsing suggestion $i: $e');
              }
            }
            print('[DEBUG] Returning ${predictions.length} predictions');
            return predictions;
          } else {
            print('[DEBUG] No suggestions in response. Available keys: ${data.keys.toList()}');
            if (data['error'] != null) {
              print('[ERROR] API returned error: ${data['error']}');
            }
          }
        } catch (e) {
          print('[ERROR] Error parsing response JSON: $e');
          print('[DEBUG] Raw response body: ${response.body}');
        }
      } else {
        print('[ERROR] HTTP error: ${response.statusCode}');
        print('[ERROR] Response body: ${response.body}');
      }

      return [];
    } catch (e) {
      print('[ERROR] Error getting autocomplete predictions: $e');
      return [];
    }
  }
}
