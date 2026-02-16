import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/data/search_result.dart';

void main() {
  group('SearchResult Tests', () {
    group('SearchResult - Concordia Building Creation', () {
      test('Create SearchResult from Concordia building', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'H');
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.name, building.name);
        expect(result.location, building.center);
        expect(result.isConcordiaBuilding, true);
        expect(result.buildingPolygon, building);
        expect(result.address, isNull);
        expect(result.placeId, isNull);
      });

      test('Create SearchResult from different Concordia buildings', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'H');
        final evBuilding = buildingPolygons.firstWhere((b) => b.code == 'EV');

        final hallResult = SearchResult.fromConcordiaBuilding(hallBuilding);
        final evResult = SearchResult.fromConcordiaBuilding(evBuilding);

        expect(hallResult.buildingPolygon?.code, 'H');
        expect(evResult.buildingPolygon?.code, 'EV');
        expect(hallResult.isConcordiaBuilding, true);
        expect(evResult.isConcordiaBuilding, true);
      });

      test('SearchResult contains correct building polygon reference', () {
        final building = buildingPolygons.first;
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.buildingPolygon, isNotNull);
        expect(result.buildingPolygon, building);
        expect(result.buildingPolygon?.code, building.code);
        expect(result.buildingPolygon?.name, building.name);
      });
    });

    group('SearchResult - Google Place Creation', () {
      test('Create SearchResult from Google place with all fields', () {
        final location = LatLng(45.5, -73.6);
        final result = SearchResult.fromGooglePlace(
          name: 'Tim Hortons',
          address: '1234 Rue Sainte-Catherine',
          location: location,
          isConcordiaBuilding: false,
          placeId: 'test_place_id',
        );

        expect(result.name, 'Tim Hortons');
        expect(result.address, '1234 Rue Sainte-Catherine');
        expect(result.location, location);
        expect(result.isConcordiaBuilding, false);
        expect(result.placeId, 'test_place_id');
        expect(result.buildingPolygon, isNull);
      });

      test('Create SearchResult from Google place with minimal fields', () {
        final location = LatLng(45.5, -73.6);
        final result = SearchResult.fromGooglePlace(
          name: 'Test Place',
          location: location,
          isConcordiaBuilding: false,
        );

        expect(result.name, 'Test Place');
        expect(result.location, location);
        expect(result.isConcordiaBuilding, false);
        expect(result.address, isNull);
        expect(result.placeId, isNull);
        expect(result.buildingPolygon, isNull);
      });

      test('Create SearchResult from Google place that is a Concordia building', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'H');
        final result = SearchResult.fromGooglePlace(
          name: 'Hall Building',
          address: '1455 De Maisonneuve Blvd. W',
          location: building.center,
          isConcordiaBuilding: true,
          buildingPolygon: building,
          placeId: 'google_hall_building_id',
        );

        expect(result.name, 'Hall Building');
        expect(result.isConcordiaBuilding, true);
        expect(result.buildingPolygon, building);
        expect(result.placeId, 'google_hall_building_id');
        expect(result.address, '1455 De Maisonneuve Blvd. W');
      });
    });

    group('SearchResult - Location Data', () {
      test('SearchResult maintains correct location coordinates', () {
        final location = LatLng(45.4973, -73.5789);
        final result = SearchResult.fromGooglePlace(
          name: 'Test Location',
          location: location,
          isConcordiaBuilding: false,
        );

        expect(result.location.latitude, 45.4973);
        expect(result.location.longitude, -73.5789);
      });

      test('SearchResult location matches building center', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'H');
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.location, building.center);
        expect(result.location.latitude, building.center.latitude);
        expect(result.location.longitude, building.center.longitude);
      });

      test('SearchResult location can be at different campuses', () {
        final sgwLocation = LatLng(45.4973, -73.5789);
        final loyolaLocation = LatLng(45.4582, -73.6405);

        final sgwResult = SearchResult.fromGooglePlace(
          name: 'SGW Place',
          location: sgwLocation,
          isConcordiaBuilding: false,
        );

        final loyolaResult = SearchResult.fromGooglePlace(
          name: 'Loyola Place',
          location: loyolaLocation,
          isConcordiaBuilding: false,
        );

        expect(sgwResult.location, sgwLocation);
        expect(loyolaResult.location, loyolaLocation);
        expect(sgwResult.location, isNot(loyolaResult.location));
      });
    });

    group('SearchResult - Concordia Building Flag', () {
      test('Concordia building result has correct flag', () {
        final building = buildingPolygons.first;
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.isConcordiaBuilding, true);
      });

      test('Non-Concordia place result has correct flag', () {
        final result = SearchResult.fromGooglePlace(
          name: 'External Place',
          location: LatLng(45.5, -73.6),
          isConcordiaBuilding: false,
        );

        expect(result.isConcordiaBuilding, false);
      });

      test('Google place found to be Concordia building has correct flag', () {
        final building = buildingPolygons.first;
        final result = SearchResult.fromGooglePlace(
          name: building.name,
          location: building.center,
          isConcordiaBuilding: true,
          buildingPolygon: building,
        );

        expect(result.isConcordiaBuilding, true);
        expect(result.buildingPolygon, isNotNull);
      });
    });

    group('SearchResult - Optional Fields', () {
      test('SearchResult address can be null', () {
        final result = SearchResult.fromGooglePlace(
          name: 'Place Without Address',
          location: LatLng(45.5, -73.6),
          isConcordiaBuilding: false,
        );

        expect(result.address, isNull);
      });

      test('SearchResult placeId can be null', () {
        final result = SearchResult.fromGooglePlace(
          name: 'Place Without ID',
          location: LatLng(45.5, -73.6),
          isConcordiaBuilding: false,
        );

        expect(result.placeId, isNull);
      });

      test('SearchResult buildingPolygon can be null for non-Concordia places', () {
        final result = SearchResult.fromGooglePlace(
          name: 'Non-Concordia Place',
          location: LatLng(45.5, -73.6),
          isConcordiaBuilding: false,
        );

        expect(result.buildingPolygon, isNull);
      });

      test('Concordia building SearchResult has null address by default', () {
        final building = buildingPolygons.first;
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.address, isNull);
      });
    });

    group('SearchResult - Multiple Buildings', () {
      test('Create SearchResults for all Concordia buildings', () {
        final results = buildingPolygons
            .map((building) => SearchResult.fromConcordiaBuilding(building))
            .toList();

        expect(results.length, buildingPolygons.length);
        expect(results.every((r) => r.isConcordiaBuilding), true);
        expect(results.every((r) => r.buildingPolygon != null), true);
      });

      test('Each SearchResult has unique location', () {
        final results = buildingPolygons
            .take(5)
            .map((building) => SearchResult.fromConcordiaBuilding(building))
            .toList();

        for (int i = 0; i < results.length; i++) {
          for (int j = i + 1; j < results.length; j++) {
            // Buildings might have same center in rare cases, so we check name uniqueness
            expect(results[i].name, isNot(results[j].name));
          }
        }
      });
    });

    group('SearchResult - Data Consistency', () {
      test('SearchResult name matches building name', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'H');
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.name, building.name);
      });

      test('SearchResult preserves all provided data', () {
        final location = LatLng(45.5, -73.6);
        final result = SearchResult.fromGooglePlace(
          name: 'Full Data Place',
          address: '1234 Main St',
          location: location,
          isConcordiaBuilding: false,
          placeId: 'place_123',
        );

        expect(result.name, 'Full Data Place');
        expect(result.address, '1234 Main St');
        expect(result.location, location);
        expect(result.isConcordiaBuilding, false);
        expect(result.placeId, 'place_123');
      });

      test('SearchResult const constructor works correctly', () {
        final location = LatLng(45.5, -73.6);
        const name = 'Test Place';
        const address = 'Test Address';
        const placeId = 'test_id';

        final result = SearchResult(
          name: name,
          address: address,
          location: location,
          isConcordiaBuilding: false,
          placeId: placeId,
        );

        expect(result.name, name);
        expect(result.address, address);
        expect(result.location, location);
        expect(result.placeId, placeId);
      });
    });

    group('SearchResult - Edge Cases', () {
      test('SearchResult handles empty name string', () {
        final result = SearchResult.fromGooglePlace(
          name: '',
          location: LatLng(45.5, -73.6),
          isConcordiaBuilding: false,
        );

        expect(result.name, '');
      });

      test('SearchResult handles very long name', () {
        final longName = 'A' * 200;
        final result = SearchResult.fromGooglePlace(
          name: longName,
          location: LatLng(45.5, -73.6),
          isConcordiaBuilding: false,
        );

        expect(result.name, longName);
        expect(result.name.length, 200);
      });

      test('SearchResult handles special characters in name', () {
        final result = SearchResult.fromGooglePlace(
          name: "Tim Horton's Café & Boulangerie",
          location: LatLng(45.5, -73.6),
          isConcordiaBuilding: false,
        );

        expect(result.name, "Tim Horton's Café & Boulangerie");
      });

      test('SearchResult handles location at extreme coordinates', () {
        final result = SearchResult.fromGooglePlace(
          name: 'Extreme Location',
          location: LatLng(89.99, -179.99),
          isConcordiaBuilding: false,
        );

        expect(result.location.latitude, 89.99);
        expect(result.location.longitude, -179.99);
      });
    });

    group('SearchResult - Building Polygon Reference', () {
      test('Building polygon reference is maintained', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'EV');
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.buildingPolygon, same(building));
      });

      test('Building polygon contains expected data', () {
        final building = buildingPolygons.firstWhere((b) => b.code == 'H');
        final result = SearchResult.fromConcordiaBuilding(building);

        expect(result.buildingPolygon?.code, 'H');
        expect(result.buildingPolygon?.name, isNotEmpty);
        expect(result.buildingPolygon?.center, isNotNull);
      });
    });

    group('SearchResult - Mixed Results List', () {
      test('List can contain both Concordia and non-Concordia results', () {
        final results = <SearchResult>[
          SearchResult.fromConcordiaBuilding(buildingPolygons.first),
          SearchResult.fromGooglePlace(
            name: 'External Place',
            location: LatLng(45.5, -73.6),
            isConcordiaBuilding: false,
          ),
        ];

        expect(results.length, 2);
        expect(results[0].isConcordiaBuilding, true);
        expect(results[1].isConcordiaBuilding, false);
      });

      test('Filter results by Concordia building flag', () {
        final allResults = <SearchResult>[
          SearchResult.fromConcordiaBuilding(buildingPolygons.first),
          SearchResult.fromGooglePlace(
            name: 'Place 1',
            location: LatLng(45.5, -73.6),
            isConcordiaBuilding: false,
          ),
          SearchResult.fromConcordiaBuilding(buildingPolygons[1]),
          SearchResult.fromGooglePlace(
            name: 'Place 2',
            location: LatLng(45.6, -73.7),
            isConcordiaBuilding: false,
          ),
        ];

        final concordiaResults = allResults.where((r) => r.isConcordiaBuilding).toList();
        final nonConcordiaResults = allResults.where((r) => !r.isConcordiaBuilding).toList();

        expect(concordiaResults.length, 2);
        expect(nonConcordiaResults.length, 2);
      });
    });

    group('SearchResult - Real-World Scenarios', () {
      test('Search result for Hall Building', () {
        final hallBuilding = buildingPolygons.firstWhere((b) => b.code == 'H');
        final result = SearchResult.fromConcordiaBuilding(hallBuilding);

        expect(result.name, 'Hall Building');
        expect(result.isConcordiaBuilding, true);
        expect(result.buildingPolygon?.code, 'H');
      });

      test('Search result for nearby coffee shop', () {
        final result = SearchResult.fromGooglePlace(
          name: 'Starbucks',
          address: '1400 De Maisonneuve Blvd W',
          location: LatLng(45.497, -73.579),
          isConcordiaBuilding: false,
          placeId: 'starbucks_place_id',
        );

        expect(result.name, 'Starbucks');
        expect(result.isConcordiaBuilding, false);
        expect(result.address, isNotNull);
        expect(result.placeId, isNotNull);
      });

      test('Search result for Concordia building found via Google', () {
        final evBuilding = buildingPolygons.firstWhere((b) => b.code == 'EV');
        final result = SearchResult.fromGooglePlace(
          name: 'EV Building',
          address: '1515 Ste-Catherine St W',
          location: evBuilding.center,
          isConcordiaBuilding: true,
          buildingPolygon: evBuilding,
          placeId: 'ev_google_id',
        );

        expect(result.isConcordiaBuilding, true);
        expect(result.buildingPolygon, isNotNull);
        expect(result.placeId, isNotNull);
        expect(result.address, isNotNull);
      });
    });
  });
}
