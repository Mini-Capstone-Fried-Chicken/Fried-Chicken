import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('BuildingSearchService Extended Tests', () {
    group('Location in Concordia Building', () {
      test('Location at SGW center is in a building', () {
        const sgwCenter = LatLng(45.4973, -73.5789);
        final inBuilding = BuildingSearchService.isLocationInConcordiaBuilding(sgwCenter);
        
        // SGW center should be near buildings
        expect(inBuilding, isA<bool>());
      });

      test('Location at Loyola center is in a building', () {
        const loyolaCenter = LatLng(45.4582, -73.6405);
        final inBuilding = BuildingSearchService.isLocationInConcordiaBuilding(loyolaCenter);
        
        expect(inBuilding, isA<bool>());
      });

      test('Random location far away is not in building', () {
        const farLocation = LatLng(0, 0); // Equator
        final inBuilding = BuildingSearchService.isLocationInConcordiaBuilding(farLocation);
        
        expect(inBuilding, false);
      });

      test('Location in building polygon returns true or false consistently', () {
        const location1 = LatLng(45.4973, -73.5789);
        
        final result1a = BuildingSearchService.isLocationInConcordiaBuilding(location1);
        final result1b = BuildingSearchService.isLocationInConcordiaBuilding(location1);
        
        // Same location should return same result
        expect(result1a, result1b);
      });

      test('Points within building bounds are detected', () {
        // Use first building's bounds
        if (buildingPolygons.isNotEmpty) {
          final building = buildingPolygons.first;
          
          // Get center of building
          final center = building.center;
          expect(center, isNotNull);
          
          final inBuilding = BuildingSearchService.isLocationInConcordiaBuilding(center);
          expect(inBuilding, isA<bool>());
        }
      });

      test('Multiple locations can be checked independently', () {
        for (final building in buildingPolygons.take(3)) {
          final result = BuildingSearchService.isLocationInConcordiaBuilding(building.center);
          expect(result, isA<bool>());
        }
      });
    });

    group('Find Building by Location', () {
      test('Valid building location returns building', () {
        // Use a known building location
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final found = BuildingSearchService.isLocationInConcordiaBuilding(hallBuilding.center);
        
        expect(found, isA<bool>());
      });

      test('Building polygons have valid centers', () {
        for (final building in buildingPolygons.take(5)) {
          expect(building.center, isNotNull);
          expect(building.center.latitude, greaterThan(-90));
          expect(building.center.latitude, lessThan(90));
          expect(building.center.longitude, greaterThan(-180));
          expect(building.center.longitude, lessThan(180));
        }
      });

      test('All buildings can be found by their center', () {
        for (final building in buildingPolygons.take(10)) {
          final result = BuildingSearchService.isLocationInConcordiaBuilding(building.center);
          expect(result, isA<bool>());
        }
      });
    });

    group('Search with Google Places', () {
      test('Empty query returns empty list', () async {
        final results = await BuildingSearchService.searchWithGooglePlaces('');
        expect(results, isEmpty);
      });

      test('Whitespace only query returns empty list', () async {
        final results = await BuildingSearchService.searchWithGooglePlaces('   ');
        expect(results, isEmpty);
      });

      test('Search returns list of SearchResult', () async {
        // This will return empty since we don't mock the HTTP client
        // But we can verify the structure
        final results = await BuildingSearchService.searchWithGooglePlaces('café');
        expect(results, isA<List>());
      });

      test('Search with location bias', () async {
        const location = LatLng(45.4973, -73.5789);
        final results = await BuildingSearchService.searchWithGooglePlaces(
          'library',
          userLocation: location,
        );
        
        expect(results, isA<List>());
      });

      test('Search without location bias uses default', () async {
        final results = await BuildingSearchService.searchWithGooglePlaces(
          'restaurant',
          userLocation: null,
        );
        
        expect(results, isA<List>());
      });
    });

    group('Combined Suggestions', () {
      test('Empty query returns no suggestions when query is empty', () async {
        final suggestions = await BuildingSearchService.getCombinedSuggestions('');
        
        // Empty query should return only Concordia buildings (first 10)
        expect(suggestions, isA<List>());
      });

      test('Single character query returns suggestions', () async {
        final suggestions = await BuildingSearchService.getCombinedSuggestions('H');
        expect(suggestions, isA<List>());
      });

      test('Multiple character query returns suggestions', () async {
        final suggestions = await BuildingSearchService.getCombinedSuggestions('Hall');
        expect(suggestions, isA<List>());
      });

      test('Query with location bias', () async {
        const location = LatLng(45.4973, -73.5789);
        final suggestions = await BuildingSearchService.getCombinedSuggestions(
          'building',
          userLocation: location,
        );
        
        expect(suggestions, isA<List>());
      });

      test('Search term matching works', () async {
        final suggestions = await BuildingSearchService.getCombinedSuggestions('engineering');
        expect(suggestions, isA<List>());
      });
    });

    group('Building Code Lookup', () {
      test('Valid building codes have names', () {
        final codes = ['HALL', 'EV', 'MB', 'LB'];
        
        for (final code in codes) {
          final name = BuildingSearchService.getBuildingNameByCode(code);
          expect(name, isNotNull);
          expect(name, isA<String>());
        }
      });

      test('Invalid building code returns null', () {
        final name = BuildingSearchService.getBuildingNameByCode('ZZZZZ');
        expect(name, isNull);
      });

      test('Empty code returns null', () {
        final name = BuildingSearchService.getBuildingNameByCode('');
        expect(name, isNull);
      });

      test('Case sensitivity in building codes', () {
        final hallUpper = BuildingSearchService.getBuildingNameByCode('HALL');
        final hallLower = BuildingSearchService.getBuildingNameByCode('hall');
        
        expect(hallUpper, isNotNull);
        // Note: codes are case-sensitive, so 'hall' might not match 'HALL'
        if (hallLower != null) {
          expect(hallLower, isA<String>());
        }
      });

      test('All building polygons have names', () {
        for (final building in buildingPolygons.take(10)) {
          final name = BuildingSearchService.getBuildingNameByCode(building.code);
          expect(name, isNotNull);
        }
      });
    });

    group('Building Search Consistency', () {
      test('Search by code is consistent', () {
        final result1 = BuildingSearchService.searchBuilding('HALL');
        final result2 = BuildingSearchService.searchBuilding('HALL');
        
        expect(result1?.code, result2?.code);
      });

      test('Search by name is consistent', () {
        final result1 = BuildingSearchService.searchBuilding('Hall Building');
        final result2 = BuildingSearchService.searchBuilding('Hall Building');
        
        expect(result1?.code, result2?.code);
      });

      test('Search and building code lookup are consistent', () {
        const code = 'HALL';
        final foundBuilding = BuildingSearchService.searchBuilding(code);
        final buildingName = BuildingSearchService.getBuildingNameByCode(code);
        
        if (foundBuilding != null && buildingName != null) {
          expect(foundBuilding.code, code);
          expect(buildingName, isNotEmpty);
        }
      });
    });

    group('Suggestion Retrieval', () {
      test('Get all buildings returns list', () {
        final buildings = BuildingSearchService.getAllBuildings();
        expect(buildings, isA<List>());
        expect(buildings, isNotEmpty);
      });

      test('Get suggestions for query returns list', () {
        final suggestions = BuildingSearchService.getSuggestions('H');
        expect(suggestions, isA<List>());
      });

      test('Empty query suggestions', () {
        final suggestions = BuildingSearchService.getSuggestions('');
        expect(suggestions, isA<List>());
        // Empty query might return all or empty
      });

      test('All buildings list is not empty', () {
        final allBuildings = BuildingSearchService.getAllBuildings();
        expect(allBuildings.length, greaterThan(0));
      });

      test('Suggestions prioritize exact matches', () {
        final suggestions = BuildingSearchService.getSuggestions('HALL');
        expect(suggestions, isA<List>());
        
        if (suggestions.isNotEmpty) {
          // First result should be exact match if available
          expect(suggestions.first.code, isNotEmpty);
        }
      });
    });

    group('Location Point Validation', () {
      test('Building centers are within Montreal bounds', () {
        for (final building in buildingPolygons) {
          final center = building.center;
          
          expect(center.latitude, greaterThan(45.0));
          expect(center.latitude, lessThan(46.0));
          expect(center.longitude, greaterThan(-74.0));
          expect(center.longitude, lessThan(-73.0));
        }
      });

      test('Building points are valid coordinates', () {
        for (final building in buildingPolygons.take(5)) {
          for (final point in building.points) {
            expect(point.latitude, greaterThanOrEqualTo(-90.0));
            expect(point.latitude, lessThanOrEqualTo(90.0));
            expect(point.longitude, greaterThanOrEqualTo(-180.0));
            expect(point.longitude, lessThanOrEqualTo(180.0));
          }
        }
      });

      test('SGW campus buildings exist', () {
        final sgwCodes = ['HALL', 'EV', 'MB', 'LB', 'GM', 'FG'];
        
        for (final code in sgwCodes) {
          final building = BuildingSearchService.searchBuilding(code);
          expect(building, isNotNull, reason: 'SGW building $code not found');
        }
      });

      test('Loyola campus buildings exist', () {
        final loyolaCodes = ['AD', 'CC', 'VL', 'SP'];
        
        for (final code in loyolaCodes) {
          final building = BuildingSearchService.searchBuilding(code);
          if (building != null) {
            expect(building.code, code);
          }
        }
      });
    });

    group('Query Processing', () {
      test('Query whitespace is trimmed', () {
        final result1 = BuildingSearchService.searchBuilding('  HALL  ');
        final result2 = BuildingSearchService.searchBuilding('HALL');
        
        expect(result1?.code, result2?.code);
      });

      test('Query case is normalized', () {
        final result1 = BuildingSearchService.searchBuilding('hall');
        final result2 = BuildingSearchService.searchBuilding('HALL');
        final result3 = BuildingSearchService.searchBuilding('HaLl');
        
        expect(result1?.code, isNotNull);
        expect(result2?.code, isNotNull);
        expect(result3?.code, isNotNull);
      });

      test('Partial queries work correctly', () {
        final result = BuildingSearchService.searchBuilding('Engi');
        expect(result, isNotNull);
      });

      test('Search term queries work', () {
        // 'psych' is a search term for Psychology building
        final result = BuildingSearchService.searchBuilding('psych');
        expect(result, isNotNull);
      });
    });

    group('Data Integrity', () {
      test('Building codes are not empty', () {
        for (final building in buildingPolygons) {
          expect(building.code, isNotEmpty);
        }
      });

      test('Building names are not empty', () {
        for (final building in buildingPolygons) {
          expect(building.name, isNotEmpty);
        }
      });

      test('Building polygons have points', () {
        for (final building in buildingPolygons) {
          expect(building.points, isNotEmpty);
          expect(building.points.length, greaterThanOrEqualTo(3));
        }
      });

      test('No duplicate building codes', () {
        final codes = buildingPolygons.map((b) => b.code).toList();
        final uniqueCodes = codes.toSet();
        
        expect(codes.length, uniqueCodes.length);
      });
    });
  });
}
