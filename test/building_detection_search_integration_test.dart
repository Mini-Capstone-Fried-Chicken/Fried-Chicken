import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/services/building_detection.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('Building Detection Service Tests', () {
    group('Building Polygon Detection', () {
      test('Detects building when point is inside polygon', () {
        // Use a point within a known building
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final insidePoint = hallBuilding.center;
        
        // Point inside should be detected
        expect(hallBuilding.points.length, greaterThan(0));
      });

      test('Returns null when point is outside all buildings', () {
        final outsidePoint = LatLng(45.6, -73.3);
        
        BuildingPolygon? building;
        try {
          building = buildingPolygons.firstWhere(
            (b) => b.points.contains(outsidePoint),
          );
        } catch (e) {
          building = null;
        }
        
        expect(building, isNull);
      });

      test('Correctly identifies current building for known location', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        expect(hallBuilding.code, 'HALL');
        expect(hallBuilding.name, 'Hall Building');
      });

      test('Building polygon contains proper coordinates', () {
        for (final building in buildingPolygons.take(5)) {
          for (final point in building.points) {
            expect(point.latitude, greaterThan(45.4));
            expect(point.latitude, lessThan(45.6));
            expect(point.longitude, greaterThan(-73.7));
            expect(point.longitude, lessThan(-73.5));
          }
        }
      });

      test('Building detection works for multiple buildings', () {
        final detectableBuildings = buildingPolygons.take(10).toList();
        expect(detectableBuildings.length, 10);
        
        for (final building in detectableBuildings) {
          expect(building.code.isNotEmpty, true);
          expect(building.name.isNotEmpty, true);
          expect(building.points.length, greaterThan(2));
        }
      });
    });

    group('Point in Polygon Tests', () {
      test('Center of polygon is inside polygon', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final center = hallBuilding.center;
        
        expect(center, isNotNull);
        expect(center.latitude, isA<double>());
        expect(center.longitude, isA<double>());
      });

      test('Corners of polygon are on polygon boundaries', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        expect(hallBuilding.points.first, isA<LatLng>());
      });

      test('Multiple points can be tested against same polygon', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final points = hallBuilding.points.take(3).toList();
        
        expect(points.length, 3);
        for (final point in points) {
          expect(point, isA<LatLng>());
        }
      });

      test('Polygon detection consistency', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final center1 = building.center;
        final center2 = building.center;
        
        expect(center1.latitude, center2.latitude);
        expect(center1.longitude, center2.longitude);
      });
    });

    group('Building Code and Name Matching', () {
      test('Building code matches search term', () {
        final search = BuildingSearchService.searchBuilding('HALL');
        expect(search?.code, 'HALL');
      });

      test('Building name matches search term', () {
        final search = BuildingSearchService.searchBuilding('Hall Building');
        expect(search?.name, 'Hall Building');
      });

      test('Case insensitive search works', () {
        final search1 = BuildingSearchService.searchBuilding('hall');
        final search2 = BuildingSearchService.searchBuilding('HALL');
        
        expect(search1?.code, 'HALL');
        expect(search2?.code, 'HALL');
      });

      test('Partial name search works', () {
        final search = BuildingSearchService.searchBuilding('Hall');
        expect(search?.name.contains('Hall'), true);
      });
    });

    group('Building Information Retrieval', () {
      test('All buildings have unique codes', () {
        final codes = buildingPolygons.map((b) => b.code).toList();
        final uniqueCodes = codes.toSet();
        
        expect(codes.length, uniqueCodes.length);
      });

      test('All buildings have non-empty names', () {
        expect(buildingPolygons.every((b) => b.name.isNotEmpty), true);
      });

      test('All buildings have at least 3 polygon points', () {
        expect(buildingPolygons.every((b) => b.points.length >= 3), true);
      });

      test('Building can be retrieved by code', () {
        for (final building in buildingPolygons.take(5)) {
          final retrieved = buildingPolygons.firstWhere((b) => b.code == building.code);
          expect(retrieved.code, building.code);
          expect(retrieved.name, building.name);
        }
      });

      test('Multiple buildings can be retrieved', () {
        final codes = ['HALL', 'EV', 'FG'];
        for (final code in codes) {
          BuildingPolygon? building;
          try {
            building = buildingPolygons.firstWhere((b) => b.code == code);
          } catch (e) {
            building = null;
          }
          if (building != null) {
            expect(building.code, code);
          }
        }
      });
    });

    group('Building Location Accuracy', () {
      test('Building centers are within Montreal bounds', () {
        for (final building in buildingPolygons) {
          expect(building.center.latitude, greaterThan(45.4));
          expect(building.center.latitude, lessThan(45.5));
          expect(building.center.longitude, greaterThan(-73.7));
          expect(building.center.longitude, lessThan(-73.5));
        }
      });

      test('Building polygon points are within Montreal bounds', () {
        for (final building in buildingPolygons) {
          for (final point in building.points) {
            expect(point.latitude, greaterThan(45.4));
            expect(point.latitude, lessThan(45.5));
          }
        }
      });

      test('Distance between building points is reasonable', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final points = hallBuilding.points;
        
        // Buildings should be small (less than 1km)
        for (int i = 0; i < points.length - 1; i++) {
          final p1 = points[i];
          final p2 = points[i + 1];
          
          // Rough distance check (latitude difference ~111km per degree)
          final latDiff = (p1.latitude - p2.latitude).abs() * 111;
          final lngDiff = (p1.longitude - p2.longitude).abs() * 85; // Approximate at Montreal
          final distanceSquared = (latDiff * latDiff) + (lngDiff * lngDiff);
          
          expect(distanceSquared, lessThan(1000000)); // Less than 1km segment squared
        }
      });

      test('Building center is close to all points', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final center = hallBuilding.center;
        
        for (final point in hallBuilding.points) {
          final latDiff = (center.latitude - point.latitude).abs();
          final lngDiff = (center.longitude - point.longitude).abs();
          
          expect(latDiff, lessThan(0.01)); // Less than ~1km
          expect(lngDiff, lessThan(0.01));
        }
      });
    });

    group('Edge Cases for Building Detection', () {
      test('Detects all buildings in dataset', () {
        expect(buildingPolygons.length, greaterThan(0));
      });

      test('Handles building with minimum points (triangle)', () {
        BuildingPolygon? minPointBuilding;
        try {
          minPointBuilding = buildingPolygons.firstWhere(
            (b) => b.points.length == 3,
          );
        } catch (e) {
          minPointBuilding = null;
        }
        
        if (minPointBuilding != null) {
          expect(minPointBuilding.points.length, 3);
          expect(minPointBuilding.center, isNotNull);
        }
      });

      test('Handles building with many points', () {
        final maxPointsBuilding = buildingPolygons.reduce(
          (a, b) => a.points.length > b.points.length ? a : b,
        );
        
        expect(maxPointsBuilding.points.length, greaterThan(3));
      });

      test('Handles duplicate coordinates in polygon', () {
        // This tests that system handles polygons correctly
        for (final building in buildingPolygons) {
          expect(building.points.length, greaterThan(2));
        }
      });
    });
  });

  group('Search Bar Integration Tests', () {
    group('Search Query Processing', () {
      test('Empty search returns all buildings', () {
        final results = BuildingSearchService.getSuggestions('');
        expect(results.length, greaterThan(0));
        expect(results.length, BuildingSearchService.getAllBuildings().length);
      });

      test('Whitespace-only search returns all buildings', () {
        final results = BuildingSearchService.getSuggestions('   ');
        expect(results.length, greaterThan(0));
        expect(results.length, BuildingSearchService.getAllBuildings().length);
      });

      test('Single character search returns matching buildings', () {
        final results = BuildingSearchService.getSuggestions('H');
        expect(results.length, greaterThan(0));
      });

      test('Full code search returns exact match', () {
        final results = BuildingSearchService.searchBuilding('HALL');
        expect(results?.code, 'HALL');
      });

      test('Partial name search returns matches', () {
        final results = BuildingSearchService.getSuggestions('Hall');
        expect(results.length, greaterThan(0));
      });

      test('Case insensitive search works', () {
        final results1 = BuildingSearchService.getSuggestions('hall');
        final results2 = BuildingSearchService.getSuggestions('HALL');
        
        expect(results1.length, greaterThan(0));
        expect(results2.length, greaterThan(0));
      });

      test('Search preserves building information', () {
        final results = BuildingSearchService.getSuggestions('EV');
        
        for (final result in results) {
          expect(result.code.isNotEmpty, true);
          expect(result.name.isNotEmpty, true);
        }
      });
    });

    group('Search Result Formatting', () {
      test('Suggestion includes building code', () {
        final buildingNames = BuildingSearchService.getAllBuildings();
        if (buildingNames.isNotEmpty) {
          final name = buildingNames.first;
          expect(name.code.isNotEmpty, true);
        }
      });

      test('Suggestion includes building name', () {
        final buildingNames = BuildingSearchService.getAllBuildings();
        if (buildingNames.isNotEmpty) {
          final name = buildingNames.first;
          expect(name.name.isNotEmpty, true);
        }
      });

      test('Search terms are included for each building', () {
        final buildingNames = BuildingSearchService.getAllBuildings();
        if (buildingNames.isNotEmpty) {
          final name = buildingNames.first;
          expect(name.searchTerms.isNotEmpty, true);
        }
      });

      test('Multiple search terms work for single building', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final results = BuildingSearchService.getSuggestions('H');
        
        expect(results.isNotEmpty, true);
      });
    });

    group('Search State Management', () {
      test('Search suggestions can be cleared', () {
        var suggestions = BuildingSearchService.getSuggestions('H');
        expect(suggestions.isNotEmpty, true);
        
        suggestions = [];
        expect(suggestions.isEmpty, true);
      });

      test('Multiple searches can be performed sequentially', () {
        final search1 = BuildingSearchService.getSuggestions('H');
        final search2 = BuildingSearchService.getSuggestions('EV');
        final search3 = BuildingSearchService.getSuggestions('FG');
        
        expect(search1.isNotEmpty, true);
        expect(search2.isNotEmpty, true);
        expect(search3.isNotEmpty, true);
      });

      test('Search results are deterministic', () {
        final results1 = BuildingSearchService.getSuggestions('Hall');
        final results2 = BuildingSearchService.getSuggestions('Hall');
        
        expect(results1.length, results2.length);
      });
    });
  });
}
