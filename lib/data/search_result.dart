import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/building_polygons.dart';

/// Represents a search result that can be either a Concordia building or a general place
class SearchResult {
  final String name;
  final String? address;
  final LatLng location;
  final bool isConcordiaBuilding;
  final BuildingPolygon? buildingPolygon;
  final String? placeId;

  const SearchResult({
    required this.name,
    this.address,
    required this.location,
    required this.isConcordiaBuilding,
    this.buildingPolygon,
    this.placeId,
  });

  /// Create a SearchResult from a Concordia building
  factory SearchResult.fromConcordiaBuilding(BuildingPolygon building) {
    return SearchResult(
      name: building.name,
      location: building.center,
      isConcordiaBuilding: true,
      buildingPolygon: building,
    );
  }

  /// Create a SearchResult from a Google place
  factory SearchResult.fromGooglePlace({
    required String name,
    String? address,
    required LatLng location,
    required bool isConcordiaBuilding,
    BuildingPolygon? buildingPolygon,
    String? placeId,
  }) {
    return SearchResult(
      name: name,
      address: address,
      location: location,
      isConcordiaBuilding: isConcordiaBuilding,
      buildingPolygon: buildingPolygon,
      placeId: placeId,
    );
  }
}
