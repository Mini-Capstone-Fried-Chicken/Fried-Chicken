import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart';

void main() {
  group('IndoorFloorConfig', () {
    test('floorsForBuilding returns empty for unknown building', () {
      final floors = IndoorFloorConfig.floorsForBuilding('THIS_DOES_NOT_EXIST');
      expect(floors, isEmpty);
    });

    test('floorsForBuilding returns floors for at least one known building', () {
      // We try a small list of likely building codes (adjust/add if needed)
      const candidates = ['H', 'MB', 'EV', 'GM', 'LB', 'VL', 'CJ', 'SB', 'FB'];

      List<IndoorFloorOption> floors = const [];
      String? winner;

      for (final code in candidates) {
        final f = IndoorFloorConfig.floorsForBuilding(code);
        if (f.isNotEmpty) {
          floors = f;
          winner = code;
          break;
        }
      }

      expect(
        floors,
        isNotEmpty,
        reason:
            'None of the candidate building codes returned floors. '
            'Update candidates to match your IndoorFloorConfig keys.',
      );

      // basic sanity checks
      expect(winner, isNotNull);
      expect(floors.first.assetPath, isNotEmpty);
    });
  });
}