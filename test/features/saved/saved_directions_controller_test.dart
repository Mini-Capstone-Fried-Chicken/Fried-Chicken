import 'package:campus_app/features/saved/saved_directions_controller.dart';
import 'package:campus_app/features/saved/saved_place.dart';
import 'package:flutter_test/flutter_test.dart';

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
        // Most datasets include "H" for Hall building; we use case-insensitive match.
        SavedDirectionsController.requestDirectionsToBuildingCode('h');

        final value = SavedDirectionsController.notifier.value;
        expect(value, isNotNull);
        expect(value!.id.toUpperCase(), 'H');
        expect(value.latitude, isNot(0));
        expect(value.longitude, isNot(0));
        expect(value.name.isNotEmpty, isTrue);
      },
    );
  });
}
