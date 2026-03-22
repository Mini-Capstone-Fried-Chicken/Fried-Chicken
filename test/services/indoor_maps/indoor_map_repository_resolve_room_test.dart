import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndoorMapRepository room resolution helpers', () {
    test(
      'getFloorOptionsForBuilding resolves aliases through IndoorFloorConfig',
      () {
        final repository = IndoorMapRepository();

        final hallFloors = repository.getFloorOptionsForBuilding('h');

        expect(hallFloors, isNotEmpty);
        expect(hallFloors, equals(IndoorFloorConfig.floorsForBuilding('HALL')));
      },
    );

    test(
      'loadFloorsForBuilding returns only successfully loaded floors',
      () async {
        final repository = _FakeFloorLoadingRepository(
          options: const [
            IndoorFloorOption(label: '8', assetPath: 'floor_8'),
            IndoorFloorOption(label: '9', assetPath: 'floor_9'),
          ],
          geoJsonByAssetPath: {
            'floor_8': _floorGeoJson(ref: 'A801', level: '8'),
          },
        );

        final floors = await repository.loadFloorsForBuilding('HALL');

        expect(floors, hasLength(1));
        expect(floors.single.$1.label, '8');
        expect(floors.single.$2['features'], isNotEmpty);
      },
    );

    test(
      'resolveRoom returns populated room metadata with normalized building code',
      () async {
        final repository = _FakeFloorLoadingRepository(
          options: const [
            IndoorFloorOption(label: 'S2', assetPath: 'floor_s2'),
          ],
          geoJsonByAssetPath: {
            'floor_s2': _floorGeoJson(ref: 'MB-S2-101', level: '-2'),
          },
        );

        final room = await repository.resolveRoom('mb', 'mb-s2-101');

        expect(room, isNotNull);
        expect(room!.buildingCode, 'MB');
        expect(room.roomCode, 'MB-S2-101');
        expect(room.floorLabel, 'S2');
        expect(room.floorLevel, '-2');
        expect(room.floorAssetPath, 'floor_s2');
      },
    );

    test(
      'resolveRoom falls back to normalized floor label when level metadata is absent',
      () async {
        final repository = _FakeFloorLoadingRepository(
          options: const [
            IndoorFloorOption(label: 'S2', assetPath: 'floor_s2'),
          ],
          geoJsonByAssetPath: {'floor_s2': _floorGeoJson(ref: 'MB-S2-101')},
        );

        final room = await repository.resolveRoom('MB', 'MB-S2-101');

        expect(room, isNotNull);
        expect(room!.floorLevel, '-2');
      },
    );

    test(
      'resolveRoom trims floor level and skips malformed features while scanning',
      () async {
        final repository = _FakeFloorLoadingRepository(
          options: const [IndoorFloorOption(label: '9', assetPath: 'floor_9')],
          geoJsonByAssetPath: {
            'floor_9': {
              'type': 'FeatureCollection',
              'features': [
                'not-a-map',
                {
                  'type': 'Feature',
                  'properties': {'level': '   '},
                  'geometry': {
                    'type': 'Polygon',
                    'coordinates': [
                      [
                        [-73.10000, 45.10000],
                        [-73.09995, 45.10000],
                        [-73.09995, 45.10005],
                        [-73.10000, 45.10005],
                        [-73.10000, 45.10000],
                      ],
                    ],
                  },
                },
                _roomFeature(ref: 'H-900', level: ' 9 '),
              ],
            },
          },
        );

        final room = await repository.resolveRoom('HALL', 'H-900');

        expect(room, isNotNull);
        expect(room!.floorLevel, '9');
      },
    );

    test('resolveRoom returns null when the room does not exist', () async {
      final repository = _FakeFloorLoadingRepository(
        options: const [IndoorFloorOption(label: '8', assetPath: 'floor_8')],
        geoJsonByAssetPath: {'floor_8': _floorGeoJson(ref: 'A801', level: '8')},
      );

      final room = await repository.resolveRoom('HALL', 'UNKNOWN');

      expect(room, isNull);
    });
  });
}

class _FakeFloorLoadingRepository extends IndoorMapRepository {
  final List<IndoorFloorOption> options;
  final Map<String, Map<String, dynamic>> geoJsonByAssetPath;

  _FakeFloorLoadingRepository({
    required this.options,
    required this.geoJsonByAssetPath,
  });

  @override
  List<IndoorFloorOption> getFloorOptionsForBuilding(String buildingCode) {
    return options;
  }

  @override
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    final geoJson = geoJsonByAssetPath[assetPath];
    if (geoJson == null) {
      throw Exception('missing asset');
    }
    return geoJson;
  }
}

Map<String, dynamic> _floorGeoJson({required String ref, String? level}) {
  return {
    'type': 'FeatureCollection',
    'features': [_roomFeature(ref: ref, level: level)],
  };
}

Map<String, dynamic> _roomFeature({required String ref, String? level}) {
  return {
    'type': 'Feature',
    'properties': {
      'indoor': 'room',
      'ref': ref,
      if (level != null) 'level': level,
    },
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        [
          [-73.00000, 45.00000],
          [-72.99995, 45.00000],
          [-72.99995, 45.00005],
          [-73.00000, 45.00005],
          [-73.00000, 45.00000],
        ],
      ],
    },
  };
}
