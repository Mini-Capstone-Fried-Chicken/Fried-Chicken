import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart';

void main() {
  group('IndoorFloorConfig', () {
    group('floorsForBuilding', () {
      test('returns correct floors for HALL building', () {
        final floors = IndoorFloorConfig.floorsForBuilding('HALL');

        expect(floors.length, greaterThan(0));
        expect(
          floors.every((f) => f.assetPath.toUpperCase().contains('HALL')),
          true,
        );
        expect(floors.every((f) => f.label.isNotEmpty), true);
      });

      test('returns correct floors for MB building', () {
        final floors = IndoorFloorConfig.floorsForBuilding('MB');

        expect(floors.length, greaterThan(0));
        expect(
          floors.every((f) => f.assetPath.toUpperCase().contains('MB')),
          true,
        );
        expect(floors.every((f) => f.label.isNotEmpty), true);
      });

      test('returns correct floors for VE building', () {
        final floors = IndoorFloorConfig.floorsForBuilding('VE');

        expect(floors.length, greaterThan(0));
        expect(
          floors.every((f) => f.assetPath.toUpperCase().contains('VE')),
          true,
        );
        expect(floors.every((f) => f.label.isNotEmpty), true);
      });

      test('returns correct floors for VL building', () {
        final floors = IndoorFloorConfig.floorsForBuilding('VL');

        expect(floors.length, greaterThan(0));
        expect(
          floors.every((f) => f.assetPath.toUpperCase().contains('VL')),
          true,
        );
        expect(floors.every((f) => f.label.isNotEmpty), true);
      });

      test('returns correct floors for CC building', () {
        final floors = IndoorFloorConfig.floorsForBuilding('CC');

        expect(floors.length, greaterThan(0));
        expect(
          floors.every((f) => f.assetPath.toUpperCase().contains('CC')),
          true,
        );
        expect(floors.every((f) => f.label.isNotEmpty), true);
      });

      test('returns empty list for unknown building code', () {
        final floors = IndoorFloorConfig.floorsForBuilding('UNKNOWN');

        expect(floors.isEmpty, true);
      });

      test('returns empty list for empty building code', () {
        final floors = IndoorFloorConfig.floorsForBuilding('');

        expect(floors.isEmpty, true);
      });

      test('floor options have correct structure', () {
        final floors = IndoorFloorConfig.floorsForBuilding('HALL');

        expect(floors.isNotEmpty, true);
        for (final floor in floors) {
          expect(floor.label, isNotEmpty);
          expect(floor.assetPath, isNotEmpty);
          expect(floor.assetPath, startsWith('assets/'));
          expect(floor.assetPath, endsWith('.geojson.json'));
        }
      });

      test('floor labels are unique within building', () {
        final floors = IndoorFloorConfig.floorsForBuilding('HALL');

        final labels = floors.map((f) => f.label).toList();
        final uniqueLabels = labels.toSet();

        expect(labels.length, uniqueLabels.length);
      });

      test('floor asset paths are unique within building', () {
        final floors = IndoorFloorConfig.floorsForBuilding('HALL');

        final paths = floors.map((f) => f.assetPath).toList();
        final uniquePaths = paths.toSet();

        expect(paths.length, uniquePaths.length);
      });

      test('all supported buildings return at least one floor', () {
        final supportedBuildings = ['HALL', 'MB', 'VE', 'VL', 'CC'];

        for (final buildingCode in supportedBuildings) {
          final floors = IndoorFloorConfig.floorsForBuilding(buildingCode);
          expect(
            floors.isNotEmpty,
            true,
            reason: '$buildingCode should have at least one floor',
          );
        }
      });
    });

    group('IndoorFloorOption', () {
      test('can be created with label and assetPath', () {
        final option = IndoorFloorOption(
          label: 'Floor 1',
          assetPath: 'assets/indoor_maps/geojson/HALL/h1.geojson.json',
        );

        expect(option.label, 'Floor 1');
        expect(
          option.assetPath,
          'assets/indoor_maps/geojson/HALL/h1.geojson.json',
        );
      });

      test('stores label correctly', () {
        final option = IndoorFloorOption(
          label: 'Test Floor',
          assetPath: 'test/path.json',
        );

        expect(option.label, 'Test Floor');
      });

      test('stores assetPath correctly', () {
        final option = IndoorFloorOption(
          label: 'Test',
          assetPath: 'assets/test/file.geojson.json',
        );

        expect(option.assetPath, 'assets/test/file.geojson.json');
      });
    });
  });
}
