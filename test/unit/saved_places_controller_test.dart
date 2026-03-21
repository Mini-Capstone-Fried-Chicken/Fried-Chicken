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

    test('ensureInitialized falls back to anonymous scope for empty user id', () async {
      SavedPlacesController.debugSetUserIdResolver(() => '');

      await SavedPlacesController.ensureInitialized();
      await SavedPlacesController.savePlace(placeA);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('saved_places__anonymous'), isNotNull);
    });

    test('ensureInitialized loads only JSON map entries from storage', () async {
      SharedPreferences.setMockInitialValues({
        'saved_places__anonymous': '''
[
  {
    "id": "a",
    "name": "Hall Building",
    "category": "concordia building",
    "latitude": 45.497,
    "longitude": -73.579,
    "openingHoursToday": "Open today: 8:00 AM - 10:00 PM"
  },
  "bad-entry",
  123,
  {
    "id": "c",
    "name": "Library",
    "category": "concordia building",
    "latitude": 45.49,
    "longitude": -73.58,
    "openingHoursToday": "Open today: 8:00 AM - 10:00 PM"
  }
]
''',
      });

      await SavedPlacesController.ensureInitialized();

      expect(SavedPlacesController.notifier.value.length, 2);
      expect(SavedPlacesController.isSaved('a'), isTrue);
      expect(SavedPlacesController.isSaved('c'), isTrue);
    });

    test('ensureInitialized clears list when stored JSON is invalid', () async {
      SharedPreferences.setMockInitialValues({
        'saved_places__anonymous': '{not-valid-json',
      });

      await SavedPlacesController.ensureInitialized();

      expect(SavedPlacesController.notifier.value, isEmpty);
    });

    test('ensureInitialized is a no-op when already initialized for scope', () async {
      SavedPlacesController.debugSetUserIdResolver(() => 'user-same');

      await SavedPlacesController.ensureInitialized();
      SavedPlacesController.notifier.value = const <SavedPlace>[placeA];

      await SavedPlacesController.ensureInitialized();

      expect(SavedPlacesController.notifier.value.length, 1);
      expect(SavedPlacesController.notifier.value.first.id, 'a');
    });

    test('savePlace updates existing place with same id', () async {
      await SavedPlacesController.ensureInitialized();
      await SavedPlacesController.savePlace(placeA);

      const updated = SavedPlace(
        id: 'a',
        name: 'Hall Building Updated',
        category: 'concordia building',
        latitude: 45.5,
        longitude: -73.57,
        openingHoursToday: 'Open today: 7:00 AM - 11:00 PM',
      );
      await SavedPlacesController.savePlace(updated);

      expect(SavedPlacesController.notifier.value.length, 1);
      expect(SavedPlacesController.notifier.value.first.name, 'Hall Building Updated');
    });

    test('removePlace removes item and persists updated list', () async {
      await SavedPlacesController.ensureInitialized();
      await SavedPlacesController.savePlace(placeA);
      await SavedPlacesController.savePlace(placeB);

      await SavedPlacesController.removePlace('a');

      expect(SavedPlacesController.isSaved('a'), isFalse);
      expect(SavedPlacesController.isSaved('b'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_places__anonymous')!;
      expect(raw.contains('"id":"a"'), isFalse);
      expect(raw.contains('"id":"b"'), isTrue);
    });

    test('togglePlace adds then removes and returns state transitions', () async {
      await SavedPlacesController.ensureInitialized();

      final added = await SavedPlacesController.togglePlace(placeA);
      final removed = await SavedPlacesController.togglePlace(placeA);

      expect(added, isTrue);
      expect(removed, isFalse);
      expect(SavedPlacesController.isSaved('a'), isFalse);
    });
  });
}
