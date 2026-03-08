import 'package:campus_app/services/indoors_routing/indoor_same_floor_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorSameFloorRouter', () {
    final router = IndoorSameFloorRouter();

    test('roomCenterOnFloor is case/whitespace insensitive', () {
      final center = router.roomCenterOnFloor(
        floorGeoJson: _simpleFloorGeoJson(),
        roomCode: '  a101 ',
      );

      expect(center, isNotNull);
    });

    test('findShortestPath returns null when room code does not exist', () {
      final path = router.findShortestPath(
        floorGeoJson: _simpleFloorGeoJson(),
        originRoomCode: 'A101',
        destinationRoomCode: 'DOES_NOT_EXIST',
      );

      expect(path, isNull);
    });

    test(
      'findShortestPath returns one point for same origin and destination',
      () {
        final path = router.findShortestPath(
          floorGeoJson: _simpleFloorGeoJson(),
          originRoomCode: 'A101',
          destinationRoomCode: 'A101',
        );

        expect(path, isNotNull);
        expect(path!.length, 1);
      },
    );

    test(
      'findShortestPath builds route across corridor and deduplicates points',
      () {
        final path = router.findShortestPath(
          floorGeoJson: _simpleFloorGeoJson(),
          originRoomCode: 'A101',
          destinationRoomCode: 'B101',
        );

        expect(path, isNotNull);
        expect(path!.length, greaterThanOrEqualTo(2));
        expect(path.first, isA<LatLng>());
        expect(path.last, isA<LatLng>());

        for (int i = 1; i < path.length; i++) {
          expect(router.areSameLatLng(path[i - 1], path[i]), isFalse);
        }
      },
    );
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
