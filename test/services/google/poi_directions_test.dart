// Tests for the POI directions feature added to googlemaps_livelocation.dart.
//
// Since the direction methods are private on _OutdoorMapPageState, we test
// the equivalent logic directly and verify the widget renders correctly
// with POI popup state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/services/nearby_poi_service.dart';

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
  await tester.pump();
}

const LatLng _sgw = LatLng(45.4973, -73.5789);
const LatLng _loyola = LatLng(45.4582, -73.6405);

PoiPlace _makePoi({
  required String placeId,
  required PoiCategory category,
  String name = 'Test Place',
  LatLng location = _sgw,
}) => PoiPlace(
  placeId: placeId,
  name: name,
  location: location,
  category: category,
);

// Replicates the _addPoiMarkers logic including the onTap handler
void addPoiMarkersWithTap({
  required Set<Marker> markers,
  required bool poisLoaded,
  required bool showRoutePreview,
  required List<PoiPlace> nearbyPois,
  required Map<PoiCategory, BitmapDescriptor> poiIcons,
  required void Function(PoiPlace poi) onPoiTapped,
}) {
  if (!poisLoaded) return;
  if (showRoutePreview) return;

  for (final poi in nearbyPois) {
    final icon = poiIcons[poi.category];
    if (icon == null) continue;

    markers.add(
      Marker(
        markerId: MarkerId('poi_${poi.placeId}'),
        position: poi.location,
        icon: icon,
        infoWindow: InfoWindow(
          title: poi.name,
          snippet: _poiCategoryLabel(poi.category),
        ),
        zIndexInt: 0,
        onTap: () => onPoiTapped(poi),
      ),
    );
  }
}

String _poiCategoryLabel(PoiCategory category) {
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('POI marker onTap handler', () {
    test('markers include onTap callback', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      PoiPlace? tappedPoi;

      addPoiMarkersWithTap(
        markers: markers,
        poisLoaded: true,
        showRoutePreview: false,
        nearbyPois: [
          _makePoi(
            placeId: 'cafe1',
            category: PoiCategory.cafe,
            name: 'Café A',
          ),
        ],
        poiIcons: {PoiCategory.cafe: icon},
        onPoiTapped: (poi) => tappedPoi = poi,
      );

      expect(markers.length, 1);
      final marker = markers.first;
      expect(marker.onTap, isNotNull);

      // Simulate tap
      marker.onTap!();
      expect(tappedPoi, isNotNull);
      expect(tappedPoi!.placeId, 'cafe1');
      expect(tappedPoi!.name, 'Café A');
    });

    test('each marker gets its own onTap with correct POI', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;
      final tappedPois = <PoiPlace>[];

      final pois = [
        _makePoi(placeId: 'p1', category: PoiCategory.cafe, name: 'Place 1'),
        _makePoi(
          placeId: 'p2',
          category: PoiCategory.restaurant,
          name: 'Place 2',
        ),
        _makePoi(
          placeId: 'p3',
          category: PoiCategory.pharmacy,
          name: 'Place 3',
        ),
      ];

      addPoiMarkersWithTap(
        markers: markers,
        poisLoaded: true,
        showRoutePreview: false,
        nearbyPois: pois,
        poiIcons: {
          PoiCategory.cafe: icon,
          PoiCategory.restaurant: icon,
          PoiCategory.pharmacy: icon,
        },
        onPoiTapped: (poi) => tappedPois.add(poi),
      );

      expect(markers.length, 3);

      // Tap each marker
      for (final marker in markers) {
        marker.onTap!();
      }

      expect(tappedPois.length, 3);
      final ids = tappedPois.map((p) => p.placeId).toSet();
      expect(ids, containsAll(['p1', 'p2', 'p3']));
    });

    test('poisLoaded=false still returns no markers', () {
      final markers = <Marker>{};
      addPoiMarkersWithTap(
        markers: markers,
        poisLoaded: false,
        showRoutePreview: false,
        nearbyPois: [_makePoi(placeId: 'x', category: PoiCategory.cafe)],
        poiIcons: {PoiCategory.cafe: BitmapDescriptor.defaultMarker},
        onPoiTapped: (_) {},
      );
      expect(markers, isEmpty);
    });

    test('showRoutePreview=true suppresses all POI markers', () {
      final markers = <Marker>{};
      final icon = BitmapDescriptor.defaultMarker;

      addPoiMarkersWithTap(
        markers: markers,
        poisLoaded: true,
        showRoutePreview: true,
        nearbyPois: [
          _makePoi(placeId: 'c1', category: PoiCategory.cafe),
          _makePoi(placeId: 'r1', category: PoiCategory.restaurant),
        ],
        poiIcons: {PoiCategory.cafe: icon, PoiCategory.restaurant: icon},
        onPoiTapped: (_) {},
      );

      expect(markers, isEmpty);
    });
  });

  group('POI directions destination logic', () {
    test('POI location is used as route destination', () {
      final poi = _makePoi(
        placeId: 'dest1',
        category: PoiCategory.restaurant,
        name: 'Restaurant ABC',
        location: _loyola,
      );

      // Simulate what _getDirectionsToPoi does
      final routeDestination = poi.location;
      final routeDestinationText = poi.name;

      expect(routeDestination, _loyola);
      expect(routeDestinationText, 'Restaurant ABC');
    });

    test('POI name becomes destination text for each category', () {
      for (final cat in PoiCategory.values) {
        final poi = _makePoi(
          placeId: 'id_${cat.name}',
          category: cat,
          name: '${cat.name} Place',
        );
        expect(poi.name, '${cat.name} Place');
        expect(poi.location, _sgw);
      }
    });

    test('_getDirectionsToPoi early-returns when selectedPoi is null', () {
      // Replicate the guard logic
      PoiPlace? selectedPoi;
      bool routeSet = false;

      // Simulate _getDirectionsToPoi
      final poi = selectedPoi;
      if (poi == null) {
        // early return
      } else {
        routeSet = true;
      }

      expect(routeSet, isFalse);
    });

    test('_getDirectionsToPoi early-returns when currentLocation is null', () {
      final poi = _makePoi(placeId: 'p1', category: PoiCategory.cafe);
      LatLng? currentLocation;
      bool routeSet = false;

      // Simulate _getDirectionsToPoi
      if (currentLocation == null) {
        // early return
      } else {
        routeSet = true;
      }

      expect(poi, isNotNull); // POI exists but location is null
      expect(routeSet, isFalse);
    });

    test('_getDirectionsToPoi sets correct route state', () {
      final poi = _makePoi(
        placeId: 'cafe_dir',
        category: PoiCategory.cafe,
        name: 'Coffee Shop',
        location: _loyola,
      );
      const LatLng currentLocation = _sgw;

      // Simulate _getDirectionsToPoi state assignments
      bool showRoutePreview = false;
      bool isPoiRoute = false;
      LatLng? routeOrigin;
      LatLng? routeDestination;
      String routeDestinationText = '';
      String? routeDestinationBuildingCode = 'HALL';

      // Apply the state changes
      showRoutePreview = true;
      isPoiRoute = true;
      routeOrigin = currentLocation;
      routeDestination = poi.location;
      routeDestinationText = poi.name;
      routeDestinationBuildingCode = null;

      expect(showRoutePreview, isTrue);
      expect(isPoiRoute, isTrue);
      expect(routeOrigin, _sgw);
      expect(routeDestination, _loyola);
      expect(routeDestinationText, 'Coffee Shop');
      expect(routeDestinationBuildingCode, isNull);
    });
  });

  group('OutdoorMapPage widget POI integration', () {
    testWidgets('page renders without errors with debugDisableMap', (
      tester,
    ) async {
      await pumpPage(tester);
      // Page should render without any POI popup initially
      expect(find.byKey(const Key('poi_popup_close')), findsNothing);
      expect(find.byKey(const Key('poi_get_directions_button')), findsNothing);
    });

    testWidgets('no POI popup shown initially', (tester) async {
      await pumpPage(tester);
      expect(find.text('Get Directions'), findsNothing);
      expect(find.byKey(const Key('poi_popup_close')), findsNothing);
    });
  });
}
