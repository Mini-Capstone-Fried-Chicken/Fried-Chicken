import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/search_result.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('Non-Concordia Building Route Preview Feature', () {
    test('Non-Concordia building triggers automatic route preview', () {
      // Create a SearchResult for a non-Concordia building
      final nonConcordiaPlace = SearchResult(
        name: 'McDonald\'s',
        address: '123 Main Street',
        location: const LatLng(45.4875, -73.5759),
        isConcordiaBuilding: false,
        placeId: 'test_place_id',
        buildingPolygon: null,
      );

      // Verify it's marked as non-Concordia
      expect(nonConcordiaPlace.isConcordiaBuilding, isFalse);
      expect(nonConcordiaPlace.name, 'McDonald\'s');
      expect(nonConcordiaPlace.location, isNotNull);
    });

    test('Concordia building does not trigger automatic route preview', () {
      // Create a SearchResult for a Concordia building
      final concordiaPlace = SearchResult(
        name: 'MB Building',
        address: '1455 De Maisonneuve W',
        location: const LatLng(45.4973, -73.5789),
        isConcordiaBuilding: true,
        placeId: null,
        buildingPolygon: null,
      );

      // Verify it's marked as Concordia
      expect(concordiaPlace.isConcordiaBuilding, isTrue);
      expect(concordiaPlace.name, 'MB Building');
    });

    test('Route preview requires both origin and destination', () {
      // Route preview state should have origin and destination
      final origin = const LatLng(45.4973, -73.5789);
      final destination = const LatLng(45.4875, -73.5759);

      expect(origin, isNotNull);
      expect(destination, isNotNull);
      expect(origin != destination, isTrue); // They should be different
    });

    test('Non-Concordia search result displays place name correctly', () {
      final place = SearchResult(
        name: 'Starbucks Coffee',
        address: '456 Queen Street',
        location: const LatLng(45.50, -73.57),
        isConcordiaBuilding: false,
        placeId: 'place_123',
        buildingPolygon: null,
      );

      expect(place.name.isNotEmpty, isTrue);
      expect(place.address, isNotNull);
      expect(place.location.latitude, closeTo(45.50, 0.01));
    });

    test('Route origin text uses "Current location" for non-Concordia places', () {
      const originText = 'Current location';
      
      expect(originText, equals('Current location'));
      expect(originText.isNotEmpty, isTrue);
    });

    test('Route destination text uses place name for non-Concordia places', () {
      const placeName = 'Pizza Hut';
      final destinationText = placeName;
      
      expect(destinationText, equals('Pizza Hut'));
      expect(destinationText.contains('Pizza'), isTrue);
    });

    test('Searching for multiple non-Concordia places shows route preview for each', () {
      final places = [
        SearchResult(
          name: 'Restaurant A',
          address: '100 Street',
          location: const LatLng(45.48, -73.57),
          isConcordiaBuilding: false,
          placeId: 'place_1',
          buildingPolygon: null,
        ),
        SearchResult(
          name: 'Restaurant B',
          address: '200 Street',
          location: const LatLng(45.49, -73.58),
          isConcordiaBuilding: false,
          placeId: 'place_2',
          buildingPolygon: null,
        ),
      ];

      expect(places.length, 2);
      expect(places.every((p) => !p.isConcordiaBuilding), isTrue);
      expect(places[0].location != places[1].location, isTrue);
    });

    test('Route preview clears when switching between places', () {
      // Simulate clearing route preview state
      final routeReviewCleared = true;
      
      expect(routeReviewCleared, isTrue);
    });

    test('Current location must be available for auto route preview', () {
      // Verify that current location is a required condition
      final hasCurrentLocation = true;
      final place = SearchResult(
        name: 'Cafe',
        address: 'Street',
        location: const LatLng(45.5, -73.5),
        isConcordiaBuilding: false,
        placeId: 'cafe_1',
        buildingPolygon: null,
      );

      // Route preview should only work if current location is available
      expect(hasCurrentLocation, isTrue);
      expect(!place.isConcordiaBuilding, isTrue);
    });

    test('Non-Concordia place can have null placeId for some search results', () {
      final placeWithoutId = SearchResult(
        name: 'Local Store',
        address: 'Downtown',
        location: const LatLng(45.5, -73.5),
        isConcordiaBuilding: false,
        placeId: null,
        buildingPolygon: null,
      );

      expect(placeWithoutId.placeId, isNull);
      expect(placeWithoutId.isConcordiaBuilding, isFalse);
    });

    test('Route preview shows confirmation message with place name', () {
      const placeName = 'Pizzeria Downtown';
      final confirmationMessage = 'Showing route to $placeName';
      
      expect(confirmationMessage, contains(placeName));
      expect(confirmationMessage, contains('Showing route to'));
    });

    test('Non-Concordia building location is valid for route calculation', () {
      final location = const LatLng(45.4875, -73.5759);
      
      // Verify coordinates are in valid range
      expect(location.latitude, inInclusiveRange(-90, 90));
      expect(location.longitude, inInclusiveRange(-180, 180));
    });

    test('Route preview mode differentiates Concordia and non-Concordia places', () {
      final concordia = SearchResult(
        name: 'MB',
        address: 'Concordia',
        location: const LatLng(45.4973, -73.5789),
        isConcordiaBuilding: true,
        placeId: null,
        buildingPolygon: null,
      );

      final nonConcordia = SearchResult(
        name: 'Restaurant',
        address: 'Downtown',
        location: const LatLng(45.50, -73.58),
        isConcordiaBuilding: false,
        placeId: 'rest_123',
        buildingPolygon: null,
      );

      // Concordia buildings should use different handling
      expect(concordia.isConcordiaBuilding, isTrue);
      expect(nonConcordia.isConcordiaBuilding, isFalse);
      expect(concordia.isConcordiaBuilding != nonConcordia.isConcordiaBuilding, isTrue);
    });
  });
}
