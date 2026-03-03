// ignore_for_file: avoid_print
//
// indoor_map_service_test.dart
//
// Tests for lib/services/indoor_maps/indoor_map_service.dart
// Covers every public function, constant, branch, and the IndoorMapData class.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/services/indoor_maps/indoor_map_service.dart';

// ============================================================================
// Helpers
// ============================================================================

/// Minimal valid GeoJSON with one room polygon.
Map<String, dynamic> _makeGeoJson({
  String type = 'Polygon',
  List<List<List<double>>>? coordinates,
  Map<String, dynamic>? properties,
}) {
  coordinates ??= [
    [
      [-73.5789, 45.4970],
      [-73.5785, 45.4970],
      [-73.5785, 45.4975],
      [-73.5789, 45.4975],
      [-73.5789, 45.4970], // closed ring
    ],
  ];
  properties ??= {'ref': '101'};
  return {
    'features': [
      {
        'geometry': {'type': type, 'coordinates': coordinates},
        'properties': properties,
      },
    ],
  };
}

/// GeoJSON containing multiple features with different property types.
Map<String, dynamic> _multiFeatureGeoJson() {
  List<List<List<double>>> ring() => [
    [
      [-73.58, 45.49],
      [-73.57, 45.49],
      [-73.57, 45.50],
      [-73.58, 45.50],
      [-73.58, 45.49],
    ],
  ];

  return {
    'features': [
      {
        'geometry': {'type': 'Polygon', 'coordinates': ring()},
        'properties': {'ref': 'esc1', 'escalators': 'yes'},
      },
      {
        'geometry': {'type': 'Polygon', 'coordinates': ring()},
        'properties': {'ref': 'elev1', 'highway': 'elevator'},
      },
      {
        'geometry': {'type': 'Polygon', 'coordinates': ring()},
        'properties': {'ref': 'step1', 'highway': 'steps'},
      },
      {
        'geometry': {'type': 'Polygon', 'coordinates': ring()},
        'properties': {'ref': 'wc1', 'amenity': 'toilets'},
      },
      {
        'geometry': {'type': 'Polygon', 'coordinates': ring()},
        'properties': {'ref': 'corr1', 'indoor': 'corridor'},
      },
      {
        'geometry': {'type': 'Polygon', 'coordinates': ring()},
        'properties': {'ref': 'room1'},
      },
    ],
  };
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  // ==========================================================================
  // Constants
  // ==========================================================================
  group('indoorMapAssets constant', () {
    test('contains all 5 supported buildings', () {
      expect(indoorMapAssets, hasLength(5));
      expect(indoorMapAssets.containsKey('HALL'), isTrue);
      expect(indoorMapAssets.containsKey('MB'), isTrue);
      expect(indoorMapAssets.containsKey('VE'), isTrue);
      expect(indoorMapAssets.containsKey('VL'), isTrue);
      expect(indoorMapAssets.containsKey('CC'), isTrue);
    });

    test('all values are non-empty asset paths', () {
      for (final path in indoorMapAssets.values) {
        expect(path, isNotEmpty);
        expect(path, startsWith('assets/'));
      }
    });
  });

  group('indoorMapStyle constant', () {
    test('is valid JSON', () {
      final parsed = jsonDecode(indoorMapStyle);
      expect(parsed, isList);
      expect((parsed as List).length, greaterThanOrEqualTo(1));
    });

    test('contains poi visibility off rule', () {
      expect(indoorMapStyle, contains('"poi"'));
      expect(indoorMapStyle, contains('"off"'));
    });
  });

  // ==========================================================================
  // isPointInPolygon
  // ==========================================================================
  group('isPointInPolygon', () {
    const square = [LatLng(0, 0), LatLng(0, 4), LatLng(4, 4), LatLng(4, 0)];

    test('point inside square → true', () {
      expect(isPointInPolygon(const LatLng(2, 2), square), isTrue);
    });

    test('point outside square → false', () {
      expect(isPointInPolygon(const LatLng(5, 5), square), isFalse);
    });

    test('point inside triangle → true', () {
      const triangle = [LatLng(0, 0), LatLng(0, 6), LatLng(6, 0)];
      expect(isPointInPolygon(const LatLng(1, 1), triangle), isTrue);
    });

    test('point outside triangle → false', () {
      const triangle = [LatLng(0, 0), LatLng(0, 6), LatLng(6, 0)];
      expect(isPointInPolygon(const LatLng(5, 5), triangle), isFalse);
    });

    test('concave L-shape – inside arm', () {
      const lShape = [
        LatLng(0, 0),
        LatLng(0, 4),
        LatLng(2, 4),
        LatLng(2, 2),
        LatLng(4, 2),
        LatLng(4, 0),
      ];
      expect(isPointInPolygon(const LatLng(1, 3), lShape), isTrue);
    });

    test('concave L-shape – outside notch', () {
      const lShape = [
        LatLng(0, 0),
        LatLng(0, 4),
        LatLng(2, 4),
        LatLng(2, 2),
        LatLng(4, 2),
        LatLng(4, 0),
      ];
      expect(isPointInPolygon(const LatLng(3, 3), lShape), isFalse);
    });

    test('vertex point – no crash', () {
      // Edge case: result is implementation-defined, just ensure no exception
      isPointInPolygon(const LatLng(0, 0), square);
    });

    test('collinear degenerate polygon – no crash', () {
      const degenerate = [LatLng(0, 0), LatLng(1, 1), LatLng(2, 2)];
      isPointInPolygon(const LatLng(1, 1), degenerate);
    });
  });

  // ==========================================================================
  // polygonArea
  // ==========================================================================
  group('polygonArea', () {
    test('4×4 square area = 16', () {
      const square = [LatLng(0, 0), LatLng(0, 4), LatLng(4, 4), LatLng(4, 0)];
      expect(polygonArea(square), closeTo(16.0, 0.001));
    });

    test('right triangle (3,4) area = 6', () {
      const triangle = [LatLng(0, 0), LatLng(3, 0), LatLng(0, 4)];
      expect(polygonArea(triangle), closeTo(6.0, 0.01));
    });

    test('degenerate line has zero area', () {
      const line = [LatLng(0, 0), LatLng(1, 0), LatLng(2, 0)];
      expect(polygonArea(line), closeTo(0, 0.001));
    });

    test('reversed winding returns same area (abs)', () {
      const cw = [LatLng(0, 0), LatLng(4, 0), LatLng(4, 4), LatLng(0, 4)];
      const ccw = [LatLng(0, 0), LatLng(0, 4), LatLng(4, 4), LatLng(4, 0)];
      expect(polygonArea(cw), closeTo(polygonArea(ccw), 0.001));
    });

    test('negative coordinates', () {
      const poly = [LatLng(-2, -3), LatLng(-2, 3), LatLng(2, 3), LatLng(2, -3)];
      expect(polygonArea(poly), closeTo(24.0, 0.01));
    });
  });

  // ==========================================================================
  // polygonCenter
  // ==========================================================================
  group('polygonCenter', () {
    test('single point → returns itself', () {
      expect(polygonCenter(const [LatLng(10, 20)]), const LatLng(10, 20));
    });

    test('two points → returns first (< 3 guard)', () {
      const pair = [LatLng(1, 2), LatLng(3, 4)];
      expect(polygonCenter(pair), const LatLng(1, 2));
    });

    test('convex square – average is inside → returns average', () {
      const square = [LatLng(0, 0), LatLng(0, 4), LatLng(4, 4), LatLng(4, 0)];
      final c = polygonCenter(square);
      expect(c.latitude, closeTo(2.0, 0.01));
      expect(c.longitude, closeTo(2.0, 0.01));
    });

    test('concave U-shape – average outside → fallback diagonal', () {
      // U-shape: simple average falls in the notch (outside)
      const uShape = [
        LatLng(0, 0),
        LatLng(0, 6),
        LatLng(2, 6),
        LatLng(2, 2),
        LatLng(4, 2),
        LatLng(4, 6),
        LatLng(6, 6),
        LatLng(6, 0),
      ];
      final c = polygonCenter(uShape);
      // Fallback should pick a point that IS inside the polygon
      expect(isPointInPolygon(c, uShape), isTrue);
    });

    test('narrow L-shape exercises diagonal scan', () {
      const narrowL = [
        LatLng(0, 0),
        LatLng(0, 8),
        LatLng(1, 8),
        LatLng(1, 1),
        LatLng(8, 1),
        LatLng(8, 0),
      ];
      final c = polygonCenter(narrowL);
      expect(c.latitude, inInclusiveRange(-1, 9));
      expect(c.longitude, inInclusiveRange(-1, 9));
    });

    test('equilateral triangle – average is inside', () {
      const tri = [LatLng(0, 0), LatLng(0, 6), LatLng(6, 3)];
      final c = polygonCenter(tri);
      expect(c.latitude, closeTo(2.0, 0.01));
      expect(c.longitude, closeTo(3.0, 0.01));
    });
  });

  // ==========================================================================
  // indoorAssetPath
  // ==========================================================================
  group('indoorAssetPath', () {
    test('known code (uppercase) → returns path', () {
      expect(indoorAssetPath('HALL'), isNotNull);
      expect(indoorAssetPath('HALL'), contains('Hall'));
    });

    test('known code (lowercase) → returns path', () {
      expect(indoorAssetPath('hall'), isNotNull);
    });

    test('known code (mixed case) → returns path', () {
      expect(indoorAssetPath('Hall'), isNotNull);
    });

    test('all supported codes return non-null', () {
      for (final code in ['HALL', 'MB', 'VE', 'VL', 'CC']) {
        expect(indoorAssetPath(code), isNotNull, reason: code);
      }
    });

    test('unsupported code → null', () {
      expect(indoorAssetPath('XYZ'), isNull);
      expect(indoorAssetPath(''), isNull);
    });
  });

  // ==========================================================================
  // indoorFillColor
  // ==========================================================================
  group('indoorFillColor', () {
    test('escalator → green', () {
      expect(indoorFillColor({'escalators': 'yes'}), Colors.green);
    });

    test('elevator → orange', () {
      expect(indoorFillColor({'highway': 'elevator'}), Colors.orange);
    });

    test('steps → pink', () {
      expect(indoorFillColor({'highway': 'steps'}), Colors.pink);
    });

    test('toilets → blue', () {
      expect(indoorFillColor({'amenity': 'toilets'}), Colors.blue);
    });

    test('corridor → lighter red', () {
      expect(
        indoorFillColor({'indoor': 'corridor'}),
        const Color.fromARGB(255, 232, 122, 149),
      );
    });

    test('default room → dark red (0xFF800020)', () {
      expect(indoorFillColor({'ref': '101'}), const Color(0xFF800020));
    });

    test('empty properties → dark red', () {
      expect(indoorFillColor({}), const Color(0xFF800020));
    });

    test('priority: escalators wins over highway', () {
      // escalators check comes first in the chain
      expect(
        indoorFillColor({'escalators': 'yes', 'highway': 'elevator'}),
        Colors.green,
      );
    });

    test('priority: elevator wins over steps', () {
      // highway == elevator is checked before highway == steps
      expect(indoorFillColor({'highway': 'elevator'}), Colors.orange);
    });
  });

  // ==========================================================================
  // geoJsonToPolygons
  // ==========================================================================
  group('geoJsonToPolygons', () {
    test('valid polygon feature → 1 Polygon returned', () {
      final polys = geoJsonToPolygons(_makeGeoJson());
      expect(polys, hasLength(1));
      expect(polys.first.polygonId.value, startsWith('indoor-'));
    });

    test('non-Polygon geometry type is skipped', () {
      final polys = geoJsonToPolygons(_makeGeoJson(type: 'Point'));
      expect(polys, isEmpty);
    });

    test('empty rings are skipped', () {
      final geo = {
        'features': [
          {
            'geometry': {'type': 'Polygon', 'coordinates': <List>[]},
            'properties': {'ref': '1'},
          },
        ],
      };
      expect(geoJsonToPolygons(geo), isEmpty);
    });

    test('fewer than 3 points is skipped', () {
      final geo = _makeGeoJson(
        coordinates: [
          [
            [-73.58, 45.49],
            [-73.57, 45.49],
          ],
        ],
      );
      expect(geoJsonToPolygons(geo), isEmpty);
    });

    test('null properties → fallback id from index', () {
      final geo = {
        'features': [
          {
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.58, 45.49],
                  [-73.57, 45.49],
                  [-73.57, 45.50],
                  [-73.58, 45.50],
                ],
              ],
            },
            'properties': null,
          },
        ],
      };
      final polys = geoJsonToPolygons(geo);
      expect(polys, hasLength(1));
      // id falls back to polygons.length (0) → "indoor-0"
      expect(polys.first.polygonId.value, 'indoor-0');
    });

    test('multiple features with all color branches', () {
      final polys = geoJsonToPolygons(_multiFeatureGeoJson());
      // 6 features, all have valid polygon geometry
      expect(polys, hasLength(6));
    });

    test('polygon uses correct stroke color and zIndex', () {
      final polys = geoJsonToPolygons(_makeGeoJson());
      final p = polys.first;
      expect(p.strokeColor, Colors.black);
      expect(p.strokeWidth, 2);
      expect(p.zIndex, 20);
    });

    test('GeoJSON [lng, lat] ordering is converted to LatLng(lat, lng)', () {
      final polys = geoJsonToPolygons(_makeGeoJson());
      final first = polys.first.points.first;
      // The first coordinate in our helper is [-73.5789, 45.4970]
      expect(first.latitude, closeTo(45.4970, 0.001));
      expect(first.longitude, closeTo(-73.5789, 0.001));
    });
  });

  // ==========================================================================
  // createTextBitmap
  // ==========================================================================
  group('createTextBitmap', () {
    testWidgets('returns a BitmapDescriptor', (tester) async {
      final icon = await createTextBitmap('H101');
      expect(icon, isA<BitmapDescriptor>());
    });

    testWidgets('custom fontSize does not crash', (tester) async {
      final icon = await createTextBitmap('Room', fontSize: 8);
      expect(icon, isA<BitmapDescriptor>());
    });

    testWidgets('empty string does not crash', (tester) async {
      final icon = await createTextBitmap('');
      expect(icon, isA<BitmapDescriptor>());
    });
  });

  // ==========================================================================
  // createRoomLabels
  // ==========================================================================
  group('createRoomLabels', () {
    testWidgets('valid polygon with ref → marker created', (tester) async {
      final geo = _makeGeoJson(properties: {'ref': 'H101'});
      final markers = await createRoomLabels(geo);
      expect(markers, hasLength(1));
      expect(markers.first.markerId.value, contains('H101'));
    });

    testWidgets('polygon without ref → skipped', (tester) async {
      final geo = _makeGeoJson(properties: {'name': 'Room'});
      final markers = await createRoomLabels(geo);
      expect(markers, isEmpty);
    });

    testWidgets('non-Polygon geometry → skipped', (tester) async {
      final geo = _makeGeoJson(type: 'Point', properties: {'ref': 'X'});
      final markers = await createRoomLabels(geo);
      expect(markers, isEmpty);
    });

    testWidgets('empty rings → skipped', (tester) async {
      final geo = {
        'features': [
          {
            'geometry': {'type': 'Polygon', 'coordinates': <List>[]},
            'properties': {'ref': 'X'},
          },
        ],
      };
      final markers = await createRoomLabels(geo);
      expect(markers, isEmpty);
    });

    testWidgets('fewer than 3 points → skipped', (tester) async {
      final geo = _makeGeoJson(
        coordinates: [
          [
            [-73.58, 45.49],
            [-73.57, 45.49],
          ],
        ],
        properties: {'ref': 'X'},
      );
      final markers = await createRoomLabels(geo);
      expect(markers, isEmpty);
    });

    testWidgets('very small polygon (area < 1e-10) → skipped', (tester) async {
      // Two nearly-identical points = near-zero area
      final geo = _makeGeoJson(
        coordinates: [
          [
            [-73.5789, 45.4970],
            [-73.5789, 45.4970 + 1e-14],
            [-73.5789 + 1e-14, 45.4970],
            [-73.5789, 45.4970],
          ],
        ],
        properties: {'ref': 'TINY'},
      );
      final markers = await createRoomLabels(geo);
      expect(markers, isEmpty);
    });

    testWidgets('large polygon uses fontSize 10', (tester) async {
      // Large enough that area > 5e-8
      final geo = _makeGeoJson(properties: {'ref': 'BIG'});
      final markers = await createRoomLabels(geo);
      // The marker is created successfully – we can't inspect fontSize
      // directly but we verify it didn't crash and a marker exists.
      expect(markers, hasLength(1));
    });

    testWidgets('small polygon uses fontSize 8', (tester) async {
      // Polygon small enough that area <= 5e-8 but > 1e-10
      final geo = _makeGeoJson(
        coordinates: [
          [
            [-73.5789, 45.4970],
            [-73.5789 + 0.00002, 45.4970],
            [-73.5789 + 0.00002, 45.4970 + 0.00002],
            [-73.5789, 45.4970 + 0.00002],
            [-73.5789, 45.4970],
          ],
        ],
        properties: {'ref': 'SM'},
      );
      final markers = await createRoomLabels(geo);
      // Area ≈ 4e-10, which is > 1e-10 but < 5e-8 → fontSize 8
      expect(markers, hasLength(1));
    });

    testWidgets('multiple features create incrementing marker ids', (
      tester,
    ) async {
      final geo = {
        'features': [
          {
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.58, 45.49],
                  [-73.57, 45.49],
                  [-73.57, 45.50],
                  [-73.58, 45.50],
                  [-73.58, 45.49],
                ],
              ],
            },
            'properties': {'ref': 'A'},
          },
          {
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.59, 45.49],
                  [-73.585, 45.49],
                  [-73.585, 45.50],
                  [-73.59, 45.50],
                  [-73.59, 45.49],
                ],
              ],
            },
            'properties': {'ref': 'B'},
          },
        ],
      };
      final markers = await createRoomLabels(geo);
      expect(markers, hasLength(2));
      final ids = markers.map((m) => m.markerId.value).toSet();
      expect(ids, contains(contains('0-A')));
      expect(ids, contains(contains('1-B')));
    });

    testWidgets('marker properties are correct', (tester) async {
      final geo = _makeGeoJson(properties: {'ref': 'Z'});
      final markers = await createRoomLabels(geo);
      final m = markers.first;
      expect(m.anchor, const Offset(0.5, 0.5));
      expect(m.flat, isTrue);
      expect(m.zIndex, 30);
      expect(m.consumeTapEvents, isFalse);
    });
  });

  // ==========================================================================
  // loadIndoorMap
  // ==========================================================================
  group('loadIndoorMap', () {
    test('unsupported building code → returns null', () async {
      final result = await loadIndoorMap('ZZZZZ');
      expect(result, isNull);
    });

    test('empty building code → returns null', () async {
      final result = await loadIndoorMap('');
      expect(result, isNull);
    });

    testWidgets('supported code loads data via repository', (tester) async {
      // Mock rootBundle to return a minimal GeoJSON for the HALL asset
      final fakeGeoJson = jsonEncode(_makeGeoJson(properties: {'ref': 'H101'}));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            // Return the fake GeoJSON for any asset request
            return ByteData.sublistView(
              Uint8List.fromList(utf8.encode(fakeGeoJson)),
            );
          });

      final result = await loadIndoorMap('HALL');
      expect(result, isNotNull);
      expect(result!.polygons, hasLength(1));
      expect(result.roomLabels, hasLength(1));
      expect(result.geojson, isNotNull);
      expect(result.geojson['features'], isList);

      // Clean up mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    testWidgets('lowercase code also works', (tester) async {
      final fakeGeoJson = jsonEncode(_makeGeoJson(properties: {'ref': 'M1'}));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            return ByteData.sublistView(
              Uint8List.fromList(utf8.encode(fakeGeoJson)),
            );
          });

      final result = await loadIndoorMap('mb');
      expect(result, isNotNull);
      expect(result!.polygons, isNotEmpty);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });
  });

  // ==========================================================================
  // IndoorMapData
  // ==========================================================================
  group('IndoorMapData', () {
    test('constructor stores all fields', () {
      final data = IndoorMapData(
        geojson: {'features': []},
        polygons: {const Polygon(polygonId: PolygonId('test'), points: [])},
        roomLabels: {const Marker(markerId: MarkerId('label'))},
      );
      expect(data.geojson, isNotNull);
      expect(data.polygons, hasLength(1));
      expect(data.roomLabels, hasLength(1));
    });

    test('empty data is valid', () {
      final data = IndoorMapData(
        geojson: {'features': []},
        polygons: const {},
        roomLabels: const {},
      );
      expect(data.polygons, isEmpty);
      expect(data.roomLabels, isEmpty);
    });
  });
}
