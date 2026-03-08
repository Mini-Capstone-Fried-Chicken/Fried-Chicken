import 'package:campus_app/services/location/indoor_route_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorRouteService', () {
    final service = IndoorRouteService();
    test('buildIndoorRoutePolylines returns empty for less than 2 points', () {
      expect(service.buildIndoorRoutePolylines(const [LatLng(0, 0)]), isEmpty);
    });

    test('buildIndoorRoutePolylines creates polyline with expected id', () {
      final polylines = service.buildIndoorRoutePolylines(const [
        LatLng(45.0, -73.0),
        LatLng(45.0, -72.9999),
      ]);

      expect(polylines.length, 1);
      expect(polylines.first.polylineId.value, 'indoor_same_floor_route');
    });

    test('buildIndoorNavigation returns summary with arrival step', () {
      final summary = service.buildIndoorNavigation(const [
        LatLng(45.00000, -73.00000),
        LatLng(45.00000, -72.99990),
        LatLng(45.00010, -72.99990),
      ]);

      expect(summary.steps, isNotEmpty);
      expect(summary.steps.last.instruction, 'Arrive at your destination room');
      expect(summary.distanceText, isNotNull);
      expect(summary.durationText, isNotNull);
    });

    test('buildIndoorNavigation empty when less than 2 points', () {
      final summary = service.buildIndoorNavigation(const [
        LatLng(45.0, -73.0),
      ]);
      expect(summary.steps, isEmpty);
      expect(summary.distanceText, isNull);
      expect(summary.durationText, isNull);
    });

    test('room lookup and same-floor path delegate to router', () {
      final geoJson = _simpleFloorGeoJson();

      final roomCenter = service.findRoomCenterOnFloor(
        floorGeoJson: geoJson,
        roomCode: 'A101',
      );
      final path = service.findSameFloorPath(
        floorGeoJson: geoJson,
        originRoomCode: 'A101',
        destinationRoomCode: 'B101',
      );

      expect(roomCenter, isNotNull);
      expect(path, isNotNull);
      expect(path!.length, greaterThanOrEqualTo(2));
    });

    test('builds origin and destination room markers', () {
      final origin = service.buildOriginRoomMarker('A101', const LatLng(1, 1));
      final destination = service.buildDestinationRoomMarker(
        'B101',
        const LatLng(2, 2),
      );

      expect(origin.markerId.value, 'origin_room');
      expect(destination.markerId.value, 'destination_room');
      expect(origin.infoWindow.title, 'Room A101');
      expect(destination.infoWindow.title, 'Room B101');
    });
  });
}

Map<String, dynamic> _simpleFloorGeoJson() {
  return {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': {'indoor': 'room', 'ref': 'A101', 'level': '1'},
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
      },
      {
        'type': 'Feature',
        'properties': {'indoor': 'corridor', 'level': '1'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-72.99995, 45.00000],
              [-72.99990, 45.00000],
              [-72.99990, 45.00005],
              [-72.99995, 45.00005],
              [-72.99995, 45.00000],
            ],
          ],
        },
      },
      {
        'type': 'Feature',
        'properties': {'indoor': 'room', 'ref': 'B101', 'level': '1'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-72.99990, 45.00000],
              [-72.99985, 45.00000],
              [-72.99985, 45.00005],
              [-72.99990, 45.00005],
              [-72.99990, 45.00000],
            ],
          ],
        },
      },
    ],
  };
}
