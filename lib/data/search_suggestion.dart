import 'building_names.dart';

/// Represents a search suggestion that can be either a Concordia building or a general place
class SearchSuggestion {
  final String name;
  final String? subtitle;
  final bool isConcordiaBuilding;
  final BuildingName? buildingName;
  final String? placeId;

  const SearchSuggestion({
    required this.name,
    this.subtitle,
    required this.isConcordiaBuilding,
    this.buildingName,
    this.placeId,
  });

  /// Create a suggestion from a Concordia building
  factory SearchSuggestion.fromConcordiaBuilding(BuildingName building) {
    return SearchSuggestion(
      name: building.name,
      subtitle: building.code,
      isConcordiaBuilding: true,
      buildingName: building,
    );
  }

  /// Create a suggestion from a Google place (autocomplete result)
  factory SearchSuggestion.fromGooglePlace({
    required String name,
    String? subtitle,
    String? placeId,
  }) {
    return SearchSuggestion(
      name: name,
      subtitle: subtitle,
      isConcordiaBuilding: false,
      placeId: placeId,
    );
  }
}
