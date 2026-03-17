import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/services/building_search_service.dart';

class _QueryCodeStrategy implements BuildingMatchStrategy {
  _QueryCodeStrategy({
    required this.id,
    required this.query,
    required this.code,
  });

  @override
  final String id;
  final String query;
  final String code;

  @override
  bool canHandle(String normalizedQuery) => normalizedQuery == query;

  @override
  BuildingPolygon? match(String normalizedQuery) {
    for (final building in buildingPolygons) {
      if (building.code == code) {
        return building;
      }
    }
    return null;
  }
}

class _NeverHandleStrategy implements BuildingMatchStrategy {
  _NeverHandleStrategy({required this.id});

  @override
  final String id;

  @override
  bool canHandle(String normalizedQuery) => false;

  @override
  BuildingPolygon? match(String normalizedQuery) {
    throw StateError('match should not be called when canHandle is false');
  }
}

void main() {
  group('BuildingSearchService runtime strategy configuration', () {
    setUp(() {
      BuildingSearchService.resetBuildingMatchStrategies();
    });

    tearDown(() {
      BuildingSearchService.resetBuildingMatchStrategies();
    });

    test('default strategy order is exact code, name, term, then partial', () {
      final ids = BuildingSearchService.buildingMatchStrategies
          .map((strategy) => strategy.id)
          .toList();

      expect(
        ids,
        equals([
          'exactCodeMatch',
          'exactNameMatch',
          'exactSearchTermMatch',
          'partialSearchTermMatch',
        ]),
      );
    });

    test('setBuildingMatchStrategies rejects empty list', () {
      expect(
        () => BuildingSearchService.setBuildingMatchStrategies(const []),
        throwsArgumentError,
      );
    });

    test('same query can resolve differently based on runtime order', () {
      final first = _QueryCodeStrategy(
        id: 'runtimeFirst',
        query: 'runtime-query',
        code: 'LB',
      );
      final second = _QueryCodeStrategy(
        id: 'runtimeSecond',
        query: 'runtime-query',
        code: 'EV',
      );

      BuildingSearchService.setBuildingMatchStrategies([first, second]);
      final resultFromFirstOrder = BuildingSearchService.searchBuilding(
        'runtime-query',
      );

      BuildingSearchService.setBuildingMatchStrategies([second, first]);
      final resultFromSecondOrder = BuildingSearchService.searchBuilding(
        'runtime-query',
      );

      expect(resultFromFirstOrder?.code, equals('LB'));
      expect(resultFromSecondOrder?.code, equals('EV'));
    });

    test('registerBuildingMatchStrategy prepend can override default', () {
      final hallDefault = BuildingSearchService.searchBuilding('hall');
      expect(hallDefault?.code, equals('HALL'));

      final override = _QueryCodeStrategy(
        id: 'hallOverride',
        query: 'hall',
        code: 'EV',
      );

      BuildingSearchService.registerBuildingMatchStrategy(
        override,
        prepend: true,
      );

      final hallOverridden = BuildingSearchService.searchBuilding('hall');
      expect(hallOverridden?.code, equals('EV'));
    });

    test('registerBuildingMatchStrategy append acts as fallback', () {
      final fallback = _QueryCodeStrategy(
        id: 'newFallback',
        query: 'zz-building',
        code: 'GM',
      );

      BuildingSearchService.registerBuildingMatchStrategy(fallback);

      final result = BuildingSearchService.searchBuilding('zz-building');
      expect(result?.code, equals('GM'));
    });

    test('removeBuildingMatchStrategy removes by id and reports result', () {
      final fallback = _QueryCodeStrategy(
        id: 'toRemove',
        query: 'remove-me',
        code: 'LB',
      );
      BuildingSearchService.registerBuildingMatchStrategy(fallback);

      expect(BuildingSearchService.searchBuilding('remove-me')?.code, 'LB');

      final removed = BuildingSearchService.removeBuildingMatchStrategy(
        'toRemove',
      );
      final removedAgain = BuildingSearchService.removeBuildingMatchStrategy(
        'toRemove',
      );

      expect(removed, isTrue);
      expect(removedAgain, isFalse);
      expect(BuildingSearchService.searchBuilding('remove-me'), isNull);
    });

    test('resetBuildingMatchStrategies restores default behavior', () {
      BuildingSearchService.setBuildingMatchStrategies([
        _QueryCodeStrategy(id: 'replacement', query: 'hall', code: 'EV'),
      ]);

      expect(BuildingSearchService.searchBuilding('hall')?.code, equals('EV'));

      BuildingSearchService.resetBuildingMatchStrategies();

      expect(
        BuildingSearchService.searchBuilding('hall')?.code,
        equals('HALL'),
      );
    });

    test('strategy with canHandle false is skipped', () {
      BuildingSearchService.setBuildingMatchStrategies([
        _NeverHandleStrategy(id: 'never'),
        _QueryCodeStrategy(id: 'next', query: 'skip-check', code: 'LB'),
      ]);

      final result = BuildingSearchService.searchBuilding('skip-check');
      expect(result?.code, equals('LB'));
    });
  });
}
