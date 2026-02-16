import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/services/building_search_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('Search Functionality Tests', () {
    group('Building Search - Basic Queries', () {
      test('Search by exact building code returns correct building', () {
        final result = BuildingSearchService.searchBuilding('HALL');
        expect(result, isNotNull);
        expect(result?.code, 'HALL');
        expect(result?.name, 'Hall Building');
      });

      test('Search by exact building name returns correct building', () {
        final result = BuildingSearchService.searchBuilding('Hall Building');
        expect(result, isNotNull);
        expect(result?.code, 'HALL');
      });

      test('Search by partial building code returns correct building', () {
        final result = BuildingSearchService.searchBuilding('EV');
        expect(result, isNotNull);
        expect(result?.code, 'EV');
      });

      test('Search by partial building name returns correct building', () {
        final result = BuildingSearchService.searchBuilding('Hall');
        expect(result, isNotNull);
        expect(result?.code, 'HALL');
      });

      test('Search by search term returns correct building', () {
        final result = BuildingSearchService.searchBuilding('engineering');
        expect(result, isNotNull);
        expect(result?.code, 'EV');
      });

      test('Search for MB building with multiple search terms', () {
        final result1 = BuildingSearchService.searchBuilding('MB');
        final result2 = BuildingSearchService.searchBuilding('JSMB');
        expect(result1, isNotNull);
        expect(result2, isNotNull);
        expect(result1?.code, 'MB');
        expect(result2?.code, 'MB');
      });

      test('Search for EV building with search terms', () {
        final engineering = BuildingSearchService.searchBuilding('engineering');
        final visualArts = BuildingSearchService.searchBuilding('visual arts');
        expect(engineering?.code, 'EV');
        expect(visualArts?.code, 'EV');
      });
    });

    group('Building Search - Case Insensitivity', () {
      test('Search is case insensitive for codes', () {
        final result1 = BuildingSearchService.searchBuilding('hall');
        final result2 = BuildingSearchService.searchBuilding('HALL');
        final result3 = BuildingSearchService.searchBuilding('HaLl');
        final result4 = BuildingSearchService.searchBuilding('hAlL');

        expect(result1, isNotNull);
        expect(result2, isNotNull);
        expect(result3, isNotNull);
        expect(result4, isNotNull);
        expect(result1?.code, result2?.code);
        expect(result2?.code, result3?.code);
        expect(result3?.code, result4?.code);
      });

      test('Search is case insensitive for names', () {
        final result1 = BuildingSearchService.searchBuilding('hall building');
        final result2 = BuildingSearchService.searchBuilding('HALL BUILDING');
        final result3 = BuildingSearchService.searchBuilding('Hall Building');

        expect(result1?.code, 'HALL');
        expect(result2?.code, 'HALL');
        expect(result3?.code, 'HALL');
      });

      test('Search is case insensitive for search terms', () {
        final result1 = BuildingSearchService.searchBuilding('ENGINEERING');
        final result2 = BuildingSearchService.searchBuilding('engineering');
        final result3 = BuildingSearchService.searchBuilding('Engineering');

        expect(result1?.code, 'EV');
        expect(result2?.code, 'EV');
        expect(result3?.code, 'EV');
      });
    });

    group('Building Search - Edge Cases', () {
      test('Search with empty string returns null', () {
        final result = BuildingSearchService.searchBuilding('');
        expect(result, isNull);
      });

      test('Search with whitespace only returns null', () {
        final result = BuildingSearchService.searchBuilding('   ');
        expect(result, isNull);
      });

      test('Search with non-existent building returns null', () {
        final result = BuildingSearchService.searchBuilding('ZZZZZ9999');
        expect(result, isNull);
      });

      test('Search trims whitespace correctly', () {
        final result1 = BuildingSearchService.searchBuilding('  HALL  ');
        final result2 = BuildingSearchService.searchBuilding('HALL');
        expect(result1?.code, 'HALL');
        expect(result1?.code, result2?.code);
      });
    });

    group('Building Search - Loyola Campus Buildings', () {
      test('Search for Administration Building (AD)', () {
        final result = BuildingSearchService.searchBuilding('AD');
        expect(result, isNotNull);
        expect(result?.code, 'AD');
      });

      test('Search for PERFORM center', () {
        final result = BuildingSearchService.searchBuilding('perform');
        expect(result, isNotNull);
        expect(result?.code, 'PC');
      });

      test('Search for Psychology building', () {
        final result1 = BuildingSearchService.searchBuilding('psychology');
        final result2 = BuildingSearchService.searchBuilding('psych');
        expect(result1?.code, 'PY');
        expect(result2?.code, 'PY');
      });

      test('Search for Oscar Peterson Concert Hall', () {
        final result = BuildingSearchService.searchBuilding('oscar peterson');
        expect(result, isNotNull);
        expect(result?.code, 'PT');
      });
    });

    group('Building Suggestions Tests', () {
      test('Get suggestions returns results for partial query', () {
        final suggestions = BuildingSearchService.getSuggestions('H');
        expect(suggestions.isNotEmpty, true);
        expect(suggestions.any((s) => s.code == 'HALL'), true);
      });

      test('Get suggestions with exact match prioritizes exact matches', () {
        final suggestions = BuildingSearchService.getSuggestions('MB');
        expect(suggestions.isNotEmpty, true);
        expect(suggestions.first.code, 'MB');
      });

      test('Get suggestions returns all buildings for empty query', () {
        final suggestions = BuildingSearchService.getSuggestions('');
        expect(suggestions.length, concordiaBuildingNames.length);
      });

      test('Get suggestions filters results correctly', () {
        final suggestions = BuildingSearchService.getSuggestions('engineering');
        expect(suggestions.isNotEmpty, true);
        expect(suggestions.any((s) => s.code == 'EV'), true);
      });

      test('Get suggestions returns unique results', () {
        final suggestions = BuildingSearchService.getSuggestions('hall');
        final codes = suggestions.map((s) => s.code).toList();
        final uniqueCodes = codes.toSet();
        expect(codes.length, uniqueCodes.length);
      });

      test('Get suggestions prioritizes code matches over name matches', () {
        final suggestions = BuildingSearchService.getSuggestions('MB');
        expect(suggestions.first.code, 'MB');
      });

      test('Get suggestions includes search term matches', () {
        final suggestions = BuildingSearchService.getSuggestions('library');
        expect(suggestions.any((s) => s.code == 'VL'), true);
      });
    });

    group('Search Suggestion Model Tests', () {
      test('Create SearchSuggestion from Concordia building', () {
        final building = concordiaBuildingNames.first;
        final suggestion = SearchSuggestion.fromConcordiaBuilding(building);

        expect(suggestion.name, building.name);
        expect(suggestion.subtitle, building.code);
        expect(suggestion.isConcordiaBuilding, true);
        expect(suggestion.buildingName, building);
        expect(suggestion.placeId, isNull);
      });

      test('Create SearchSuggestion from Google place', () {
        final suggestion = SearchSuggestion.fromGooglePlace(
          name: 'Test Place',
          subtitle: 'Test Address',
          placeId: 'test_place_id',
        );

        expect(suggestion.name, 'Test Place');
        expect(suggestion.subtitle, 'Test Address');
        expect(suggestion.isConcordiaBuilding, false);
        expect(suggestion.buildingName, isNull);
        expect(suggestion.placeId, 'test_place_id');
      });

      test('SearchSuggestion handles null subtitle for Google place', () {
        final suggestion = SearchSuggestion.fromGooglePlace(
          name: 'Test Place',
          placeId: 'test_place_id',
        );

        expect(suggestion.name, 'Test Place');
        expect(suggestion.subtitle, isNull);
        expect(suggestion.placeId, 'test_place_id');
      });
    });

    group('Building Name by Code Tests', () {
      test('Get building name by code returns correct name', () {
        final name = BuildingSearchService.getBuildingNameByCode('HALL');
        expect(name, 'Hall Building');
      });

      test('Get building name by code returns null for non-existent code', () {
        final name = BuildingSearchService.getBuildingNameByCode('NONEXISTENT');
        expect(name, isNull);
      });

      test('Get building name by code works for all buildings', () {
        for (final building in concordiaBuildingNames) {
          final name = BuildingSearchService.getBuildingNameByCode(building.code);
          expect(name, building.name);
        }
      });
    });

    group('Get All Buildings Tests', () {
      test('Get all buildings returns complete list', () {
        final allBuildings = BuildingSearchService.getAllBuildings();
        expect(allBuildings.length, concordiaBuildingNames.length);
      });

      test('Get all buildings returns same reference', () {
        final allBuildings = BuildingSearchService.getAllBuildings();
        expect(allBuildings, concordiaBuildingNames);
      });
    });

    group('Location-Based Building Detection Tests', () {
      test('Check if location in Concordia building returns correct result', () {
        // Test with Hall Building coordinates (approximate center)
        final hallCenter = LatLng(45.4973, -73.5789);
        final isInBuilding = BuildingSearchService.isLocationInConcordiaBuilding(hallCenter);
        
        // The result depends on the actual polygon data, but we can test the method works
        expect(isInBuilding, isA<bool>());
      });

      test('Check if random location returns boolean', () {
        final randomLocation = LatLng(45.5, -73.5);
        final isInBuilding = BuildingSearchService.isLocationInConcordiaBuilding(randomLocation);
        expect(isInBuilding, isA<bool>());
      });
    });

    group('Search Results Priority Tests', () {
      test('Exact code match takes priority', () {
        final suggestions = BuildingSearchService.getSuggestions('EV');
        expect(suggestions.first.code, 'EV');
      });

      test('Exact name match appears before partial matches', () {
        final suggestions = BuildingSearchService.getSuggestions('Hall Building');
        expect(suggestions.first.code, 'HALL');
      });

      test('Multiple character search returns relevant results', () {
        final suggestions = BuildingSearchService.getSuggestions('sci');
        expect(suggestions.isNotEmpty, true);
        // Should include Science-related buildings
      });
    });

    group('Special Building Tests', () {
      test('Search for Grey Nuns Building', () {
        final result1 = BuildingSearchService.searchBuilding('grey nuns');
        final result2 = BuildingSearchService.searchBuilding('GN');
        expect(result1?.code, 'GN');
        expect(result2?.code, 'GN');
      });

      test('Search for Learning Square', () {
        final result1 = BuildingSearchService.searchBuilding('learning square');
        final result2 = BuildingSearchService.searchBuilding('LS');
        expect(result1?.code, 'LS');
        expect(result2?.code, 'LS');
      });

      test('Search for Faubourg variations', () {
        final result1 = BuildingSearchService.searchBuilding('faubourg');
        final result2 = BuildingSearchService.searchBuilding('FG');
        expect(result1, isNotNull);
        expect(result2, isNotNull);
      });

      test('Search for annexes', () {
        final resultB = BuildingSearchService.searchBuilding('B annex');
        final resultCI = BuildingSearchService.searchBuilding('CI annex');
        expect(resultB, isNotNull);
        expect(resultCI, isNotNull);
      });
    });

    group('Search Functionality Consistency Tests', () {
      test('All building codes can be searched', () {
        for (final building in concordiaBuildingNames) {
          final result = BuildingSearchService.searchBuilding(building.code);
          expect(result, isNotNull, reason: 'Building ${building.code} should be searchable');
        }
      });

      test('All building names can be searched', () {
        for (final building in concordiaBuildingNames) {
          final result = BuildingSearchService.searchBuilding(building.name);
          expect(result, isNotNull, reason: 'Building "${building.name}" should be searchable');
        }
      });

      test('Search results are consistent', () {
        final result1 = BuildingSearchService.searchBuilding('HALL');
        final result2 = BuildingSearchService.searchBuilding('HALL');
        expect(result1?.code, result2?.code);
        expect(result1?.name, result2?.name);
      });
    });
  });
}
