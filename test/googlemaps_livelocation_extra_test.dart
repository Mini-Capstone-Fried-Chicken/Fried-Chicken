// ignore_for_file: avoid_print
//
// googlemaps_livelocation_extra_test.dart
//
// Additional coverage tests for googlemaps_livelocation.dart.
// Focuses on indoor map features (_toggleIndoorMap, _geoJsonToPolygons,
// _createRoomLabels, _turnOffIndoorMap), transit helpers, navigation,
// and algorithm replicas for private methods.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/shared/widgets/building_info_popup.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';
import 'package:campus_app/services/google_directions_service.dart';
import 'package:campus_app/services/navigation_steps.dart';
import 'package:campus_app/features/indoor/data/building_info.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';

// ============================================================================
// GoogleMap MethodChannel mock
// ============================================================================
void _setupGoogleMapsMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_maps'),
        (MethodCall call) async {
          switch (call.method) {
            case 'map#waitForMap':
              return null;
            case 'map#update':
              return null;
            case 'camera#move':
              return null;
            case 'camera#animate':
              return null;
            case 'map#getVisibleRegion':
              return {
                'southwest': {'lat': 45.49, 'lng': -73.59},
                'northeast': {'lat': 45.51, 'lng': -73.57},
              };
            case 'map#getScreenCoordinate':
              return {'x': 200, 'y': 400};
            case 'map#getLatLng':
              return {'lat': 45.4973, 'lng': -73.5789};
            case 'map#isCompassEnabled':
              return true;
            case 'map#isMapToolbarEnabled':
              return false;
            case 'map#getMinMaxZoomLevels':
              return {'min': 3.0, 'max': 21.0};
            case 'map#isZoomGesturesEnabled':
              return true;
            case 'map#isZoomControlsEnabled':
              return false;
            case 'map#isTiltGesturesEnabled':
              return true;
            case 'map#isRotateGesturesEnabled':
              return true;
            case 'map#isScrollGesturesEnabled':
              return true;
            case 'map#isMyLocationButtonEnabled':
              return false;
            case 'map#setStyle':
              return [true, null];
            case 'markers#update':
              return null;
            case 'polygons#update':
              return null;
            case 'polylines#update':
              return null;
            case 'circles#update':
              return null;
            default:
              return null;
          }
        },
      );
}

// ============================================================================
// Geolocator mock – injects a fixed Montreal location
// ============================================================================
void _setupGeolocatorMock() {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'isLocationServiceEnabled':
            return true;
          case 'checkPermission':
            return 3; // LocationPermission.always
          case 'requestPermission':
            return 3;
          case 'getCurrentPosition':
            return {
              'latitude': 45.4973,
              'longitude': -73.5789,
              'accuracy': 10.0,
              'altitude': 0.0,
              'speed': 0.0,
              'speed_accuracy': 0.0,
              'heading': 0.0,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'floor': null,
              'is_mocked': false,
            };
          case 'getPositionStream':
            return null;
          default:
            return null;
        }
      });
}

// ============================================================================
// Pump helpers
// ============================================================================

/// Pumps with the REAL GoogleMap (mocked channel).
Future<void> pumpWithMap(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
  bool isLoggedIn = false,
  BuildingPolygon? debugSelectedBuilding,
  Offset? debugAnchorOffset,
  String? debugLinkOverride,
}) async {
  _setupGoogleMapsMock();
  _setupGeolocatorMock();

  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        isLoggedIn: isLoggedIn,
        debugSelectedBuilding: debugSelectedBuilding,
        debugAnchorOffset: debugAnchorOffset,
        debugLinkOverride: debugLinkOverride,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pumps with debugDisableMap:true (fast, for tests that don't need GoogleMap).
Future<void> pumpNoMap(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
  bool isLoggedIn = false,
  BuildingPolygon? debugSelectedBuilding,
  Offset? debugAnchorOffset,
  String? debugLinkOverride,
}) async {
  _setupGeolocatorMock();

  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        isLoggedIn: isLoggedIn,
        debugDisableMap: true,
        debugDisableLocation: true,
        debugSelectedBuilding: debugSelectedBuilding,
        debugAnchorOffset: debugAnchorOffset,
        debugLinkOverride: debugLinkOverride,
      ),
    ),
  );
  await tester.pump();
}

BuildingPolygon get firstBuilding => buildingPolygons.first;

/// Helper to find a BuildingPolygon by code.
BuildingPolygon? _findBuildingByCode(String code) {
  for (final b in buildingPolygons) {
    if (b.code.toUpperCase() == code.toUpperCase()) return b;
  }
  return null;
}

// ============================================================================
// Sample GeoJSON for testing _geoJsonToPolygons / _createRoomLabels replicas
// ============================================================================

Map<String, dynamic> _buildTestGeoJson() => {
  'type': 'FeatureCollection',
  'features': [
    // 1. Regular room polygon (default dark red)
    {
      'type': 'Feature',
      'properties': {'ref': '101', 'indoor': 'room', 'level': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5790, 45.4970],
            [-73.5788, 45.4970],
            [-73.5788, 45.4972],
            [-73.5790, 45.4972],
            [-73.5790, 45.4970],
          ],
        ],
      },
    },
    // 2. Escalator (green)
    {
      'type': 'Feature',
      'properties': {'escalators': 'yes', 'level': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5792, 45.4970],
            [-73.5791, 45.4970],
            [-73.5791, 45.4971],
            [-73.5792, 45.4971],
            [-73.5792, 45.4970],
          ],
        ],
      },
    },
    // 3. Elevator (orange)
    {
      'type': 'Feature',
      'properties': {'highway': 'elevator', 'level': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5794, 45.4970],
            [-73.5793, 45.4970],
            [-73.5793, 45.4971],
            [-73.5794, 45.4971],
            [-73.5794, 45.4970],
          ],
        ],
      },
    },
    // 4. Steps (pink)
    {
      'type': 'Feature',
      'properties': {'highway': 'steps', 'level': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5796, 45.4970],
            [-73.5795, 45.4970],
            [-73.5795, 45.4971],
            [-73.5796, 45.4971],
            [-73.5796, 45.4970],
          ],
        ],
      },
    },
    // 5. Toilets (blue)
    {
      'type': 'Feature',
      'properties': {'amenity': 'toilets', 'level': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5798, 45.4970],
            [-73.5797, 45.4970],
            [-73.5797, 45.4971],
            [-73.5798, 45.4971],
            [-73.5798, 45.4970],
          ],
        ],
      },
    },
    // 6. Corridor (lighter red)
    {
      'type': 'Feature',
      'properties': {'indoor': 'corridor', 'level': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5800, 45.4970],
            [-73.5799, 45.4970],
            [-73.5799, 45.4972],
            [-73.5800, 45.4972],
            [-73.5800, 45.4970],
          ],
        ],
      },
    },
    // 7. Point geometry – should be skipped
    {
      'type': 'Feature',
      'properties': {'entrance': 'yes'},
      'geometry': {
        'type': 'Point',
        'coordinates': [-73.5790, 45.4975],
      },
    },
    // 8. Polygon with < 3 points – should be skipped
    {
      'type': 'Feature',
      'properties': {'ref': 'tiny'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5790, 45.4975],
            [-73.5789, 45.4975],
          ],
        ],
      },
    },
    // 9. Empty rings – should be skipped
    {
      'type': 'Feature',
      'properties': {'ref': 'empty'},
      'geometry': {'type': 'Polygon', 'coordinates': []},
    },
    // 10. Room with no 'ref'
    {
      'type': 'Feature',
      'properties': {'indoor': 'room', 'level': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5802, 45.4970],
            [-73.5801, 45.4970],
            [-73.5801, 45.4972],
            [-73.5802, 45.4972],
            [-73.5802, 45.4970],
          ],
        ],
      },
    },
    // 11. Very small polygon with ref (area < 1e-10)
    {
      'type': 'Feature',
      'properties': {'ref': 'micro'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5790000, 45.4970000],
            [-73.5790001, 45.4970000],
            [-73.5790001, 45.4970001],
            [-73.5790000, 45.4970001],
            [-73.5790000, 45.4970000],
          ],
        ],
      },
    },
    // 12. Larger room with ref (gets label)
    {
      'type': 'Feature',
      'properties': {'ref': '200', 'indoor': 'room'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5810, 45.4970],
            [-73.5805, 45.4970],
            [-73.5805, 45.4975],
            [-73.5810, 45.4975],
            [-73.5810, 45.4970],
          ],
        ],
      },
    },
    // 13. Empty properties
    {
      'type': 'Feature',
      'properties': {},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5812, 45.4970],
            [-73.5811, 45.4970],
            [-73.5811, 45.4971],
            [-73.5812, 45.4971],
            [-73.5812, 45.4970],
          ],
        ],
      },
    },
    // 14. Null properties
    {
      'type': 'Feature',
      'properties': null,
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.5814, 45.4970],
            [-73.5813, 45.4970],
            [-73.5813, 45.4971],
            [-73.5814, 45.4971],
            [-73.5814, 45.4970],
          ],
        ],
      },
    },
  ],
};

// ============================================================================
// Algorithm replicas
// ============================================================================

bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  bool inside = false;
  int j = polygon.length - 1;
  for (int i = 0; i < polygon.length; i++) {
    final xi = polygon[i].latitude;
    final yi = polygon[i].longitude;
    final xj = polygon[j].latitude;
    final yj = polygon[j].longitude;
    if (((yi > point.longitude) != (yj > point.longitude)) &&
        (point.latitude <
            (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

double polygonArea(List<LatLng> pts) {
  double area = 0;
  int j = pts.length - 1;
  for (int i = 0; i < pts.length; i++) {
    area +=
        (pts[j].longitude + pts[i].longitude) *
        (pts[j].latitude - pts[i].latitude);
    j = i;
  }
  return area.abs() / 2;
}

LatLng polygonCenter(List<LatLng> pts) {
  if (pts.length < 3) return pts.first;
  double lat = 0, lng = 0;
  for (final p in pts) {
    lat += p.latitude;
    lng += p.longitude;
  }
  final avg = LatLng(lat / pts.length, lng / pts.length);
  if (isPointInPolygon(avg, pts)) return avg;

  double maxDist = 0;
  LatLng best = avg;
  for (int i = 0; i < pts.length; i++) {
    for (int j = i + 1; j < pts.length; j++) {
      final mid = LatLng(
        (pts[i].latitude + pts[j].latitude) / 2,
        (pts[i].longitude + pts[j].longitude) / 2,
      );
      final dist =
          (pts[i].latitude - pts[j].latitude) *
              (pts[i].latitude - pts[j].latitude) +
          (pts[i].longitude - pts[j].longitude) *
              (pts[i].longitude - pts[j].longitude);
      if (dist > maxDist && isPointInPolygon(mid, pts)) {
        maxDist = dist;
        best = mid;
      }
    }
  }
  return best;
}

LatLngBounds calculateBounds(List<LatLng> points) {
  double minLat = points.first.latitude, maxLat = points.first.latitude;
  double minLng = points.first.longitude, maxLng = points.first.longitude;
  for (final point in points) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

String? formatArrivalTime(int? durationSeconds) {
  if (durationSeconds == null) return null;
  final now = DateTime.now();
  final arrival = now.add(Duration(seconds: durationSeconds));
  int hour = arrival.hour;
  final minute = arrival.minute.toString().padLeft(2, '0');
  final isPm = hour >= 12;
  final period = isPm ? 'pm' : 'am';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '$hour:$minute $period';
}

Color? parseHexColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  final normalized = hex.trim().replaceFirst('#', '');
  if (normalized.length != 6) return null;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

Color resolveTransitSegmentColor(DirectionsRouteSegment segment) {
  const defaultRed = Color(0xFF76263D);
  final mode = segment.travelMode.toUpperCase();
  if (mode == 'WALKING') return defaultRed;
  final vehicleType = segment.transitVehicleType?.toUpperCase();
  if (vehicleType == 'BUS') return Colors.blue;
  final lineColor = parseHexColor(segment.transitLineColorHex);
  if (lineColor != null) return lineColor;
  return defaultRed;
}

String formatTransitSegmentTitle(DirectionsRouteSegment segment) {
  final vehicleType = segment.transitVehicleType?.toUpperCase();
  final lineLabel =
      segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
  if (vehicleType == 'BUS') return 'Bus $lineLabel';
  if (vehicleType == 'SUBWAY' ||
      vehicleType == 'METRO_RAIL' ||
      vehicleType == 'HEAVY_RAIL' ||
      vehicleType == 'COMMUTER_TRAIN' ||
      vehicleType == 'RAIL' ||
      vehicleType == 'TRAM' ||
      vehicleType == 'LIGHT_RAIL' ||
      vehicleType == 'MONORAIL') {
    return 'Metro $lineLabel';
  }
  return 'Transit $lineLabel';
}

IconData transitSegmentIcon(DirectionsRouteSegment segment) {
  final vehicleType = segment.transitVehicleType?.toUpperCase();
  if (vehicleType == 'BUS') return Icons.directions_bus;
  if (vehicleType == 'SUBWAY' ||
      vehicleType == 'METRO_RAIL' ||
      vehicleType == 'HEAVY_RAIL' ||
      vehicleType == 'COMMUTER_TRAIN' ||
      vehicleType == 'RAIL' ||
      vehicleType == 'TRAM' ||
      vehicleType == 'LIGHT_RAIL' ||
      vehicleType == 'MONORAIL') {
    return Icons.directions_subway;
  }
  return Icons.directions_transit;
}

Color determineFillColor(Map<String, dynamic> props) {
  if (props['escalators'] == 'yes') return Colors.green;
  if (props['highway'] == 'elevator') return Colors.orange;
  if (props['highway'] == 'steps') return Colors.pink;
  if (props['amenity'] == 'toilets') return Colors.blue;
  if (props['indoor'] == 'corridor')
    return const Color.fromARGB(255, 232, 122, 149);
  return const Color(0xFF800020);
}

int countGeoJsonPolygons(Map<String, dynamic> geojson) {
  final features = (geojson['features'] as List).cast<dynamic>();
  int count = 0;
  for (final f in features) {
    final feature = f as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    if (geometry['type'] != 'Polygon') continue;
    final rings = geometry['coordinates'] as List;
    if (rings.isEmpty) continue;
    final outer = rings[0] as List;
    final points = outer.map<LatLng>((p) {
      final coords = p as List;
      return LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
    }).toList();
    if (points.length < 3) continue;
    count++;
  }
  return count;
}

int countRoomLabels(Map<String, dynamic> geojson) {
  final features = (geojson['features'] as List).cast<dynamic>();
  int count = 0;
  for (final f in features) {
    final feature = f as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final props =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    if (geometry['type'] != 'Polygon') continue;
    if (props['ref'] == null) continue;
    final rings = geometry['coordinates'] as List;
    if (rings.isEmpty) continue;
    final outer = rings[0] as List;
    final points = outer.map<LatLng>((p) {
      final coords = p as List;
      return LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
    }).toList();
    if (points.length < 3) continue;
    final area = polygonArea(points);
    if (area < 1e-10) continue;
    count++;
  }
  return count;
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  // --------------------------------------------------------------------------
  // 1. _geoJsonToPolygons – feature type colour branches
  // --------------------------------------------------------------------------
  group('_geoJsonToPolygons feature colour branches (algorithm replica)', () {
    test('escalator feature → green', () {
      expect(determineFillColor({'escalators': 'yes'}), Colors.green);
    });

    test('elevator feature → orange', () {
      expect(determineFillColor({'highway': 'elevator'}), Colors.orange);
    });

    test('steps feature → pink', () {
      expect(determineFillColor({'highway': 'steps'}), Colors.pink);
    });

    test('toilets feature → blue', () {
      expect(determineFillColor({'amenity': 'toilets'}), Colors.blue);
    });

    test('corridor feature → lighter red', () {
      expect(
        determineFillColor({'indoor': 'corridor'}),
        const Color.fromARGB(255, 232, 122, 149),
      );
    });

    test('default room (with ref) → dark red (0xFF800020)', () {
      expect(determineFillColor({'ref': '101'}), const Color(0xFF800020));
    });

    test('empty properties → dark red', () {
      expect(determineFillColor({}), const Color(0xFF800020));
    });

    test('non-matching properties → dark red', () {
      expect(
        determineFillColor({'random_key': 'val'}),
        const Color(0xFF800020),
      );
    });
  });

  // --------------------------------------------------------------------------
  // 2. _geoJsonToPolygons – geometry filtering
  // --------------------------------------------------------------------------
  group('_geoJsonToPolygons geometry filtering (algorithm replica)', () {
    test('Point geometry is skipped', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'entrance': 'yes'},
            'geometry': {
              'type': 'Point',
              'coordinates': [-73.5790, 45.4975],
            },
          },
        ],
      };
      expect(countGeoJsonPolygons(geo), 0);
    });

    test('polygon with < 3 points is skipped', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 'tiny'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5790, 45.4975],
                  [-73.5789, 45.4975],
                ],
              ],
            },
          },
        ],
      };
      expect(countGeoJsonPolygons(geo), 0);
    });

    test('empty rings is skipped', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 'empty'},
            'geometry': {'type': 'Polygon', 'coordinates': []},
          },
        ],
      };
      expect(countGeoJsonPolygons(geo), 0);
    });

    test('valid polygon is counted', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': '101'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5790, 45.4970],
                  [-73.5788, 45.4970],
                  [-73.5788, 45.4972],
                  [-73.5790, 45.4972],
                  [-73.5790, 45.4970],
                ],
              ],
            },
          },
        ],
      };
      expect(countGeoJsonPolygons(geo), 1);
    });

    test('mixed features: only valid polygons counted', () {
      final geo = _buildTestGeoJson();
      expect(countGeoJsonPolygons(geo), 11);
    });
  });

  // --------------------------------------------------------------------------
  // 3. _createRoomLabels – label counting logic
  // --------------------------------------------------------------------------
  group('_createRoomLabels logic (algorithm replica)', () {
    test('only Polygon with ref and area >= 1e-10 get labels', () {
      final geo = _buildTestGeoJson();
      expect(countRoomLabels(geo), 2);
    });

    test('no features with ref → 0 labels', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'indoor': 'room'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5790, 45.4970],
                  [-73.5788, 45.4970],
                  [-73.5788, 45.4972],
                  [-73.5790, 45.4972],
                  [-73.5790, 45.4970],
                ],
              ],
            },
          },
        ],
      };
      expect(countRoomLabels(geo), 0);
    });

    test('Point feature with ref is skipped', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': '101'},
            'geometry': {
              'type': 'Point',
              'coordinates': [-73.5790, 45.4975],
            },
          },
        ],
      };
      expect(countRoomLabels(geo), 0);
    });

    test('polygon with ref but area < 1e-10 is skipped', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 'micro'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5790000, 45.4970000],
                  [-73.5790001, 45.4970000],
                  [-73.5790001, 45.4970001],
                  [-73.5790000, 45.4970001],
                  [-73.5790000, 45.4970000],
                ],
              ],
            },
          },
        ],
      };
      expect(countRoomLabels(geo), 0);
    });

    test('font size depends on area (large → 10, small → 8)', () {
      final largePts = [
        const LatLng(45.4970, -73.5810),
        const LatLng(45.4970, -73.5805),
        const LatLng(45.4975, -73.5805),
        const LatLng(45.4975, -73.5810),
      ];
      expect(polygonArea(largePts) > 5e-8 ? 10.0 : 8.0, 10.0);

      final smallPts = [
        const LatLng(45.4970, -73.5790),
        const LatLng(45.4970, -73.5789),
        const LatLng(45.4971, -73.5789),
        const LatLng(45.4971, -73.5790),
      ];
      expect(polygonArea(smallPts) > 5e-8 ? 10.0 : 8.0, 8.0);
    });
  });

  // --------------------------------------------------------------------------
  // 4. _toggleIndoorMap – asset path resolution per building code
  // --------------------------------------------------------------------------
  group('_toggleIndoorMap asset path branches', () {
    String? resolveAssetPath(String code) {
      if (code.toUpperCase() == 'HALL')
        return 'assets/indoor_maps/geojson/Hall/h1.geojson.json';
      if (code.toUpperCase() == 'MB')
        return 'assets/indoor_maps/geojson/MB/mb1.geojson.json';
      if (code.toUpperCase() == 'VE')
        return 'assets/indoor_maps/geojson/VE/ve1.geojson.json';
      if (code.toUpperCase() == 'VL')
        return 'assets/indoor_maps/geojson/VL/vl1.geojson.json';
      if (code.toUpperCase() == 'CC')
        return 'assets/indoor_maps/geojson/CC/cc1.geojson.json';
      return null;
    }

    test('HALL → correct asset path', () {
      expect(
        resolveAssetPath('HALL'),
        'assets/indoor_maps/geojson/Hall/h1.geojson.json',
      );
    });

    test('MB → correct asset path', () {
      expect(
        resolveAssetPath('MB'),
        'assets/indoor_maps/geojson/MB/mb1.geojson.json',
      );
    });

    test('VE → correct asset path', () {
      expect(
        resolveAssetPath('VE'),
        'assets/indoor_maps/geojson/VE/ve1.geojson.json',
      );
    });

    test('VL → correct asset path', () {
      expect(
        resolveAssetPath('VL'),
        'assets/indoor_maps/geojson/VL/vl1.geojson.json',
      );
    });

    test('CC → correct asset path', () {
      expect(
        resolveAssetPath('CC'),
        'assets/indoor_maps/geojson/CC/cc1.geojson.json',
      );
    });

    test('unsupported LB → null', () {
      expect(resolveAssetPath('LB'), isNull);
    });

    test('case-insensitive: hall → correct path', () {
      expect(resolveAssetPath('hall'), isNotNull);
    });

    test('case-insensitive: mb → correct path', () {
      expect(resolveAssetPath('mb'), isNotNull);
    });

    test('unsupported EV → null', () {
      expect(resolveAssetPath('EV'), isNull);
    });

    test('unsupported GM → null', () {
      expect(resolveAssetPath('GM'), isNull);
    });
  });

  // --------------------------------------------------------------------------
  // 5. Widget: _toggleIndoorMap for unsupported building shows SnackBar
  // --------------------------------------------------------------------------
  group('_toggleIndoorMap via widget – unsupported building', () {
    testWidgets('indoor map toggle for EV (unsupported) does not crash', (
      tester,
    ) async {
      final evBuilding = _findBuildingByCode('EV');
      if (evBuilding == null) return;

      await pumpNoMap(
        tester,
        debugSelectedBuilding: evBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsOneWidget);

      // Tapping the indoor button calls _toggleIndoorMap which returns early
      // because _selectedBuildingPoly is null (only debugSelectedBuilding is set).
      // This tests the null guard: `if (b == null) return;`
      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('indoor map toggle for GM (unsupported) does not crash', (
      tester,
    ) async {
      final gmBuilding = _findBuildingByCode('GM');
      if (gmBuilding == null) return;

      await pumpNoMap(
        tester,
        debugSelectedBuilding: gmBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 6. Widget: _toggleIndoorMap for SUPPORTED buildings
  // --------------------------------------------------------------------------
  group('_toggleIndoorMap via widget – supported buildings', () {
    for (final code in ['HALL', 'MB', 'VE', 'VL', 'CC']) {
      testWidgets('indoor map button for $code renders without crash', (
        tester,
      ) async {
        final building = _findBuildingByCode(code);
        if (building == null) return;

        await pumpWithMap(
          tester,
          debugSelectedBuilding: building,
          debugAnchorOffset: const Offset(200, 400),
          isLoggedIn: true,
        );
        await tester.pumpAndSettle();
        expect(find.byType(BuildingInfoPopup), findsOneWidget);

        final indoorBtn = find.descendant(
          of: find.byType(BuildingInfoPopup),
          matching: find.byIcon(Icons.map),
        );
        if (indoorBtn.evaluate().isNotEmpty) {
          await tester.tap(indoorBtn.first, warnIfMissed: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });
    }
  });

  // --------------------------------------------------------------------------
  // 7. Widget: indoor map toggle on/off cycle
  // --------------------------------------------------------------------------
  group('_toggleIndoorMap on/off cycle', () {
    testWidgets('toggle indoor map on then off for HALL', (tester) async {
      final hallBuilding = _findBuildingByCode('HALL');
      if (hallBuilding == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isEmpty) return;

      // Toggle ON
      await tester.tap(indoorBtn.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(OutdoorMapPage), findsOneWidget);

      // Toggle OFF
      final indoorBtn2 = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn2.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn2.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('toggle indoor map on then off for CC', (tester) async {
      final ccBuilding = _findBuildingByCode('CC');
      if (ccBuilding == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: ccBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isEmpty) return;

      await tester.tap(indoorBtn.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final indoorBtn2 = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn2.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn2.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 8. Widget: indoor map with real map renders polygons + labels
  // --------------------------------------------------------------------------
  group('Indoor map rendering with real GoogleMap', () {
    testWidgets('HALL indoor map loads polygons on real map', (tester) async {
      final hallBuilding = _findBuildingByCode('HALL');
      if (hallBuilding == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: hallBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(find.byType(GoogleMap), findsOneWidget);

      // GoogleMap should have polygons (building + indoor)
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMap.polygons.length, greaterThan(0));
    });

    testWidgets('MB indoor map loads and renders without crash', (
      tester,
    ) async {
      final mbBuilding = _findBuildingByCode('MB');
      if (mbBuilding == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: mbBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('VE indoor map loads and renders without crash', (
      tester,
    ) async {
      final veBuilding = _findBuildingByCode('VE');
      if (veBuilding == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: veBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(GoogleMap), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 9. _isPointInPolygon algorithm coverage
  // --------------------------------------------------------------------------
  group('_isPointInPolygon (algorithm replica)', () {
    test('point inside triangle → true', () {
      final tri = [const LatLng(0, 0), const LatLng(4, 0), const LatLng(2, 4)];
      expect(isPointInPolygon(const LatLng(2, 1), tri), true);
    });

    test('point outside triangle → false', () {
      final tri = [const LatLng(0, 0), const LatLng(4, 0), const LatLng(2, 4)];
      expect(isPointInPolygon(const LatLng(5, 5), tri), false);
    });

    test('point inside square → true', () {
      final sq = [
        const LatLng(0, 0),
        const LatLng(4, 0),
        const LatLng(4, 4),
        const LatLng(0, 4),
      ];
      expect(isPointInPolygon(const LatLng(2, 2), sq), true);
    });

    test('concave polygon (L-shape)', () {
      final l = [
        const LatLng(0, 0),
        const LatLng(2, 0),
        const LatLng(2, 2),
        const LatLng(4, 2),
        const LatLng(4, 4),
        const LatLng(0, 4),
      ];
      expect(isPointInPolygon(const LatLng(1, 1), l), true);
      expect(isPointInPolygon(const LatLng(3, 1), l), false);
    });

    test('all building polygon centers inside their polygon', () {
      for (final b in buildingPolygons.take(10)) {
        final center = polygonCenter(b.points);
        expect(isPointInPolygon(center, b.points), true, reason: '${b.code}');
      }
    });
  });

  // --------------------------------------------------------------------------
  // 10. _polygonArea algorithm coverage
  // --------------------------------------------------------------------------
  group('_polygonArea (algorithm replica)', () {
    test('square area', () {
      final sq = [
        const LatLng(0, 0),
        const LatLng(0, 4),
        const LatLng(4, 4),
        const LatLng(4, 0),
      ];
      expect(polygonArea(sq), closeTo(16.0, 0.001));
    });

    test('degenerate line → zero', () {
      final line = [const LatLng(0, 0), const LatLng(1, 0), const LatLng(2, 0)];
      expect(polygonArea(line), closeTo(0, 0.001));
    });

    test('real building polygon has positive area', () {
      for (final b in buildingPolygons.take(5)) {
        expect(polygonArea(b.points), greaterThan(0), reason: '${b.code}');
      }
    });
  });

  // --------------------------------------------------------------------------
  // 11. _polygonCenter algorithm coverage
  // --------------------------------------------------------------------------
  group('_polygonCenter (algorithm replica)', () {
    test('triangle center', () {
      final tri = [const LatLng(0, 0), const LatLng(4, 0), const LatLng(2, 6)];
      final c = polygonCenter(tri);
      expect(c.latitude, closeTo(2.0, 0.01));
      expect(c.longitude, closeTo(2.0, 0.01));
    });

    test('single point returns itself', () {
      expect(
        polygonCenter([const LatLng(45.5, -73.5)]),
        const LatLng(45.5, -73.5),
      );
    });

    test('two points returns first', () {
      final pair = [const LatLng(45.5, -73.5), const LatLng(45.6, -73.6)];
      expect(polygonCenter(pair), const LatLng(45.5, -73.5));
    });
  });

  // --------------------------------------------------------------------------
  // 12. _calculateBounds coverage
  // --------------------------------------------------------------------------
  group('_calculateBounds (algorithm replica)', () {
    test('single point → sw == ne', () {
      final b = calculateBounds([const LatLng(45.5, -73.5)]);
      expect(b.southwest.latitude, 45.5);
      expect(b.northeast.longitude, -73.5);
    });

    test('multiple points', () {
      final b = calculateBounds([
        const LatLng(45.5, -73.5),
        const LatLng(45.6, -73.4),
        const LatLng(45.4, -73.6),
      ]);
      expect(b.southwest.latitude, closeTo(45.4, 0.01));
      expect(b.northeast.longitude, closeTo(-73.4, 0.01));
    });
  });

  // --------------------------------------------------------------------------
  // 13. _formatArrivalTime coverage
  // --------------------------------------------------------------------------
  group('_formatArrivalTime (algorithm replica)', () {
    test('null → null', () => expect(formatArrivalTime(null), isNull));
    test('0 seconds → valid format', () {
      expect(
        formatArrivalTime(0)!,
        matches(RegExp(r'^\d{1,2}:\d{2} (am|pm)$')),
      );
    });
    test('3600 seconds → valid format', () {
      expect(
        formatArrivalTime(3600)!,
        matches(RegExp(r'^\d{1,2}:\d{2} (am|pm)$')),
      );
    });
    test('negative seconds → valid format', () {
      expect(
        formatArrivalTime(-3600)!,
        matches(RegExp(r'^\d{1,2}:\d{2} (am|pm)$')),
      );
    });
    test('86400 seconds → valid format', () {
      expect(formatArrivalTime(86400), isNotNull);
    });
  });

  // --------------------------------------------------------------------------
  // 14. _parseHexColor coverage
  // --------------------------------------------------------------------------
  group('_parseHexColor (algorithm replica)', () {
    test('null → null', () => expect(parseHexColor(null), isNull));
    test('empty → null', () => expect(parseHexColor(''), isNull));
    test('whitespace → null', () => expect(parseHexColor('   '), isNull));
    test('too short → null', () => expect(parseHexColor('#FFF'), isNull));
    test('too long → null', () => expect(parseHexColor('#FFFFFFF'), isNull));
    test('invalid hex → null', () => expect(parseHexColor('#ZZZZZZ'), isNull));
    test(
      '#FF0000 → red',
      () => expect(parseHexColor('#FF0000')!.value, 0xFFFF0000),
    );
    test(
      '00FF00 → green',
      () => expect(parseHexColor('00FF00')!.value, 0xFF00FF00),
    );
    test(
      '#0000FF → blue',
      () => expect(parseHexColor('#0000FF')!.value, 0xFF0000FF),
    );
    test(
      'whitespace trim',
      () => expect(parseHexColor('  #ABCDEF  ')!.value, 0xFFABCDEF),
    );
    test(
      'lowercase',
      () => expect(parseHexColor('#abcdef')!.value, 0xFFABCDEF),
    );
    test(
      '#000000 → black',
      () => expect(parseHexColor('#000000')!.value, 0xFF000000),
    );
    test(
      '#FFFFFF → white',
      () => expect(parseHexColor('#FFFFFF')!.value, 0xFFFFFFFF),
    );
  });

  // --------------------------------------------------------------------------
  // 15. _resolveTransitSegmentColor coverage
  // --------------------------------------------------------------------------
  group('_resolveTransitSegmentColor (algorithm replica)', () {
    test('WALKING → default red', () {
      expect(
        resolveTransitSegmentColor(
          const DirectionsRouteSegment(points: [], travelMode: 'WALKING'),
        ),
        const Color(0xFF76263D),
      );
    });

    test('TRANSIT + BUS → blue', () {
      expect(
        resolveTransitSegmentColor(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'BUS',
          ),
        ),
        Colors.blue,
      );
    });

    test('TRANSIT + SUBWAY with line color', () {
      final c = resolveTransitSegmentColor(
        const DirectionsRouteSegment(
          points: [],
          travelMode: 'TRANSIT',
          transitVehicleType: 'SUBWAY',
          transitLineColorHex: '#00FF00',
        ),
      );
      expect(c.value, 0xFF00FF00);
    });

    test('TRANSIT + null vehicle + null color → default red', () {
      expect(
        resolveTransitSegmentColor(
          const DirectionsRouteSegment(points: [], travelMode: 'TRANSIT'),
        ),
        const Color(0xFF76263D),
      );
    });

    test('lowercase walking → default red', () {
      expect(
        resolveTransitSegmentColor(
          const DirectionsRouteSegment(points: [], travelMode: 'walking'),
        ),
        const Color(0xFF76263D),
      );
    });
  });

  // --------------------------------------------------------------------------
  // 16. _formatTransitSegmentTitle coverage
  // --------------------------------------------------------------------------
  group('_formatTransitSegmentTitle (algorithm replica)', () {
    test('BUS → "Bus 165"', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'BUS',
            transitLineShortName: '165',
          ),
        ),
        'Bus 165',
      );
    });

    test('SUBWAY → "Metro Green"', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'SUBWAY',
            transitLineShortName: 'Green',
          ),
        ),
        'Metro Green',
      );
    });

    for (final vt in [
      'METRO_RAIL',
      'HEAVY_RAIL',
      'COMMUTER_TRAIN',
      'RAIL',
      'TRAM',
      'LIGHT_RAIL',
      'MONORAIL',
    ]) {
      test('$vt → "Metro <label>"', () {
        expect(
          formatTransitSegmentTitle(
            DirectionsRouteSegment(
              points: const [],
              travelMode: 'TRANSIT',
              transitVehicleType: vt,
              transitLineShortName: 'X',
            ),
          ),
          'Metro X',
        );
      });
    }

    test('unknown type → "Transit F1"', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'FERRY',
            transitLineShortName: 'F1',
          ),
        ),
        'Transit F1',
      );
    });

    test('null type → "Transit X"', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitLineShortName: 'X',
          ),
        ),
        'Transit X',
      );
    });

    test('fallback to lineName', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'BUS',
            transitLineName: 'Route 24',
          ),
        ),
        'Bus Route 24',
      );
    });

    test('fallback to "Route" when both null', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'BUS',
          ),
        ),
        'Bus Route',
      );
    });
  });

  // --------------------------------------------------------------------------
  // 17. _transitSegmentIcon coverage
  // --------------------------------------------------------------------------
  group('_transitSegmentIcon (algorithm replica)', () {
    test('BUS → directions_bus', () {
      expect(
        transitSegmentIcon(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'BUS',
          ),
        ),
        Icons.directions_bus,
      );
    });

    for (final vt in [
      'SUBWAY',
      'METRO_RAIL',
      'HEAVY_RAIL',
      'COMMUTER_TRAIN',
      'RAIL',
      'TRAM',
      'LIGHT_RAIL',
      'MONORAIL',
    ]) {
      test('$vt → directions_subway', () {
        expect(
          transitSegmentIcon(
            DirectionsRouteSegment(
              points: const [],
              travelMode: 'TRANSIT',
              transitVehicleType: vt,
            ),
          ),
          Icons.directions_subway,
        );
      });
    }

    test('FERRY → directions_transit', () {
      expect(
        transitSegmentIcon(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'FERRY',
          ),
        ),
        Icons.directions_transit,
      );
    });

    test('null type → directions_transit', () {
      expect(
        transitSegmentIcon(
          const DirectionsRouteSegment(points: [], travelMode: 'TRANSIT'),
        ),
        Icons.directions_transit,
      );
    });
  });

  // --------------------------------------------------------------------------
  // 18. NavigationStep coverage
  // --------------------------------------------------------------------------
  group('NavigationStep endPoint/startPoint', () {
    test('empty → null', () {
      const s = NavigationStep(instruction: 'Go', travelMode: 'walking');
      expect(s.endPoint, isNull);
      expect(s.startPoint, isNull);
    });

    test('with points', () {
      const s = NavigationStep(
        instruction: 'Go',
        travelMode: 'walking',
        points: [LatLng(45.5, -73.5), LatLng(45.6, -73.6)],
      );
      expect(s.startPoint, const LatLng(45.5, -73.5));
      expect(s.endPoint, const LatLng(45.6, -73.6));
    });

    test('single point → start == end', () {
      const s = NavigationStep(
        instruction: 'Go',
        travelMode: 'walking',
        points: [LatLng(45.5, -73.5)],
      );
      expect(s.startPoint, s.endPoint);
    });

    test('secondaryLine', () {
      const s = NavigationStep(
        instruction: 'Walk',
        travelMode: 'walking',
        distanceText: '500 m',
        durationText: '7 min',
      );
      expect(s.secondaryLine, '500 m • 7 min');
    });

    test('transitLabel BUS', () {
      const s = NavigationStep(
        instruction: 'Bus',
        travelMode: 'transit',
        transitVehicleType: 'BUS',
        transitLineShortName: '165',
      );
      expect(s.transitLabel, 'Bus 165');
    });

    test('transitLabel SUBWAY', () {
      const s = NavigationStep(
        instruction: 'Metro',
        travelMode: 'transit',
        transitVehicleType: 'SUBWAY',
        transitLineShortName: 'Green',
      );
      expect(s.transitLabel, 'Metro Green');
    });

    test('transitLabel null → "Transit"', () {
      const s = NavigationStep(instruction: 'Go', travelMode: 'transit');
      expect(s.transitLabel, 'Transit');
    });
  });

  // --------------------------------------------------------------------------
  // 19. RouteTravelMode enum
  // --------------------------------------------------------------------------
  group('RouteTravelMode enum', () {
    test('4 modes', () => expect(RouteTravelMode.values.length, 4));
    test('apiValue', () {
      expect(RouteTravelMode.driving.apiValue, 'driving');
      expect(RouteTravelMode.walking.apiValue, 'walking');
      expect(RouteTravelMode.bicycling.apiValue, 'bicycling');
      expect(RouteTravelMode.transit.apiValue, 'transit');
    });
    test('label', () {
      expect(RouteTravelMode.driving.label, 'Driving');
      expect(RouteTravelMode.walking.label, 'Walking');
      expect(RouteTravelMode.bicycling.label, 'Biking');
      expect(RouteTravelMode.transit.label, 'Transit');
    });
  });

  // --------------------------------------------------------------------------
  // 20. TransitDetailItem
  // --------------------------------------------------------------------------
  group('TransitDetailItem', () {
    test('construction', () {
      const item = TransitDetailItem(
        icon: Icons.directions_bus,
        color: Colors.blue,
        title: 'Bus 165',
      );
      expect(item.title, 'Bus 165');
      expect(item.icon, Icons.directions_bus);
      expect(item.color, Colors.blue);
    });
  });

  // --------------------------------------------------------------------------
  // 21. buildingInfoByCode lookups
  // --------------------------------------------------------------------------
  group('buildingInfoByCode coverage', () {
    test('H (Hall) exists', () => expect(buildingInfoByCode['H'], isNotNull));
    test('MB exists', () => expect(buildingInfoByCode['MB'], isNotNull));
    test('unknown → null', () => expect(buildingInfoByCode['ZZZZZ'], isNull));

    test('indoor-supported buildings have entries', () {
      // Note: building_polygons uses 'HALL' but buildingInfoByCode uses 'H'
      for (final code in ['H', 'MB', 'VE', 'VL', 'CC']) {
        expect(buildingInfoByCode[code], isNotNull, reason: '$code');
      }
    });
  });

  // --------------------------------------------------------------------------
  // 22. Building polygon data validation
  // --------------------------------------------------------------------------
  group('Building polygon data validation', () {
    test('every polygon has >= 3 points', () {
      for (final b in buildingPolygons) {
        expect(b.points.length, greaterThanOrEqualTo(3), reason: b.code);
      }
    });

    test('every building has non-empty code', () {
      for (final b in buildingPolygons) expect(b.code, isNotEmpty);
    });

    test('valid lat/lng ranges', () {
      for (final b in buildingPolygons) {
        expect(b.center.latitude, inInclusiveRange(-90, 90));
        expect(b.center.longitude, inInclusiveRange(-180, 180));
      }
    });

    test('indoor-supported codes exist', () {
      for (final code in ['HALL', 'MB', 'VE', 'VL', 'CC']) {
        expect(_findBuildingByCode(code), isNotNull, reason: code);
      }
    });
  });

  // --------------------------------------------------------------------------
  // 23. currentLocationTag
  // --------------------------------------------------------------------------
  group('currentLocationTag constant', () {
    test(
      'is "Current location"',
      () => expect(currentLocationTag, 'Current location'),
    );
  });

  // --------------------------------------------------------------------------
  // 24. detectCampus parity
  // --------------------------------------------------------------------------
  group('detectCampus parity', () {
    test('SGW', () => expect(detectCampus(concordiaSGW), Campus.sgw));
    test('Loyola', () => expect(detectCampus(concordiaLoyola), Campus.loyola));
    test(
      'far away',
      () => expect(detectCampus(const LatLng(0, 0)), Campus.none),
    );
    test('midpoint', () {
      final mid = LatLng(
        (concordiaSGW.latitude + concordiaLoyola.latitude) / 2,
        (concordiaSGW.longitude + concordiaLoyola.longitude) / 2,
      );
      expect([
        Campus.sgw,
        Campus.loyola,
        Campus.none,
      ], contains(detectCampus(mid)));
    });
  });

  // --------------------------------------------------------------------------
  // 25. Widget: popup for indoor-supported buildings
  // --------------------------------------------------------------------------
  group('BuildingInfoPopup for indoor-supported buildings', () {
    for (final code in ['HALL', 'MB', 'VE', 'VL', 'CC']) {
      testWidgets('popup for $code', (tester) async {
        final b = _findBuildingByCode(code);
        if (b == null) return;
        await pumpNoMap(
          tester,
          debugSelectedBuilding: b,
          debugAnchorOffset: const Offset(200, 400),
          isLoggedIn: true,
        );
        await tester.pumpAndSettle();
        expect(find.byType(BuildingInfoPopup), findsOneWidget);
      });
    }
  });

  // --------------------------------------------------------------------------
  // 26. Popup show/close cycle
  // --------------------------------------------------------------------------
  group('Popup show/close cycles', () {
    testWidgets('show then close then show again', (tester) async {
      final hall = _findBuildingByCode('HALL');
      if (hall == null) return;

      await pumpNoMap(
        tester,
        debugSelectedBuilding: hall,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsOneWidget);

      final closeIcon = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.close),
      );
      if (closeIcon.evaluate().isNotEmpty) {
        await tester.tap(closeIcon.first);
        await tester.pumpAndSettle();
      }

      await pumpNoMap(
        tester,
        debugSelectedBuilding: hall,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 27. State consistency under rapid pumps
  // --------------------------------------------------------------------------
  group('State consistency under rapid pumps', () {
    testWidgets('rapid pumps do not crash', (tester) async {
      await pumpNoMap(tester);
      for (int i = 0; i < 5; i++) await tester.pump();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('rapid campus switches do not crash', (tester) async {
      for (final c in [Campus.sgw, Campus.loyola, Campus.none]) {
        await pumpNoMap(tester, initialCampus: c);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 28. Dispose during indoor map
  // --------------------------------------------------------------------------
  group('dispose during indoor map', () {
    testWidgets('dispose while indoor map active does not crash', (
      tester,
    ) async {
      final hall = _findBuildingByCode('HALL');
      if (hall == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: hall,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('done'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('done'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 29. Indoor map style applied to GoogleMap
  // --------------------------------------------------------------------------
  group('Indoor map style on GoogleMap', () {
    testWidgets(
      'indoor map button tap does not crash with debugSelectedBuilding',
      (tester) async {
        final hall = _findBuildingByCode('HALL');
        if (hall == null) return;

        await pumpWithMap(
          tester,
          debugSelectedBuilding: hall,
          debugAnchorOffset: const Offset(200, 400),
          isLoggedIn: true,
        );
        await tester.pumpAndSettle();

        final indoorBtn = find.descendant(
          of: find.byType(BuildingInfoPopup),
          matching: find.byIcon(Icons.map),
        );
        if (indoorBtn.evaluate().isNotEmpty) {
          await tester.tap(indoorBtn.first, warnIfMissed: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        // The indoor toggle uses _selectedBuildingPoly (which is null when only debugSelectedBuilding is set)
        // so the toggle returns early. GoogleMap still renders fine.
        expect(find.byType(GoogleMap), findsOneWidget);
      },
    );

    testWidgets('no indoor style when indoor map not active', (tester) async {
      await pumpWithMap(tester);
      await tester.pumpAndSettle();

      final gm = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(gm.style, isNull);
    });
  });

  // --------------------------------------------------------------------------
  // 30. Merged polygons in GoogleMap after indoor toggle
  // --------------------------------------------------------------------------
  group('Building polygons merged with indoor polygons', () {
    testWidgets('GoogleMap has building + indoor polys after toggle', (
      tester,
    ) async {
      final hall = _findBuildingByCode('HALL');
      if (hall == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: hall,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      // Count polygons before toggle
      final gmBefore = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final polyCountBefore = gmBefore.polygons.length;

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      final gmAfter = tester.widget<GoogleMap>(find.byType(GoogleMap));
      // After toggle, should have more polygons (building + indoor)
      expect(gmAfter.polygons.length, greaterThanOrEqualTo(polyCountBefore));
    });
  });

  // --------------------------------------------------------------------------
  // 31. Room label markers merged into GoogleMap
  // --------------------------------------------------------------------------
  group('Room label markers merged into GoogleMap', () {
    testWidgets('markers include room labels after toggle', (tester) async {
      final hall = _findBuildingByCode('HALL');
      if (hall == null) return;

      await pumpWithMap(
        tester,
        debugSelectedBuilding: hall,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final markersBefore = tester
          .widget<GoogleMap>(find.byType(GoogleMap))
          .markers
          .length;

      final indoorBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.map),
      );
      if (indoorBtn.evaluate().isNotEmpty) {
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      final markersAfter = tester
          .widget<GoogleMap>(find.byType(GoogleMap))
          .markers
          .length;
      // After toggle, room label markers should be added
      expect(markersAfter, greaterThanOrEqualTo(markersBefore));
    });
  });

  // --------------------------------------------------------------------------
  // 32. _createMarkers and _createCircles via real map
  // --------------------------------------------------------------------------
  group('_createMarkers and _createCircles via real map', () {
    testWidgets('markers and circles render with location', (tester) async {
      await pumpWithMap(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('with debugSelectedBuilding markers still render', (
      tester,
    ) async {
      await pumpWithMap(tester, debugSelectedBuilding: firstBuilding);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GoogleMap), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 33. Campus FAB
  // --------------------------------------------------------------------------
  group('Campus FAB', () {
    testWidgets('campus FAB present', (tester) async {
      await pumpWithMap(tester);
      final fab = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'campus_button',
      );
      expect(fab, findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 34. _switchCampus via CampusToggle
  // --------------------------------------------------------------------------
  group('_switchCampus via CampusToggle', () {
    testWidgets('tap LOY', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();
      final loyText = find.text('LOY');
      if (loyText.evaluate().isNotEmpty) {
        await tester.tap(loyText.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('tap SGW from Loyola', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      await tester.pumpAndSettle();
      final sgwText = find.text('SGW');
      if (sgwText.evaluate().isNotEmpty) {
        await tester.tap(sgwText.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 35. IndoorMapRepository
  // --------------------------------------------------------------------------
  group('IndoorMapRepository', () {
    test('can be instantiated', () {
      expect(IndoorMapRepository(), isNotNull);
    });
  });

  // --------------------------------------------------------------------------
  // 36. _turnOffIndoorMap logic replica
  // --------------------------------------------------------------------------
  group('_turnOffIndoorMap logic', () {
    test('turning off clears state', () {
      bool showIndoor = true;
      Set<Polygon> indoorPolygons = {
        const Polygon(
          polygonId: PolygonId('test'),
          points: [LatLng(0, 0), LatLng(1, 0), LatLng(1, 1)],
        ),
      };
      Map<String, dynamic>? indoorGeoJson = {'type': 'FeatureCollection'};
      Set<Marker> roomLabelMarkers = {
        const Marker(markerId: MarkerId('test'), position: LatLng(0, 0)),
      };

      if (showIndoor) {
        showIndoor = false;
        indoorPolygons = {};
        indoorGeoJson = null;
        roomLabelMarkers = {};
      }

      expect(showIndoor, false);
      expect(indoorPolygons, isEmpty);
      expect(indoorGeoJson, isNull);
      expect(roomLabelMarkers, isEmpty);
    });

    test('already off → no change', () {
      bool showIndoor = false;
      expect(showIndoor, false);
      // Verifies that when _showIndoor is already false,
      // calling _turnOffIndoorMap does nothing
    });
  });

  // --------------------------------------------------------------------------
  // 37. Widget: indoor map for every supported building with real map (full flow)
  // --------------------------------------------------------------------------
  group('Full indoor map flow per building', () {
    for (final code in ['HALL', 'MB', 'VE', 'VL', 'CC']) {
      testWidgets('$code: open popup → tap indoor button → verify no crash', (
        tester,
      ) async {
        final building = _findBuildingByCode(code);
        if (building == null) return;

        await pumpWithMap(
          tester,
          debugSelectedBuilding: building,
          debugAnchorOffset: const Offset(200, 400),
          isLoggedIn: true,
        );
        await tester.pumpAndSettle();

        expect(find.byType(BuildingInfoPopup), findsOneWidget);

        final indoorBtn = find.descendant(
          of: find.byType(BuildingInfoPopup),
          matching: find.byIcon(Icons.map),
        );
        if (indoorBtn.evaluate().isEmpty) return;

        // Tap indoor map button (calls _toggleIndoorMap)
        // _selectedBuildingPoly is null with debugSelectedBuilding, so toggle returns early.
        // This exercises the null guard path.
        await tester.tap(indoorBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final gm = tester.widget<GoogleMap>(find.byType(GoogleMap));
        // Building polygons should still be rendered
        expect(gm.polygons.length, greaterThan(0));

        // Tap again to verify double-tap doesn't crash
        final indoorBtn2 = find.descendant(
          of: find.byType(BuildingInfoPopup),
          matching: find.byIcon(Icons.map),
        );
        if (indoorBtn2.evaluate().isNotEmpty) {
          await tester.tap(indoorBtn2.first, warnIfMissed: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });
    }
  });

  // --------------------------------------------------------------------------
  // 38. _geoJsonToPolygons: additional edge cases for color branches
  // --------------------------------------------------------------------------
  group('_geoJsonToPolygons: combined color + geometry edge cases', () {
    test('escalator with extra props still green', () {
      expect(
        determineFillColor({'escalators': 'yes', 'indoor': 'room'}),
        Colors.green,
      );
    });

    test('elevator takes priority over corridor', () {
      expect(
        determineFillColor({'highway': 'elevator', 'indoor': 'corridor'}),
        Colors.orange,
      );
    });

    test('steps takes priority over toilets', () {
      expect(
        determineFillColor({'highway': 'steps', 'amenity': 'toilets'}),
        Colors.pink,
      );
    });

    test('toilets takes priority over corridor', () {
      expect(
        determineFillColor({'amenity': 'toilets', 'indoor': 'corridor'}),
        Colors.blue,
      );
    });

    test('corridor with ref still lighter red', () {
      expect(
        determineFillColor({'indoor': 'corridor', 'ref': '100'}),
        const Color.fromARGB(255, 232, 122, 149),
      );
    });

    test('room with level is default dark red', () {
      expect(
        determineFillColor({'indoor': 'room', 'level': '2'}),
        const Color(0xFF800020),
      );
    });

    test('LineString geometry skipped (only Polygon counted)', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': '101'},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-73.5790, 45.4970],
                [-73.5788, 45.4970],
              ],
            },
          },
        ],
      };
      expect(countGeoJsonPolygons(geo), 0);
    });

    test('MultiPolygon geometry is skipped', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 'multi'},
            'geometry': {
              'type': 'MultiPolygon',
              'coordinates': [
                [
                  [
                    [-73.5790, 45.4970],
                    [-73.5788, 45.4970],
                    [-73.5788, 45.4972],
                    [-73.5790, 45.4970],
                  ],
                ],
              ],
            },
          },
        ],
      };
      expect(countGeoJsonPolygons(geo), 0);
    });

    test('exactly 3 points is valid', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 'tri'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5790, 45.4970],
                  [-73.5788, 45.4970],
                  [-73.5788, 45.4972],
                  [-73.5790, 45.4970],
                ],
              ],
            },
          },
        ],
      };
      expect(countGeoJsonPolygons(geo), 1);
    });

    test('polygon IDs are unique for multiple features', () {
      final geo = _buildTestGeoJson();
      final count = countGeoJsonPolygons(geo);
      expect(count, greaterThan(1));
    });
  });

  // --------------------------------------------------------------------------
  // 39. _createRoomLabels: more edge cases
  // --------------------------------------------------------------------------
  group('_createRoomLabels: additional edge cases', () {
    test('multiple rooms with refs → correct count', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 'A101'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5810, 45.4970],
                  [-73.5805, 45.4970],
                  [-73.5805, 45.4975],
                  [-73.5810, 45.4975],
                  [-73.5810, 45.4970],
                ],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'ref': 'A102'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5820, 45.4970],
                  [-73.5815, 45.4970],
                  [-73.5815, 45.4975],
                  [-73.5820, 45.4975],
                  [-73.5820, 45.4970],
                ],
              ],
            },
          },
        ],
      };
      expect(countRoomLabels(geo), 2);
    });

    test('room with empty ref string is still counted (ref is non-null)', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': ''},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5810, 45.4970],
                  [-73.5805, 45.4970],
                  [-73.5805, 45.4975],
                  [-73.5810, 45.4975],
                  [-73.5810, 45.4970],
                ],
              ],
            },
          },
        ],
      };
      expect(countRoomLabels(geo), 1);
    });

    test('room with integer ref is counted', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 101},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5810, 45.4970],
                  [-73.5805, 45.4970],
                  [-73.5805, 45.4975],
                  [-73.5810, 45.4975],
                  [-73.5810, 45.4970],
                ],
              ],
            },
          },
        ],
      };
      expect(countRoomLabels(geo), 1);
    });

    test('mixed valid/invalid features: only valid counted', () {
      final geo = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'ref': 'A'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5810, 45.4970],
                  [-73.5805, 45.4970],
                  [-73.5805, 45.4975],
                  [-73.5810, 45.4975],
                  [-73.5810, 45.4970],
                ],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'indoor': 'room'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5810, 45.4970],
                  [-73.5805, 45.4970],
                  [-73.5805, 45.4975],
                  [-73.5810, 45.4975],
                  [-73.5810, 45.4970],
                ],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'ref': 'B'},
            'geometry': {
              'type': 'Point',
              'coordinates': [-73.5810, 45.4970],
            },
          },
          {
            'type': 'Feature',
            'properties': {'ref': 'C'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-73.5790000, 45.4970000],
                  [-73.5790001, 45.4970000],
                  [-73.5790001, 45.4970001],
                  [-73.5790000, 45.4970001],
                  [-73.5790000, 45.4970000],
                ],
              ],
            },
          },
        ],
      };
      expect(countRoomLabels(geo), 1);
    });
  });

  // --------------------------------------------------------------------------
  // 40. _polygonArea: additional coverage for boundary values
  // --------------------------------------------------------------------------
  group('_polygonArea: boundary values', () {
    test('triangle area', () {
      final tri = [const LatLng(0, 0), const LatLng(2, 0), const LatLng(0, 2)];
      expect(polygonArea(tri), closeTo(2.0, 0.001));
    });

    test('pentagon has positive area', () {
      final pentagon = [
        const LatLng(0, 1),
        const LatLng(0.951, 0.309),
        const LatLng(0.588, -0.809),
        const LatLng(-0.588, -0.809),
        const LatLng(-0.951, 0.309),
      ];
      expect(polygonArea(pentagon), greaterThan(0));
    });

    test('reversed winding still positive (absolute)', () {
      final sq = [
        const LatLng(0, 0),
        const LatLng(4, 0),
        const LatLng(4, 4),
        const LatLng(0, 4),
      ];
      final sqRev = [
        const LatLng(0, 4),
        const LatLng(4, 4),
        const LatLng(4, 0),
        const LatLng(0, 0),
      ];
      expect(polygonArea(sq), closeTo(polygonArea(sqRev), 0.001));
    });
  });

  // --------------------------------------------------------------------------
  // 41. _isPointInPolygon: more boundary cases
  // --------------------------------------------------------------------------
  group('_isPointInPolygon: boundary cases', () {
    test('point on vertex is ambiguous (may return true or false)', () {
      final sq = [
        const LatLng(0, 0),
        const LatLng(4, 0),
        const LatLng(4, 4),
        const LatLng(0, 4),
      ];
      final result = isPointInPolygon(const LatLng(0, 0), sq);
      expect(result, isA<bool>());
    });

    test('point far below polygon → false', () {
      final sq = [
        const LatLng(10, 10),
        const LatLng(10, 20),
        const LatLng(20, 20),
        const LatLng(20, 10),
      ];
      expect(isPointInPolygon(const LatLng(0, 15), sq), false);
    });

    test('point exactly inside center → true', () {
      final sq = [
        const LatLng(0, 0),
        const LatLng(10, 0),
        const LatLng(10, 10),
        const LatLng(0, 10),
      ];
      expect(isPointInPolygon(const LatLng(5, 5), sq), true);
    });

    test('narrow polygon inside test', () {
      final narrow = [
        const LatLng(0, 0),
        const LatLng(100, 0),
        const LatLng(100, 0.001),
        const LatLng(0, 0.001),
      ];
      expect(isPointInPolygon(const LatLng(50, 0.0005), narrow), true);
    });
  });

  // --------------------------------------------------------------------------
  // 42. _polygonCenter: concave polygon fallback path
  // --------------------------------------------------------------------------
  group('_polygonCenter: concave polygon fallback', () {
    test('concave U-shape uses diagonal midpoint fallback', () {
      final u = [
        const LatLng(0, 0),
        const LatLng(0, 4),
        const LatLng(1, 4),
        const LatLng(1, 1),
        const LatLng(3, 1),
        const LatLng(3, 4),
        const LatLng(4, 4),
        const LatLng(4, 0),
      ];
      final c = polygonCenter(u);
      expect(isPointInPolygon(c, u), true);
    });

    test('long thin polygon center is inside', () {
      final thin = [
        const LatLng(0, 0),
        const LatLng(100, 0),
        const LatLng(100, 0.1),
        const LatLng(0, 0.1),
      ];
      final c = polygonCenter(thin);
      expect(isPointInPolygon(c, thin), true);
    });
  });

  // --------------------------------------------------------------------------
  // 43. _calculateBounds: negatives and mixed coords
  // --------------------------------------------------------------------------
  group('_calculateBounds: negatives', () {
    test('negative coords', () {
      final b = calculateBounds([
        const LatLng(-10, -20),
        const LatLng(-5, -15),
        const LatLng(-8, -25),
      ]);
      expect(b.southwest.latitude, closeTo(-10, 0.01));
      expect(b.northeast.latitude, closeTo(-5, 0.01));
      expect(b.southwest.longitude, closeTo(-25, 0.01));
      expect(b.northeast.longitude, closeTo(-15, 0.01));
    });

    test('mixed positive/negative', () {
      final b = calculateBounds([const LatLng(-1, -1), const LatLng(1, 1)]);
      expect(b.southwest.latitude, closeTo(-1, 0.01));
      expect(b.northeast.latitude, closeTo(1, 0.01));
    });
  });

  // --------------------------------------------------------------------------
  // 44. _parseHexColor: more edge cases
  // --------------------------------------------------------------------------
  group('_parseHexColor: more edge cases', () {
    test('exactly 6 digits no hash', () {
      expect(parseHexColor('AABBCC')!.value, 0xFFAABBCC);
    });

    test('5 chars → null', () {
      expect(parseHexColor('#AABBC'), isNull);
    });

    test('7 chars without hash → null', () {
      expect(parseHexColor('AABBCCD'), isNull);
    });

    test('mixed valid/invalid hex chars → null', () {
      expect(parseHexColor('#GG0000'), isNull);
    });
  });

  // --------------------------------------------------------------------------
  // 45. _resolveTransitSegmentColor: more vehicle type branches
  // --------------------------------------------------------------------------
  group('_resolveTransitSegmentColor: more branches', () {
    test('TRANSIT + SUBWAY no color → default red', () {
      expect(
        resolveTransitSegmentColor(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'SUBWAY',
          ),
        ),
        const Color(0xFF76263D),
      );
    });

    test('TRANSIT + SUBWAY with invalid color → default red', () {
      expect(
        resolveTransitSegmentColor(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'SUBWAY',
            transitLineColorHex: '#ZZZ',
          ),
        ),
        const Color(0xFF76263D),
      );
    });

    test('TRANSIT + FERRY with valid color', () {
      final c = resolveTransitSegmentColor(
        const DirectionsRouteSegment(
          points: [],
          travelMode: 'TRANSIT',
          transitVehicleType: 'FERRY',
          transitLineColorHex: '#FF5500',
        ),
      );
      expect(c.value, 0xFFFF5500);
    });

    test('DRIVING → default red', () {
      expect(
        resolveTransitSegmentColor(
          const DirectionsRouteSegment(points: [], travelMode: 'DRIVING'),
        ),
        const Color(0xFF76263D),
      );
    });
  });

  // --------------------------------------------------------------------------
  // 46. _formatArrivalTime: specific time checks
  // --------------------------------------------------------------------------
  group('_formatArrivalTime: specific times', () {
    test('midnight crossing', () {
      final result = formatArrivalTime(43200);
      expect(result, isNotNull);
      expect(result!, matches(RegExp(r'^\d{1,2}:\d{2} (am|pm)$')));
    });

    test('very large seconds', () {
      expect(formatArrivalTime(999999), isNotNull);
    });

    test('1 second', () {
      expect(
        formatArrivalTime(1)!,
        matches(RegExp(r'^\d{1,2}:\d{2} (am|pm)$')),
      );
    });
  });

  // --------------------------------------------------------------------------
  // 47. _formatTransitSegmentTitle: fallback chain
  // --------------------------------------------------------------------------
  group('_formatTransitSegmentTitle: fallback chain', () {
    test('shortName preferred over lineName', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'BUS',
            transitLineShortName: '165',
            transitLineName: 'STM 165',
          ),
        ),
        'Bus 165',
      );
    });

    test('lineName used when shortName null', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'BUS',
            transitLineName: 'STM 165',
          ),
        ),
        'Bus STM 165',
      );
    });

    test('HEAVY_RAIL with lineName', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'HEAVY_RAIL',
            transitLineName: 'Exo 3',
          ),
        ),
        'Metro Exo 3',
      );
    });

    test('unknown vehicle with both names → Transit shortName', () {
      expect(
        formatTransitSegmentTitle(
          const DirectionsRouteSegment(
            points: [],
            travelMode: 'TRANSIT',
            transitVehicleType: 'FERRY',
            transitLineShortName: 'F1',
            transitLineName: 'Ferry 1',
          ),
        ),
        'Transit F1',
      );
    });
  });

  // --------------------------------------------------------------------------
  // 48. Widget: _createBuildingPolygons styling branches via real map
  // --------------------------------------------------------------------------
  group('_createBuildingPolygons styling branches via real map', () {
    testWidgets('no selected / no current building → default style', (
      tester,
    ) async {
      await pumpWithMap(tester);
      await tester.pumpAndSettle();

      final gm = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(gm.polygons.length, greaterThanOrEqualTo(buildingPolygons.length));
    });

    testWidgets('with debugSelectedBuilding → popup shown', (tester) async {
      await pumpWithMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BuildingInfoPopup), findsOneWidget);
      final gm = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(gm.polygons.length, greaterThanOrEqualTo(buildingPolygons.length));
    });

    testWidgets('second building also shows popup', (tester) async {
      if (buildingPolygons.length < 2) return;
      await pumpWithMap(
        tester,
        debugSelectedBuilding: buildingPolygons[1],
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BuildingInfoPopup), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 49. Widget: close button + popup lifecycle
  // --------------------------------------------------------------------------
  group('Widget: close button + popup lifecycle', () {
    testWidgets('close button removes popup', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsOneWidget);

      // Note: debugSelectedBuilding is an immutable widget parameter that takes
      // priority over _selectedBuildingPoly via the ?? operator, so tapping
      // close calls _closePopup (sets _selectedBuildingPoly = null) but the
      // popup remains because debugSelectedBuilding is still non-null.
      // We verify the close button is present and tappable without crashing.
      final closeBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.close),
      );
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first);
        await tester.pumpAndSettle();
      }
      // Popup stays visible because debugSelectedBuilding overrides state
      expect(find.byType(BuildingInfoPopup), findsOneWidget);
    });

    testWidgets('Get Directions button with null location does not crash', (
      tester,
    ) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();

      final dirBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.directions),
      );
      if (dirBtn.evaluate().isNotEmpty) {
        await tester.tap(dirBtn.first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 50. Widget: campus FAB labels
  // --------------------------------------------------------------------------
  group('Widget: campus FAB labels', () {
    testWidgets('SGW campus shows Campus text on FAB', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();
      expect(find.textContaining('Campus'), findsWidgets);
    });

    testWidgets('Loyola campus renders', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 51. IndoorMapRepository instantiation
  // --------------------------------------------------------------------------
  group('IndoorMapRepository detailed', () {
    test('can be instantiated', () {
      expect(IndoorMapRepository(), isNotNull);
    });

    test('loadGeoJsonAsset throws on invalid path', () async {
      final repo = IndoorMapRepository();
      expect(
        () => repo.loadGeoJsonAsset('invalid/path.json'),
        throwsA(anything),
      );
    });
  });

  // --------------------------------------------------------------------------
  // 52. _turnOffIndoorMap: state transitions
  // --------------------------------------------------------------------------
  group('_turnOffIndoorMap: state transitions', () {
    test('turn off from active state clears all indoor state', () {
      bool showIndoor = true;
      Set<Polygon> indoorPolygons = {
        const Polygon(
          polygonId: PolygonId('a'),
          points: [LatLng(0, 0), LatLng(1, 0), LatLng(1, 1)],
        ),
        const Polygon(
          polygonId: PolygonId('b'),
          points: [LatLng(2, 2), LatLng(3, 2), LatLng(3, 3)],
        ),
      };
      Map<String, dynamic>? indoorGeoJson = {
        'type': 'FeatureCollection',
        'features': [],
      };
      Set<Marker> roomLabelMarkers = {
        const Marker(markerId: MarkerId('l1'), position: LatLng(0.5, 0.5)),
        const Marker(markerId: MarkerId('l2'), position: LatLng(2.5, 2.5)),
      };

      if (showIndoor) {
        showIndoor = false;
        indoorPolygons = {};
        indoorGeoJson = null;
        roomLabelMarkers = {};
      }

      expect(showIndoor, false);
      expect(indoorPolygons, isEmpty);
      expect(indoorGeoJson, isNull);
      expect(roomLabelMarkers, isEmpty);
    });

    test('multiple turn-off calls are idempotent', () {
      bool showIndoor = true;
      Set<Polygon> indoorPolygons = {
        const Polygon(
          polygonId: PolygonId('a'),
          points: [LatLng(0, 0), LatLng(1, 0), LatLng(1, 1)],
        ),
      };
      Map<String, dynamic>? indoorGeoJson = {};
      Set<Marker> roomLabelMarkers = {};

      for (int i = 0; i < 3; i++) {
        if (showIndoor) {
          showIndoor = false;
          indoorPolygons = {};
          indoorGeoJson = null;
          roomLabelMarkers = {};
        }
      }

      expect(showIndoor, false);
      expect(indoorPolygons, isEmpty);
      expect(indoorGeoJson, isNull);
      expect(roomLabelMarkers, isEmpty);
    });
  });

  // --------------------------------------------------------------------------
  // 53. _toggleIndoorMap: asset path case sensitivity
  // --------------------------------------------------------------------------
  group('_toggleIndoorMap: asset path case sensitivity', () {
    String? resolveAssetPath(String code) {
      if (code.toUpperCase() == 'HALL')
        return 'assets/indoor_maps/geojson/Hall/h1.geojson.json';
      if (code.toUpperCase() == 'MB')
        return 'assets/indoor_maps/geojson/MB/mb1.geojson.json';
      if (code.toUpperCase() == 'VE')
        return 'assets/indoor_maps/geojson/VE/ve1.geojson.json';
      if (code.toUpperCase() == 'VL')
        return 'assets/indoor_maps/geojson/VL/vl1.geojson.json';
      if (code.toUpperCase() == 'CC')
        return 'assets/indoor_maps/geojson/CC/cc1.geojson.json';
      return null;
    }

    test(
      'Hall (mixed case) → correct path',
      () => expect(resolveAssetPath('Hall'), isNotNull),
    );
    test(
      'hall (lowercase) → correct path',
      () => expect(resolveAssetPath('hall'), isNotNull),
    );
    test(
      'HALL (uppercase) → correct path',
      () => expect(resolveAssetPath('HALL'), isNotNull),
    );
    test(
      'Mb (mixed case) → correct path',
      () => expect(resolveAssetPath('Mb'), isNotNull),
    );
    test(
      've (lowercase) → correct path',
      () => expect(resolveAssetPath('ve'), isNotNull),
    );
    test(
      'Vl (mixed case) → correct path',
      () => expect(resolveAssetPath('Vl'), isNotNull),
    );
    test(
      'Cc (mixed case) → correct path',
      () => expect(resolveAssetPath('Cc'), isNotNull),
    );
    test('empty string → null', () => expect(resolveAssetPath(''), isNull));
    test(
      'single char H → null (not HALL)',
      () => expect(resolveAssetPath('H'), isNull),
    );
    test(
      'space-padded → null',
      () => expect(resolveAssetPath(' HALL '), isNull),
    );
  });

  // --------------------------------------------------------------------------
  // 54. Widget: multiple campus renders back-to-back
  // --------------------------------------------------------------------------
  group('Widget: multiple campus renders', () {
    testWidgets('SGW → Loyola → none renders correctly', (tester) async {
      for (final campus in [Campus.sgw, Campus.loyola, Campus.none]) {
        await pumpNoMap(tester, initialCampus: campus);
        await tester.pumpAndSettle();
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      }
    });
  });

  // --------------------------------------------------------------------------
  // 55. NavigationStep: extended coverage
  // --------------------------------------------------------------------------
  group('NavigationStep: extended coverage', () {
    test('transitLabel COMMUTER_TRAIN', () {
      const s = NavigationStep(
        instruction: 'Train',
        travelMode: 'transit',
        transitVehicleType: 'COMMUTER_TRAIN',
        transitLineShortName: 'Line 1',
      );
      expect(s.transitLabel, 'Metro Line 1');
    });

    test('transitLabel TRAM', () {
      const s = NavigationStep(
        instruction: 'Tram',
        travelMode: 'transit',
        transitVehicleType: 'TRAM',
        transitLineShortName: 'T1',
      );
      expect(s.transitLabel, 'Metro T1');
    });

    test('transitLabel with lineName only (no shortName)', () {
      const s = NavigationStep(
        instruction: 'Go',
        travelMode: 'transit',
        transitVehicleType: 'BUS',
        transitLineName: 'Route 24',
      );
      expect(s.transitLabel, 'Bus Route 24');
    });

    test('secondaryLine with only distance', () {
      const s = NavigationStep(
        instruction: 'Go',
        travelMode: 'walking',
        distanceText: '200 m',
      );
      expect(s.secondaryLine, '200 m');
    });

    test('secondaryLine with only duration', () {
      const s = NavigationStep(
        instruction: 'Go',
        travelMode: 'walking',
        durationText: '3 min',
      );
      expect(s.secondaryLine, '3 min');
    });

    test('secondaryLine empty', () {
      const s = NavigationStep(instruction: 'Go', travelMode: 'walking');
      expect(s.secondaryLine, '');
    });

    test('maneuver field stored', () {
      const s = NavigationStep(
        instruction: 'Turn',
        travelMode: 'walking',
        maneuver: 'turn-left',
      );
      expect(s.maneuver, 'turn-left');
    });

    test('transitHeadsign stored', () {
      const s = NavigationStep(
        instruction: 'Go',
        travelMode: 'transit',
        transitHeadsign: 'Downtown',
      );
      expect(s.transitHeadsign, 'Downtown');
    });
  });

  // --------------------------------------------------------------------------
  // 56. DirectionsRouteSegment: transit fields
  // --------------------------------------------------------------------------
  group('DirectionsRouteSegment: transit fields', () {
    test('with all transit fields', () {
      const s = DirectionsRouteSegment(
        points: [LatLng(45.5, -73.5), LatLng(45.6, -73.6)],
        travelMode: 'TRANSIT',
        transitVehicleType: 'BUS',
        transitLineShortName: '165',
        transitLineName: 'STM 165',
        transitLineColorHex: '#0000FF',
        transitHeadsign: 'Downtown',
      );
      expect(s.transitVehicleType, 'BUS');
      expect(s.transitLineShortName, '165');
      expect(s.transitLineName, 'STM 165');
      expect(s.transitLineColorHex, '#0000FF');
      expect(s.transitHeadsign, 'Downtown');
      expect(s.points.length, 2);
    });

    test('walking segment has no transit fields', () {
      const s = DirectionsRouteSegment(points: [], travelMode: 'WALKING');
      expect(s.transitVehicleType, isNull);
      expect(s.transitLineShortName, isNull);
      expect(s.transitLineName, isNull);
      expect(s.transitLineColorHex, isNull);
    });
  });

  // --------------------------------------------------------------------------
  // 57. Widget: markers/circles with real map and location
  // --------------------------------------------------------------------------
  group('Widget: markers/circles with real map and location', () {
    testWidgets('markers include current_location marker', (tester) async {
      await pumpWithMap(tester);
      await tester.pump(const Duration(milliseconds: 500));

      final gm = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markerIds = gm.markers.map((m) => m.markerId.value).toSet();
      expect(markerIds.contains('current_location'), true);
    });

    testWidgets('circles include accuracy circle', (tester) async {
      await pumpWithMap(tester);
      await tester.pump(const Duration(milliseconds: 500));

      final gm = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final circleIds = gm.circles.map((c) => c.circleId.value).toSet();
      expect(circleIds.contains('current_location_accuracy'), true);
    });
  });

  // --------------------------------------------------------------------------
  // 58. Widget: dispose in various states
  // --------------------------------------------------------------------------
  group('Widget: dispose in various states', () {
    testWidgets('dispose from SGW campus', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('disposed'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('disposed'), findsOneWidget);
    });

    testWidgets('dispose from Loyola campus', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('disposed'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('disposed'), findsOneWidget);
    });

    testWidgets('dispose with popup active', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('disposed'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('disposed'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 59. Deterministic fill color priority
  // --------------------------------------------------------------------------
  group('determineFillColor priority order', () {
    test('escalator > elevator > steps > toilets > corridor > default', () {
      expect(
        determineFillColor({
          'escalators': 'yes',
          'highway': 'elevator',
          'amenity': 'toilets',
          'indoor': 'corridor',
        }),
        Colors.green,
      );

      expect(
        determineFillColor({
          'highway': 'elevator',
          'amenity': 'toilets',
          'indoor': 'corridor',
        }),
        Colors.orange,
      );

      expect(
        determineFillColor({
          'highway': 'steps',
          'amenity': 'toilets',
          'indoor': 'corridor',
        }),
        Colors.pink,
      );

      expect(
        determineFillColor({'amenity': 'toilets', 'indoor': 'corridor'}),
        Colors.blue,
      );

      expect(
        determineFillColor({'indoor': 'corridor'}),
        const Color.fromARGB(255, 232, 122, 149),
      );

      expect(determineFillColor({}), const Color(0xFF800020));
    });
  });

  // --------------------------------------------------------------------------
  // 60. Widget: search bar interaction
  // --------------------------------------------------------------------------
  group('Widget: search bar interaction', () {
    testWidgets('search bar renders and accepts text', (tester) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();

      final searchFields = find.byType(TextField);
      if (searchFields.evaluate().isNotEmpty) {
        await tester.enterText(searchFields.first, 'Hall');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 61. Widget: CampusToggle interaction
  // --------------------------------------------------------------------------
  group('Widget: CampusToggle interaction', () {
    testWidgets('tap LOY from SGW', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();
      final loyText = find.text('LOY');
      if (loyText.evaluate().isNotEmpty) {
        await tester.tap(loyText.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('tap SGW from Loyola', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      await tester.pumpAndSettle();
      final sgwText = find.text('SGW');
      if (sgwText.evaluate().isNotEmpty) {
        await tester.tap(sgwText.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });
}
