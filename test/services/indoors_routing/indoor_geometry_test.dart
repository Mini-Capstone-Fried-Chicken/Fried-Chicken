import 'package:campus_app/services/indoors_routing/core/indoor_geometry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorGeometry', () {
    const geometry = IndoorGeometry();

    test('removes only consecutive duplicate points', () {
      final a = const LatLng(45.0, -73.0);
      final b = const LatLng(45.0, -72.9999);

      final cleaned = geometry.removeConsecutiveDuplicatePoints([a, a, b, a]);

      expect(cleaned, [a, b, a]);
    });

    test('segmentInsideCorridor blocks room crossing when enabled', () {
      final corridor = <LatLng>[
        const LatLng(0, 0),
        const LatLng(0, 0.00006),
        const LatLng(0.00004, 0.00006),
        const LatLng(0.00004, 0),
        const LatLng(0, 0),
      ];
      final blockedRoom = <LatLng>[
        const LatLng(0.00001, 0.000025),
        const LatLng(0.00001, 0.000035),
        const LatLng(0.00003, 0.000035),
        const LatLng(0.00003, 0.000025),
        const LatLng(0.00001, 0.000025),
      ];

      final start = const LatLng(0.00002, 0.000005);
      final end = const LatLng(0.00002, 0.000055);

      expect(
        geometry.segmentInsideCorridor(
          a: start,
          b: end,
          corridorPolygon: corridor,
          blockedRoomPolygons: [blockedRoom],
          avoidBlockedRooms: false,
          minSamples: 12,
          sampleSpacingMeters: 0.75,
        ),
        isTrue,
      );

      expect(
        geometry.segmentInsideCorridor(
          a: start,
          b: end,
          corridorPolygon: corridor,
          blockedRoomPolygons: [blockedRoom],
          avoidBlockedRooms: true,
          minSamples: 12,
          sampleSpacingMeters: 0.75,
        ),
        isFalse,
      );
    });
  });
}
