import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_directions_controller.dart';
import 'package:campus_app/features/saved/saved_places_controller.dart';
import 'package:campus_app/features/saved/ui/saved_screen.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

  Future<void> mockGeolocator({
    required bool serviceEnabled,
    required int permissionValue,
    Map<String, dynamic>? position,
  }) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, (MethodCall call) async {
          switch (call.method) {
            case 'isLocationServiceEnabled':
              return serviceEnabled;
            case 'checkPermission':
              return permissionValue;
            case 'requestPermission':
              return permissionValue;
            case 'getCurrentPosition':
              return position;
            default:
              return null;
          }
        });
  }

  Widget screenUnderTest() {
    return const MaterialApp(
      home: SavedScreen(isLoggedIn: true),
    );
  }

  Future<void> seedPlaces(List<SavedPlace> places) async {
    await SavedPlacesController.ensureInitialized();
    for (final place in places) {
      await SavedPlacesController.savePlace(place);
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SavedPlacesController.debugSetUserIdResolver(() => null);
    AppSettingsController.notifier.value = const AppSettingsState();
    SavedPlacesController.notifier.value = const <SavedPlace>[];
    SavedDirectionsController.clear();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, null);
    SavedPlacesController.debugResetUserIdResolver();
    SavedDirectionsController.clear();
  });

  testWidgets('renders single All dropdown option even when a place category is all', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    await seedPlaces(const <SavedPlace>[
      SavedPlace(
        id: 'p1',
        name: 'General Place',
        category: 'all',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    final allItems = find.text('All');
    expect(allItems, findsAtLeast(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows dynamic categories from saved list', (WidgetTester tester) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    await seedPlaces(const <SavedPlace>[
      SavedPlace(
        id: 'p1',
        name: 'Dinner Spot',
        category: 'restaurant',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Open today: 8:00 AM - 8:00 PM',
      ),
      SavedPlace(
        id: 'p2',
        name: 'MB Building',
        category: 'concordia building',
        latitude: 45.1,
        longitude: -73.1,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('Concordia Building'), findsOneWidget);
  });

  testWidgets('does not show removed current-location icon in header', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.my_location), findsNothing);
    expect(find.byTooltip('Refresh location'), findsNothing);
  });

  testWidgets('shows empty saved places message when list is empty', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No saved places yet. Save a place from the map.'), findsOneWidget);
  });

  testWidgets('shows no match message for selected filter', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: true,
      permissionValue: 3,
      position: {
        'latitude': 45.4973,
        'longitude': -73.5789,
        'accuracy': 10.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'heading': 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'floor': null,
        'is_mocked': false,
      },
    );

    await seedPlaces(const <SavedPlace>[
      SavedPlace(
        id: 'p1',
        name: 'Far Coffee Spot',
        category: 'cafe',
        latitude: 45.5300,
        longitude: -73.6200,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('No places match the selected radius/filter.'), findsOneWidget);
  });

  testWidgets('formats category label with underscores and hyphens', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    await seedPlaces(const <SavedPlace>[
      SavedPlace(
        id: 'p1',
        name: 'Sushi Place',
        category: 'japanese-restaurant',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Category: Japanese Restaurant'), findsOneWidget);
  });

  testWidgets('removes place when remove button is tapped', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    await SavedPlacesController.ensureInitialized();
    await SavedPlacesController.savePlace(
      const SavedPlace(
        id: 'p1',
        name: 'To Remove',
        category: 'cafe',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    );

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('To Remove'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_remove_outlined));
    await tester.pumpAndSettle();

    expect(find.text('To Remove'), findsNothing);
  });

  testWidgets('get directions button updates SavedDirectionsController', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    const place = SavedPlace(
      id: 'p1',
      name: 'Directions Place',
      category: 'cafe',
      latitude: 45.0,
      longitude: -73.0,
      openingHoursToday: 'Open today: Hours unavailable',
    );

    await seedPlaces(const <SavedPlace>[place]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get directions'));
    await tester.pump();

    expect(SavedDirectionsController.notifier.value?.id, 'p1');
  });

  testWidgets('shows computed distance labels when location is available', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: true,
      permissionValue: 3,
      position: {
        'latitude': 45.4973,
        'longitude': -73.5789,
        'accuracy': 10.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'heading': 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'floor': null,
        'is_mocked': false,
      },
    );

    await seedPlaces(const <SavedPlace>[
      SavedPlace(
        id: 'near',
        name: 'Near Place',
        category: 'cafe',
        latitude: 45.4975,
        longitude: -73.5790,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Distance: '), findsOneWidget);
    expect(find.textContaining('km away'), findsOneWidget);
  });

  testWidgets('sorts places by nearest distance first when location available', (
    WidgetTester tester,
  ) async {
    await mockGeolocator(
      serviceEnabled: true,
      permissionValue: 3,
      position: {
        'latitude': 45.4973,
        'longitude': -73.5789,
        'accuracy': 10.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'heading': 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'floor': null,
        'is_mocked': false,
      },
    );

    await seedPlaces(const <SavedPlace>[
      SavedPlace(
        id: 'far',
        name: 'Far Place',
        category: 'cafe',
        latitude: 45.5300,
        longitude: -73.6200,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
      SavedPlace(
        id: 'near',
        name: 'Near Place',
        category: 'cafe',
        latitude: 45.4975,
        longitude: -73.5790,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    final nearTop = tester.getTopLeft(find.text('Near Place')).dy;
    final farTop = tester.getTopLeft(find.text('Far Place')).dy;
    expect(nearTop, lessThan(farTop));
  });

  testWidgets('radius slider updates label', (WidgetTester tester) async {
    await mockGeolocator(
      serviceEnabled: false,
      permissionValue: 0,
      position: null,
    );

    await seedPlaces(const <SavedPlace>[
      SavedPlace(
        id: 'p1',
        name: 'Any Place',
        category: 'cafe',
        latitude: 45.0,
        longitude: -73.0,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    ]);

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Search by radius: All'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Search by radius: 1 km'), findsOneWidget);
  });
}
