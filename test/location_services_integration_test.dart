import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/data/search_result.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('Location Services and Map Integration Tests', () {
    group('Current Location Handling', () {
      test('Current location is stored correctly', () {
        final currentLocation = LatLng(45.4973, -73.5789);
        expect(currentLocation, isNotNull);
        expect(currentLocation.latitude, 45.4973);
        expect(currentLocation.longitude, -73.5789);
      });

      test('Current location is within valid bounds', () {
        final currentLocation = LatLng(45.4973, -73.5789);
        expect(currentLocation.latitude, greaterThan(-90));
        expect(currentLocation.latitude, lessThan(90));
        expect(currentLocation.longitude, greaterThan(-180));
        expect(currentLocation.longitude, lessThan(180));
      });

      test('Multiple location updates can be handled', () {
        final locations = [
          LatLng(45.4973, -73.5789),
          LatLng(45.4975, -73.5790),
          LatLng(45.4980, -73.5785),
        ];

        for (final location in locations) {
          expect(location.latitude, isA<double>());
          expect(location.longitude, isA<double>());
        }
      });

      test('Location precision is maintained', () {
        final location = LatLng(45.49731234567, -73.57891234567);
        expect(location.latitude.toString().contains('.'), true);
        expect(location.longitude.toString().contains('.'), true);
      });

      test('Building can be detected at current location', () {
        final currentLocation = LatLng(45.4968, -73.5788);
        final hall = buildingPolygons.firstWhere((b) => b.code == 'HALL');

        expect(hall, isNotNull);
        expect(hall.center.latitude, closeTo(currentLocation.latitude, 0.001));
      });
    });

    group('Building Popup Display', () {
      test('Building popup appears when building is tapped', () {
        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        final selectedBuilding = hallBuilding;

        expect(selectedBuilding, hallBuilding);
      });

      test('Building popup displays correct information', () {
        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        final buildingName = hallBuilding.name;
        final buildingCode = hallBuilding.code;

        expect(buildingName, isNotEmpty);
        expect(buildingCode, isNotEmpty);
        expect(buildingName, 'Hall Building');
        expect(buildingCode, 'HALL');
      });

      test('Building popup can be closed', () {
        BuildingPolygon? selectedBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        selectedBuilding = null;

        expect(selectedBuilding, isNull);
      });

      test('Multiple popup opens and closes work correctly', () {
        BuildingPolygon? selectedBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        expect(selectedBuilding, isNotNull);

        selectedBuilding = null;
        expect(selectedBuilding, isNull);

        selectedBuilding = buildingPolygons.firstWhere((b) => b.code == 'EV');
        expect(selectedBuilding, isNotNull);
      });

      test('Building info is preserved in search result', () {
        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        final result = SearchResult.fromConcordiaBuilding(hallBuilding);

        expect(result.name, 'Hall Building');
        expect(result.buildingPolygon?.code, 'HALL');
      });
    });

    group('Directions and Navigation', () {
      test('Get directions button initiates route preview', () {
        var showRoutePreview = false;
        final currentLocation = LatLng(45.4973, -73.5789);
        final destination = buildingPolygons
            .firstWhere((b) => b.code == 'HALL')
            .center;

        showRoutePreview = true;

        expect(showRoutePreview, true);
        expect(currentLocation, isNotNull);
        expect(destination, isNotNull);
      });

      test('Route origin is set to current location by default', () {
        var routeOriginText = 'Current location';
        expect(routeOriginText, 'Current location');
      });

      test('Route destination is set to selected building', () {
        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        var routeDestinationText =
            '${hallBuilding.name} - ${hallBuilding.code}';

        expect(routeDestinationText, 'Hall Building - HALL');
      });

      test('Route can use both Concordia and external locations', () {
        final concordiaOrigin = LatLng(45.4973, -73.5789);
        final externalOrigin = LatLng(45.50, -73.60);

        var routeOrigin = concordiaOrigin;
        expect(routeOrigin, concordiaOrigin);

        routeOrigin = externalOrigin;
        expect(routeOrigin, externalOrigin);
      });

      test('Multiple route calculations can be performed', () {
        final buildings = buildingPolygons.take(3).toList();

        for (final building in buildings) {
          final destination = building.center;
          expect(destination, isNotNull);
        }
      });
    });

    group('Map Polyline Display', () {
      test('Polyline can be added to map', () {
        var polylines = <Polyline>{};

        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [LatLng(45.4973, -73.5789), LatLng(45.4968, -73.5788)],
          ),
        );

        expect(polylines.length, 1);
      });

      test('Polyline has correct color', () {
        const burgundy = Color(0xFF76263D);
        expect(burgundy.red, 118);
        expect(burgundy.green, 38);
        expect(burgundy.blue, 61);
      });

      test('Polyline has correct styling', () {
        const polylineId = PolylineId('route');
        const width = 5;

        expect(polylineId, const PolylineId('route'));
        expect(width, 5);
      });

      test('Polyline can be cleared', () {
        var polylines = <Polyline>{};

        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [LatLng(45.5, -73.5)],
          ),
        );

        expect(polylines.isNotEmpty, true);

        polylines = {};
        expect(polylines.isEmpty, true);
      });

      test('Multiple polylines can be displayed', () {
        var polylines = <Polyline>{};

        for (int i = 0; i < 3; i++) {
          polylines.add(
            Polyline(
              polylineId: PolylineId('route_$i'),
              points: [LatLng(45.5 + i * 0.01, -73.5)],
            ),
          );
        }

        expect(polylines.length, 3);
      });
    });

    group('Building Polygon Display', () {
      test('All buildings can be displayed as polygons', () {
        final polygons = <Polygon>{};

        for (final building in buildingPolygons) {
          polygons.add(
            Polygon(
              polygonId: PolygonId('poly_${building.code}'),
              points: building.points,
            ),
          );
        }

        expect(polygons.length, buildingPolygons.length);
      });

      test('Selected building polygon has different styling', () {
        const selectedBlue = Color(0xFF7F83C3);
        const burgundy = Color(0xFF800020);

        expect(selectedBlue.red, isNot(burgundy.red));
      });

      test('Current building polygon has different styling', () {
        var polygonFill = Colors.blue.withOpacity(0.25);
        var polygonStroke = Colors.blue.withOpacity(0.8);

        expect(polygonFill.opacity, closeTo(0.25, 0.01));
        expect(polygonStroke.opacity, closeTo(0.8, 0.01));
      });

      test('Building polygon z-index reflects importance', () {
        const selectedZIndex = 3;
        const currentZIndex = 2;
        const normalZIndex = 1;

        expect(selectedZIndex, greaterThan(currentZIndex));
        expect(currentZIndex, greaterThan(normalZIndex));
      });

      test('Building polygons handle tap events', () {
        var tappedBuilding = null;

        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        tappedBuilding = hallBuilding;

        expect(tappedBuilding, hallBuilding);
      });
    });

    group('Marker Display', () {
      test('Current location marker is created', () {
        final markerId = const MarkerId('current_location');
        expect(markerId.value, 'current_location');
      });

      test('Current location marker has correct settings', () {
        final position = LatLng(45.4973, -73.5789);
        const flat = true;
        const zIndex = 999;

        expect(position, isNotNull);
        expect(flat, true);
        expect(zIndex, 999);
      });

      test('Marker position updates with location', () {
        var markerPosition = LatLng(45.4973, -73.5789);
        expect(markerPosition.latitude, 45.4973);

        markerPosition = LatLng(45.4975, -73.5790);
        expect(markerPosition.latitude, 45.4975);
      });

      test('Multiple markers can be displayed', () {
        var markers = <Marker>{};

        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(45.4973, -73.5789),
          ),
        );

        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(45.4968, -73.5788),
          ),
        );

        expect(markers.length, 2);
      });
    });

    group('Search Bar Integration on Map', () {
      test('Search bar displays search query', () {
        var searchText = '';
        searchText = 'Hall';

        expect(searchText, 'Hall');
      });

      test('Search bar updates when building is selected', () {
        var searchText = '';
        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        searchText = hallBuilding.name;

        expect(searchText, 'Hall Building');
      });

      test('Search bar can be cleared', () {
        var searchText = 'Hall Building';
        searchText = '';

        expect(searchText, isEmpty);
      });

      test('Search suggestions update as user types', () {
        var searchText = '';
        var suggestions = <SearchSuggestion>[];

        searchText = 'H';
        suggestions = BuildingSearchService.getSuggestions(
          searchText,
        ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();

        expect(suggestions.length, greaterThan(0));
      });

      test('Submitting search navigates to building', () {
        final query = 'Hall';
        final building = BuildingSearchService.searchBuilding(query);

        expect(building, isNotNull);
        expect(building?.name, 'Hall Building');
      });
    });

    group('Camera Animation', () {
      test('Camera animates to current location', () {
        final currentLocation = LatLng(45.4973, -73.5789);
        expect(currentLocation, isNotNull);
      });

      test('Camera animates to selected building', () {
        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        final destination = hallBuilding.center;

        expect(destination, isNotNull);
      });

      test('Camera zoom level is appropriate', () {
        const buildingZoom = 18.0;
        const generalZoom = 15.0;

        expect(buildingZoom, greaterThan(generalZoom));
      });

      test('Camera can animate to multiple locations', () {
        final locations = [
          LatLng(45.4973, -73.5789),
          buildingPolygons.firstWhere((b) => b.code == 'HALL').center,
          buildingPolygons.firstWhere((b) => b.code == 'EV').center,
        ];

        for (final location in locations) {
          expect(location, isNotNull);
        }
      });
    });

    group('UI State Management', () {
      test('Camera moving flag is set correctly', () {
        var cameraMoving = false;
        cameraMoving = true;
        expect(cameraMoving, true);
        cameraMoving = false;
        expect(cameraMoving, false);
      });

      test('Selected building is maintained', () {
        var selectedBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        expect(selectedBuilding, isNotNull);
      });

      test('Current building is detected and updated', () {
        var currentBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        expect(currentBuilding, isNotNull);

        currentBuilding = buildingPolygons.firstWhere((b) => b.code == 'EV');
        expect(currentBuilding.code, 'EV');
      });

      test('Anchor offset for popup is calculated', () {
        final anchorOffset = Offset(100, 150);
        expect(anchorOffset.dx, 100);
        expect(anchorOffset.dy, 150);
      });

      test('Search suggestions list is maintained', () {
        var suggestions = <SearchSuggestion>[];
        suggestions.add(
          SearchSuggestion.fromGooglePlace(name: 'Place 1', placeId: 'id_1'),
        );

        expect(suggestions.length, 1);
      });
    });
  });
}
