import '../data/building_names.dart';
import '../data/building_polygons.dart';
import '../data/search_result.dart';
import '../data/search_suggestion.dart';
import 'google_places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef BuildingMatcher = BuildingPolygon? Function(String normalizedQuery);

/// Service for searching buildings using Google Places API and Concordia building data
class BuildingSearchService {
  static final List<BuildingMatcher> _exactBuildingMatchers = [
    _findExactCodeMatch,
    _findExactNameMatch,
    _findExactSearchTermMatch,
  ];

  static const BuildingMatcher _partialBuildingMatcher =
      _findPartialSearchTermMatch;

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
    final placesResults = await GooglePlacesService.instance.searchPlaces(
      query,
      location: userLocation,
      radius: 5000,
    );

    final results = <SearchResult>[];

    for (final place in placesResults) {
      // Check if this place is a Concordia building
      final concordiaBuilding = _findBuildingByLocation(place.location);
      final isConcordia = concordiaBuilding != null;

      results.add(
        SearchResult.fromGooglePlace(
          name: place.name,
          address: place.formattedAddress,
          location: place.location,
          isConcordiaBuilding: isConcordia,
          buildingPolygon: concordiaBuilding,
          placeId: place.placeId,
        ),
      );
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

  /// Search for a building by query string (prioritize exact matches, allow partial for search terms)
  /// Returns the matching BuildingPolygon if found, null otherwise
  /// This method prioritizes exact matches to avoid false positives like "Hall's Restaurant" matching "Hall Building"
  static BuildingPolygon? searchBuilding(String query) {
    if (query.trim().isEmpty) {
      return null;
    }

    final normalizedQuery = query.toLowerCase().trim();

    for (final matcher in _exactBuildingMatchers) {
      final match = matcher(normalizedQuery);
      if (match != null) {
        return match;
      }
    }

    if (normalizedQuery.length < 3) {
      return null;
    }

    final partialMatch = _partialBuildingMatcher(normalizedQuery);
    if (partialMatch != null) {
      return partialMatch;
    }

    return null;
  }

  static BuildingPolygon? _findExactCodeMatch(String normalizedQuery) {
    for (final buildingName in concordiaBuildingNames) {
      final normalizedCode = buildingName.code.toLowerCase();
      if (normalizedCode == normalizedQuery) {
        return _findBuildingByCode(buildingName.code);
      }
    }
    return null;
  }

  static BuildingPolygon? _findExactNameMatch(String normalizedQuery) {
    for (final buildingName in concordiaBuildingNames) {
      final normalizedName = buildingName.name.toLowerCase();
      if (normalizedName == normalizedQuery) {
        return _findBuildingByCode(buildingName.code);
      }
    }
    return null;
  }

  static BuildingPolygon? _findExactSearchTermMatch(String normalizedQuery) {
    for (final buildingName in concordiaBuildingNames) {
      for (final term in buildingName.searchTerms) {
        final normalizedTerm = term.toLowerCase();
        if (normalizedTerm == normalizedQuery) {
          return _findBuildingByCode(buildingName.code);
        }
      }
    }
    return null;
  }

  static BuildingPolygon? _findPartialSearchTermMatch(String normalizedQuery) {
    for (final buildingName in concordiaBuildingNames) {
      for (final term in buildingName.searchTerms) {
        final normalizedTerm = term.toLowerCase();
        if (normalizedTerm.startsWith(normalizedQuery) ||
            normalizedTerm.contains(normalizedQuery)) {
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

    _addExactCodeSuggestions(normalizedQuery, suggestions);
    _addExactNameSuggestions(normalizedQuery, suggestions);
    _addPartialCodeOrNameSuggestions(normalizedQuery, suggestions);
    _addSearchTermSuggestions(normalizedQuery, suggestions);

    return suggestions;
  }

  static void _addExactCodeSuggestions(
    String normalizedQuery,
    List<BuildingName> suggestions,
  ) {
    for (final buildingName in concordiaBuildingNames) {
      final normalizedCode = buildingName.code.toLowerCase();
      if (normalizedCode == normalizedQuery) {
        _addUniqueSuggestion(buildingName, suggestions);
      }
    }
  }

  static void _addExactNameSuggestions(
    String normalizedQuery,
    List<BuildingName> suggestions,
  ) {
    for (final buildingName in concordiaBuildingNames) {
      final normalizedName = buildingName.name.toLowerCase();
      if (normalizedName == normalizedQuery) {
        _addUniqueSuggestion(buildingName, suggestions);
      }
    }
  }

  static void _addPartialCodeOrNameSuggestions(
    String normalizedQuery,
    List<BuildingName> suggestions,
  ) {
    for (final buildingName in concordiaBuildingNames) {
      final normalizedCode = buildingName.code.toLowerCase();
      final normalizedName = buildingName.name.toLowerCase();
      final codeMatches = normalizedCode.contains(normalizedQuery);
      final nameMatches = normalizedName.contains(normalizedQuery);
      if (codeMatches || nameMatches) {
        _addUniqueSuggestion(buildingName, suggestions);
      }
    }
  }

  static void _addSearchTermSuggestions(
    String normalizedQuery,
    List<BuildingName> suggestions,
  ) {
    for (final buildingName in concordiaBuildingNames) {
      if (_hasMatchingSearchTerm(buildingName, normalizedQuery)) {
        _addUniqueSuggestion(buildingName, suggestions);
      }
    }
  }

  static bool _hasMatchingSearchTerm(
    BuildingName buildingName,
    String normalizedQuery,
  ) {
    for (final term in buildingName.searchTerms) {
      final normalizedTerm = term.toLowerCase();
      if (normalizedTerm.contains(normalizedQuery) ||
          normalizedQuery.contains(normalizedTerm)) {
        return true;
      }
    }
    return false;
  }

  static void _addUniqueSuggestion(
    BuildingName buildingName,
    List<BuildingName> suggestions,
  ) {
    if (!suggestions.contains(buildingName)) {
      suggestions.add(buildingName);
    }
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

    print('[DEBUG] Getting combined suggestions for: $query');

    // Get Concordia building suggestions
    final concordiaSuggestions = getSuggestions(query);
    print(
      '[DEBUG] Found ${concordiaSuggestions.length} Concordia building suggestions',
    );
    for (final building in concordiaSuggestions.take(2)) {
      suggestions.add(SearchSuggestion.fromConcordiaBuilding(building));
    }

    // Get Google Places autocomplete predictions
    try {
      final placePredictions = await GooglePlacesService.instance
          .getAutocompletePredictions(
            query,
            location: userLocation,
            radius: 5000,
          );

      print(
        '[DEBUG] Received ${placePredictions.length} Google Places predictions',
      );

      for (final prediction in placePredictions) {
        print(
          '[DEBUG] Adding place: ${prediction.mainText} - ${prediction.secondaryText}',
        );
        suggestions.add(
          SearchSuggestion.fromGooglePlace(
            name: prediction.mainText,
            subtitle: prediction.secondaryText,
            placeId: prediction.placeId,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Error getting Google Places predictions: $e');
    }

    print('[DEBUG] Total suggestions: ${suggestions.length}');
    return suggestions;
  }

  /// Find building polygon by code
  static BuildingPolygon? _findBuildingByCode(String code) {
    try {
      return buildingPolygons.firstWhere((building) => building.code == code);
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
