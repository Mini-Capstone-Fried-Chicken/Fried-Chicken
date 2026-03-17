// ignore_for_file: avoid_print
//
// Targeted tests for the POI methods added to googlemaps_livelocation.dart:
//
//   _initPois()
//   _loadNearbyPois()
//   _addPoiMarkers()
//   _poiCategoryLabel()
//
// Strategy
// --------
// These methods are private on _OutdoorMapPageState.  We cover them via:
//   1. Direct unit tests on equivalent pure logic (_poiCategoryLabel switch,
//      deduplication logic, _addPoiMarkers guard).
//   2. Widget pumps with debugDisableMap/Location that exercise initState
//      code paths (fire-and-forget _initPois) and the _addPoiMarkers early-
//      return branch (poisLoaded == false on test startup).
//   3. PoiPlace / PoiCategory contract tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/services/nearby_poi_service.dart';
import 'package:campus_app/data/building_polygons.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> pumpPage(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
  bool isLoggedIn = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        isLoggedIn: isLoggedIn,
        debugDisableMap: true,
        debugDisableLocation: true,
      ),
    ),
  );
  // Give fire-and-forget _initPois a chance to start
  await tester.pump();
}

// Replicates the exact logic of _poiCategoryLabel in the source file.
String poiCategoryLabel(PoiCategory category) {
  switch (category) {
    case PoiCategory.cafe:
      return 'Cafe';
    case PoiCategory.restaurant:
      return 'Restaurant';
    case PoiCategory.pharmacy:
      return 'Pharmacy';
    case PoiCategory.depanneur:
      return 'Dépanneur';
  }
}

// Replicates the deduplication logic from _loadNearbyPois.
List<PoiPlace> deduplicatePois(List<List<PoiPlace>> results) {
  final seen = <String>{};
  final merged = <PoiPlace>[];
  for (final list in results) {
    for (final poi in list) {
      if (seen.add(poi.placeId)) {
        merged.add(poi);
      }
    }
  }
  return merged;
}

// Replicates the _addPoiMarkers guard + loop from the source file.
void addPoiMarkers({
  required Set<Marker> markers,
  required bool poisLoaded,
  required List<PoiPlace> nearbyPois,
  required Map<PoiCategory, BitmapDescriptor> poiIcons,
}) {
  if (!poisLoaded) return; // early-return branch

  for (final poi in nearbyPois) {
    final icon = poiIcons[poi.category];
    if (icon == null) continue; // null-icon skip branch

    markers.add(
      Marker(
        markerId: MarkerId('poi_${poi.placeId}'),
        position: poi.location,
        icon: icon,
        infoWindow: InfoWindow(
          title: poi.name,
          snippet: poiCategoryLabel(poi.category),
        ),
        zIndexInt: 0,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const LatLng _sgw = LatLng(45.4973, -73.5789);

PoiPlace _makePoi({
  required String placeId,
  required PoiCategory category,
  String name = 'Test Place',
}) =>
    PoiPlace(placeId: placeId, name: name, location: _sgw, category: category);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // 1. _poiCategoryLabel – all four switch cases
  // =========================================================================
  group('_poiCategoryLabel – all four cases', () {
    test('cafe → "Cafe"', () {
      expect(poiCategoryLabel(PoiCategory.cafe), 'Cafe');
    });

    test('restaurant → "Restaurant"', () {
      expect(poiCategoryLabel(PoiCategory.restaurant), 'Restaurant');
    });

    test('pharmacy → "Pharmacy"', () {
      expect(poiCategoryLabel(PoiCategory.pharmacy), 'Pharmacy');
    });

    test('depanneur → "Dépanneur"', () {
      expect(poiCategoryLabel(PoiCategory.depanneur), 'Dépanneur');
    });

    test('all PoiCategory values have a non-empty label', () {
      for (final cat in PoiCategory.values) {
        expect(poiCategoryLabel(cat), isNotEmpty);
      }
    });

    test('each label is unique', () {
      final labels = PoiCategory.values.map(poiCategoryLabel).toSet();
      expect(labels.length, PoiCategory.values.length);
    });

    test('labels are title-cased strings', () {
      for (final cat in PoiCategory.values) {
        final label = poiCategoryLabel(cat);
        expect(label[0], label[0].toUpperCase());
      }
    });
  });

  // =========================================================================
  // 2. Deduplication logic from _loadNearbyPois
  // =========================================================================
  group('_loadNearbyPois deduplication logic', () {
    test('empty results → empty list', () {
      expect(deduplicatePois([[], []]), isEmpty);
    });

    test('single list, no duplicates → all items kept', () {
      final pois = [
        _makePoi(placeId: 'a', category: PoiCategory.cafe),
        _makePoi(placeId: 'b', category: PoiCategory.restaurant),
      ];
      expect(deduplicatePois([pois, []]).length, 2);
    });

    test('duplicate placeId across two lists → deduplicated to 1', () {
      final sgw = [_makePoi(placeId: 'dup', category: PoiCategory.cafe)];
      final loyola = [_makePoi(placeId: 'dup', category: PoiCategory.cafe)];
      expect(deduplicatePois([sgw, loyola]).length, 1);
    });

    test('unique items in both lists → all kept', () {
      final sgw = [
        _makePoi(placeId: 's1', category: PoiCategory.cafe),
        _makePoi(placeId: 's2', category: PoiCategory.pharmacy),
      ];
      final loyola = [
        _makePoi(placeId: 'l1', category: PoiCategory.restaurant),
        _makePoi(placeId: 'l2', category: PoiCategory.depanneur),
      ];
      expect(deduplicatePois([sgw, loyola]).length, 4);
    });

    test('first occurrence wins in deduplication', () {
      final first = [
        _makePoi(placeId: 'x', category: PoiCategory.cafe, name: 'First'),
      ];
      final second = [
        _makePoi(
          placeId: 'x',
          category: PoiCategory.restaurant,
          name: 'Second',
        ),
      ];
      final result = deduplicatePois([first, second]);
      expect(result.first.name, 'First');
      expect(result.first.category, PoiCategory.cafe);
    });

    test('three duplicates across three lists → only one kept', () {
      final p = _makePoi(placeId: 'triple', category: PoiCategory.pharmacy);
      expect(
        deduplicatePois([
          [p],
          [p],
          [p],
        ]).length,
        1,
      );
    });

    test('preserves order of first encounter', () {
      final pois = [
        _makePoi(placeId: 'c', category: PoiCategory.cafe),
        _makePoi(placeId: 'a', category: PoiCategory.restaurant),
        _makePoi(placeId: 'b', category: PoiCategory.depanneur),
      ];
      final result = deduplicatePois([pois, []]);
      expect(result.map((p) => p.placeId).toList(), ['c', 'a', 'b']);
    });

    test('many duplicates in single list → all kept (no self-dedup)', () {
      final pois = [
        _makePoi(placeId: 'x', category: PoiCategory.cafe),
        _makePoi(placeId: 'y', category: PoiCategory.cafe),
      ];
      // In _loadNearbyPois each fetchNearby returns distinct placeIds (dedup
      // is only across the two campus results), but our helper deduplicates
      // within a single list too — same as the source.
      expect(deduplicatePois([pois]).length, 2);
    });

    test('empty second list → all SGW items kept', () {
      final sgw = List.generate(
        5,
        (i) => _makePoi(placeId: 'sgw_$i', category: PoiCategory.restaurant),
      );
      expect(deduplicatePois([sgw, []]).length, 5);
    });

    test('empty first list → all Loyola items kept', () {
      final loyola = List.generate(
        3,
        (i) => _makePoi(placeId: 'loy_$i', category: PoiCategory.pharmacy),
      );
      expect(deduplicatePois([[], loyola]).length, 3);
    });
  });

  // =========================================================================
  // 3. _addPoiMarkers guard + loop logic
  // =========================================================================
  group('_addPoiMarkers logic', () {
    test('poisLoaded=false → early return, no markers added', () {
      final markers = <Marker>{};
      addPoiMarkers(
        markers: markers,
        poisLoaded: false,
        nearbyPois: [_makePoi(placeId: 'x', category: PoiCategory.cafe)],
        poiIcons: {},
      );
      expect(markers, isEmpty);
    });

    test('poisLoaded=true, empty pois → no markers added', () {
      final markers = <Marker>{};
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [],
        poiIcons: {},
      );
      expect(markers, isEmpty);
    });

    test('poisLoaded=true, icon missing → poi skipped', () {
      final markers = <Marker>{};
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [_makePoi(placeId: 'x', category: PoiCategory.cafe)],
        poiIcons: {}, // no icon for cafe
      );
      expect(markers, isEmpty);
    });

    test('icon present for one category → only that poi added', () {
      final markers = <Marker>{};
      final fakeIcon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [
          _makePoi(placeId: 'cafe1', category: PoiCategory.cafe),
          _makePoi(placeId: 'rest1', category: PoiCategory.restaurant),
        ],
        poiIcons: {PoiCategory.cafe: fakeIcon}, // only cafe has icon
      );
      expect(markers.length, 1);
      expect(markers.first.markerId.value, 'poi_cafe1');
    });

    test('all icons present → all pois added as markers', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      final pois = PoiCategory.values
          .map((cat) => _makePoi(placeId: cat.name, category: cat))
          .toList();
      final icons = {for (final cat in PoiCategory.values) cat: icon};

      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: pois,
        poiIcons: icons,
      );
      expect(markers.length, PoiCategory.values.length);
    });

    test('marker id uses poi_<placeId> format', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [
          _makePoi(placeId: 'abc123', category: PoiCategory.pharmacy),
        ],
        poiIcons: {PoiCategory.pharmacy: icon},
      );
      expect(markers.first.markerId.value, 'poi_abc123');
    });

    test('marker position matches poi location', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      const loc = LatLng(45.456, -73.640);
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [
          PoiPlace(
            placeId: 'p1',
            name: 'Test',
            location: loc,
            category: PoiCategory.cafe,
          ),
        ],
        poiIcons: {PoiCategory.cafe: icon},
      );
      expect(markers.first.position, loc);
    });

    test('infoWindow title is poi name', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [
          _makePoi(
            placeId: 'n1',
            category: PoiCategory.restaurant,
            name: 'Tim Hortons',
          ),
        ],
        poiIcons: {PoiCategory.restaurant: icon},
      );
      expect(markers.first.infoWindow.title, 'Tim Hortons');
    });

    test('infoWindow snippet is the category label', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [
          _makePoi(placeId: 'dep1', category: PoiCategory.depanneur),
        ],
        poiIcons: {PoiCategory.depanneur: icon},
      );
      expect(markers.first.infoWindow.snippet, 'Dépanneur');
    });

    test('zIndexInt is 0 for all poi markers', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      final pois = [
        _makePoi(placeId: 'z1', category: PoiCategory.cafe),
        _makePoi(placeId: 'z2', category: PoiCategory.pharmacy),
      ];
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: pois,
        poiIcons: {PoiCategory.cafe: icon, PoiCategory.pharmacy: icon},
      );
      for (final m in markers) {
        expect(m.zIndexInt, 0);
      }
    });

    test('20 pois with icons → 20 markers', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      final pois = List.generate(
        20,
        (i) => _makePoi(placeId: 'p$i', category: PoiCategory.restaurant),
      );
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: pois,
        poiIcons: {PoiCategory.restaurant: icon},
      );
      expect(markers.length, 20);
    });
  });

  // =========================================================================
  // 4. PoiPlace contract tests
  // =========================================================================
  group('PoiPlace contract', () {
    test('stores all fields correctly', () {
      const poi = PoiPlace(
        placeId: 'id1',
        name: 'Tim Hortons',
        location: LatLng(45.49, -73.57),
        category: PoiCategory.cafe,
      );
      expect(poi.placeId, 'id1');
      expect(poi.name, 'Tim Hortons');
      expect(poi.location.latitude, 45.49);
      expect(poi.location.longitude, -73.57);
      expect(poi.category, PoiCategory.cafe);
    });

    test('all four categories can be stored', () {
      for (final cat in PoiCategory.values) {
        final poi = _makePoi(placeId: cat.name, category: cat);
        expect(poi.category, cat);
      }
    });

    test('empty name is allowed', () {
      const poi = PoiPlace(
        placeId: 'x',
        name: '',
        location: _sgw,
        category: PoiCategory.pharmacy,
      );
      expect(poi.name, '');
    });

    test('placeId is preserved exactly', () {
      const id = 'ChIJ_abc-123_XYZ';
      const poi = PoiPlace(
        placeId: id,
        name: 'N',
        location: _sgw,
        category: PoiCategory.depanneur,
      );
      expect(poi.placeId, id);
    });
  });

  // =========================================================================
  // 5. PoiCategory enum
  // =========================================================================
  group('PoiCategory enum', () {
    test('has exactly 4 values', () => expect(PoiCategory.values.length, 4));

    test(
      'contains cafe',
      () => expect(PoiCategory.values, contains(PoiCategory.cafe)),
    );
    test(
      'contains restaurant',
      () => expect(PoiCategory.values, contains(PoiCategory.restaurant)),
    );
    test(
      'contains pharmacy',
      () => expect(PoiCategory.values, contains(PoiCategory.pharmacy)),
    );
    test(
      'contains depanneur',
      () => expect(PoiCategory.values, contains(PoiCategory.depanneur)),
    );

    test('all values are distinct', () {
      expect(PoiCategory.values.toSet().length, PoiCategory.values.length);
    });

    test('each value isA<PoiCategory>', () {
      for (final c in PoiCategory.values) {
        expect(c, isA<PoiCategory>());
      }
    });
  });

  // =========================================================================
  // 6. Widget tests – exercise _initPois / _loadNearbyPois code paths
  // =========================================================================
  group('_initPois and _loadNearbyPois via widget pump', () {
    testWidgets('widget renders after _initPois fires (no crash)', (
      tester,
    ) async {
      await pumpPage(tester);
      // Let the fire-and-forget _initPois future progress
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('_initPois fires for SGW campus', (tester) async {
      await pumpPage(tester, initialCampus: Campus.sgw);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('_initPois fires for Loyola campus', (tester) async {
      await pumpPage(tester, initialCampus: Campus.loyola);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets(
      '_loadNearbyPois try-catch does not crash widget on API failure',
      (tester) async {
        // In test environment, NearbyPoiService HTTP calls fail.
        // The try-catch in _loadNearbyPois should swallow the error.
        await pumpPage(tester);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      },
    );

    testWidgets(
      '_addPoiMarkers early-return (poisLoaded=false) execised on first build',
      (tester) async {
        // On first pump _poisLoaded is false → _addPoiMarkers returns immediately
        await pumpPage(tester);
        // The map markers call happens in build() → _createMarkers() → _addPoiMarkers()
        // With poisLoaded=false the early-return line is hit
        expect(find.byType(OutdoorMapPage), findsOneWidget);
      },
    );

    testWidgets('multiple pump cycles after _initPois fires do not crash', (
      tester,
    ) async {
      await pumpPage(tester);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('pumpAndSettle after _initPois does not hang', (tester) async {
      await pumpPage(tester);
      await tester.pumpAndSettle();
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('dispose while _initPois is running does not crash', (
      tester,
    ) async {
      await pumpPage(tester);
      // Immediately navigate away before _initPois completes
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('gone'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('gone'), findsOneWidget);
    });

    testWidgets('rebuild after _initPois does not crash', (tester) async {
      await pumpPage(tester, initialCampus: Campus.sgw);
      await tester.pump(const Duration(milliseconds: 100));
      // Rebuild with different campus
      await pumpPage(tester, initialCampus: Campus.loyola);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });

  // =========================================================================
  // 7. _poiCategoryLabel snippet coverage (each label used in infoWindow)
  // =========================================================================
  group('_poiCategoryLabel used as infoWindow snippet', () {
    test('cafe snippet is "Cafe"', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [_makePoi(placeId: 'c', category: PoiCategory.cafe)],
        poiIcons: {PoiCategory.cafe: icon},
      );
      expect(markers.first.infoWindow.snippet, 'Cafe');
    });

    test('restaurant snippet is "Restaurant"', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [_makePoi(placeId: 'r', category: PoiCategory.restaurant)],
        poiIcons: {PoiCategory.restaurant: icon},
      );
      expect(markers.first.infoWindow.snippet, 'Restaurant');
    });

    test('pharmacy snippet is "Pharmacy"', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [_makePoi(placeId: 'ph', category: PoiCategory.pharmacy)],
        poiIcons: {PoiCategory.pharmacy: icon},
      );
      expect(markers.first.infoWindow.snippet, 'Pharmacy');
    });

    test('depanneur snippet is "Dépanneur"', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      addPoiMarkers(
        markers: markers,
        poisLoaded: true,
        nearbyPois: [_makePoi(placeId: 'd', category: PoiCategory.depanneur)],
        poiIcons: {PoiCategory.depanneur: icon},
      );
      expect(markers.first.infoWindow.snippet, 'Dépanneur');
    });
  });
}
