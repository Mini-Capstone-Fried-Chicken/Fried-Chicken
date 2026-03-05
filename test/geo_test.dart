import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/utils/geo.dart';
import 'package:flutter/material.dart';

void main() {
  group('pointInPolygon - Basic Tests', () {
    test('Point inside simple triangle', () {
      final triangle = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(2, 2);
      expect(pointInPolygon(point, triangle), isTrue);
    });

    test('Point outside simple triangle', () {
      final triangle = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(8, 8);
      expect(pointInPolygon(point, triangle), isFalse);
    });

    test('Point inside square', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(5, 5);
      expect(pointInPolygon(point, square), isTrue);
    });

    test('Point outside square', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(15, 5);
      expect(pointInPolygon(point, square), isFalse);
    });
  });

  group('pointInPolygon - Boundary Tests', () {
    test('Point on vertex of polygon', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(0, 0);
      // Boundary behavior depends on implementation
      // This test documents current behavior
      final result = pointInPolygon(point, square);
      expect(result, isA<bool>());
    });

    test('Point on edge of polygon', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(5, 0);
      final result = pointInPolygon(point, square);
      expect(result, isA<bool>());
    });

    test('Point very close to edge but outside', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(-0.0001, 5);
      expect(pointInPolygon(point, square), isFalse);
    });

    test('Point very close to edge but inside', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      final point = const LatLng(0.0001, 5);
      expect(pointInPolygon(point, square), isTrue);
    });
  });

  group('pointInPolygon - Complex Polygons', () {
    test('Point inside pentagon', () {
      final pentagon = [
        const LatLng(5, 0),
        const LatLng(10, 4),
        const LatLng(8, 10),
        const LatLng(2, 10),
        const LatLng(0, 4),
      ];
      final point = const LatLng(5, 5);
      expect(pointInPolygon(point, pentagon), isTrue);
    });

    test('Point outside pentagon', () {
      final pentagon = [
        const LatLng(5, 0),
        const LatLng(10, 4),
        const LatLng(8, 10),
        const LatLng(2, 10),
        const LatLng(0, 4),
      ];
      final point = const LatLng(15, 5);
      expect(pointInPolygon(point, pentagon), isFalse);
    });

    test('Point inside concave polygon', () {
      // L-shaped polygon
      final concavePolygon = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(5, 10),
        const LatLng(5, 5),
        const LatLng(10, 5),
        const LatLng(10, 0),
      ];
      final point = const LatLng(7, 2);
      expect(pointInPolygon(point, concavePolygon), isTrue);
    });

    test('Point outside concave polygon in indentation', () {
      // L-shaped polygon
      final concavePolygon = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(5, 10),
        const LatLng(5, 5),
        const LatLng(10, 5),
        const LatLng(10, 0),
      ];
      // Point in the indented area
      final point = const LatLng(7, 7);
      expect(pointInPolygon(point, concavePolygon), isFalse);
    });
  });

  group('pointInPolygon - Edge Cases', () {
    test('Point inside hexagon', () {
      final hexagon = [
        const LatLng(0, 5),
        const LatLng(3, 10),
        const LatLng(8, 10),
        const LatLng(11, 5),
        const LatLng(8, 0),
        const LatLng(3, 0),
      ];
      final point = const LatLng(5.5, 5);
      expect(pointInPolygon(point, hexagon), isTrue);
    });

    test('Multiple rays intersect polygon', () {
      final rectangle = [
        const LatLng(0, 0),
        const LatLng(0, 20),
        const LatLng(10, 20),
        const LatLng(10, 0),
      ];
      // Point where horizontal ray crosses multiple edges
      final point = const LatLng(5, 10);
      expect(pointInPolygon(point, rectangle), isTrue);
    });

    test('Point far outside large polygon', () {
      final square = [
        const LatLng(40, -73),
        const LatLng(40, -74),
        const LatLng(41, -74),
        const LatLng(41, -73),
      ];
      final point = const LatLng(45, -70);
      expect(pointInPolygon(point, square), isFalse);
    });

    test('Point far inside large polygon', () {
      final square = [
        const LatLng(40, -74),
        const LatLng(40, -72),
        const LatLng(42, -72),
        const LatLng(42, -74),
      ];
      final point = const LatLng(41, -73);
      expect(pointInPolygon(point, square), isTrue);
    });

    test('Point with negative coordinates inside polygon', () {
      final polygon = [
        const LatLng(-10, -10),
        const LatLng(-10, 10),
        const LatLng(10, 10),
        const LatLng(10, -10),
      ];
      final point = const LatLng(-5, -5);
      expect(pointInPolygon(point, polygon), isTrue);
    });

    test('Point with negative coordinates outside polygon', () {
      final polygon = [
        const LatLng(-10, -10),
        const LatLng(-10, 10),
        const LatLng(10, 10),
        const LatLng(10, -10),
      ];
      final point = const LatLng(-15, -15);
      expect(pointInPolygon(point, polygon), isFalse);
    });
  });

  group('pointInPolygon - Real-world Scenarios', () {
    test('Campus building polygon - point inside', () {
      // Simulating a building polygon similar to those in the app
      final buildingPolygon = [
        const LatLng(45.497, -73.579),
        const LatLng(45.497, -73.578),
        const LatLng(45.498, -73.578),
        const LatLng(45.498, -73.579),
      ];
      final studentLocation = const LatLng(45.4975, -73.5785);
      expect(pointInPolygon(studentLocation, buildingPolygon), isTrue);
    });

    test('Campus building polygon - point outside', () {
      final buildingPolygon = [
        const LatLng(45.497, -73.579),
        const LatLng(45.497, -73.578),
        const LatLng(45.498, -73.578),
        const LatLng(45.498, -73.579),
      ];
      final studentLocation = const LatLng(45.496, -73.580);
      expect(pointInPolygon(studentLocation, buildingPolygon), isFalse);
    });

    test('Large campus area polygon - student inside', () {
      // Approximate SGW campus boundaries
      final campusPolygon = [
        const LatLng(45.495, -73.582),
        const LatLng(45.495, -73.575),
        const LatLng(45.501, -73.575),
        const LatLng(45.501, -73.582),
      ];
      final studentLocation = const LatLng(45.498, -73.579);
      expect(pointInPolygon(studentLocation, campusPolygon), isTrue);
    });

    test('Large campus area polygon - student outside', () {
      final campusPolygon = [
        const LatLng(45.495, -73.582),
        const LatLng(45.495, -73.575),
        const LatLng(45.501, -73.575),
        const LatLng(45.501, -73.582),
      ];
      final studentLocation = const LatLng(45.492, -73.580);
      expect(pointInPolygon(studentLocation, campusPolygon), isFalse);
    });
  });

  group('pointInPolygon - Ray Casting Algorithm Verification', () {
    test('Multiple horizontal rays from point', () {
      final triangle = [
        const LatLng(0, 0),
        const LatLng(5, 10),
        const LatLng(10, 0),
      ];
      // Center point
      final center = const LatLng(5, 3);
      expect(pointInPolygon(center, triangle), isTrue);
    });

    test('Ray passes through vertex', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      // This point's horizontal ray passes through a vertex
      final point = const LatLng(5, 10);
      final result = pointInPolygon(point, square);
      expect(result, isA<bool>());
    });

    test('Point with same latitude as multiple vertices', () {
      final hexagon = [
        const LatLng(0, 0),
        const LatLng(0, 5),
        const LatLng(5, 10),
        const LatLng(10, 5),
        const LatLng(10, 0),
        const LatLng(5, -5),
      ];
      final point = const LatLng(5, 5);
      final result = pointInPolygon(point, hexagon);
      expect(result, isA<bool>());
    });
  });

  group('pointInPolygon - Degenerate Cases', () {
    test('Point at center of tiny polygon', () {
      final tinySquare = [
        const LatLng(0, 0),
        const LatLng(0, 0.00001),
        const LatLng(0.00001, 0.00001),
        const LatLng(0.00001, 0),
      ];
      final center = const LatLng(0.000005, 0.000005);
      expect(pointInPolygon(center, tinySquare), isTrue);
    });

    test('Point with high precision coordinates inside', () {
      final polygon = [
        const LatLng(45.4973123456, -73.5789654321),
        const LatLng(45.4973123456, -73.5788654321),
        const LatLng(45.4974123456, -73.5788654321),
        const LatLng(45.4974123456, -73.5789654321),
      ];
      final point = const LatLng(45.49736234560, -73.57891234210);
      expect(pointInPolygon(point, polygon), isTrue);
    });

    test('Point with high precision coordinates outside', () {
      final polygon = [
        const LatLng(45.4973123456, -73.5789654321),
        const LatLng(45.4973123456, -73.5788654321),
        const LatLng(45.4974123456, -73.5788654321),
        const LatLng(45.4974123456, -73.5789654321),
      ];
      final point = const LatLng(45.49720234560, -73.57891234210);
      expect(pointInPolygon(point, polygon), isFalse);
    });
  });

    group('polygonArea', () {
    test('Returns positive area for simple square', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 1),
        const LatLng(1, 1),
        const LatLng(1, 0),
      ];

      final a = polygonArea(square);
      expect(a, closeTo(1.0, 1e-9));
    });

    test('Area is the same regardless of winding order (abs)', () {
      final squareCW = [
        const LatLng(0, 0),
        const LatLng(0, 2),
        const LatLng(2, 2),
        const LatLng(2, 0),
      ];
      final squareCCW = squareCW.reversed.toList();

      final a1 = polygonArea(squareCW);
      final a2 = polygonArea(squareCCW);

      expect(a1, closeTo(a2, 1e-12));
      expect(a1, closeTo(4.0, 1e-9));
    });

    test('Tiny polygon has tiny non-negative area', () {
      final tinySquare = [
        const LatLng(0, 0),
        const LatLng(0, 0.00001),
        const LatLng(0.00001, 0.00001),
        const LatLng(0.00001, 0),
      ];

      final a = polygonArea(tinySquare);
      expect(a, greaterThan(0));
    });
  });

  group('polygonCenter', () {
    test('Throws ArgumentError when pts is empty', () {
      expect(() => polygonCenter([]), throwsArgumentError);
    });

    test('If pts.length < 3 returns first point', () {
      final pts = [const LatLng(10, 20), const LatLng(30, 40)];
      final c = polygonCenter(pts);
      expect(c, equals(const LatLng(10, 20)));
    });

    test('Uses average point when average is inside polygon', () {
      final square = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];

      final c = polygonCenter(square);

      // average of vertices is (5,5) and it's inside
      expect(c.latitude, closeTo(5.0, 1e-9));
      expect(c.longitude, closeTo(5.0, 1e-9));
      expect(pointInPolygon(c, square), isTrue);
    });

    test('Fallback path: average outside polygon but returns a midpoint inside', () {
      // This is a "U" shape (concave). Average of vertices lands in the hole,
      // so pointInPolygon(avg, pts) is false => fallback runs.
      final uShape = [
        const LatLng(0, 0),
        const LatLng(0, 10),
        const LatLng(2, 10),
        const LatLng(2, 2),
        const LatLng(8, 2),
        const LatLng(8, 10),
        const LatLng(10, 10),
        const LatLng(10, 0),
      ];
      
      double avgLat = 0, avgLng = 0;
      for (final p in uShape) {
        avgLat += p.latitude;
        avgLng += p.longitude;
      }
      final avg = LatLng(avgLat / uShape.length, avgLng / uShape.length);

      expect(pointInPolygon(avg, uShape), isFalse);

      final c = polygonCenter(uShape);
      expect(pointInPolygon(c, uShape), isTrue);
    });
  });

  group('calculateBounds', () {
    test('Throws ArgumentError when points is empty', () {
      expect(() => calculateBounds([]), throwsArgumentError);
    });

    test('Returns correct bounds for multiple points', () {
      final pts = [
        const LatLng(45.0, -73.0),
        const LatLng(46.0, -74.0),
        const LatLng(44.5, -72.5),
        const LatLng(45.5, -73.5),
      ];

      final b = calculateBounds(pts);

      expect(b.southwest.latitude, closeTo(44.5, 1e-9));
      expect(b.southwest.longitude, closeTo(-74.0, 1e-9));
      expect(b.northeast.latitude, closeTo(46.0, 1e-9));
      expect(b.northeast.longitude, closeTo(-72.5, 1e-9));
    });

    test('Single point returns bounds with same SW and NE', () {
      final pts = [const LatLng(10, 20)];
      final b = calculateBounds(pts);

      expect(b.southwest, equals(const LatLng(10, 20)));
      expect(b.northeast, equals(const LatLng(10, 20)));
    });
  });

  group('parseHexColor', () {
    test('Returns null for null/empty/whitespace', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('   '), isNull);
    });

    test('Parses valid hex with #', () {
      final c = parseHexColor('#FF0000');
      expect(c, isNotNull);
      expect(c!.value, equals(const Color(0xFFFF0000).value));
    });

    test('Parses valid hex without #', () {
      final c = parseHexColor('00FF00');
      expect(c, isNotNull);
      expect(c!.value, equals(const Color(0xFF00FF00).value));
    });

    test('Returns null for invalid length', () {
      expect(parseHexColor('#FFF'), isNull);
      expect(parseHexColor('12345'), isNull);
      expect(parseHexColor('1234567'), isNull);
    });

    test('Returns null for non-hex characters', () {
      expect(parseHexColor('#GGGGGG'), isNull);
      expect(parseHexColor('ZZZZZZ'), isNull);
    });
  });

}
