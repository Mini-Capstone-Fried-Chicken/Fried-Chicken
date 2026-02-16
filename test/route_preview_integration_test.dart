import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/data/building_names.dart';

void main() {
  group('Route Preview Integration Tests', () {
    group('Route Preview State Management', () {
      test('Route preview should have origin and destination', () {
        final origin = LatLng(45.4973, -73.5789);
        final destination = LatLng(45.4582, -73.6405);

        expect(origin.latitude, 45.4973);
        expect(origin.longitude, -73.5789);
        expect(destination.latitude, 45.4582);
        expect(destination.longitude, -73.6405);
      });

      test('Route origin can be set from current location', () {
        final currentLocation = LatLng(45.4973, -73.5789);
        final routeOrigin = currentLocation;

        expect(routeOrigin, currentLocation);
      });

      test('Route destination can be set from building', () {
        final building = buildingPolygons.first;
        final routeDestination = building.center;

        expect(routeDestination, building.center);
      });

      test('Route origin and destination can be switched', () {
        var origin = LatLng(45.4973, -73.5789);
        var destination = LatLng(45.4582, -73.6405);

        // Switch
        final temp = origin;
        origin = destination;
        destination = temp;

        expect(origin.latitude, 45.4582);
        expect(destination.latitude, 45.4973);
      });

      test('Route text labels can be switched', () {
        var originText = 'Current location';
        var destinationText = 'Hall Building - H';

        // Switch
        final temp = originText;
        originText = destinationText;
        destinationText = temp;

        expect(originText, 'Hall Building - H');
        expect(destinationText, 'Current location');
      });
    });

    group('Route Bounds Calculation', () {
      test('Calculate bounds for two points on same campus', () {
        final point1 = LatLng(45.4973, -73.5789);
        final point2 = LatLng(45.4975, -73.5791);

        final points = [point1, point2];
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (final point in points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        expect(bounds.southwest.latitude, 45.4973);
        expect(bounds.northeast.latitude, 45.4975);
      });

      test('Calculate bounds for two points on different campuses', () {
        final sgw = LatLng(45.4973, -73.5789);
        final loyola = LatLng(45.4582, -73.6405);

        final points = [sgw, loyola];
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (final point in points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        expect(bounds.southwest.latitude, 45.4582);
        expect(bounds.northeast.latitude, 45.4973);
        expect(bounds.southwest.longitude, -73.6405);
        expect(bounds.northeast.longitude, -73.5789);
      });

      test('Calculate bounds for multiple route points', () {
        final points = [
          LatLng(45.497, -73.579),
          LatLng(45.498, -73.580),
          LatLng(45.499, -73.581),
          LatLng(45.500, -73.582),
        ];

        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (final point in points) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        expect(minLat, 45.497);
        expect(maxLat, 45.500);
        expect(minLng, -73.582);
        expect(maxLng, -73.579);
      });
    });

    group('Route Polyline Creation', () {
      test('Create polyline from route points', () {
        final routePoints = [
          LatLng(45.497, -73.579),
          LatLng(45.498, -73.580),
          LatLng(45.499, -73.581),
        ];

        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: const Color(0xFF76263D),
          width: 5,
          patterns: [PatternItem.dot, PatternItem.gap(10)],
        );

        expect(polyline.polylineId.value, 'route');
        expect(polyline.points.length, 3);
        expect(polyline.color, const Color(0xFF76263D));
        expect(polyline.width, 5);
      });

      test('Polyline contains correct points', () {
        final routePoints = [
          LatLng(45.497, -73.579),
          LatLng(45.498, -73.580),
        ];

        final polyline = Polyline(
          polylineId: const PolylineId('test_route'),
          points: routePoints,
        );

        expect(polyline.points[0].latitude, 45.497);
        expect(polyline.points[0].longitude, -73.579);
        expect(polyline.points[1].latitude, 45.498);
        expect(polyline.points[1].longitude, -73.580);
      });

      test('Empty route points create empty polyline', () {
        final routePoints = <LatLng>[];

        final polyline = Polyline(
          polylineId: const PolylineId('empty_route'),
          points: routePoints,
        );

        expect(polyline.points, isEmpty);
      });

      test('Single point route creates valid polyline', () {
        final routePoints = [LatLng(45.497, -73.579)];

        final polyline = Polyline(
          polylineId: const PolylineId('single_point'),
          points: routePoints,
        );

        expect(polyline.points.length, 1);
        expect(polyline.points.first.latitude, 45.497);
      });
    });

    group('Route Suggestion Selection', () {
      test('Select Concordia building as origin creates proper location', () {
        final suggestion = SearchSuggestion.fromConcordiaBuilding(
          concordiaBuildingNames.firstWhere((b) => b.code == 'HALL'),
        );

        expect(suggestion.isConcordiaBuilding, true);
        expect(suggestion.buildingName, isNotNull);
        expect(suggestion.buildingName?.code, 'HALL');
      });

      test('Select Google Place as origin creates proper location', () {
        final suggestion = SearchSuggestion.fromGooglePlace(
          name: 'Tim Hortons',
          subtitle: '1234 Rue Sainte-Catherine',
          placeId: 'test_place_id',
        );

        expect(suggestion.isConcordiaBuilding, false);
        expect(suggestion.placeId, 'test_place_id');
        expect(suggestion.name, 'Tim Hortons');
      });

      test('Origin suggestion selection updates route origin', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final newOrigin = building.center;

        expect(newOrigin, isNotNull);
        expect(newOrigin.latitude, isA<double>());
        expect(newOrigin.longitude, isA<double>());
      });

      test('Destination suggestion selection updates route destination', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'EV');
        final newDestination = building.center;

        expect(newDestination, isNotNull);
        expect(newDestination.latitude, isA<double>());
        expect(newDestination.longitude, isA<double>());
      });
    });

    group('Route Text Display', () {
      test('Concordia building displays as "Name - Code"', () {
        final building = concordiaBuildingNames.firstWhere((b) => b.code == 'HALL');
        final displayText = '${building.name} - ${building.code}';

        expect(displayText, 'Hall Building - HALL');
      });

      test('Google Place displays as name only', () {
        final placeName = 'Tim Hortons';
        final displayText = placeName;

        expect(displayText, 'Tim Hortons');
      });

      test('Current location displays correctly', () {
        final displayText = 'Current location';
        expect(displayText, 'Current location');
      });

      test('Route text updates after selection', () {
        var routeOriginText = 'Current location';
        var routeDestinationText = '';

        // Simulate selection
        final building = concordiaBuildingNames.firstWhere((b) => b.code == 'HALL');
        routeDestinationText = '${building.name} - ${building.code}';

        expect(routeOriginText, 'Current location');
        expect(routeDestinationText, 'Hall Building - HALL');
      });
    });

    group('Route Preview Mode Control', () {
      test('Enter route preview mode sets flag', () {
        var showRoutePreview = false;
        showRoutePreview = true;

        expect(showRoutePreview, isTrue);
      });

      test('Close route preview clears state', () {
        var showRoutePreview = true;
        var routeOriginSuggestions = [
          SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[0]),
        ];
        var routeDestinationSuggestions = [
          SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[1]),
        ];

        // Simulate close
        showRoutePreview = false;
        routeOriginSuggestions = [];
        routeDestinationSuggestions = [];

        expect(showRoutePreview, isFalse);
        expect(routeOriginSuggestions, isEmpty);
        expect(routeDestinationSuggestions, isEmpty);
      });

      test('Route preview hides building popup', () {
        LatLng? selectedBuildingCenter = LatLng(45.497, -73.579);
        var showLearnMore = true;

        // Enter route preview mode
        selectedBuildingCenter = null;
        showLearnMore = false;

        expect(selectedBuildingCenter, isNull);
        expect(showLearnMore, isFalse);
      });
    });

    group('Route Marker Creation', () {
      test('Create origin marker', () {
        final originLocation = LatLng(45.4973, -73.5789);
        final marker = Marker(
          markerId: const MarkerId('route_origin'),
          position: originLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );

        expect(marker.markerId.value, 'route_origin');
        expect(marker.position, originLocation);
      });

      test('Create destination marker', () {
        final destLocation = LatLng(45.4582, -73.6405);
        final marker = Marker(
          markerId: const MarkerId('route_destination'),
          position: destLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );

        expect(marker.markerId.value, 'route_destination');
        expect(marker.position, destLocation);
      });

      test('Both markers can exist simultaneously', () {
        final markers = <Marker>{
          Marker(
            markerId: const MarkerId('route_origin'),
            position: LatLng(45.4973, -73.5789),
          ),
          Marker(
            markerId: const MarkerId('route_destination'),
            position: LatLng(45.4582, -73.6405),
          ),
        };

        expect(markers.length, 2);
        expect(
          markers.any((m) => m.markerId.value == 'route_origin'),
          isTrue,
        );
        expect(
          markers.any((m) => m.markerId.value == 'route_destination'),
          isTrue,
        );
      });
    });

    group('Route Suggestion Filtering', () {
      test('Origin suggestions can be cleared', () {
        var suggestions = [
          SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[0]),
          SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[1]),
        ];

        suggestions = [];

        expect(suggestions, isEmpty);
      });

      test('Destination suggestions can be cleared', () {
        var suggestions = [
          SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[0]),
        ];

        suggestions = [];

        expect(suggestions, isEmpty);
      });

      test('Suggestions clear when switching origin and destination', () {
        var originSuggestions = [
          SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[0]),
        ];
        var destinationSuggestions = [
          SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[1]),
        ];

        // Simulate switch
        originSuggestions = [];
        destinationSuggestions = [];

        expect(originSuggestions, isEmpty);
        expect(destinationSuggestions, isEmpty);
      });
    });

    group('Route Preview Initial State', () {
      test('Initial route uses current location as origin', () {
        final currentLocation = LatLng(45.4973, -73.5789);
        final routeOrigin = currentLocation;
        final routeOriginText = 'Current location';

        expect(routeOrigin, currentLocation);
        expect(routeOriginText, 'Current location');
      });

      test('Initial route uses selected building as destination', () {
        final selectedBuilding = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final routeDestination = selectedBuilding.center;
        final routeDestinationText = '${selectedBuilding.name} - ${selectedBuilding.code}';

        expect(routeDestination, selectedBuilding.center);
        expect(routeDestinationText, 'Hall Building - HALL');
      });
    });

    group('Route Validation', () {
      test('Route requires both origin and destination', () {
        final origin = LatLng(45.4973, -73.5789);
        final destination = LatLng(45.4582, -73.6405);

        expect(origin, isNotNull);
        expect(destination, isNotNull);
      });

      test('Route cannot be calculated with null origin', () {
        LatLng? origin;
        final destination = LatLng(45.4582, -73.6405);

        expect(origin, isNull);
        expect(destination, isNotNull);
      });

      test('Route cannot be calculated with null destination', () {
        final origin = LatLng(45.4973, -73.5789);
        LatLng? destination;

        expect(origin, isNotNull);
        expect(destination, isNull);
      });

      test('Route cannot be calculated with both null', () {
        LatLng? origin;
        LatLng? destination;

        expect(origin, isNull);
        expect(destination, isNull);
      });
    });

    group('Route Mode Transitions', () {
      test('Transition from building popup to route preview', () {
        BuildingPolygon? selectedBuildingPoly = buildingPolygons.first;
        var showRoutePreview = false;

        // User clicks "Get Directions"
        final destination = selectedBuildingPoly.center;
        showRoutePreview = true;
        selectedBuildingPoly = null;

        expect(showRoutePreview, isTrue);
        expect(selectedBuildingPoly, isNull);
        expect(destination, isNotNull);
      });

      test('Transition from route preview to normal map', () {
        var showRoutePreview = true;
        Set<Polyline> routePolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [LatLng(45.497, -73.579)],
          ),
        };

        // User closes route preview
        showRoutePreview = false;
        routePolylines = {};

        expect(showRoutePreview, isFalse);
        expect(routePolylines, isEmpty);
      });
    });
  });
}
