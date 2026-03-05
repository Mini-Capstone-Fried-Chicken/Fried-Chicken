import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'indoor_floor_config.dart';
import 'indoor_geojson_renderer.dart';
import 'indoor_map_repository.dart';

class IndoorLoadResult {
  final Set<Polygon> polygons;
  final Set<Marker> labels;
  final Map<String, dynamic> geoJson;

  IndoorLoadResult({
    required this.polygons,
    required this.labels,
    required this.geoJson,
  });
}

class IndoorMapController {
  final IndoorMapRepository _repo;

  IndoorMapController({IndoorMapRepository? repo})
      : _repo = repo ?? IndoorMapRepository();

  List<IndoorFloorOption> floorsForBuilding(String buildingCode) {
    return IndoorFloorConfig.floorsForBuilding(buildingCode);
  }

  Future<IndoorLoadResult> loadFloor(String assetPath) async {
    final geo = await _repo.loadGeoJsonAsset(assetPath);
    final polygons = IndoorGeoJsonRenderer.geoJsonToPolygons(geo);
    final labels = await IndoorGeoJsonRenderer.createRoomLabels(geo);

    return IndoorLoadResult(polygons: polygons, labels: labels, geoJson: geo);
  }
}