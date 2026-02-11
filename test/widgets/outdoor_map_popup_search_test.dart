import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/shared/widgets/building_info_popup.dart';
import 'package:campus_app/shared/widgets/map_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String _readSearchText(WidgetTester tester) {
  final editable = find.descendant(
    of: find.byType(MapSearchBar),
    matching: find.byType(EditableText),
  );

  if (editable.evaluate().isNotEmpty) {
    final w = tester.widget<EditableText>(editable.first);
    return w.controller.text;
  }

  final tf = find.descendant(
    of: find.byType(MapSearchBar),
    matching: find.byType(TextField),
  );

  if (tf.evaluate().isNotEmpty) {
    final w = tester.widget<TextField>(tf.first);
    return w.controller?.text ?? '';
  }

  final tff = find.descendant(
    of: find.byType(MapSearchBar),
    matching: find.byType(TextFormField),
  );

  if (tff.evaluate().isNotEmpty) {
    final w = tester.widget<TextFormField>(tff.first);
    return w.controller?.text ?? '';
  }

  return '';
}

Positioned _popupPositioned(WidgetTester tester) {
  final positionedFinder = find.ancestor(
    of: find.byType(BuildingInfoPopup),
    matching: find.byType(Positioned),
  );
  return tester.widget<Positioned>(positionedFinder.first);
}

String readSearchHint(WidgetTester tester) {
  final tf = find.descendant(
    of: find.byType(MapSearchBar),
    matching: find.byType(TextField),
  );

  final w = tester.widget<TextField>(tf.first);
  final deco = w.decoration;
  return deco?.hintText ?? '';
}

Future<void> _moveCameraCenter(WidgetTester tester, LatLng target) async {
  final mapFinder = find.byType(GoogleMap);
  expect(mapFinder, findsOneWidget);

  final map = tester.widget<GoogleMap>(mapFinder);

  expect(map.onCameraMove, isNotNull);
  expect(map.onCameraIdle, isNotNull);

  map.onCameraMove!(
    CameraPosition(target: target, zoom: 15),
  );
  await tester.pump();

  map.onCameraIdle!();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final launchedCalls = <MethodCall>[];
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
      launchedCalls.add(call);
      return true;
    });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  setUp(() {
    launchedCalls.clear();
  });

  testWidgets('popup clamps to top-left (covers clamp branches)', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(top: 0),
        ),
        child: MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: true,
            debugDisableMap: true,
            debugDisableLocation: true,
            debugSelectedBuilding: BuildingPolygon(
              code: 'X',
              name: 'Test',
              points: const [
                LatLng(0, 0),
                LatLng(0, 1),
                LatLng(1, 0),
              ],
            ),
            debugAnchorOffset: const Offset(0, 0),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BuildingInfoPopup), findsOneWidget);

    final pos = _popupPositioned(tester);
    expect(pos.left, 8);
    expect(pos.top, 8);
  });

  testWidgets('popup clamps to bottom-right (covers max clamp)', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(top: 0),
        ),
        child: MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: true,
            debugDisableMap: true,
            debugDisableLocation: true,
            debugSelectedBuilding: BuildingPolygon(
              code: 'Y',
              name: 'Test',
              points: const [
                LatLng(0, 0),
                LatLng(1, 1),
                LatLng(2, 2),
              ],
            ),
            debugAnchorOffset: const Offset(399, 799),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final pos = _popupPositioned(tester);
    expect(pos.left, 92);
    expect(pos.top, 532);
  });

  testWidgets('popup does not show when anchor is out of view', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(top: 0),
        ),
        child: MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: true,
            debugDisableMap: true,
            debugDisableLocation: true,
            debugSelectedBuilding: BuildingPolygon(
              code: 'Z',
              name: 'Test',
              points: const [
                LatLng(0, 0),
                LatLng(0, 1),
                LatLng(1, 1),
              ],
            ),
            debugAnchorOffset: const Offset(401, 100),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(BuildingInfoPopup), findsNothing);
  });

  testWidgets('opening popup fills search bar, closing clears it', (tester) async {
    final b = buildingPolygons.first;

    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugSelectedBuilding: b,
          debugAnchorOffset: const Offset(200, 420),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BuildingInfoPopup), findsOneWidget);
    expect(_readSearchText(tester).isNotEmpty, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(BuildingInfoPopup), findsNothing);
    expect(_readSearchText(tester), '');
  });

  testWidgets('More button calls launcher when link is set', (tester) async {
    final b = buildingPolygons.first;

    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugSelectedBuilding: b,
          debugAnchorOffset: const Offset(200, 180),
          debugLinkOverride: 'https://example.com',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final moreBtn = find.widgetWithText(TextButton, 'More');
    expect(moreBtn, findsOneWidget);

    await tester.tap(moreBtn);
    await tester.pumpAndSettle();

    expect(launchedCalls.isNotEmpty, isTrue);
  });

  testWidgets('More button does nothing for empty link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugSelectedBuilding: BuildingPolygon(
            code: 'B',
            name: 'Test',
            points: const [
              LatLng(0, 0),
              LatLng(0, 1),
              LatLng(1, 1),
            ],
          ),
          debugAnchorOffset: const Offset(200, 180),
          debugLinkOverride: '',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final moreBtn = find.widgetWithText(TextButton, 'More');
    expect(moreBtn, findsOneWidget);

    await tester.tap(moreBtn);
    await tester.pumpAndSettle();

    expect(launchedCalls.isEmpty, isTrue);
  });

  testWidgets('search hint updates when campus toggle is tapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(readSearchHint(tester), 'Search Concordia SGW');

    await tester.tap(find.text('Loyola'));
    await tester.pumpAndSettle();

    expect(readSearchHint(tester), 'Search Concordia Loyola');

    await tester.tap(find.text('Sir George William'));
    await tester.pumpAndSettle();

    expect(readSearchHint(tester), 'Search Concordia SGW');
  });

  testWidgets('initialCampus none -> search hint is "Search"', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.none,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(readSearchHint(tester), 'Search');
  });

  testWidgets('switching campus clears popup + search text', (tester) async {
    final b = buildingPolygons.first;

    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugSelectedBuilding: b,
          debugAnchorOffset: const Offset(200, 180),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BuildingInfoPopup), findsOneWidget);
    expect(_readSearchText(tester).isNotEmpty, isTrue);

    await tester.tap(find.text('Loyola'));
    await tester.pumpAndSettle();

    expect(find.byType(BuildingInfoPopup), findsNothing);
    expect(_readSearchText(tester), '');
  });

  testWidgets('switching campus clears popup when going back to SGW', (tester) async {
    final b = buildingPolygons.first;

    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugSelectedBuilding: b,
          debugAnchorOffset: const Offset(200, 180),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BuildingInfoPopup), findsOneWidget);

    await tester.tap(find.text('Sir George William'));
    await tester.pumpAndSettle();

    expect(find.byType(BuildingInfoPopup), findsNothing);
    expect(_readSearchText(tester), '');
  });

  group('auto-switch campus from camera center', () {
    testWidgets('camera center in Loyola -> hint switches to Loyola', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: true,
            debugDisableLocation: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await _moveCameraCenter(tester, const LatLng(45.4582, -73.6405));
      expect(readSearchHint(tester), 'Search Concordia Loyola');
    });

    testWidgets('camera center in SGW -> hint switches back to SGW', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.loyola,
            isLoggedIn: true,
            debugDisableLocation: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await _moveCameraCenter(tester, const LatLng(45.4973, -73.5789));
      expect(readSearchHint(tester), 'Search Concordia SGW');
    });

    testWidgets('camera center far away -> hint switches to Search (Campus.none)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: true,
            debugDisableLocation: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await _moveCameraCenter(tester, const LatLng(0, 0));
      expect(readSearchHint(tester), 'Search');
    });
  });
}
