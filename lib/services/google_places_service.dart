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
  static const String _apiKey = 'AIzaSyCGyz5Z6uLqqBDVBJnVUeZ4l23fJ6iXE6s';
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
      final uri = Uri.parse('$_baseUrl/$placeId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final location = data['location'] as Map<String, dynamic>?;
        final displayName = data['displayName'] as Map<String, dynamic>?;
        
        return PlaceResult(
          placeId: data['id'] as String? ?? placeId,
          name: displayName?['text'] as String? ?? 'Unknown',
          formattedAddress: data['formattedAddress'] as String?,
          location: LatLng(
            location?['latitude'] as double? ?? 0.0,
            location?['longitude'] as double? ?? 0.0,
          ),
        );
      }

      return null;
    } catch (e) {
      print('Error getting place details: $e');
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

      print('Fetching Google Places predictions for: $query');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        print('Google Places API response received');

        if (data['suggestions'] != null) {
          final suggestions = data['suggestions'] as List<dynamic>;
          print('Found ${suggestions.length} Google Places predictions');
          
          final predictions = <PlacePrediction>[];
          for (final suggestion in suggestions) {
            final suggestionData = suggestion as Map<String, dynamic>;
            if (suggestionData['placePrediction'] != null) {
              final placePrediction = suggestionData['placePrediction'] as Map<String, dynamic>;
              final placeId = placePrediction['placeId'] as String? ?? 
                             placePrediction['place'] as String? ?? '';
              final text = placePrediction['text'] as Map<String, dynamic>?;
              final structuredFormat = placePrediction['structuredFormat'] as Map<String, dynamic>?;
              
              final mainText = structuredFormat?['mainText'] as Map<String, dynamic>?;
              final secondaryText = structuredFormat?['secondaryText'] as Map<String, dynamic>?;
              
              predictions.add(PlacePrediction(
                placeId: placeId,
                description: text?['text'] as String? ?? '',
                mainText: mainText?['text'] as String? ?? text?['text'] as String? ?? '',
                secondaryText: secondaryText?['text'] as String?,
              ));
            }
          }
          return predictions;
        } else {
          print('No suggestions in response');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      return [];
    } catch (e) {
      print('Error getting autocomplete predictions: $e');
      return [];
    }
  }
}
