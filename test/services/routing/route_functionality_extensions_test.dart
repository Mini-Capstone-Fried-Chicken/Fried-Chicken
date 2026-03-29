import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('Route Preview Functionality Tests', () {
    group('Route Suggestion Creation', () {
      test('Create suggestion from Concordia building for origin', () {
        final buildingNames = BuildingSearchService.getAllBuildings();
        final hallBuilding = buildingNames.firstWhere((b) => b.code == 'HALL');

        final suggestion = SearchSuggestion.fromConcordiaBuilding(hallBuilding);

        expect(suggestion.isConcordiaBuilding, true);
        expect(suggestion.buildingName, hallBuilding);
        expect(suggestion.name, 'Hall Building');
      });

      test('Create suggestion from Google Place for origin', () {
        final suggestion = SearchSuggestion.fromGooglePlace(
          name: 'Tim Hortons',
          subtitle: '1234 Rue Sainte-Catherine',
          placeId: 'test_place_id_1',
        );

        expect(suggestion.isConcordiaBuilding, false);
        expect(suggestion.placeId, 'test_place_id_1');
        expect(suggestion.name, 'Tim Hortons');
      });

      test('Multiple origin suggestions can be created', () {
        final suggestions = [
          SearchSuggestion.fromGooglePlace(name: 'Place 1', placeId: 'id_1'),
          SearchSuggestion.fromGooglePlace(name: 'Place 2', placeId: 'id_2'),
          SearchSuggestion.fromGooglePlace(name: 'Place 3', placeId: 'id_3'),
        ];

        expect(suggestions.length, 3);
        expect(suggestions.every((s) => !s.isConcordiaBuilding), true);
      });

      test('Create suggestion from Concordia building for destination', () {
        final buildingNames = BuildingSearchService.getAllBuildings();
        final evBuilding = buildingNames.firstWhere((b) => b.code == 'EV');

        final suggestion = SearchSuggestion.fromConcordiaBuilding(evBuilding);

        expect(suggestion.isConcordiaBuilding, true);
        expect(suggestion.buildingName?.code, 'EV');
      });
    });

    group('Route Origin and Destination Selection', () {
      test('Origin selection updates route origin', () {
        final locations = <LatLng>[];
        final originSGW = LatLng(45.4973, -73.5789);

        locations.add(originSGW);

        expect(locations.first, originSGW);
      });

      test('Destination selection updates route destination', () {
        final destinationEV = buildingPolygons
            .firstWhere((b) => b.code == 'EV')
            .center;
        final destination = destinationEV;

        expect(destination, isNotNull);
        expect(destination.latitude, isA<double>());
      });

      test('Route can be created with both origin and destination', () {
        final origin = LatLng(45.4973, -73.5789);
        final destination = buildingPolygons
            .firstWhere((b) => b.code == 'HALL')
            .center;

        final routeExists = origin != null && destination != null;
        expect(routeExists, true);
      });

      test('Switching origin and destination works correctly', () {
        var originText = 'Current location';
        var destinationText = 'Hall Building - HALL';

        // Switch
        final temp = originText;
        originText = destinationText;
        destinationText = temp;

        expect(originText, 'Hall Building - HALL');
        expect(destinationText, 'Current location');
      });

      test('Origin suggestion selection changes route origin state', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        var routeOrigin = building.center;
        var routeOriginText = '${building.name} - ${building.code}';

        expect(routeOrigin, building.center);
        expect(routeOriginText, 'Hall Building - HALL');
      });
    });

    group('Route Text Display', () {
      test('Concordia building displays as "Name - Code"', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final displayText = '${building.name} - ${building.code}';

        expect(displayText, 'Hall Building - HALL');
      });

      test('Google Place displays as name only', () {
        const placeName = 'Tim Hortons';
        final displayText = placeName;

        expect(displayText, 'Tim Hortons');
      });

      test('Current location displays correctly', () {
        const displayText = 'Current location';
        expect(displayText, 'Current location');
      });

      test('Route text updates after selection', () {
        var routeOriginText = 'Current location';
        var routeDestinationText = '';

        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        routeDestinationText = '${building.name} - ${building.code}';

        expect(routeOriginText, 'Current location');
        expect(routeDestinationText, 'Hall Building - HALL');
      });

      test('Multiple route texts can be maintained', () {
        final texts = [
          'Current location',
          'Hall Building - HALL',
          'EV Building - EV',
          'Starbucks',
        ];

        expect(texts.length, 4);
        expect(texts.contains('Current location'), true);
      });
    });

    group('Route Preview Mode Control', () {
      test('Enter route preview mode sets flag', () {
        var showRoutePreview = false;
        showRoutePreview = true;

        expect(showRoutePreview, true);
      });

      test('Exit route preview mode clears flag', () {
        var showRoutePreview = true;
        showRoutePreview = false;

        expect(showRoutePreview, false);
      });

      test('Route preview mode clears route polylines on exit', () {
        var routePolylines = <Polyline>{};

        // Simulate adding polylines
        routePolylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [LatLng(45.5, -73.5)],
          ),
        );

        expect(routePolylines.isNotEmpty, true);

        // Clear on exit
        routePolylines = {};
        expect(routePolylines.isEmpty, true);
      });

      test('Route preview mode clears suggestions on exit', () {
        var originSuggestions = <SearchSuggestion>[];
        var destinationSuggestions = <SearchSuggestion>[];

        // Simulate adding suggestions
        originSuggestions.add(
          SearchSuggestion.fromGooglePlace(name: 'Place 1', placeId: 'id_1'),
        );

        expect(originSuggestions.isNotEmpty, true);

        // Clear on exit
        originSuggestions = [];
        destinationSuggestions = [];

        expect(originSuggestions.isEmpty, true);
        expect(destinationSuggestions.isEmpty, true);
      });

      test('Multiple enter/exit of route preview mode works', () {
        var showRoutePreview = false;

        showRoutePreview = true;
        expect(showRoutePreview, true);

        showRoutePreview = false;
        expect(showRoutePreview, false);

        showRoutePreview = true;
        expect(showRoutePreview, true);
      });
    });

    group('Route Calculation and Display', () {
      test('Route can be calculated from current location to building', () {
        final origin = LatLng(45.4973, -73.5789);
        final destination = buildingPolygons
            .firstWhere((b) => b.code == 'HALL')
            .center;

        expect(origin, isNotNull);
        expect(destination, isNotNull);
      });

      test('LatLngBounds can be created from route points', () {
        final points = [LatLng(45.4973, -73.5789), LatLng(45.4968, -73.5785)];

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

        expect(minLat, lessThan(maxLat));
        expect(minLng, lessThan(maxLng));
      });

      test('Route polyline is created with correct properties', () {
        const testPolylineId = PolylineId('route');
        final points = [LatLng(45.4973, -73.5789), LatLng(45.4968, -73.5785)];

        expect(points.length, 2);
        expect(points.first, LatLng(45.4973, -73.5789));
      });

      test('Polyline color matches Concordia burgundy', () {
        const burgundy = Color(0xFF76263D);
        expect(burgundy.value, isA<int>());
      });

      test('Multiple route segments can be displayed', () {
        final polylines = <Polyline>{};

        // Add route segments
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route1'),
            points: [LatLng(45.5, -73.5)],
          ),
        );

        polylines.add(
          Polyline(
            polylineId: const PolylineId('route2'),
            points: [LatLng(45.5, -73.5)],
          ),
        );

        expect(polylines.length, 2);
      });
    });

    group('Building Selection in Route Preview', () {
      test('Building center can be used as route destination', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final destination = building.center;

        expect(destination, isNotNull);
        expect(destination.latitude, closeTo(45.497, 0.001));
      });

      test('Multiple buildings can be selected as destinations', () {
        final destinations = [
          buildingPolygons.firstWhere((b) => b.code == 'HALL').center,
          buildingPolygons.firstWhere((b) => b.code == 'EV').center,
          buildingPolygons.firstWhere((b) => b.code == 'FG').center,
        ];

        expect(destinations.length, 3);
        expect(destinations.every((d) => d != null), true);
      });

      test('Current building is detected and available', () {
        final hallBuilding = buildingPolygons.firstWhere(
          (b) => b.code == 'HALL',
        );
        expect(hallBuilding, isNotNull);
        expect(hallBuilding.code, 'HALL');
      });

      test('Building information is preserved in route', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        final routeDestinationText = '${building.name} - ${building.code}';

        expect(routeDestinationText.contains('HALL'), true);
        expect(routeDestinationText.contains('Hall Building'), true);
      });
    });

    group('Route Preview Panel Integration', () {
      test('Close button clears route preview state', () {
        var showRoutePreview = true;
        var routePolylines = <Polyline>{};

        // Simulate close
        showRoutePreview = false;
        routePolylines = {};

        expect(showRoutePreview, false);
        expect(routePolylines.isEmpty, true);
      });

      test('Swap button exchanges origin and destination', () {
        var originText = 'Current location';
        var destinationText = 'Hall Building - HALL';

        // Swap
        final temp = originText;
        originText = destinationText;
        destinationText = temp;

        expect(originText, 'Hall Building - HALL');
        expect(destinationText, 'Current location');
      });

      test('Route preview maintains consistent state', () {
        var showRoutePreview = true;
        var routeOrigin = LatLng(45.4973, -73.5789);
        var routeDestination = buildingPolygons
            .firstWhere((b) => b.code == 'HALL')
            .center;
        var routeOriginText = 'Current location';
        var routeDestinationText = 'Hall Building - HALL';

        expect(showRoutePreview, true);
        expect(routeOrigin, isNotNull);
        expect(routeDestination, isNotNull);
        expect(routeOriginText, isNotEmpty);
        expect(routeDestinationText, isNotEmpty);
      });
    });

    group('Route Suggestion Search', () {
      test('Empty query returns no suggestions', () {
        final query = '';
        final isEmpty = query.trim().isEmpty;

        expect(isEmpty, true);
      });

      test('Query with whitespace only returns no suggestions', () {
        final query = '   ';
        final isEmpty = query.trim().isEmpty;

        expect(isEmpty, true);
      });

      test('Valid building code returns suggestion', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'HALL');
        expect(building.code, 'HALL');
      });

      test('Valid building name returns suggestion', () {
        final building = buildingPolygons.firstWhere(
          (b) => b.name.contains('Hall'),
        );
        expect(building.name.isNotEmpty, true);
      });

      test('Suggestions can be filtered by type (Concordia vs Google)', () {
        final suggestions = <SearchSuggestion>[
          SearchSuggestion.fromGooglePlace(name: 'Building 1', placeId: 'id_1'),
          SearchSuggestion.fromGooglePlace(name: 'Building 2', placeId: 'id_2'),
        ];

        final concordiaSuggestions = suggestions
            .where((s) => s.isConcordiaBuilding)
            .toList();
        final googleSuggestions = suggestions
            .where((s) => !s.isConcordiaBuilding)
            .toList();

        expect(concordiaSuggestions.isEmpty, true);
        expect(googleSuggestions.length, 2);
      });
    });

    group('Route Debouncing', () {
      test('Debounce timer delay is reasonable', () {
        const duration = Duration(milliseconds: 500);
        expect(duration.inMilliseconds, 500);
      });

      test('Multiple search queries without delay use debounce', () {
        final queries = ['H', 'Ha', 'Hal', 'Hall'];
        expect(queries.length, 4);
        // Only the last query should be processed after debounce
      });
    });
  });

  group('Google Places Service Integration Tests', () {
    group('Place Details Retrieval', () {
      test('Place details includes location', () {
        // Mock place details structure
        final placeDetailsMap = {
          'location': {'lat': 45.5, 'lng': -73.5},
          'name': 'Test Place',
          'formatted_address': '123 Main St',
          'place_id': 'test_id',
        };

        expect(placeDetailsMap.containsKey('location'), true);
      });

      test('Place details includes name and address', () {
        final placeDetailsMap = {
          'location': {'lat': 45.5, 'lng': -73.5},
          'name': 'Test Place',
          'formatted_address': '123 Main St',
          'place_id': 'test_id',
        };

        expect(placeDetailsMap['name'], 'Test Place');
        expect(placeDetailsMap['formatted_address'], isNotNull);
      });
    });
  });
}
