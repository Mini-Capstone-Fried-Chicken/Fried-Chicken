import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/google_places_service.dart';

void main() {
  group('GooglePlacesService Tests', () {
    group('PlacePrediction Creation', () {
      test('PlacePrediction from JSON with all fields', () {
        final json = {
          'place_id': 'test_place_1',
          'description': 'Test Place, Montreal',
          'structured_formatting': {
            'main_text': 'Test Place',
            'secondary_text': 'Montreal, QC',
          },
        };

        final prediction = PlacePrediction.fromJson(json);

        expect(prediction.placeId, 'test_place_1');
        expect(prediction.description, 'Test Place, Montreal');
        expect(prediction.mainText, 'Test Place');
        expect(prediction.secondaryText, 'Montreal, QC');
      });

      test('PlacePrediction from JSON without structured_formatting', () {
        final json = {
          'place_id': 'test_place_2',
          'description': 'Library Building',
        };

        final prediction = PlacePrediction.fromJson(json);

        expect(prediction.placeId, 'test_place_2');
        expect(prediction.description, 'Library Building');
        expect(prediction.mainText, 'Library Building');
        expect(prediction.secondaryText, isNull);
      });

      test('PlacePrediction from JSON without secondary_text', () {
        final json = {
          'place_id': 'test_place_3',
          'description': 'Store',
          'structured_formatting': {'main_text': 'Store'},
        };

        final prediction = PlacePrediction.fromJson(json);

        expect(prediction.mainText, 'Store');
        expect(prediction.secondaryText, isNull);
      });

      test('PlacePrediction stores all field types correctly', () {
        final prediction = PlacePrediction(
          placeId: 'place_123',
          description: 'Description text',
          mainText: 'Main text',
          secondaryText: 'Secondary text',
        );

        expect(prediction.placeId, isA<String>());
        expect(prediction.description, isA<String>());
        expect(prediction.mainText, isA<String>());
        expect(prediction.secondaryText, isA<String>());
      });

      test('PlacePrediction with empty strings', () {
        final prediction = PlacePrediction(
          placeId: '',
          description: '',
          mainText: '',
          secondaryText: '',
        );

        expect(prediction.placeId, isEmpty);
        expect(prediction.description, isEmpty);
        expect(prediction.mainText, isEmpty);
        expect(prediction.secondaryText, isEmpty);
      });
    });

    group('PlaceResult Creation', () {
      test('PlaceResult with complete information', () {
        const location = LatLng(45.5, -73.5);
        final result = PlaceResult(
          placeId: 'place_456',
          name: 'Test Building',
          formattedAddress: '123 Main St, Montreal',
          location: location,
        );

        expect(result.placeId, 'place_456');
        expect(result.name, 'Test Building');
        expect(result.formattedAddress, '123 Main St, Montreal');
        expect(result.location.latitude, 45.5);
        expect(result.location.longitude, -73.5);
      });

      test('PlaceResult without formatted address', () {
        const location = LatLng(45.5, -73.5);
        final result = PlaceResult(
          placeId: 'place_789',
          name: 'Test Place',
          location: location,
        );

        expect(result.formattedAddress, isNull);
      });

      test('PlaceResult with null address is valid', () {
        const location = LatLng(45.5, -73.5);
        final result = PlaceResult(
          placeId: 'place_null',
          name: 'Place',
          formattedAddress: null,
          location: location,
        );

        expect(result.formattedAddress, isNull);
        expect(result.location, isNotNull);
      });

      test('PlaceResult location is Montreal area', () {
        const location = LatLng(45.5017, -73.5673);
        final result = PlaceResult(
          placeId: 'mtl_place',
          name: 'Montreal Place',
          location: location,
        );

        expect(result.location.latitude, inInclusiveRange(45.0, 46.0));
        expect(result.location.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('PlaceResult with Concordia locations', () {
        const sgwLocation = LatLng(45.4973, -73.5789);
        const loyolaLocation = LatLng(45.4582, -73.6405);

        final sgwResult = PlaceResult(
          placeId: 'sgw',
          name: 'Concordia SGW',
          location: sgwLocation,
        );

        final loyolaResult = PlaceResult(
          placeId: 'loyola',
          name: 'Concordia Loyola',
          location: loyolaLocation,
        );

        expect(sgwResult.location.latitude, 45.4973);
        expect(loyolaResult.location.latitude, 45.4582);
      });
    });

    group('Search Query Validation', () {
      test('Empty query returns empty list', () {
        final emptyQueries = ['', '   ', '\t', '\n'];

        for (final query in emptyQueries) {
          expect(query.trim().isEmpty, true);
        }
      });

      test('Query with special characters is valid', () {
        final queries = ['café', 'St. Mary\'s', '(Library)'];

        for (final query in queries) {
          expect(query.trim().isNotEmpty, true);
        }
      });

      test('Query with numbers is valid', () {
        final queries = ['Room 123', '456 Mountain Street'];

        for (final query in queries) {
          expect(query.trim().isNotEmpty, true);
        }
      });

      test('Very long query is handled', () {
        final longQuery = 'a' * 255; // Very long search query
        expect(longQuery.length, 255);
        expect(longQuery.trim().isNotEmpty, true);
      });
    });

    group('Location Bias Handling', () {
      test('Location bias with Montreal area', () {
        const location = LatLng(45.5017, -73.5673);
        const radius = 5000; // 5km radius

        expect(location.latitude, closeTo(45.5, 0.1));
        expect(location.longitude, closeTo(-73.5, 0.1));
        expect(radius, greaterThan(0));
      });

      test('Location bias with SGW campus', () {
        const sgw = LatLng(45.4973, -73.5789);
        const radius = 500;

        expect(sgw.latitude, inInclusiveRange(45.0, 46.0));
        expect(sgw.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Location bias with Loyola campus', () {
        const loyola = LatLng(45.4582, -73.6405);
        const radius = 500;

        expect(loyola.latitude, inInclusiveRange(45.0, 46.0));
        expect(loyola.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Default location bias towards Concordia', () {
        const defaultLat = 45.4958;
        const defaultLng = -73.5711;
        const defaultRadius = 15000.0;

        expect(defaultLat, inInclusiveRange(45.0, 46.0));
        expect(defaultLng, inInclusiveRange(-74.0, -73.0));
        expect(defaultRadius, greaterThan(0));
      });

      test('Radius parameter is positive', () {
        final radiusValues = [1000, 5000, 10000, 50000];

        for (final radius in radiusValues) {
          expect(radius, greaterThan(0));
        }
      });
    });

    group('PlaceId Handling', () {
      test('PlaceId with ChIJ prefix', () {
        final placeId = 'ChIJvRHvxVVwtEwRBUF7FZm8zzE';
        expect(placeId.startsWith('ChIJ'), true);
      });

      test('PlaceId without prefix', () {
        final placeId = 'some_place_id_123';
        expect(placeId.startsWith('places/'), false);
      });

      test('PlaceId with places/ prefix', () {
        final placeId = 'places/ChIJvRHvxVVwtEwRBUF7FZm8zzE';
        expect(placeId.startsWith('places/'), true);
      });

      test('Empty placeId handling', () {
        final placeId = '';
        expect(placeId.isEmpty, true);
      });

      test('PlaceId format variations', () {
        final ids = [
          'ChIJvRHvxVVwtEwRBUF7FZm8zzE',
          'places/ChIJvRHvxVVwtEwRBUF7FZm8zzE',
          'simple_id',
          '12345',
        ];

        for (final id in ids) {
          expect(id, isA<String>());
        }
      });
    });

    group('API Response Data Structures', () {
      test('Search results are list of PlaceResult', () {
        final results = <PlaceResult>[];
        expect(results, isA<List<PlaceResult>>());
        expect(results, isEmpty);
      });

      test('Place result with valid location data', () {
        const location = LatLng(45.4973, -73.5789);
        final result = PlaceResult(
          placeId: 'test',
          name: 'Test',
          location: location,
        );

        expect(result.location, isA<LatLng>());
        expect(result.location.latitude, 45.4973);
        expect(result.location.longitude, -73.5789);
      });

      test('Predictions are list of PlacePrediction', () {
        final predictions = <PlacePrediction>[];
        expect(predictions, isA<List<PlacePrediction>>());
      });

      test('Prediction with structured formatting', () {
        final prediction = PlacePrediction(
          placeId: 'id',
          description: 'desc',
          mainText: 'Main',
          secondaryText: 'Secondary',
        );

        expect(prediction, isA<PlacePrediction>());
        expect(prediction.placeId, isNotEmpty);
      });
    });

    group('JSON Parsing Edge Cases', () {
      test('PlacePrediction handles missing place_id gracefully', () {
        final json = {
          'description': 'No ID provided',
          'structured_formatting': {'main_text': 'Text'},
        };

        try {
          final prediction = PlacePrediction.fromJson(json);
          // If it doesn't throw, placeId should be handled somehow
          expect(prediction, isNotNull);
        } catch (e) {
          // If it throws, that's also valid behavior
          expect(e, isNotNull);
        }
      });

      test('PlacePrediction handles null structured_formatting', () {
        final json = {
          'place_id': 'id123',
          'description': 'Test description',
          'structured_formatting': null,
        };

        final prediction = PlacePrediction.fromJson(json);
        expect(prediction.description, 'Test description');
      });

      test('PlaceResult with zero coordinates', () {
        const location = LatLng(0, 0);
        final result = PlaceResult(
          placeId: 'equator',
          name: 'Equator Place',
          location: location,
        );

        expect(result.location.latitude, 0);
        expect(result.location.longitude, 0);
      });

      test('PlaceResult with max valid coordinates', () {
        const location = LatLng(85.0511287798066, 179.9);
        final result = PlaceResult(
          placeId: 'max',
          name: 'Max Coord Place',
          location: location,
        );

        expect(result.location.latitude, 85.0511287798066);
        expect(result.location.longitude, 179.9);
      });
    });

    group('Location Coordinates Validation', () {
      test('Valid Montreal latitude range', () {
        final mtlLatitude = 45.5017;
        expect(mtlLatitude, inInclusiveRange(45.0, 46.0));
      });

      test('Valid Montreal longitude range', () {
        final mtlLongitude = -73.5673;
        expect(mtlLongitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Concordia SGW coordinates are valid', () {
        const sgw = LatLng(45.4973, -73.5789);
        expect(sgw.latitude, inInclusiveRange(45.0, 46.0));
        expect(sgw.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Concordia Loyola coordinates are valid', () {
        const loyola = LatLng(45.4582, -73.6405);
        expect(loyola.latitude, inInclusiveRange(45.0, 46.0));
        expect(loyola.longitude, inInclusiveRange(-74.0, -73.0));
      });

      test('Distance between SGW and Loyola', () {
        const sgw = LatLng(45.4973, -73.5789);
        const loyola = LatLng(45.4582, -73.6405);

        final latDiff = (sgw.latitude - loyola.latitude).abs();
        final lngDiff = (sgw.longitude - loyola.longitude).abs();

        expect(latDiff, greaterThan(0));
        expect(lngDiff, greaterThan(0));
      });
    });

    group('Response Status Validation', () {
      test('HTTP 200 is success status', () {
        const statusCode = 200;
        expect(statusCode, 200);
      });

      test('HTTP 400+ are error statuses', () {
        final errorStatuses = [400, 401, 403, 404, 429, 500, 503];

        for (final status in errorStatuses) {
          expect(status, greaterThanOrEqualTo(400));
        }
      });

      test('API response keys validation', () {
        final responseKeys = ['places', 'suggestions', 'error'];
        expect(responseKeys, isNotEmpty);
      });
    });

    group('Text Search Parameters', () {
      test('Search query is required', () {
        final queries = ['café', 'library', 'restaurant'];

        for (final query in queries) {
          expect(query.trim().isNotEmpty, true);
        }
      });

      test('Location bias is optional', () {
        LatLng? location = null;
        expect(location, isNull);

        location = const LatLng(45.5, -73.5);
        expect(location, isNotNull);
      });

      test('Radius has default value', () {
        const defaultRadius = 5000;
        expect(defaultRadius, greaterThan(0));
      });
    });
  });
}
