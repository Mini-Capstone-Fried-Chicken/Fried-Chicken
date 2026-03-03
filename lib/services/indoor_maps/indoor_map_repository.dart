import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class IndoorMapRepository {
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Get all asset paths for a building (all floor files)
  List<String> getAssetPathsForBuilding(String buildingCode) {
    final upperCode = buildingCode.toUpperCase();

    print(
      '[DEBUG] getAssetPathsForBuilding called with: "$buildingCode" -> uppercase: "$upperCode"',
    );

    const pathMap = {
      'HALL': [
        'assets/indoor_maps/geojson/Hall/h1.geojson.json',
        'assets/indoor_maps/geojson/Hall/h2.geojson.json',
        'assets/indoor_maps/geojson/Hall/h8.geojson.json',
        'assets/indoor_maps/geojson/Hall/h9.geojson.json',
      ],
      'MB': ['assets/indoor_maps/geojson/MB/mb1.geojson.json'],
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

    final paths = pathMap[upperCode] ?? [];
    print(
      '[DEBUG] Found ${paths.length} asset paths for building "$upperCode"',
    );
    if (paths.isNotEmpty) {
      print('[DEBUG] Asset paths: $paths');
    }

    return paths;
  }

  /// Extract all valid room codes from a building's GeoJSON files
  Future<List<String>> getRoomCodesForBuilding(String buildingCode) async {
    try {
      final assetPaths = getAssetPathsForBuilding(buildingCode);
      if (assetPaths.isEmpty) {
        print('[DEBUG] No asset paths found for building: $buildingCode');
        return [];
      }

      final rooms = <String>[];

      // Load all floor files for this building
      for (final assetPath in assetPaths) {
        try {
          print('[DEBUG] Loading GeoJSON from: $assetPath');
          final geoJson = await loadGeoJsonAsset(assetPath);
          print('[DEBUG] Successfully loaded GeoJSON');

          final features = geoJson['features'] as List?;
          print('[DEBUG] Features count: ${features?.length ?? 0}');

          if (features == null) {
            print('[WARNING] No features found in $assetPath');
            continue;
          }

          int roomsInThisFile = 0;
          for (final feature in features) {
            try {
              // Feature is already a Map from JSON decode
              final featureMap = feature as Map<String, dynamic>;
              final props = featureMap['properties'] as Map<String, dynamic>?;

              if (props == null) continue;

              final roomCode = props['ref']?.toString();

              if (roomCode != null && roomCode.isNotEmpty) {
                rooms.add(roomCode);
                roomsInThisFile++;
              }
            } catch (e) {
              // Skip features that can't be parsed
              continue;
            }
          }
          print('[DEBUG] Found $roomsInThisFile rooms in $assetPath');
        } catch (e) {
          print('[WARNING] Failed to load floor file $assetPath: $e');
          // Continue with next floor file
          continue;
        }
      }

      print('[DEBUG] Total rooms loaded: ${rooms.length}');
      return rooms;
    } catch (e) {
      print('[ERROR] Failed to extract room codes: $e');
      return [];
    }
  }

  /// Check if a room exists in a building
  Future<bool> roomExists(String buildingCode, String roomCode) async {
    try {
      final validRooms = await getRoomCodesForBuilding(buildingCode);
      final searchCode = roomCode.toUpperCase();

      print(
        '[DEBUG] Validating room: "$roomCode" (uppercase: "$searchCode") in building: "$buildingCode"',
      );
      print('[DEBUG] Valid rooms count: ${validRooms.length}');
      if (validRooms.length <= 20) {
        print('[DEBUG] Valid rooms: $validRooms');
      }

      final exists = validRooms.contains(searchCode);
      print('[DEBUG] Room exists result: $exists');

      return exists;
    } catch (e) {
      print('[ERROR] Failed to validate room: $e');
      return false;
    }
  }

  /// Calculate the center point (centroid) of a polygon
  LatLng _calculatePolygonCenter(List<List<double>> coordinates) {
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
    try {
      final assetPaths = getAssetPathsForBuilding(buildingCode);
      if (assetPaths.isEmpty) {
        print('[DEBUG] No asset paths found for building: $buildingCode');
        return null;
      }

      final searchCode = roomCode.toUpperCase();

      // Search through all floor files
      for (final assetPath in assetPaths) {
        try {
          final geoJson = await loadGeoJsonAsset(assetPath);
          final features = geoJson['features'] as List?;

          if (features == null) continue;

          // Look for the room in this floor
          for (final feature in features) {
            try {
              final featureMap = feature as Map<String, dynamic>;
              final props = featureMap['properties'] as Map<String, dynamic>?;

              if (props == null) continue;

              final roomRefCode = props['ref']?.toString().toUpperCase();

              // Found the room!
              if (roomRefCode == searchCode) {
                final geometry =
                    featureMap['geometry'] as Map<String, dynamic>?;
                if (geometry == null) continue;

                final geometryType = geometry['type'] as String?;

                // Handle Polygon geometry
                if (geometryType == 'Polygon') {
                  final coordinates = geometry['coordinates'] as List?;
                  if (coordinates != null && coordinates.isNotEmpty) {
                    final outerRing = coordinates[0] as List;
                    final coords = outerRing.map((c) {
                      final list = c as List;
                      return [
                        (list[0] as num).toDouble(),
                        (list[1] as num).toDouble(),
                      ];
                    }).toList();

                    final center = _calculatePolygonCenter(coords);
                    print('[DEBUG] Found room $roomCode at $center');
                    return center;
                  }
                }
              }
            } catch (e) {
              // Skip features that can't be parsed
              continue;
            }
          }
        } catch (e) {
          print('[WARNING] Failed to search floor file $assetPath: $e');
          continue;
        }
      }

      print('[DEBUG] Room $roomCode not found in building $buildingCode');
      return null;
    } catch (e) {
      print('[ERROR] Failed to get room location: $e');
      return null;
    }
  }
}
