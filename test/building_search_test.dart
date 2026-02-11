import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('Building Search Service Tests', () {
    test('All building polygons have corresponding building names', () {
      final polygonCodes = buildingPolygons.map((b) => b.code).toSet();
      final nameCodes = concordiaBuildingNames.map((b) => b.code).toSet();

      // Check if all polygon codes have a corresponding name entry
      for (final code in polygonCodes) {
        expect(
          nameCodes.contains(code),
          true,
          reason: 'Building code "$code" missing from building_names.dart',
        );
      }
    });

    test('Search by exact building code works', () {
      final result = BuildingSearchService.searchBuilding('HALL');
      expect(result, isNotNull);
      expect(result?.code, 'HALL');
    });

    test('Search by exact building name works', () {
      final result = BuildingSearchService.searchBuilding('Hall Building');
      expect(result, isNotNull);
      expect(result?.code, 'HALL');
    });

    test('Search by partial name works', () {
      final result = BuildingSearchService.searchBuilding('Hall');
      expect(result, isNotNull);
      expect(result?.code, 'HALL');
    });

    test('Search by search term works', () {
      final result = BuildingSearchService.searchBuilding('engineering');
      expect(result, isNotNull);
      expect(result?.code, 'EV');
    });

    test('Case insensitive search works', () {
      final result1 = BuildingSearchService.searchBuilding('hall');
      final result2 = BuildingSearchService.searchBuilding('HALL');
      final result3 = BuildingSearchService.searchBuilding('HaLl');

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result3, isNotNull);
      expect(result1?.code, result2?.code);
      expect(result2?.code, result3?.code);
    });

    test('Search with empty string returns null', () {
      final result = BuildingSearchService.searchBuilding('');
      expect(result, isNull);
    });

    test('Get suggestions returns results', () {
      final suggestions = BuildingSearchService.getSuggestions('H');
      expect(suggestions.isNotEmpty, true);
    });

    test('Get suggestions with exact match prioritizes exact matches', () {
      final suggestions = BuildingSearchService.getSuggestions('MB');
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first.code, 'MB');
    });

    test('Get all buildings returns complete list', () {
      final allBuildings = BuildingSearchService.getAllBuildings();
      expect(allBuildings.length, concordiaBuildingNames.length);
    });

    test('Get building name by code works', () {
      final name = BuildingSearchService.getBuildingNameByCode('HALL');
      expect(name, 'Hall Building');
    });

    test('Get building name by invalid code returns null', () {
      final name = BuildingSearchService.getBuildingNameByCode('INVALID');
      expect(name, isNull);
    });
  });

  group('Building Name Coverage Tests', () {
    test('SGW Campus buildings are included', () {
      final sgwBuildings = ['LB', 'MB', 'HALL', 'EV', 'GM', 'FG'];
      for (final code in sgwBuildings) {
        final result = BuildingSearchService.searchBuilding(code);
        expect(result, isNotNull, reason: 'SGW building "$code" not found');
      }
    });

    test('Loyola Campus buildings are included', () {
      final loyolaBuildings = ['AD', 'CC', 'VL', 'SP', 'RA', 'SC'];
      for (final code in loyolaBuildings) {
        final result = BuildingSearchService.searchBuilding(code);
        expect(result, isNotNull, reason: 'Loyola building "$code" not found');
      }
    });
  });
}
