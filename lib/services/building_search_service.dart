import '../data/building_names.dart';
import '../data/building_polygons.dart';

/// Service for searching Concordia buildings by name or code
class BuildingSearchService {
  /// Search for a building by query string
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
