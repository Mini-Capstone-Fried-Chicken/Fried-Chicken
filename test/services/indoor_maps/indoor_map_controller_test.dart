import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/services/indoor_maps/indoor_map_controller.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';
import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart';

class FakeIndoorMapRepository extends IndoorMapRepository {
  final Map<String, dynamic> fakeGeoJson;

  FakeIndoorMapRepository(this.fakeGeoJson);

  @override
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    return fakeGeoJson;
  }
}

Map<String, dynamic> _simpleGeoJson() {
  return {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': {
          'ref': 'H-920',
        },
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-73.5790, 45.4970],
              [-73.5788, 45.4970],
              [-73.5788, 45.4972],
              [-73.5790, 45.4972],
              [-73.5790, 45.4970],
            ]
          ],
        },
      },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IndoorMapController', () {
    test('floorsForBuilding returns floors for known building', () {
      final controller = IndoorMapController();

      final floors = controller.floorsForBuilding('HALL');

      expect(floors, isA<List<IndoorFloorOption>>());
      expect(floors, isNotEmpty);
    });

    test('floorsForBuilding returns empty list for unknown building', () {
      final controller = IndoorMapController();

      final floors = controller.floorsForBuilding('UNKNOWN_BUILDING');

      expect(floors, isEmpty);
    });

    test('loadFloor returns geoJson, polygons, and labels', () async {
      final controller = IndoorMapController(
        repo: FakeIndoorMapRepository(_simpleGeoJson()),
      );

      final result = await controller.loadFloor('fake/path.geojson');

      expect(result.geoJson['type'], equals('FeatureCollection'));
      expect(result.polygons, isNotEmpty);
      expect(result.labels, isNotEmpty);

      expect(result.polygons.first, isA<Polygon>());
      expect(result.labels.first, isA<Marker>());
    });
  });
}