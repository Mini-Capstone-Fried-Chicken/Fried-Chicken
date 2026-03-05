import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Maps building codes to their indoor map asset paths (by floor)
const Map<String, List<String>> _buildingAssetPaths = {
  'HALL': [
    'assets/indoor_maps/geojson/Hall/h1.geojson.json',
    'assets/indoor_maps/geojson/Hall/h2.geojson.json',
    'assets/indoor_maps/geojson/Hall/h8.geojson.json',
    'assets/indoor_maps/geojson/Hall/h9.geojson.json',
  ],
  'MB': [
    'assets/indoor_maps/geojson/MB/mb1.geojson.json',
    'assets/indoor_maps/geojson/MB/mbS2.geojson.json',
  ],
  'VE': [
    'assets/indoor_maps/geojson/VE/ve1.geojson.json',
    'assets/indoor_maps/geojson/VE/ve2.geojson.json',
  ],
  'VL': [
    'assets/indoor_maps/geojson/VL/vl1.geojson.json',
    'assets/indoor_maps/geojson/VL/vl2.geojson.json',
  ],
  'CC': ['assets/indoor_maps/geojson/CC/cc1.geojson.json'],
};

class IndoorMapRepository {
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @visibleForTesting
  List<String> getAssetPathsForBuilding(String buildingCode) {
    final upperCode = buildingCode.toUpperCase();
    return _buildingAssetPaths[upperCode] ?? [];
  }

  @visibleForTesting
  List<String> extractRoomCodesFromGeoJson(Map<String, dynamic> geoJson) {
    final rooms = <String>[];
    final features = geoJson['features'] as List?;
    if (features == null) return rooms;
    for (final feature in features) {
      try {
        final featureMap = feature as Map<String, dynamic>;
        final props = featureMap['properties'] as Map<String, dynamic>?;
        if (props == null) continue;
        final roomCode = props['ref']?.toString();
        if (roomCode != null && roomCode.isNotEmpty) {
          rooms.add(roomCode.toUpperCase());
        }
      } catch (e) {
        continue;
      }
    }

    return rooms;
  }

  Future<List<String>> getRoomCodesForBuilding(String buildingCode) async {
    final assetPaths = getAssetPathsForBuilding(buildingCode);
    if (assetPaths.isEmpty) return [];
    final rooms = <String>{};
    for (final assetPath in assetPaths) {
      try {
        final geoJson = await loadGeoJsonAsset(assetPath);
        final roomsInFloor = extractRoomCodesFromGeoJson(geoJson);
        rooms.addAll(roomsInFloor);
      } catch (e) {
        continue;
      }
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
    } catch (e) {
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

  /// Get the location (center coordinates) of a specific room in a building
  Future<LatLng?> getRoomLocation(String buildingCode, String roomCode) async {
    final assetPaths = getAssetPathsForBuilding(buildingCode);
    if (assetPaths.isEmpty) {
      print('[DEBUG] No asset paths found for building: $buildingCode');
      return null;
    }

    final searchCode = roomCode.toUpperCase();
    print('[DEBUG] Searching for room: $searchCode in $buildingCode');

    for (final assetPath in assetPaths) {
      try {
        final geoJson = await loadGeoJsonAsset(assetPath);
        final features = geoJson['features'] as List?;
        if (features == null) continue;

        final location = _findRoomLocationInFeatures(features, searchCode);
        if (location != null) {
          print('[DEBUG] Room $searchCode found at: $location');
          return location;
        }
      } catch (e) {
        print('[ERROR] Error loading asset $assetPath: $e');
        continue;
      }
    }

    print('[ERROR] Room $searchCode not found in $buildingCode');
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
      try {
        final featureMap = feature as Map<String, dynamic>;
        final props = featureMap['properties'] as Map<String, dynamic>?;

        if (props == null) continue;

        final roomRefCode = props['ref']?.toString().toUpperCase();
        if (roomRefCode == searchCode) {
          final coords = extractPolygonCoordinates(featureMap);
          if (coords != null && coords.isNotEmpty) {
            return calculatePolygonCenter(coords);
          }
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }
}
