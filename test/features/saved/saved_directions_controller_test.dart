import 'package:campus_app/features/saved/saved_directions_controller.dart';
import 'package:campus_app/features/saved/saved_place.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/data/building_polygons.dart';

void main() {
  group('SavedDirectionsController', () {
    tearDown(() {
      // Ensure we don't leak notifier values between tests.
      SavedDirectionsController.clear();
    });

    test('requestDirections sets notifier value', () {
      final place = SavedPlace(
        id: 'H',
        name: 'Hall Building',
        category: 'all',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Hours unavailable today',
      );

      SavedDirectionsController.requestDirections(place);

      expect(SavedDirectionsController.notifier.value, isNotNull);
      expect(SavedDirectionsController.notifier.value!.id, 'H');
      expect(SavedDirectionsController.notifier.value!.latitude, 45.0);
    });

    test('clear resets notifier value to null', () {
      SavedDirectionsController.requestDirections(
        const SavedPlace(
          id: 'X',
          name: 'Some Place',
          category: 'all',
          latitude: 1,
          longitude: 2,
          openingHoursToday: 'Hours unavailable today',
        ),
      );

      expect(SavedDirectionsController.notifier.value, isNotNull);

      SavedDirectionsController.clear();

      expect(SavedDirectionsController.notifier.value, isNull);
    });

    test('requestDirectionsToBuildingCode ignores empty/whitespace input', () {
      SavedDirectionsController.requestDirectionsToBuildingCode('   ');
      expect(SavedDirectionsController.notifier.value, isNull);
    });

    test('requestDirectionsToBuildingCode ignores unknown building code', () {
      SavedDirectionsController.requestDirectionsToBuildingCode(
        'THIS_DOES_NOT_EXIST',
      );
      expect(SavedDirectionsController.notifier.value, isNull);
    });

    test(
      'requestDirectionsToBuildingCode is case-insensitive and emits SavedPlace',
      () {
        // Pick a building code that definitely exists in the dataset available
        // in CI, avoiding assumptions like "H" always being present.
        expect(buildingPolygons, isNotEmpty);

        final existing = buildingPolygons.first;
        final codeLower = existing.code.toLowerCase();

        SavedDirectionsController.requestDirectionsToBuildingCode(codeLower);

        final value = SavedDirectionsController.notifier.value;
        expect(value, isNotNull);
        expect(value!.id.toUpperCase(), existing.code.toUpperCase());
        expect(value.latitude, existing.center.latitude);
        expect(value.longitude, existing.center.longitude);
        expect(value.name.isNotEmpty, isTrue);
      },
    );
  });
}
