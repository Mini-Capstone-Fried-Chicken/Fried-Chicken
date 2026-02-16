import '../data/building_names.dart';
import '../data/building_polygons.dart';
import '../data/search_result.dart';
import '../data/search_suggestion.dart';
import 'google_places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for searching buildings using Google Places API and Concordia building data
class BuildingSearchService {
  /// Search for places using Google Places API with Concordia building check
  /// Returns a list of SearchResult objects
  static Future<List<SearchResult>> searchWithGooglePlaces(
    String query, {
    LatLng? userLocation,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Search using Google Places API
    final placesResults = await GooglePlacesService.searchPlaces(
      query,
      location: userLocation,
      radius: 5000,
    );

    final results = <SearchResult>[];

    for (final place in placesResults) {
      // Check if this place is a Concordia building
      final concordiaBuilding = _findBuildingByLocation(place.location);
      final isConcordia = concordiaBuilding != null;

      results.add(SearchResult.fromGooglePlace(
        name: place.name,
        address: place.formattedAddress,
        location: place.location,
        isConcordiaBuilding: isConcordia,
        buildingPolygon: concordiaBuilding,
        placeId: place.placeId,
      ));
    }

    return results;
  }

  /// Find a Concordia building by checking if a location is within any building polygon
  static BuildingPolygon? _findBuildingByLocation(LatLng location) {
    for (final building in buildingPolygons) {
      if (building.containsPoint(location)) {
        return building;
      }
    }
    return null;
  }

  /// Check if a location is within a Concordia building
  static bool isLocationInConcordiaBuilding(LatLng location) {
    return _findBuildingByLocation(location) != null;
  }

  /// Search for a building by query string (legacy method for backward compatibility)
  /// Returns the matching BuildingPolygon if found, null otherwise
  static BuildingPolygon? searchBuilding(String query) {
    if (query.trim().isEmpty) {
      return null;
    }

    final normalizedQuery = query.toLowerCase().trim();

    // First, try exact code match
    for (final buildingName in concordiaBuildingNames) {
      if (buildingName.code.toLowerCase() == normalizedQuery) {
        return _findBuildingByCode(buildingName.code);
      }
    }

    // Then, try exact name match
    for (final buildingName in concordiaBuildingNames) {
      if (buildingName.name.toLowerCase() == normalizedQuery) {
        return _findBuildingByCode(buildingName.code);
      }
    }

    // Try partial name match
    for (final buildingName in concordiaBuildingNames) {
      if (buildingName.name.toLowerCase().contains(normalizedQuery)) {
        return _findBuildingByCode(buildingName.code);
      }
    }

    // Try search terms match
    for (final buildingName in concordiaBuildingNames) {
      for (final term in buildingName.searchTerms) {
        if (term.toLowerCase().contains(normalizedQuery) ||
            normalizedQuery.contains(term.toLowerCase())) {
          return _findBuildingByCode(buildingName.code);
        }
      }
    }

    return null;
  }

  /// Get all building suggestions for autocomplete
  static List<BuildingName> getAllBuildings() {
    return concordiaBuildingNames;
  }

  /// Get filtered building suggestions based on query
  static List<BuildingName> getSuggestions(String query) {
    if (query.trim().isEmpty) {
      return concordiaBuildingNames;
    }

    final normalizedQuery = query.toLowerCase().trim();
    final suggestions = <BuildingName>[];

    // Add exact code matches first
    for (final buildingName in concordiaBuildingNames) {
      if (buildingName.code.toLowerCase() == normalizedQuery) {
        suggestions.add(buildingName);
      }
    }

    // Add exact name matches
    for (final buildingName in concordiaBuildingNames) {
      if (buildingName.name.toLowerCase() == normalizedQuery &&
          !suggestions.contains(buildingName)) {
        suggestions.add(buildingName);
      }
    }

    // Add partial matches
    for (final buildingName in concordiaBuildingNames) {
      if ((buildingName.code.toLowerCase().contains(normalizedQuery) ||
              buildingName.name.toLowerCase().contains(normalizedQuery)) &&
          !suggestions.contains(buildingName)) {
        suggestions.add(buildingName);
      }
    }

    // Add search term matches
    for (final buildingName in concordiaBuildingNames) {
      for (final term in buildingName.searchTerms) {
        if ((term.toLowerCase().contains(normalizedQuery) ||
                normalizedQuery.contains(term.toLowerCase())) &&
            !suggestions.contains(buildingName)) {
          suggestions.add(buildingName);
          break;
        }
      }
    }

    return suggestions;
  }

  /// Get combined suggestions from Concordia buildings and Google Places
  /// Returns a list of SearchSuggestion objects
  static Future<List<SearchSuggestion>> getCombinedSuggestions(
    String query, {
    LatLng? userLocation,
  }) async {
    final suggestions = <SearchSuggestion>[];

    if (query.trim().isEmpty) {
      // Return only Concordia buildings when query is empty
      return concordiaBuildingNames
          .take(10)
          .map((building) => SearchSuggestion.fromConcordiaBuilding(building))
          .toList();
    }

    print('Getting combined suggestions for: $query');

    // Get Concordia building suggestions
    final concordiaSuggestions = getSuggestions(query);
    print('Found ${concordiaSuggestions.length} Concordia building suggestions');
    for (final building in concordiaSuggestions.take(5)) {
      suggestions.add(SearchSuggestion.fromConcordiaBuilding(building));
    }

    // Get Google Places autocomplete predictions
    try {
      final placePredictions = await GooglePlacesService.getAutocompletePredictions(
        query,
        location: userLocation,
        radius: 5000,
      );

      print('Received ${placePredictions.length} Google Places predictions');
      
      for (final prediction in placePredictions.take(5)) {
        suggestions.add(SearchSuggestion.fromGooglePlace(
          name: prediction.mainText,
          subtitle: prediction.secondaryText,
          placeId: prediction.placeId,
        ));
      }
    } catch (e) {
      print('Error getting Google Places predictions: $e');
    }

    print('Total suggestions: ${suggestions.length}');
    return suggestions;
  }

  /// Find building polygon by code
  static BuildingPolygon? _findBuildingByCode(String code) {
    try {
      return buildingPolygons.firstWhere(
        (building) => building.code == code,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get building name by code
  static String? getBuildingNameByCode(String code) {
    try {
      final buildingName = concordiaBuildingNames.firstWhere(
        (building) => building.code == code,
      );
      return buildingName.name;
    } catch (e) {
      return null;
    }
  }
}
