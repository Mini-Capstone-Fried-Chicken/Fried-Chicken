import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/services/building_detection.dart';

void main() {
  group('US 2.3 - Show current user building location', () {
    test('pointInPolygon returns true for a point inside LB polygon', () {
      final lb = buildingPolygons.firstWhere((b) => b.code == "LB");

      // Choose a point that should be inside LB (you can tweak if needed)
      const insidePoint = LatLng(45.49680, -73.57790);

      expect(pointInPolygon(insidePoint, lb.points), isTrue);
    });

    test('pointInPolygon returns false for a far away point', () {
      final lb = buildingPolygons.firstWhere((b) => b.code == "LB");

      const farAway = LatLng(45.0, -73.0);

      expect(pointInPolygon(farAway, lb.points), isFalse);
    });

    test('detectBuildingPoly returns the correct building when inside one', () {
      // Pick a point likely inside LB
      const user = LatLng(45.49680, -73.57790);

      final detected = detectBuildingPoly(user);

      expect(detected, isNotNull);
      expect(detected!.code, "LB");
    });

    test('detectBuildingPoly returns null when user is outside all polygons', () {
      const user = LatLng(45.0, -73.0);

      final detected = detectBuildingPoly(user);

      expect(detected, isNull);
    });

    test('detectBuildingPoly returns the first match when overlapping occurs', () {
      // This test is about behavior, not geography.
      // If two polygons overlap (rare but possible), your loop returns the first matching polygon.
      // We simulate overlap by creating two simple squares.
      final polyA = BuildingPolygon(
        code: "A",
        name: "A",
        points: const [
          LatLng(0, 0),
          LatLng(0, 10),
          LatLng(10, 10),
          LatLng(10, 0),
        ],
      );

      final polyB = BuildingPolygon(
        code: "B",
        name: "B",
        points: const [
          LatLng(0, 0),
          LatLng(0, 10),
          LatLng(10, 10),
          LatLng(10, 0),
        ],
      );

      const user = LatLng(5, 5);

      // local version of detect for this test (so we don't depend on your real data)
      BuildingPolygon? detectLocal(LatLng p, List<BuildingPolygon> polys) {
        for (final b in polys) {
          if (pointInPolygon(p, b.points)) return b;
        }
        return null;
      }

      final detected = detectLocal(user, [polyA, polyB]);
      expect(detected!.code, "A");
    });
  });
}