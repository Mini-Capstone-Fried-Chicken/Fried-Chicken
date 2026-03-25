import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../indoors_routing/core/indoor_route_plan_models.dart';
import 'indoor_floor_config.dart';

/// Handles building code aliases (ex: H -> HALL)
const Map<String, String> _buildingCodeAliases = {'H': 'HALL'};

String _normalizeBuildingCode(String code) {
  final upper = code.toUpperCase().trim();
  return _buildingCodeAliases[upper] ?? upper;
}

class IndoorMapRepository {
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @visibleForTesting
  List<String> getAssetPathsForBuilding(String buildingCode) {
    final code = _normalizeBuildingCode(buildingCode);
    return IndoorFloorConfig.floorsForBuilding(
      code,
    ).map((floor) => floor.assetPath).toList(growable: false);
  }

  List<IndoorFloorOption> getFloorOptionsForBuilding(String buildingCode) {
    return IndoorFloorConfig.floorsForBuilding(
      _normalizeBuildingCode(buildingCode),
    );
  }

  Future<List<(IndoorFloorOption option, Map<String, dynamic> geoJson)>>
  loadFloorsForBuilding(String buildingCode) async {
    final floors = getFloorOptionsForBuilding(buildingCode);
    final loaded = <(IndoorFloorOption, Map<String, dynamic>)>[];

    for (final floor in floors) {
      try {
        final geoJson = await loadGeoJsonAsset(floor.assetPath);
        loaded.add((floor, geoJson));
      } catch (_) {
        continue;
      }
    }

    return loaded;
  }

  @visibleForTesting
  List<String> extractRoomCodesFromGeoJson(Map<String, dynamic> geoJson) {
    final rooms = <String>[];
    final features = geoJson['features'] as List?;
    if (features == null) return rooms;

    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;

      final props = feature['properties'];
      if (props is! Map<String, dynamic>) continue;

      final roomCode = props['ref']?.toString();
      if (roomCode != null && roomCode.isNotEmpty) {
        rooms.add(roomCode.toUpperCase());
      }
    }

    return rooms;
  }

  Future<List<String>> getRoomCodesForBuilding(String buildingCode) async {
    final rooms = <String>{};

    for (final loadedFloor in await loadFloorsForBuilding(buildingCode)) {
      rooms.addAll(extractRoomCodesFromGeoJson(loadedFloor.$2));
    }

    return rooms.toList();
  }

  Future<bool> roomExists(String buildingCode, String roomCode) async {
    final validRooms = await getRoomCodesForBuilding(buildingCode);
    return validRooms.contains(roomCode.toUpperCase());
  }

  @visibleForTesting
  List<List<double>>? extractPolygonCoordinates(Map<String, dynamic> feature) {
    try {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) return null;

      final geometryType = geometry['type'] as String?;
      if (geometryType != 'Polygon') return null;

      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) return null;

      final outerRing = coordinates[0] as List;
      return outerRing.map((c) {
        final list = c as List;
        return [(list[0] as num).toDouble(), (list[1] as num).toDouble()];
      }).toList();
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  LatLng calculatePolygonCenter(List<List<double>> coordinates) {
    if (coordinates.isEmpty) return const LatLng(0, 0);

    double lat = 0;
    double lng = 0;

    for (final coord in coordinates) {
      if (coord.length >= 2) {
        lng += coord[0];
        lat += coord[1];
      }
    }

    final count = coordinates.length;
    return LatLng(lat / count, lng / count);
  }

  Future<LatLng?> getRoomLocation(String buildingCode, String roomCode) async {
    return (await resolveRoom(buildingCode, roomCode))?.center;
  }

  Future<IndoorResolvedRoom?> resolveRoom(
    String buildingCode,
    String roomCode,
  ) async {
    final normalizedBuildingCode = _normalizeBuildingCode(buildingCode);
    final searchCode = roomCode.toUpperCase().trim();

    for (final loadedFloor in await loadFloorsForBuilding(
      normalizedBuildingCode,
    )) {
      final option = loadedFloor.$1;
      final geoJson = loadedFloor.$2;
      final features = geoJson['features'] as List?;
      if (features == null) continue;

      final location = _findRoomLocationInFeatures(features, searchCode);
      if (location == null) continue;

      final floorLevel =
          _extractFloorLevel(features) ??
          IndoorFloorConfig.normalizeFloorLabel(option.label);

      return IndoorResolvedRoom(
        buildingCode: normalizedBuildingCode,
        roomCode: searchCode,
        floorLabel: option.label,
        floorLevel: floorLevel,
        floorAssetPath: option.assetPath,
        floorGeoJson: geoJson,
        center: location,
      );
    }

    return null;
  }

  @visibleForTesting
  LatLng? findRoomLocationInFeatures(
    List<dynamic> features,
    String searchCode,
  ) {
    return _findRoomLocationInFeatures(features, searchCode);
  }

  LatLng? _findRoomLocationInFeatures(
    List<dynamic> features,
    String searchCode,
  ) {
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;

      final props = feature['properties'];
      if (props is! Map<String, dynamic>) continue;

      final roomRefCode = props['ref']?.toString().toUpperCase();
      if (roomRefCode == searchCode) {
        final coords = extractPolygonCoordinates(feature);
        if (coords != null && coords.isNotEmpty) {
          return calculatePolygonCenter(coords);
        }
      }
    }

    return null;
  }

  String? _extractFloorLevel(List<dynamic> features) {
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) {
        _logMalformedFeature('_extractFloorLevel: feature is not a map');
        continue;
      }

      final props = feature['properties'];
      if (props is! Map<String, dynamic>) {
        _logMalformedFeature(
          '_extractFloorLevel: properties missing or malformed',
        );
        continue;
      }

      final trimmedLevel = _trimmedNonEmpty(props['level']);
      if (trimmedLevel != null) {
        return trimmedLevel;
      }
    }

    return null;
  }

  String? _trimmedNonEmpty(Object? value) {
    final trimmed = value?.toString().trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  void _logMalformedFeature(String message) {
    if (kDebugMode) {
      debugPrint('IndoorMapRepository: $message');
    }
  }
}
