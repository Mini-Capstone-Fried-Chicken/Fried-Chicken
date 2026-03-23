import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_places_controller.dart';
import 'package:campus_app/shared/widgets/building_info_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_app/services/nearby_poi_service.dart';

void main() {
  group('BuildingInfoPopup Widget Tests', () {
    late bool closePressed;
    late bool morePressed;

    setUp(() {
      closePressed = false;
      morePressed = false;
      SharedPreferences.setMockInitialValues({});
      SavedPlacesController.debugSetUserIdResolver(() => null);
      SavedPlacesController.notifier.value = const <SavedPlace>[];
    });

    tearDown(() {
      SavedPlacesController.debugResetUserIdResolver();
      SavedPlacesController.notifier.value = const <SavedPlace>[];
    });

    Widget createPopupUnderTest({
      required bool isLoggedIn,
      SavedPlace? savedPlace,
      PoiCategory? poiCategory,
      List<String> facilities = const [],
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BuildingInfoPopup(
            title: 'Test Building',
            description: 'This is a test building description.',
            onClose: () {
              closePressed = true;
            },
            onMore: () {
              morePressed = true;
            },
            isLoggedIn: isLoggedIn,
            onGetDirections: () {},
            savedPlace: savedPlace,
            poiCategory: poiCategory,
            facilities: facilities,
          ),
        ),
      );
    }

    Widget createBuildingWithPopup({required bool isLoggedIn}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  key: const Key('buildingButton'),
                  child: const Text('Test Building Button'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => BuildingInfoPopup(
                        title: 'Test Building',
                        description: 'This is a test building description.',
                        onClose: () {
                          closePressed = true;
                          Navigator.of(context).pop();
                        },
                        onMore: () {
                          morePressed = true;
                        },
                        isLoggedIn: isLoggedIn,
                        onGetDirections: () {},
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders title and description', (WidgetTester tester) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      expect(find.text('Test Building'), findsOneWidget);
      expect(find.text('This is a test building description.'), findsOneWidget);
    });

    testWidgets('renders core controls (close + More + action icons)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      expect(find.widgetWithIcon(IconButton, Icons.directions), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.map), findsOneWidget);
    });

    testWidgets('save button is hidden when logged out', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: false));

      expect(find.byIcon(Icons.bookmark_border), findsNothing);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('save button is visible when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('tapping save toggles to unsave', (WidgetTester tester) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pump();

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('close button stays right aligned without facility icons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      final saveRect = tester.getRect(find.byIcon(Icons.bookmark_border));
      final closeRect = tester.getRect(find.byIcon(Icons.close));

      expect(closeRect.left, greaterThan(saveRect.right + 120));
    });

    testWidgets('recognizes saved place alias with places/ prefix', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'saved_places__anonymous':
            '[{"id":"abc123","name":"Cafe","category":"cafe","latitude":45.5,"longitude":-73.5,"openingHoursToday":"Open today: Hours unavailable"}]',
      });

      const savedPlace = SavedPlace(
        id: 'places/abc123',
        name: 'Cafe',
        category: 'cafe',
        latitude: 45.5,
        longitude: -73.5,
        openingHoursToday: 'Open today: Hours unavailable',
      );

      await tester.pumpWidget(
        createPopupUnderTest(isLoggedIn: true, savedPlace: savedPlace),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('unsave removes all id aliases', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'saved_places__anonymous':
            '[{"id":"abc123","name":"Cafe","category":"cafe","latitude":45.5,"longitude":-73.5,"openingHoursToday":"Open today: Hours unavailable"},{"id":"places/abc123","name":"Cafe","category":"cafe","latitude":45.5,"longitude":-73.5,"openingHoursToday":"Open today: Hours unavailable"}]',
      });

      const savedPlace = SavedPlace(
        id: 'places/abc123',
        name: 'Cafe',
        category: 'cafe',
        latitude: 45.5,
        longitude: -73.5,
        openingHoursToday: 'Open today: Hours unavailable',
      );

      await tester.pumpWidget(
        createPopupUnderTest(isLoggedIn: true, savedPlace: savedPlace),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark), findsOneWidget);

      await tester.tap(find.byKey(const Key('save_toggle_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(SavedPlacesController.isSaved('abc123'), isFalse);
      expect(SavedPlacesController.isSaved('places/abc123'), isFalse);
    });

    testWidgets('close button triggers onClose callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closePressed, isTrue);
    });

    testWidgets('More button triggers onMore callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      await tester.tap(find.text('More'));
      await tester.pump();

      expect(morePressed, isTrue);
    });

    testWidgets('other icon buttons can be tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPopupUnderTest(isLoggedIn: true));

      await tester.tap(find.widgetWithIcon(IconButton, Icons.directions));
      await tester.pump();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.map));
      await tester.pump();
    });

    testWidgets('clicking a building opens popup with correct info', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createBuildingWithPopup(isLoggedIn: true));

      await tester.tap(find.byKey(const Key('buildingButton')));
      await tester.pumpAndSettle();

      expect(find.text('Test Building'), findsOneWidget);
      expect(find.text('This is a test building description.'), findsOneWidget);

      expect(find.widgetWithIcon(IconButton, Icons.directions), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('popup can be closed after opening from building tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createBuildingWithPopup(isLoggedIn: true));

      await tester.tap(find.byKey(const Key('buildingButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Test Building'), findsNothing);
      expect(closePressed, isTrue);
    });

    testWidgets('More button works when popup opened from building tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createBuildingWithPopup(isLoggedIn: true));

      await tester.tap(find.byKey(const Key('buildingButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('More'));
      await tester.pump();

      expect(morePressed, isTrue);
    });

    testWidgets('shows top icons for accessibility and facilities', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingInfoPopup(
              title: 'Test Building',
              description: 'desc',
              onClose: () {},
              onMore: () {},
              isLoggedIn: true,
              onGetDirections: () {},
              accessibility: true,
              facilities: const [
                'Washrooms',
                'Coffee shop',
                'Restaurant',
                'Zen den',
                'Metro',
                'Parking',
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.accessible), findsOneWidget);
      expect(find.byIcon(Icons.wc), findsOneWidget);
      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      expect(find.byIcon(Icons.subway), findsOneWidget);
      expect(find.byIcon(Icons.local_parking), findsOneWidget);
    });

    testWidgets('facility matching is case-insensitive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingInfoPopup(
              title: 'T',
              description: 'D',
              onClose: () {},
              onMore: () {},
              isLoggedIn: false,
              onGetDirections: () {},
              facilities: const ['COFFEE SHOP'],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
    });

    testWidgets('facility matching supports typos like washroms', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingInfoPopup(
              title: 'T',
              description: 'D',
              onClose: () {},
              onMore: () {},
              isLoggedIn: false,
              onGetDirections: () {},
              facilities: const ['washroms near entrance'],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wc), findsOneWidget);
    });

    testWidgets('tapping a top icon shows label overlay then auto-hides', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingInfoPopup(
              title: 'T',
              description: 'D',
              onClose: () {},
              onMore: () {},
              isLoggedIn: false,
              onGetDirections: () {},
              facilities: const ['Coffee shop'],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.local_cafe));
      await tester.pump();

      expect(find.text('Coffee'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 950));
      expect(find.text('Coffee'), findsNothing);
    });

    testWidgets('label text is bold and has no underline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingInfoPopup(
              title: 'T',
              description: 'D',
              onClose: () {},
              onMore: () {},
              isLoggedIn: false,
              onGetDirections: () {},
              facilities: const ['Coffee shop'],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.local_cafe));
      await tester.pump();

      final text = tester.widget<Text>(find.text('Coffee'));
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.decoration, TextDecoration.none);
    });

    testWidgets('tapping another top icon replaces previous label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingInfoPopup(
              title: 'T',
              description: 'D',
              onClose: () {},
              onMore: () {},
              isLoggedIn: false,
              onGetDirections: () {},
              facilities: const ['Coffee shop', 'Washrooms'],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.local_cafe));
      await tester.pump();
      expect(find.text('Coffee'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.wc));
      await tester.pump();
      expect(find.text('Washrooms'), findsOneWidget);
      expect(find.text('Coffee'), findsNothing);
    });

    testWidgets('POI popup uses cafe icon from poiCategory', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createPopupUnderTest(isLoggedIn: false, poiCategory: PoiCategory.cafe),
      );

      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsNothing);
    });

    testWidgets('POI popup uses restaurant icon from poiCategory', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createPopupUnderTest(
          isLoggedIn: false,
          poiCategory: PoiCategory.restaurant,
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.local_cafe), findsNothing);
    });

    testWidgets(
      'POI popup ignores facility-based restaurant icon when category is cafe',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createPopupUnderTest(
            isLoggedIn: false,
            poiCategory: PoiCategory.cafe,
            facilities: const ['Restaurant', 'Food', 'Coffee shop'],
          ),
        );

        expect(find.byIcon(Icons.local_cafe), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsNothing);
      },
    );

    testWidgets('POI popup uses pharmacy icon from poiCategory', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createPopupUnderTest(
          isLoggedIn: false,
          poiCategory: PoiCategory.pharmacy,
        ),
      );

      expect(find.byIcon(Icons.local_pharmacy), findsOneWidget);
    });

    testWidgets('POI popup uses depanneur icon from poiCategory', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createPopupUnderTest(
          isLoggedIn: false,
          poiCategory: PoiCategory.depanneur,
        ),
      );

      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });

    testWidgets('non-POI popup still uses facility-based icons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createPopupUnderTest(
          isLoggedIn: false,
          facilities: const ['Coffee shop', 'Restaurant'],
        ),
      );

      expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });
  });
}
