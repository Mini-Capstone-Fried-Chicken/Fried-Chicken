import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_places_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SavedPlacesController', () {
    const placeA = SavedPlace(
      id: 'a',
      name: 'Hall Building',
      category: 'concordia building',
      latitude: 45.497,
      longitude: -73.579,
      openingHoursToday: 'Open today: 8:00 AM - 10:00 PM',
    );

    const placeB = SavedPlace(
      id: 'b',
      name: 'Loyola Campus',
      category: 'concordia building',
      latitude: 45.458,
      longitude: -73.641,
      openingHoursToday: 'Open today: 8:00 AM - 10:00 PM',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SavedPlacesController.debugSetUserIdResolver(() => null);
      SavedPlacesController.notifier.value = const <SavedPlace>[];
    });

    tearDown(() {
      SavedPlacesController.debugResetUserIdResolver();
      SavedPlacesController.notifier.value = const <SavedPlace>[];
    });

    test('loads and persists places in anonymous scope', () async {
      await SavedPlacesController.ensureInitialized();
      await SavedPlacesController.savePlace(placeA);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('saved_places__anonymous'), isNotNull);
      expect(SavedPlacesController.isSaved('a'), isTrue);
    });

    test('saved places are isolated between accounts', () async {
      SavedPlacesController.debugSetUserIdResolver(() => 'user-a');
      await SavedPlacesController.reloadForCurrentUser();
      await SavedPlacesController.savePlace(placeA);

      SavedPlacesController.debugSetUserIdResolver(() => 'user-b');
      await SavedPlacesController.reloadForCurrentUser();
      expect(SavedPlacesController.notifier.value, isEmpty);
      await SavedPlacesController.savePlace(placeB);
      expect(SavedPlacesController.isSaved('b'), isTrue);
      expect(SavedPlacesController.isSaved('a'), isFalse);

      SavedPlacesController.debugSetUserIdResolver(() => 'user-a');
      await SavedPlacesController.reloadForCurrentUser();
      expect(SavedPlacesController.isSaved('a'), isTrue);
      expect(SavedPlacesController.isSaved('b'), isFalse);
    });
  });
}
