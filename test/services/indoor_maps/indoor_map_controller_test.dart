import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_controller.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';

class TestIndoorMapRepository extends IndoorMapRepository {
  final Map<String, String> mockAssets;

  TestIndoorMapRepository(this.mockAssets);

  @override
  List<String> getAssetPathsForBuilding(String buildingCode) {
    return mockAssets.keys.toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Helper to register mock asset responses
  void setMockAsset(String assetPath, String content) {
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final String requestedKey = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        if (requestedKey == assetPath) {
          return ByteData.view(Uint8List.fromList(utf8.encode(content)).buffer);
        }
        return null;
      },
    );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('IndoorMapController', () {
    group('loadFloor', () {
      test('returns IndoorLoadResult with amenity icons', () async {
        final controller = IndoorMapController();
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '101', 'indoor': 'room'},
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
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.580, 45.497],
                    [-73.581, 45.497],
                    [-73.581, 45.496],
                    [-73.580, 45.496],
                    [-73.580, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final assetPath = 'assets/test/floor.geojson.json';
        setMockAsset(assetPath, jsonEncode(geoJson));

        final result = await controller.loadFloor(assetPath);

        expect(result.polygons, isNotEmpty);
        expect(result.amenityIcons, isNotEmpty);
        expect(result.amenityIcons.length, 1);
        expect(result.geoJson, isNotNull);
      });

      test('passes zoom parameter to amenity icon generation', () async {
        final controller = IndoorMapController();
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
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

        final assetPath = 'assets/test/floor.geojson.json';
        setMockAsset(assetPath, jsonEncode(geoJson));

        final resultZoom17 = await controller.loadFloor(assetPath, zoom: 17.0);

        expect(resultZoom17.amenityIcons, isNotEmpty);

        final resultZoom20 = await controller.loadFloor(assetPath, zoom: 20.0);

        expect(resultZoom20.amenityIcons, isNotEmpty);
        expect(
          resultZoom17.amenityIcons.length,
          resultZoom20.amenityIcons.length,
        );
      });

      test('creates room label markers for rooms with ref property', () async {
        final controller = IndoorMapController();
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '101', 'indoor': 'room'},
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
            {
              'type': 'Feature',
              'properties': {'ref': '102', 'indoor': 'room'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.580, 45.497],
                    [-73.581, 45.497],
                    [-73.581, 45.496],
                    [-73.580, 45.496],
                    [-73.580, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final assetPath = 'assets/test/floor.geojson.json';
        setMockAsset(assetPath, jsonEncode(geoJson));

        final result = await controller.loadFloor(assetPath);

        expect(result.labels, isNotEmpty);
        expect(result.labels.length, greaterThan(0));
      });

      test('handles GeoJSON with no amenities', () async {
        final controller = IndoorMapController();
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '101', 'indoor': 'room'},
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

        final assetPath = 'assets/test/floor.geojson.json';
        setMockAsset(assetPath, jsonEncode(geoJson));

        final result = await controller.loadFloor(assetPath);

        expect(result.polygons, isNotEmpty);
      });

      test('uses default zoom of 18.0 when not specified', () async {
        final controller = IndoorMapController();
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
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

        final assetPath = 'assets/test/floor.geojson.json';
        setMockAsset(assetPath, jsonEncode(geoJson));

        final result = await controller.loadFloor(assetPath);

        expect(result.amenityIcons, isNotEmpty);
      });

      test('returns geoJson in result', () async {
        final controller = IndoorMapController();
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
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final assetPath = 'assets/test/floor.geojson.json';
        setMockAsset(assetPath, jsonEncode(geoJson));

        final result = await controller.loadFloor(assetPath);

        expect(result.geoJson, isA<Map<String, dynamic>>());
        expect(result.geoJson['type'], 'FeatureCollection');
        expect(result.geoJson['features'], isA<List>());
      });
    });

    group('IndoorLoadResult', () {
      test('can be created with all properties', () {
        final polygons = <Polygon>{};
        final labels = <Marker>{};
        final amenityIcons = <Marker>{};
        final geoJson = {'type': 'FeatureCollection', 'features': []};

        final result = IndoorLoadResult(
          polygons: polygons,
          labels: labels,
          amenityIcons: amenityIcons,
          geoJson: geoJson,
        );

        expect(result.polygons, same(polygons));
        expect(result.labels, same(labels));
        expect(result.amenityIcons, same(amenityIcons));
        expect(result.geoJson, same(geoJson));
      });

      test('stores polygons correctly', () {
        final polygon = Polygon(
          polygonId: const PolygonId('test'),
          points: [const LatLng(45.497, -73.579)],
        );
        final polygons = {polygon};

        final result = IndoorLoadResult(
          polygons: polygons,
          labels: {},
          amenityIcons: {},
          geoJson: {},
        );

        expect(result.polygons.length, 1);
        expect(result.polygons.first.polygonId.value, 'test');
      });

      test('stores labels correctly', () {
        final marker = Marker(
          markerId: const MarkerId('label_1'),
          position: const LatLng(45.497, -73.579),
        );
        final labels = {marker};

        final result = IndoorLoadResult(
          polygons: {},
          labels: labels,
          amenityIcons: {},
          geoJson: {},
        );

        expect(result.labels.length, 1);
        expect(result.labels.first.markerId.value, 'label_1');
      });

      test('stores amenityIcons correctly', () {
        final marker = Marker(
          markerId: const MarkerId('toilet_1'),
          position: const LatLng(45.497, -73.579),
        );
        final amenityIcons = {marker};

        final result = IndoorLoadResult(
          polygons: {},
          labels: {},
          amenityIcons: amenityIcons,
          geoJson: {},
        );

        expect(result.amenityIcons.length, 1);
        expect(result.amenityIcons.first.markerId.value, 'toilet_1');
      });

      test('stores geoJson correctly', () {
        final geoJson = {'type': 'test'};
        final result = IndoorLoadResult(
          polygons: {},
          labels: {},
          amenityIcons: {},
          geoJson: geoJson,
        );

        expect(result.geoJson, same(geoJson));
      });
    });
  });
}
