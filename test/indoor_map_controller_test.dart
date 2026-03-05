import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/services/indoor_maps/indoor_map_controller.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';

class FakeIndoorMapRepository implements IndoorMapRepository {
  final Map<String, dynamic> geoJsonToReturn;

  FakeIndoorMapRepository(this.geoJsonToReturn);

  @override
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    // Simulate async load
    return geoJsonToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IndoorMapController', () {
    test('floorsForBuilding returns a list (smoke test)', () {
      final controller = IndoorMapController(repo: FakeIndoorMapRepository(_simpleGeoJson()));

      final floors = controller.floorsForBuilding('H');
      expect(floors, isA<List>());
    });

    test('loadFloor returns polygons, labels, and geoJson from repo', () async {
      final geo = _simpleGeoJson();
      final controller = IndoorMapController(repo: FakeIndoorMapRepository(geo));

      final result = await controller.loadFloor('assets/fake_floor.geojson');

      // 1) geoJson returned unchanged
      expect(result.geoJson, same(geo));

      // 2) polygons created
      expect(result.polygons, isNotEmpty);
      final firstPoly = result.polygons.first;
      expect(firstPoly.polygonId.value, startsWith('indoor-'));
      expect(firstPoly.points.length, greaterThanOrEqualTo(3));

      // 3) labels created (because ref exists and polygon area isn't tiny)
      expect(result.labels, isNotEmpty);
      final firstMarker = result.labels.first;
      expect(firstMarker.markerId.value, contains('room-label'));
    });

    test('loadFloor skips non-polygon geometries (no crash)', () async {
      final geo = _geoJsonWithNonPolygonFeature();
      final controller = IndoorMapController(repo: FakeIndoorMapRepository(geo));

      final result = await controller.loadFloor('assets/fake.geojson');

      // Only the Polygon feature should produce a polygon
      expect(result.polygons.length, equals(1));
    });

    test('loadFloor produces 0 labels when ref is missing', () async {
      final geo = _geoJsonWithoutRef();
      final controller = IndoorMapController(repo: FakeIndoorMapRepository(geo));

      final result = await controller.loadFloor('assets/fake.geojson');

      expect(result.polygons, isNotEmpty);
      expect(result.labels, isEmpty);
    });
  });
}

/// A minimal GeoJSON that should generate:
/// - 1 polygon (geometry type Polygon)
/// - 1 label (has "ref" + polygon area not tiny)
Map<String, dynamic> _simpleGeoJson() {
  return {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": {
          "ref": "H-801",
          "indoor": "room",
        },
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [-73.5789, 45.4973],
              [-73.5788, 45.4973],
              [-73.5788, 45.4974],
              [-73.5789, 45.4974],
              [-73.5789, 45.4973],
            ]
          ]
        }
      }
    ]
  };
}

Map<String, dynamic> _geoJsonWithNonPolygonFeature() {
  return {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": {"name": "ignore me"},
        "geometry": {
          "type": "Point",
          "coordinates": [-73.0, 45.0]
        }
      },
      {
        "type": "Feature",
        "properties": {"ref": "X-1"},
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [-73.0, 45.0],
              [-73.0, 45.1],
              [-73.1, 45.1],
              [-73.1, 45.0],
              [-73.0, 45.0],
            ]
          ]
        }
      }
    ]
  };
}

Map<String, dynamic> _geoJsonWithoutRef() {
  return {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": {
          // no "ref"
          "indoor": "room",
        },
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [-73.5789, 45.4973],
              [-73.5788, 45.4973],
              [-73.5788, 45.4974],
              [-73.5789, 45.4974],
              [-73.5789, 45.4973],
            ]
          ]
        }
      }
    ]
  };
}