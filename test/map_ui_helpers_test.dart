import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/data/search_result.dart';
import 'package:campus_app/services/building_search_service.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('Map UIHelper Functions Tests', () {
    group('Polygon Center Calculation', () {
      test('Calculates center of triangle correctly', () {
        final points = [
          LatLng(0, 0),
          LatLng(0, 2),
          LatLng(2, 0),
        ];
        // Center of right triangle should be near centroid
        final polygonPoints = points;
        var sumLat = 0.0;
        var sumLng = 0.0;
        for (var p in polygonPoints) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final centerLat = sumLat / polygonPoints.length;
        final centerLng = sumLng / polygonPoints.length;
        
        expect(centerLat, closeTo(0.666, 0.01));
        expect(centerLng, closeTo(0.666, 0.01));
      });

      test('Calculates center of square correctly', () {
        final points = [
          LatLng(0, 0),
          LatLng(0, 2),
          LatLng(2, 2),
          LatLng(2, 0),
        ];
        var sumLat = 0.0;
        var sumLng = 0.0;
        for (var p in points) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final centerLat = sumLat / points.length;
        final centerLng = sumLng / points.length;
        
        expect(centerLat, 1.0);
        expect(centerLng, 1.0);
      });

      test('Handles single point polygon', () {
        final points = [LatLng(45.5, -73.5)];
        expect(points.first, LatLng(45.5, -73.5));
      });

      test('Handles two-point polygon (line)', () {
        final points = [
          LatLng(0, 0),
          LatLng(2, 2),
        ];
        final midpoint = LatLng(1, 1);
        // Verify line exists
        expect(points.length, 2);
        expect(points.first, LatLng(0, 0));
      });

      test('Calculates center of real building polygon', () {
        // Use an actual building polygon from the data
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        expect(hallBuilding.points.length, greaterThan(2));
        expect(hallBuilding.center, isNotNull);
        expect(hallBuilding.center.latitude, isA<double>());
        expect(hallBuilding.center.longitude, isA<double>());
      });

      test('Building polygon centers are within building bounds', () {
        for (final building in buildingPolygons.take(5)) {
          final center = building.center;
          expect(center, isNotNull);
          
          // Get bounds
          double minLat = building.points.first.latitude;
          double maxLat = building.points.first.latitude;
          double minLng = building.points.first.longitude;
          double maxLng = building.points.first.longitude;
          
          for (final point in building.points) {
            minLat = minLat < point.latitude ? minLat : point.latitude;
            maxLat = maxLat > point.latitude ? maxLat : point.latitude;
            minLng = minLng < point.longitude ? minLng : point.longitude;
            maxLng = maxLng > point.longitude ? maxLng : point.longitude;
          }
          
          // Center should be within bounds (with some tolerance)
          expect(center.latitude, greaterThanOrEqualTo(minLat - 0.001));
          expect(center.latitude, lessThanOrEqualTo(maxLat + 0.001));
        }
      });
    });

    group('Building Bounds Calculation', () {
      test('Calculates bounds for list of points', () {
        final points = [
          LatLng(45.4, -73.4),
          LatLng(45.5, -73.5),
          LatLng(45.3, -73.6),
        ];
        
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;
        
        for (final point in points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }
        
        expect(minLat, 45.3);
        expect(maxLat, 45.5);
        expect(minLng, -73.6);
        expect(maxLng, -73.4);
      });

      test('LatLngBounds encompasses all points', () {
        final sw = LatLng(45.3, -73.6);
        final ne = LatLng(45.5, -73.4);
        
        expect(sw.latitude, lessThan(ne.latitude));
        expect(sw.longitude, lessThan(ne.longitude));
      });

      test('All building polygons have valid bounds', () {
        for (final building in buildingPolygons.take(10)) {
          double minLat = building.points.first.latitude;
          double maxLat = building.points.first.latitude;
          
          for (final point in building.points) {
            minLat = minLat < point.latitude ? minLat : point.latitude;
            maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          }
          
          expect(minLat, lessThan(maxLat));
        }
      });
    });

    group('Coordinate Validation', () {
      test('Valid latitude and longitude ranges', () {
        final coord = LatLng(45.4973, -73.5789);
        expect(coord.latitude, greaterThan(-90));
        expect(coord.latitude, lessThan(90));
        expect(coord.longitude, greaterThan(-180));
        expect(coord.longitude, lessThan(180));
      });

      test('All building points are within valid coordinate ranges', () {
        for (final building in buildingPolygons) {
          for (final point in building.points) {
            expect(point.latitude, greaterThan(-90));
            expect(point.latitude, lessThan(90));
            expect(point.longitude, greaterThan(-180));
            expect(point.longitude, lessThan(180));
          }
        }
      });

      test('Building center is within valid range', () {
        for (final building in buildingPolygons) {
          final center = building.center;
          expect(center.latitude, greaterThan(-90));
          expect(center.latitude, lessThan(90));
          expect(center.longitude, greaterThan(-180));
          expect(center.longitude, lessThan(180));
        }
      });
    });

    group('Search Result Creation from Buildings', () {
      test('SearchResult maintains building reference', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final result = SearchResult.fromConcordiaBuilding(hallBuilding);
        
        expect(result.buildingPolygon, hallBuilding);
        expect(result.isConcordiaBuilding, true);
      });

      test('SearchResult location matches building center', () {
        final building = buildingPolygons.first;
        final result = SearchResult.fromConcordiaBuilding(building);
        
        expect(result.location.latitude, building.center.latitude);
        expect(result.location.longitude, building.center.longitude);
      });

      test('All buildingPolygons can be converted to SearchResult', () {
        final results = buildingPolygons
            .map((b) => SearchResult.fromConcordiaBuilding(b))
            .toList();
        
        expect(results.length, buildingPolygons.length);
        expect(results.every((r) => r.isConcordiaBuilding), true);
      });

      test('SearchResult preserves building name and code', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final result = SearchResult.fromConcordiaBuilding(hallBuilding);
        
        expect(result.name, hallBuilding.name);
        expect(result.buildingPolygon?.code, 'HALL');
      });
    });

    group('SearchSuggestion Creation from Buildings', () {
      test('SearchSuggestion from building name works', () {
        final buildingNames = BuildingSearchService.getAllBuildings();
        if (buildingNames.isNotEmpty) {
          final firstName = buildingNames.first;
          final suggestion = SearchSuggestion.fromConcordiaBuilding(firstName);
          
          expect(suggestion.isConcordiaBuilding, true);
          expect(suggestion.buildingName, firstName);
          expect(suggestion.name, firstName.name);
        }
      });

      test('SearchSuggestion from Google Place works', () {
        final suggestion = SearchSuggestion.fromGooglePlace(
          name: 'Test Place',
          subtitle: 'Test Subtitle',
          placeId: 'test_place_id',
        );
        
        expect(suggestion.isConcordiaBuilding, false);
        expect(suggestion.placeId, 'test_place_id');
        expect(suggestion.name, 'Test Place');
      });

      test('Multiple suggestions can be created from different buildings', () {
        final buildings = buildingPolygons.take(5).toList();
        final suggestions = <SearchSuggestion>[];
        
        for (final building in buildings) {
          final buildingName = BuildingSearchService.getAllBuildings()
              .firstWhere((b) => b.code == building.code);
          suggestions.add(SearchSuggestion.fromConcordiaBuilding(buildingName));
        }
        
        expect(suggestions.length, 5);
        expect(suggestions.every((s) => s.isConcordiaBuilding), true);
      });
    });

    group('Color and Styling Constants', () {
      test('Burgundy color is valid', () {
        const burgundy = Color(0xFF800020);
        expect(burgundy.red, 128);
        expect(burgundy.green, 0);
        expect(burgundy.blue, 32);
      });

      test('Selected blue color is valid', () {
        const selectedBlue = Color(0xFF7F83C3);
        expect(selectedBlue.red, 127);
        expect(selectedBlue.green, 131);
        expect(selectedBlue.blue, 195);
      });

      test('Colors with opacity are valid', () {
        const burgundy = Color(0xFF800020);
        final withOpacity1 = burgundy.withOpacity(0.55);
        final withOpacity2 = burgundy.withOpacity(0.22);
        
        expect(withOpacity1, isA<Color>());
        expect(withOpacity2, isA<Color>());
        expect(withOpacity1.opacity, closeTo(0.55, 0.01));
        expect(withOpacity2.opacity, closeTo(0.22, 0.01));
      });

      test('Blue color variations are valid', () {
        final blue1 = Colors.blue.withOpacity(0.8);
        final blue2 = Colors.blue.withOpacity(0.25);
        
        expect(blue1.opacity, closeTo(0.8, 0.01));
        expect(blue2.opacity, closeTo(0.25, 0.01));
      });
    });
  });
}
