import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';

class TestIndoorMapRepository extends IndoorMapRepository {
  final List<String> mockedPaths;
  TestIndoorMapRepository(this.mockedPaths);
  @override
  List<String> getAssetPathsForBuilding(String buildingCode) {
    return mockedPaths;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IndoorMapRepository repository;

  setUp(() {
    repository = IndoorMapRepository();
  });

  tearDown(() {
    // Reset the mock asset bundle after each test
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  /// Helper to register a fake asset that [rootBundle.loadString] will return.
  void setMockAsset(String assetPath, String content) {
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        // Decode the requested asset key from the platform message
        final String requestedKey = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        if (requestedKey == assetPath) {
          return ByteData.view(Uint8List.fromList(utf8.encode(content)).buffer);
        }
        // Asset not found – return null so rootBundle throws
        return null;
      },
    );
  }

  group('IndoorMapRepository', () {
    group('loadGeoJsonAsset', () {
      test('returns parsed map for a valid GeoJSON asset', () async {
        final validGeoJson = {
          'type': 'FeatureCollection',
          'name': 'TestBuilding',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '101', 'level': '1'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        setMockAsset(
          'assets/indoor_maps/geojson/Test/t1.geojson.json',
          jsonEncode(validGeoJson),
        );

        final result = await repository.loadGeoJsonAsset(
          'assets/indoor_maps/geojson/Test/t1.geojson.json',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result['type'], 'FeatureCollection');
        expect(result['name'], 'TestBuilding');
        expect(result['features'], isA<List>());
        expect(result['features'].length, 1);
      });

      test('returned features contain correct properties', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '200', 'indoor': 'room'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        setMockAsset('assets/test.json', jsonEncode(geoJson));

        final result = await repository.loadGeoJsonAsset('assets/test.json');
        final feature = result['features'][0] as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;

        expect(props['ref'], '200');
        expect(props['indoor'], 'room');
      });

      test('returned features contain correct geometry', () async {
        final coordinates = [
          [
            [-73.5790, 45.4970],
            [-73.5780, 45.4970],
            [-73.5780, 45.4960],
            [-73.5790, 45.4960],
            [-73.5790, 45.4970],
          ],
        ];

        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '301'},
              'geometry': {'type': 'Polygon', 'coordinates': coordinates},
            },
          ],
        };

        setMockAsset('assets/geom.json', jsonEncode(geoJson));

        final result = await repository.loadGeoJsonAsset('assets/geom.json');
        final feature = result['features'][0] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;

        expect(geometry['type'], 'Polygon');
        expect(geometry['coordinates'], isA<List>());

        final ring = geometry['coordinates'][0] as List;
        expect(ring.length, 5);
        expect(ring[0][0], -73.5790); // longitude
        expect(ring[0][1], 45.4970); // latitude
      });

      test('handles empty FeatureCollection', () async {
        final geoJson = {'type': 'FeatureCollection', 'features': []};

        setMockAsset('assets/empty.json', jsonEncode(geoJson));

        final result = await repository.loadGeoJsonAsset('assets/empty.json');

        expect(result['type'], 'FeatureCollection');
        expect(result['features'], isEmpty);
      });

      test('handles multiple features', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '101'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {'ref': '102'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.580, 45.498],
                    [-73.579, 45.498],
                    [-73.579, 45.497],
                    [-73.580, 45.498],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {'escalators': 'yes'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.581, 45.499],
                    [-73.580, 45.499],
                    [-73.580, 45.498],
                    [-73.581, 45.499],
                  ],
                ],
              },
            },
          ],
        };

        setMockAsset('assets/multi.json', jsonEncode(geoJson));

        final result = await repository.loadGeoJsonAsset('assets/multi.json');
        final features = result['features'] as List;

        expect(features.length, 3);
        expect(features[0]['properties']['ref'], '101');
        expect(features[1]['properties']['ref'], '102');
        expect(features[2]['properties']['escalators'], 'yes');
      });

      test('handles features with special property types', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets', 'female': 'yes'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {'highway': 'elevator'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.580, 45.498],
                    [-73.579, 45.498],
                    [-73.579, 45.497],
                    [-73.580, 45.498],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {'highway': 'steps'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.581, 45.499],
                    [-73.580, 45.499],
                    [-73.580, 45.498],
                    [-73.581, 45.499],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {'indoor': 'corridor'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.582, 45.500],
                    [-73.581, 45.500],
                    [-73.581, 45.499],
                    [-73.582, 45.500],
                  ],
                ],
              },
            },
          ],
        };

        setMockAsset('assets/special.json', jsonEncode(geoJson));

        final result = await repository.loadGeoJsonAsset('assets/special.json');
        final features = result['features'] as List;

        expect(features.length, 4);
        expect(features[0]['properties']['amenity'], 'toilets');
        expect(features[0]['properties']['female'], 'yes');
        expect(features[1]['properties']['highway'], 'elevator');
        expect(features[2]['properties']['highway'], 'steps');
        expect(features[3]['properties']['indoor'], 'corridor');
      });

      test('throws when asset does not exist', () async {
        // No mock registered for this path, so rootBundle.loadString will fail
        setMockAsset('assets/nonexistent.json', '');

        expect(
          () => repository.loadGeoJsonAsset('assets/does_not_exist.json'),
          throwsA(anything),
        );
      });

      test('throws on invalid JSON content', () async {
        setMockAsset('assets/bad.json', '{ not valid json!!!');

        expect(
          () => repository.loadGeoJsonAsset('assets/bad.json'),
          throwsA(isA<FormatException>()),
        );
      });

      test('handles features with no properties', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        setMockAsset('assets/noprops.json', jsonEncode(geoJson));

        final result = await repository.loadGeoJsonAsset('assets/noprops.json');
        final feature = result['features'][0] as Map<String, dynamic>;

        expect(feature['properties'], isA<Map>());
        expect((feature['properties'] as Map).isEmpty, isTrue);
      });

      test('preserves numeric coordinate precision', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '500'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.57884914394536, 45.49683537599080],
                    [-73.57834327182124, 45.49737401309186],
                    [-73.57903463039088, 45.49771340247506],
                    [-73.57884914394536, 45.49683537599080],
                  ],
                ],
              },
            },
          ],
        };

        setMockAsset('assets/precision.json', jsonEncode(geoJson));

        final result = await repository.loadGeoJsonAsset(
          'assets/precision.json',
        );
        final coords =
            result['features'][0]['geometry']['coordinates'][0] as List;

        expect(coords[0][0], closeTo(-73.57884914394536, 1e-14));
        expect(coords[0][1], closeTo(45.49683537599080, 1e-14));
      });
    });
    group('Additional coverage for remaining methods', () {
      test(
        'getAssetPathsForBuilding returns correct paths and unknown empty',
        () {
          final hall = repository.getAssetPathsForBuilding('hall');
          expect(hall.length, 4);
          final mb = repository.getAssetPathsForBuilding('MB');
          expect(mb.length, 2);
          final unknown = repository.getAssetPathsForBuilding('XYZ');
          expect(unknown, isEmpty);
        },
      );

      test('getRoomCodesForBuilding extracts valid room codes', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '101'},
            },
            {
              'type': 'Feature',
              'properties': {'ref': '102'},
            },
            {
              'type': 'Feature',
              'properties': {'ref': ''},
            },
            {'type': 'Feature', 'properties': null},
          ],
        };
        const path = 'assets/test_rooms.json';
        setMockAsset(path, jsonEncode(geoJson));

        final repo = TestIndoorMapRepository([path]);
        final rooms = await repo.getRoomCodesForBuilding('ANY');

        expect(rooms, containsAll(['101', '102']));
        expect(rooms.length, 2);
      });

      test('getRoomCodesForBuilding handles null features', () async {
        final geoJson = {'type': 'FeatureCollection'};

        const path = 'assets/null_features.json';
        setMockAsset(path, jsonEncode(geoJson));

        final repo = TestIndoorMapRepository([path]);
        final rooms = await repo.getRoomCodesForBuilding('ANY');

        expect(rooms, isEmpty);
      });

      test('getRoomCodesForBuilding skips malformed features safely', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            'invalid_feature',
            {
              'type': 'Feature',
              'properties': {'ref': '200'},
            },
          ],
        };

        const path = 'assets/malformed.json';
        setMockAsset(path, jsonEncode(geoJson));
        final repo = TestIndoorMapRepository([path]);
        final rooms = await repo.getRoomCodesForBuilding('ANY');
        expect(rooms, contains('200'));
      });

      test('roomExists returns true and false correctly', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': 'A1'},
            },
          ],
        };

        const path = 'assets/exists.json';
        setMockAsset(path, jsonEncode(geoJson));
        final repo = TestIndoorMapRepository([path]);
        expect(await repo.roomExists('ANY', 'A1'), isTrue);
        expect(await repo.roomExists('ANY', 'B2'), isFalse);
      });

      test('getRoomLocation returns centroid for polygon', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': 'R1'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [0.0, 0.0],
                    [0.0, 2.0],
                    [2.0, 0.0],
                    [2.0, 2.0],
                  ],
                ],
              },
            },
          ],
        };
        const path = 'assets/location.json';
        setMockAsset(path, jsonEncode(geoJson));
        final repo = TestIndoorMapRepository([path]);
        final location = await repo.getRoomLocation('ANY', 'R1');
        expect(location, isNotNull);
        expect(location!.latitude, closeTo(1.0, 0.001));
        expect(location.longitude, closeTo(1.0, 0.001));
      });

      test('getRoomLocation skips null geometry', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': 'R1'},
              'geometry': null,
            },
          ],
        };
        const path = 'assets/null_geom.json';
        setMockAsset(path, jsonEncode(geoJson));
        final repo = TestIndoorMapRepository([path]);
        final result = await repo.getRoomLocation('ANY', 'R1');
        expect(result, isNull);
      });

      test('getRoomLocation ignores non-Polygon geometry', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': 'R1'},
              'geometry': {
                'type': 'Point',
                'coordinates': [1.0, 2.0],
              },
            },
          ],
        };

        const path = 'assets/non_polygon.json';
        setMockAsset(path, jsonEncode(geoJson));

        final repo = TestIndoorMapRepository([path]);

        final result = await repo.getRoomLocation('ANY', 'R1');
        expect(result, isNull);
      });

      test('getRoomLocation returns null if no asset paths', () async {
        final repo = TestIndoorMapRepository([]);
        final result = await repo.getRoomLocation('NONE', 'R1');
        expect(result, isNull);
      });
      test('repository outer catch handling', () async {
        final repo = TestIndoorMapRepository(['assets/invalid.json']);

        setMockAsset('assets/invalid.json', 'INVALID_JSON');

        final rooms = await repo.getRoomCodesForBuilding('ANY');

        expect(rooms, isEmpty);
      });
      test('handles malformed polygon coordinate structure', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'properties': {'ref': 'R1'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [[]],
                ],
              },
            },
          ],
        };
        const path = 'assets/malformed_polygon2.json';
        setMockAsset(path, jsonEncode(geoJson));
        final repo = TestIndoorMapRepository([path]);
        final result = await repo.getRoomLocation('ANY', 'R1');
        expect(result, isNull);
      });
    });
  });
}
