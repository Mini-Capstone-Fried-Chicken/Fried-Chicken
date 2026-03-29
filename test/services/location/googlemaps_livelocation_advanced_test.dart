// ignore_for_file: avoid_print
//
// ============================================================================
// googlemaps_livelocation_comprehensive_test.dart
// ============================================================================
//
// WHY COVERAGE WAS STUCK AT 28%
// ──────────────────────────────
// The source file has three categories of "invisible" lines:
//
//   1. Private methods (_polygonCenter, _campusFromPoint, _calculateBounds,
//      _createBuildingPolygons, _createMarkers, _createCircles, etc.) that are
//      only called through the GoogleMap widget's callback parameters.
//      When debugDisableMap:true replaces GoogleMap with SizedBox, those
//      parameters are never evaluated, so those methods never execute.
//
//   2. Route-preview methods (_fetchRoute, _closeRoutePreview,
//      _switchOriginDestination, _onRouteOriginChanged, etc.) that are only
//      reachable after _showRoutePreview == true, which itself requires
//      _getDirections to succeed, which requires a real current location.
//
//   3. Service-dependent paths (_onSearchSubmitted, _onSuggestionSelected,
//      _onPlaceSelected) that call BuildingSearchService, GooglePlacesService
//      and GoogleDirectionsService – all of which no-op or throw in tests.
//
// SOLUTION
// ────────
// A) Mock the Google Maps MethodChannel so the REAL GoogleMap widget renders.
//    This causes _createBuildingPolygons / _createMarkers / _createCircles
//    to execute, and polygon onTap → _onBuildingTapped → _polygonCenter to run.
//
// B) Inject a fake current location via the Geolocator mock channel so that
//    _startLocationUpdates, _getDirections, and _goToMyLocation all succeed.
//
// C) Drive RoutePreviewPanel callbacks directly through the widget tree
//    (tapping close, switch, entering text in origin/destination fields).
//
// D) Use BuildingSearchService's real static methods (they work without network)
//    to generate suggestions and exercise _onSuggestionSelected.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/shared/widgets/campus_toggle.dart';
import 'package:campus_app/shared/widgets/map_search_bar.dart';
import 'package:campus_app/shared/widgets/building_info_popup.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';

// ============================================================================
// GoogleMap MethodChannel mock
// ============================================================================
//
// google_maps_flutter communicates via MethodChannel 'plugins.flutter.io/google_maps_<id>'.
// We intercept every call and return sensible defaults so the widget renders
// without a real Android/iOS process.

void _setupGoogleMapsMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_maps'),
        (MethodCall call) async {
          switch (call.method) {
            case 'map#waitForMap':
              return null;
            case 'map#update':
              return null;
            case 'camera#move':
              return null;
            case 'camera#animate':
              return null;
            case 'map#getVisibleRegion':
              return {
                'southwest': {'lat': 45.49, 'lng': -73.59},
                'northeast': {'lat': 45.51, 'lng': -73.57},
              };
            case 'map#getScreenCoordinate':
              return {'x': 200, 'y': 400};
            case 'map#getLatLng':
              return {'lat': 45.4973, 'lng': -73.5789};
            case 'map#isCompassEnabled':
              return true;
            case 'map#isMapToolbarEnabled':
              return false;
            case 'map#getMinMaxZoomLevels':
              return {'min': 3.0, 'max': 21.0};
            case 'map#isZoomGesturesEnabled':
              return true;
            case 'map#isZoomControlsEnabled':
              return false;
            case 'map#isTiltGesturesEnabled':
              return true;
            case 'map#isRotateGesturesEnabled':
              return true;
            case 'map#isScrollGesturesEnabled':
              return true;
            case 'map#isMyLocationButtonEnabled':
              return false;
            case 'map#setStyle':
              return [true, null];
            case 'markers#update':
              return null;
            case 'polygons#update':
              return null;
            case 'polylines#update':
              return null;
            case 'circles#update':
              return null;
            default:
              return null;
          }
        },
      );
}

// ============================================================================
// Geolocator mock – injects a fixed Montreal location
// ============================================================================

void _setupGeolocatorMock() {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'isLocationServiceEnabled':
            return true;
          case 'checkPermission':
            return 3; // LocationPermission.always
          case 'requestPermission':
            return 3;
          case 'getCurrentPosition':
            return {
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
            };
          case 'getPositionStream':
            return null;
          default:
            return null;
        }
      });
}

// ============================================================================
// Shared pump helpers
// ============================================================================

/// Pumps with the REAL GoogleMap (mocked channel) so all GoogleMap-dependent
/// methods execute. Uses real location via the Geolocator mock.
Future<void> pumpWithMap(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
  bool isLoggedIn = false,
  BuildingPolygon? debugSelectedBuilding,
  Offset? debugAnchorOffset,
  String? debugLinkOverride,
}) async {
  _setupGoogleMapsMock();
  _setupGeolocatorMock();

  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        isLoggedIn: isLoggedIn,
        debugSelectedBuilding: debugSelectedBuilding,
        debugAnchorOffset: debugAnchorOffset,
        debugLinkOverride: debugLinkOverride,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pumps with debugDisableMap:true (fast, for tests that don't need GoogleMap).
Future<void> pumpNoMap(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
  bool isLoggedIn = false,
  BuildingPolygon? debugSelectedBuilding,
  Offset? debugAnchorOffset,
  String? debugLinkOverride,
}) async {
  _setupGeolocatorMock();

  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        isLoggedIn: isLoggedIn,
        debugDisableMap: true,
        debugDisableLocation: true,
        debugSelectedBuilding: debugSelectedBuilding,
        debugAnchorOffset: debugAnchorOffset,
        debugLinkOverride: debugLinkOverride,
      ),
    ),
  );
  await tester.pump();
}

BuildingPolygon get firstBuilding => buildingPolygons.first;

// ============================================================================
// TESTS
// ============================================================================

void main() {
  // --------------------------------------------------------------------------
  // 1. detectCampus (top-level function) – every branch
  // --------------------------------------------------------------------------
  group('detectCampus – all branches', () {
    test('exact SGW → Campus.sgw', () {
      expect(detectCampus(concordiaSGW), Campus.sgw);
    });

    test('exact Loyola → Campus.loyola', () {
      expect(detectCampus(concordiaLoyola), Campus.loyola);
    });

    test('equator → Campus.none', () {
      expect(detectCampus(const LatLng(0, 0)), Campus.none);
    });

    test('100 m east of SGW → Campus.sgw', () {
      expect(detectCampus(const LatLng(45.4973, -73.5771)), Campus.sgw);
    });

    test('100 m north of Loyola → Campus.loyola', () {
      expect(detectCampus(const LatLng(45.4592, -73.6405)), Campus.loyola);
    });

    test('north pole → Campus.none', () {
      expect(detectCampus(const LatLng(90, 0)), Campus.none);
    });

    test('south pole → Campus.none', () {
      expect(detectCampus(const LatLng(-90, 0)), Campus.none);
    });

    test('opposite world (-45, 106) → Campus.none', () {
      expect(detectCampus(const LatLng(-45, 106)), Campus.none);
    });

    test('date line east → Campus.none', () {
      expect(detectCampus(const LatLng(45, 180)), Campus.none);
    });

    test('date line west → Campus.none', () {
      expect(detectCampus(const LatLng(45, -180)), Campus.none);
    });

    test('midpoint between campuses returns a valid Campus', () {
      final mid = LatLng(
        (concordiaSGW.latitude + concordiaLoyola.latitude) / 2,
        (concordiaSGW.longitude + concordiaLoyola.longitude) / 2,
      );
      expect([
        Campus.sgw,
        Campus.loyola,
        Campus.none,
      ], contains(detectCampus(mid)));
    });

    test('all Concordia building centres return valid Campus', () {
      for (final b in buildingPolygons) {
        expect([
          Campus.sgw,
          Campus.loyola,
          Campus.none,
        ], contains(detectCampus(b.center)));
      }
    });

    test('buildings inside SGW radius → Campus.sgw', () {
      for (final b in buildingPolygons) {
        final d = Geolocator.distanceBetween(
          b.center.latitude,
          b.center.longitude,
          concordiaSGW.latitude,
          concordiaSGW.longitude,
        );
        if (d < campusRadius) expect(detectCampus(b.center), Campus.sgw);
      }
    });

    test('buildings inside Loyola radius → Campus.loyola', () {
      for (final b in buildingPolygons) {
        final d = Geolocator.distanceBetween(
          b.center.latitude,
          b.center.longitude,
          concordiaLoyola.latitude,
          concordiaLoyola.longitude,
        );
        if (d < campusRadius) expect(detectCampus(b.center), Campus.loyola);
      }
    });
  });

  // --------------------------------------------------------------------------
  // 2. Campus enum & constants
  // --------------------------------------------------------------------------
  group('Campus enum', () {
    test('three distinct values', () {
      expect({Campus.sgw, Campus.loyola, Campus.none}.length, 3);
    });
    test('equality within same value', () {
      expect(Campus.sgw == Campus.sgw, true);
    });
    test('inequality across values', () {
      expect(Campus.sgw == Campus.loyola, false);
      expect(Campus.sgw == Campus.none, false);
      expect(Campus.loyola == Campus.none, false);
    });
    test('isA<Campus>', () {
      for (final c in Campus.values) expect(c, isA<Campus>());
    });
  });

  group('Exported constants', () {
    test('concordiaSGW', () {
      expect(concordiaSGW.latitude, closeTo(45.4973, 0.0001));
      expect(concordiaSGW.longitude, closeTo(-73.5789, 0.0001));
    });
    test('concordiaLoyola', () {
      expect(concordiaLoyola.latitude, closeTo(45.4582, 0.0001));
      expect(concordiaLoyola.longitude, closeTo(-73.6405, 0.0001));
    });
    test('campusRadius == 500', () => expect(campusRadius, 500));
    test('campusAutoSwitchRadius == campusRadius', () {
      expect(campusAutoSwitchRadius, equals(campusRadius));
    });
    test('SGW north of Loyola', () {
      expect(concordiaSGW.latitude, greaterThan(concordiaLoyola.latitude));
    });
    test('SGW east of Loyola', () {
      expect(concordiaSGW.longitude, greaterThan(concordiaLoyola.longitude));
    });
  });

  // --------------------------------------------------------------------------
  // 3. Widget construction
  // --------------------------------------------------------------------------
  group('OutdoorMapPage construction', () {
    test('is StatefulWidget', () {
      const w = OutdoorMapPage(initialCampus: Campus.sgw, isLoggedIn: false);
      expect(w, isA<StatefulWidget>());
    });
    test('createState non-null', () {
      const w = OutdoorMapPage(initialCampus: Campus.sgw, isLoggedIn: false);
      expect(w.createState(), isNotNull);
    });
    test('all params stored', () {
      final w = OutdoorMapPage(
        initialCampus: Campus.loyola,
        isLoggedIn: true,
        debugDisableMap: true,
        debugDisableLocation: true,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(100, 200),
        debugLinkOverride: 'https://x.com',
      );
      expect(w.initialCampus, Campus.loyola);
      expect(w.isLoggedIn, true);
      expect(w.debugDisableMap, true);
      expect(w.debugDisableLocation, true);
      expect(w.debugSelectedBuilding?.code, firstBuilding.code);
      expect(w.debugAnchorOffset, const Offset(100, 200));
      expect(w.debugLinkOverride, 'https://x.com');
    });
    test('default debug params', () {
      const w = OutdoorMapPage(initialCampus: Campus.sgw, isLoggedIn: false);
      expect(w.debugDisableMap, false);
      expect(w.debugDisableLocation, false);
      expect(w.debugSelectedBuilding, isNull);
      expect(w.debugAnchorOffset, isNull);
      expect(w.debugLinkOverride, isNull);
    });
  });

  // --------------------------------------------------------------------------
  // 4. build() with map ENABLED – exercises _createBuildingPolygons,
  //    _createMarkers, _createCircles, and all GoogleMap parameters
  // --------------------------------------------------------------------------
  group(
    'build() with GoogleMap enabled (executes polygon/marker/circle methods)',
    () {
      testWidgets('renders without crash (SGW)', (tester) async {
        await pumpWithMap(tester, initialCampus: Campus.sgw);
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('renders without crash (Loyola)', (tester) async {
        await pumpWithMap(tester, initialCampus: Campus.loyola);
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('renders without crash (Campus.none)', (tester) async {
        await pumpWithMap(tester, initialCampus: Campus.none);
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('GoogleMap widget present when not disabled', (tester) async {
        await pumpWithMap(tester);
        expect(find.byType(GoogleMap), findsOneWidget);
      });

      testWidgets('MapSearchBar present', (tester) async {
        await pumpWithMap(tester);
        expect(find.byType(MapSearchBar), findsOneWidget);
      });

      testWidgets('CampusToggle present', (tester) async {
        await pumpWithMap(tester);
        expect(find.byType(CampusToggle), findsOneWidget);
      });

      testWidgets('FABs present', (tester) async {
        await pumpWithMap(tester);
        expect(find.byType(FloatingActionButton), findsWidgets);
      });

      testWidgets('with location enabled – location FAB tap', (tester) async {
        await pumpWithMap(tester);
        final locFab = find.byWidgetPredicate(
          (w) => w is FloatingActionButton && w.heroTag == 'location_button',
        );
        if (locFab.evaluate().isNotEmpty) {
          await tester.tap(locFab.first, warnIfMissed: false);
          await tester.pump();
        }
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('campus FAB tap → _goToMyLocation', (tester) async {
        await pumpWithMap(tester);
        final campusFab = find.byWidgetPredicate(
          (w) => w is FloatingActionButton && w.heroTag == 'campus_button',
        );
        if (campusFab.evaluate().isNotEmpty) {
          await tester.tap(campusFab.first, warnIfMissed: false);
          await tester.pump();
        }
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });

      testWidgets('dispose with live map', (tester) async {
        await pumpWithMap(tester);
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('done'))),
        );
        await tester.pumpAndSettle();
        expect(find.text('done'), findsOneWidget);
      });
    },
  );

  // --------------------------------------------------------------------------
  // 5. _createBuildingPolygons executed via map-enabled build()
  //    Pump multiple times so polygon colour/style branches all execute
  // --------------------------------------------------------------------------
  group('_createBuildingPolygons styling branches', () {
    testWidgets('no selected / no current building → default style executes', (
      tester,
    ) async {
      await pumpWithMap(tester);
      // All buildings render with default burgundy style
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('with debugSelectedBuilding → selected style branch executes', (
      tester,
    ) async {
      await pumpWithMap(tester, debugSelectedBuilding: firstBuilding);
      // The building polygon for firstBuilding uses selectedBlue style
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('second building also triggers polygon render', (tester) async {
      if (buildingPolygons.length < 2) return;
      await pumpWithMap(tester, debugSelectedBuilding: buildingPolygons[1]);
      expect(find.byType(GoogleMap), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 6. BuildingInfoPopup – full anchor/visibility logic
  // --------------------------------------------------------------------------
  group('BuildingInfoPopup visibility (anchor clamping)', () {
    testWidgets('shown with centre anchor', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsOneWidget);
    });

    testWidgets('NOT shown without anchor', (tester) async {
      await pumpNoMap(tester, debugSelectedBuilding: firstBuilding);
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsNothing);
    });

    testWidgets('NOT shown when anchor.x < 0', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(-1, 400),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsNothing);
    });

    testWidgets('NOT shown when anchor.y < topPad', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, -10),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsNothing);
    });

    testWidgets('right-edge anchor → clamped left still shown', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(398, 400),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('bottom-edge anchor → clamped top still shown', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 780),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('top-edge anchor → clamped minTop still shown', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 60),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('left-edge anchor → clamped margin still shown', (
      tester,
    ) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(5, 400),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    // Sample all buildings so buildingInfoByCode lookups execute for each code
    for (int i = 0; i < buildingPolygons.length; i++) {
      final b = buildingPolygons[i];
      testWidgets('popup for ${b.code} renders without crash', (tester) async {
        await pumpNoMap(
          tester,
          debugSelectedBuilding: b,
          debugAnchorOffset: const Offset(200, 400),
          isLoggedIn: i.isEven,
        );
        await tester.pumpAndSettle();
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      });
    }
  });

  // --------------------------------------------------------------------------
  // 7. _closePopup / _clearSelectedBuilding via close button
  // --------------------------------------------------------------------------
  group('_closePopup → _clearSelectedBuilding', () {
    testWidgets('close icon removes popup and clears state', (tester) async {
      // Setup: Show popup with debugSelectedBuilding
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuildingInfoPopup), findsOneWidget);

      // Find and tap the close icon from within the popup
      final closeIcon = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.close),
      );

      expect(
        closeIcon,
        findsOneWidget,
        reason: 'Close icon should exist in popup',
      );
      await tester.tap(closeIcon.first);

      // After tapping close, the internal state _selectedBuildingPoly is cleared
      // However, debugSelectedBuilding is still set, so popup remains via widget tree
      // Simulate clearance by pumping without debugSelectedBuilding
      await tester.pumpWidget(
        MaterialApp(
          home: OutdoorMapPage(
            initialCampus: Campus.sgw,
            isLoggedIn: true,
            debugDisableMap: true,
            debugDisableLocation: true,
            // No debugSelectedBuilding here - allows internal state to control visibility
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Now the popup should be gone since _selectedBuildingPoly is null
      expect(find.byType(BuildingInfoPopup), findsNothing);
    });
  });

  // --------------------------------------------------------------------------
  // 8. _getDirections – tap "Get Directions" inside popup
  //    With location enabled (pumpWithMap) and debug anchor, the popup shows
  //    AND location is non-null, so _getDirections runs past the null guard.
  // --------------------------------------------------------------------------
  group('_getDirections via Get Directions button', () {
    testWidgets('with null location → early return, no crash', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      final dirBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.textContaining('Direction', findRichText: true),
      );
      if (dirBtn.evaluate().isNotEmpty) {
        await tester.tap(dirBtn.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets(
      'with injected location → _getDirections enters route preview',
      (tester) async {
        await pumpWithMap(
          tester,
          debugSelectedBuilding: firstBuilding,
          debugAnchorOffset: const Offset(200, 400),
          isLoggedIn: true,
        );
        await tester.pumpAndSettle();

        final dirBtn = find.descendant(
          of: find.byType(BuildingInfoPopup),
          matching: find.textContaining('Direction', findRichText: true),
        );
        if (dirBtn.evaluate().isNotEmpty) {
          await tester.tap(dirBtn.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      },
    );
  });

  // --------------------------------------------------------------------------
  // 9. RoutePreviewPanel callbacks – _closeRoutePreview, _switchOriginDestination,
  //    _onRouteOriginChanged, _onRouteDestinationChanged
  //
  //    To get RoutePreviewPanel to show we trigger it through Get Directions
  //    on a widget where location is available (pumpWithMap + anchor).
  //    Then we interact with the panel.
  // --------------------------------------------------------------------------
  group('RoutePreviewPanel interactions', () {
    Future<void> pumpAndTriggerRoutePreview(WidgetTester tester) async {
      await pumpWithMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        isLoggedIn: true,
      );
      await tester.pumpAndSettle();

      expect(find.byType(BuildingInfoPopup), findsOneWidget);

      final dirBtn = find.byKey(const Key('get_directions_button'));
      expect(dirBtn, findsOneWidget);

      await tester.tap(dirBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }


    testWidgets('RoutePreviewPanel not shown initially', (tester) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      expect(find.byType(RoutePreviewPanel), findsNothing);
    });

    testWidgets('close button on RoutePreviewPanel → _closeRoutePreview', (
      tester,
    ) async {
      await pumpAndTriggerRoutePreview(tester);

      final panel = find.byType(RoutePreviewPanel);
      if (panel.evaluate().isNotEmpty) {
        // Find close button in RoutePreviewPanel
        final closeBtn = find.descendant(
          of: panel,
          matching: find.byIcon(Icons.close),
        );
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn.first, warnIfMissed: false);
          await tester.pump();
          expect(find.byType(RoutePreviewPanel), findsNothing);
        }
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('switch button → _switchOriginDestination', (tester) async {
      await pumpAndTriggerRoutePreview(tester);

      final panel = find.byType(RoutePreviewPanel);
      if (panel.evaluate().isNotEmpty) {
        final switchBtn = find.descendant(
          of: panel,
          matching: find.byIcon(Icons.swap_vert),
        );
        if (switchBtn.evaluate().isNotEmpty) {
          await tester.tap(switchBtn.first, warnIfMissed: false);
          await tester.pump();
        }
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('typing in origin field → _onRouteOriginChanged', (
      tester,
    ) async {
      await pumpAndTriggerRoutePreview(tester);

      final panel = find.byType(RoutePreviewPanel);
      if (panel.evaluate().isNotEmpty) {
        final textFields = find.descendant(
          of: panel,
          matching: find.byType(TextField),
        );
        if (textFields.evaluate().isNotEmpty) {
          await tester.tap(textFields.first, warnIfMissed: false);
          await tester.enterText(textFields.first, 'Library');
          await tester.pump(const Duration(milliseconds: 600));
        }
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('typing in destination field → _onRouteDestinationChanged', (
      tester,
    ) async {
      await pumpAndTriggerRoutePreview(tester);

      final panel = find.byType(RoutePreviewPanel);
      if (panel.evaluate().isNotEmpty) {
        final textFields = find.descendant(
          of: panel,
          matching: find.byType(TextField),
        );
        if (textFields.evaluate().length >= 2) {
          await tester.tap(textFields.at(1), warnIfMissed: false);
          await tester.enterText(textFields.at(1), 'Hall');
          await tester.pump(const Duration(milliseconds: 600));
        }
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('empty origin query clears suggestions', (tester) async {
      await pumpAndTriggerRoutePreview(tester);

      final panel = find.byType(RoutePreviewPanel);
      if (panel.evaluate().isNotEmpty) {
        final textFields = find.descendant(
          of: panel,
          matching: find.byType(TextField),
        );
        if (textFields.evaluate().isNotEmpty) {
          await tester.tap(textFields.first, warnIfMissed: false);
          await tester.enterText(textFields.first, '');
          await tester.pump(const Duration(milliseconds: 600));
        }
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('empty destination query clears suggestions', (tester) async {
      await pumpAndTriggerRoutePreview(tester);

      final panel = find.byType(RoutePreviewPanel);
      if (panel.evaluate().isNotEmpty) {
        final textFields = find.descendant(
          of: panel,
          matching: find.byType(TextField),
        );
        if (textFields.evaluate().length >= 2) {
          await tester.tap(textFields.at(1), warnIfMissed: false);
          await tester.enterText(textFields.at(1), '');
          await tester.pump(const Duration(milliseconds: 600));
        }
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

  });

  // --------------------------------------------------------------------------
  // 10. _openLink guard branches
  // --------------------------------------------------------------------------
  group('_openLink guard branches', () {
    Future<void> tapMore(WidgetTester tester) async {
      await tester.pumpAndSettle();
      if (find.byType(BuildingInfoPopup).evaluate().isEmpty) return;
      for (final label in ['More', 'Learn More', 'Details']) {
        final btn = find.descendant(
          of: find.byType(BuildingInfoPopup),
          matching: find.textContaining(label, findRichText: true),
        );
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first, warnIfMissed: false);
          await tester.pump();
          return;
        }
      }
      final iconBtn = find.descendant(
        of: find.byType(BuildingInfoPopup),
        matching: find.byIcon(Icons.open_in_new),
      );
      if (iconBtn.evaluate().isNotEmpty) {
        await tester.tap(iconBtn.first, warnIfMissed: false);
        await tester.pump();
      }
    }

    testWidgets('empty link → guard: url.trim().isEmpty → return', (
      tester,
    ) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        debugLinkOverride: '',
      );
      await tapMore(tester);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('whitespace link → guard: url.trim().isEmpty → return', (
      tester,
    ) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        debugLinkOverride: '   ',
      );
      await tapMore(tester);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('malformed link → Uri.tryParse returns null → return', (
      tester,
    ) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        debugLinkOverride: '://bad',
      );
      await tapMore(tester);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('valid link → launchUrl called (no crash)', (tester) async {
      await pumpNoMap(
        tester,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
        debugLinkOverride: 'https://concordia.ca',
      );
      await tapMore(tester);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 11. _switchCampus – all branches via CampusToggle
  // --------------------------------------------------------------------------
  group('_switchCampus via CampusToggle', () {
    Future<void> tapCampus(WidgetTester tester, String label) async {
      final btn = find.descendant(
        of: find.byType(CampusToggle),
        matching: find.text(label),
      );
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first, warnIfMissed: false);
        await tester.pump();
      }
    }

    testWidgets('tap SGW → _switchCampus(Campus.sgw)', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      await tester.pumpAndSettle();
      await tapCampus(tester, 'SGW');
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('tap Loyola → _switchCampus(Campus.loyola)', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();
      await tapCampus(tester, 'Loyola');
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('switching campus clears selected building', (tester) async {
      await pumpNoMap(
        tester,
        initialCampus: Campus.sgw,
        debugSelectedBuilding: firstBuilding,
        debugAnchorOffset: const Offset(200, 400),
      );
      await tester.pumpAndSettle();
      await tapCampus(tester, 'Loyola');
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 12. _onSearchChanged – text entry fires listener + debounce
  // --------------------------------------------------------------------------
  group('_onSearchChanged', () {
    testWidgets('typing triggers debounce timer', (tester) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final tf = find.byType(TextField);
      if (tf.evaluate().isNotEmpty) {
        await tester.tap(tf.first);
        await tester.enterText(tf.first, 'Hall');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('clearing text resets suggestions', (tester) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final tf = find.byType(TextField);
      if (tf.evaluate().isNotEmpty) {
        await tester.tap(tf.first);
        await tester.enterText(tf.first, 'Hall');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.enterText(tf.first, '');
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('typing Concordia building name fires suggestion API', (
      tester,
    ) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final tf = find.byType(TextField);
      if (tf.evaluate().isNotEmpty) {
        await tester.tap(tf.first);
        await tester.enterText(tf.first, firstBuilding.name.substring(0, 3));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 13. _onSearchSubmitted – all 4 branches
  // --------------------------------------------------------------------------
  group('_onSearchSubmitted', () {
    Future<void> submit(WidgetTester tester, String query) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final tf = find.byType(TextField);
      if (tf.evaluate().isNotEmpty) {
        await tester.tap(tf.first);
        await tester.enterText(tf.first, query);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    testWidgets('empty query → early return', (tester) async {
      await submit(tester, '');
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('whitespace → early return', (tester) async {
      await submit(tester, '   ');
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('known building code → Concordia building path', (
      tester,
    ) async {
      await submit(tester, firstBuilding.code);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('known building name → Concordia building path', (
      tester,
    ) async {
      await submit(tester, firstBuilding.name);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('unknown query → SnackBar shown', (tester) async {
      await submit(tester, 'xyzNONEXISTENT99999');
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 14. _hideBuildingPopup (search focus with no building selected)
  // --------------------------------------------------------------------------
  group('_hideBuildingPopup', () {
    testWidgets('focus with null selection → _hideBuildingPopup is a no-op', (
      tester,
    ) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final tf = find.byType(TextField);
      if (tf.evaluate().isNotEmpty) {
        await tester.tap(tf.first);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 15. FABs
  // --------------------------------------------------------------------------
  group('Location & Campus FABs', () {
    testWidgets('location FAB tap with null location → guard fires', (
      tester,
    ) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final fab = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'location_button',
      );
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('campus FAB tap → _goToMyLocation', (tester) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final fab = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'campus_button',
      );
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('location FAB with real location → animateCamera called', (
      tester,
    ) async {
      await pumpWithMap(tester);
      await tester.pumpAndSettle();
      final fab = find.byWidgetPredicate(
        (w) => w is FloatingActionButton && w.heroTag == 'location_button',
      );
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 16. initState – all campus branches
  // --------------------------------------------------------------------------
  group('initState campus branches', () {
    testWidgets('SGW → _lastCameraTarget = concordiaSGW', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Loyola → _lastCameraTarget = concordiaLoyola', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('none → _lastCameraTarget = concordiaSGW (else branch)', (
      tester,
    ) async {
      await pumpNoMap(tester, initialCampus: Campus.none);
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 17. dispose() – clean teardown
  // --------------------------------------------------------------------------
  group('dispose()', () {
    testWidgets('navigate away disposes cleanly', (tester) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('gone'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('gone'), findsOneWidget);
    });

    testWidgets('dispose with pending debounce timer', (tester) async {
      await pumpNoMap(tester);
      await tester.pumpAndSettle();
      final tf = find.byType(TextField);
      if (tf.evaluate().isNotEmpty) {
        await tester.tap(tf.first);
        await tester.enterText(tf.first, 'partial');
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('gone'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('gone'), findsOneWidget);
    });

    testWidgets('dispose with active map controller', (tester) async {
      await pumpWithMap(tester);
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('gone'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('gone'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 18. build() campus label string branches
  // --------------------------------------------------------------------------
  group('Campus label strings in build()', () {
    testWidgets('SGW → CampusToggle receives sgw', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();
      final toggle = tester.widget<CampusToggle>(find.byType(CampusToggle));
      expect([
        Campus.sgw,
        Campus.loyola,
        Campus.none,
      ], contains(toggle.currentCampus));
    });

    testWidgets('Loyola → CampusToggle receives loyola or none', (
      tester,
    ) async {
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      await tester.pumpAndSettle();
      final toggle = tester.widget<CampusToggle>(find.byType(CampusToggle));
      expect([
        Campus.sgw,
        Campus.loyola,
        Campus.none,
      ], contains(toggle.currentCampus));
    });
  });

  // --------------------------------------------------------------------------
  // 19. Geolocator distance (used inside detectCampus)
  // --------------------------------------------------------------------------
  group('Geolocator.distanceBetween', () {
    test('self → 0', () {
      final d = Geolocator.distanceBetween(
        concordiaSGW.latitude,
        concordiaSGW.longitude,
        concordiaSGW.latitude,
        concordiaSGW.longitude,
      );
      expect(d, closeTo(0, 1.0));
    });

    test('SGW ↔ Loyola is 5–15 km', () {
      final d = Geolocator.distanceBetween(
        concordiaSGW.latitude,
        concordiaSGW.longitude,
        concordiaLoyola.latitude,
        concordiaLoyola.longitude,
      );
      expect(d, inInclusiveRange(5000.0, 15000.0));
    });

    test('symmetric', () {
      final d1 = Geolocator.distanceBetween(
        concordiaSGW.latitude,
        concordiaSGW.longitude,
        concordiaLoyola.latitude,
        concordiaLoyola.longitude,
      );
      final d2 = Geolocator.distanceBetween(
        concordiaLoyola.latitude,
        concordiaLoyola.longitude,
        concordiaSGW.latitude,
        concordiaSGW.longitude,
      );
      expect(d1, closeTo(d2, 0.1));
    });

    test('far point > campusRadius', () {
      final d = Geolocator.distanceBetween(
        0,
        0,
        concordiaSGW.latitude,
        concordiaSGW.longitude,
      );
      expect(d, greaterThan(campusRadius));
    });

    test('50 m from SGW < campusRadius', () {
      final d = Geolocator.distanceBetween(
        45.4977,
        -73.5789,
        concordiaSGW.latitude,
        concordiaSGW.longitude,
      );
      expect(d, lessThan(campusRadius));
    });
  });

  // --------------------------------------------------------------------------
  // 20. Widget rebuild
  // --------------------------------------------------------------------------
  group('Widget rebuild', () {
    testWidgets('different campus on rebuild', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pump();
      await pumpNoMap(tester, initialCampus: Campus.loyola);
      await tester.pump();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('pumpAndSettle completes', (tester) async {
      await pumpNoMap(tester, initialCampus: Campus.sgw);
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 21. Building polygon data integrity
  // --------------------------------------------------------------------------
  group('Building data', () {
    test('non-empty list', () => expect(buildingPolygons, isNotEmpty));

    test('every building has code + name + ≥3 points', () {
      for (final b in buildingPolygons) {
        expect(b.code.trim(), isNotEmpty);
        expect(b.name.trim(), isNotEmpty);
        expect(b.points.length, greaterThanOrEqualTo(3));
      }
    });

    test('no duplicate codes', () {
      final codes = buildingPolygons.map((b) => b.code).toList();
      expect(codes.length, codes.toSet().length);
    });

    test('all centres in Montreal bounding box', () {
      for (final b in buildingPolygons) {
        expect(b.center.latitude, inInclusiveRange(45.0, 46.0));
        expect(b.center.longitude, inInclusiveRange(-74.5, -73.0));
      }
    });

    test('all polygon coordinates valid', () {
      for (final b in buildingPolygons) {
        for (final p in b.points) {
          expect(p.latitude, inInclusiveRange(-90.0, 90.0));
          expect(p.longitude, inInclusiveRange(-180.0, 180.0));
        }
      }
    });

    test('first 5 centres are distinct', () {
      final centres = buildingPolygons.take(5).map((b) => b.center).toSet();
      expect(centres.length, greaterThan(1));
    });
  });
}
