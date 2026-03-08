import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_app/services/google_places_service.dart';

/// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final http.Response Function(http.Request request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('GooglePlacesService Coverage Tests', () {
    group('searchPlaces method', () {
      test('returns empty list when query is empty', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Should not be called');
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('');

        expect(result, isEmpty);
      });

      test('returns empty list when query is only whitespace', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Should not be called');
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('   ');

        expect(result, isEmpty);
      });

      test('returns places when API returns valid response', () async {
        final mockClient = MockHttpClient((request) {
          expect(request.method, 'POST');
          expect(request.url.path, contains('/places:searchText'));

          final body = json.decode(request.body);
          expect(body['textQuery'], 'test query');

          return http.Response(
            json.encode({
              'places': [
                {
                  'id': 'place1',
                  'displayName': {'text': 'Test Place 1'},
                  'formattedAddress': '123 Test St',
                  'location': {'latitude': 45.5, 'longitude': -73.5},
                },
                {
                  'id': 'place2',
                  'displayName': {'text': 'Test Place 2'},
                  'location': {'latitude': 45.6, 'longitude': -73.6},
                },
              ],
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('test query');

        expect(result, hasLength(2));
        expect(result[0].placeId, 'place1');
        expect(result[0].name, 'Test Place 1');
        expect(result[0].formattedAddress, '123 Test St');
        expect(result[0].location.latitude, 45.5);
        expect(result[0].location.longitude, -73.5);
      });

      test('includes location bias when location provided', () async {
        final mockClient = MockHttpClient((request) {
          final body = json.decode(request.body);
          expect(body['locationBias'], isNotNull);
          expect(body['locationBias']['circle']['center']['latitude'], 45.5);
          expect(body['locationBias']['circle']['center']['longitude'], -73.5);
          expect(body['locationBias']['circle']['radius'], 5000.0);

          return http.Response(json.encode({'places': []}), 200);
        });

        final service = GooglePlacesService(client: mockClient);
        await service.searchPlaces(
          'test',
          location: const LatLng(45.5, -73.5),
          radius: 5000,
        );
      });

      test('returns empty list when no places in response', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(json.encode({}), 200);
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('test');

        expect(result, isEmpty);
      });

      test('returns empty list when places array is null', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(json.encode({'places': null}), 200);
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('test');

        expect(result, isEmpty);
      });

      test('handles HTTP errors gracefully', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response('Error', 404);
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('test');

        expect(result, isEmpty);
      });

      test('handles exceptions gracefully', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Network error');
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('test');

        expect(result, isEmpty);
      });

      test('handles missing optional fields', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'places': [
                {
                  'id': 'place1',
                  'location': {'latitude': 45.5, 'longitude': -73.5},
                },
              ],
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.searchPlaces('test');

        expect(result, hasLength(1));
        expect(result[0].name, 'Unknown');
      });
    });

    group('getPlaceDetails method', () {
      test('returns place details when API returns valid response', () async {
        final mockClient = MockHttpClient((request) {
          expect(request.method, 'GET');
          expect(request.url.path, contains('/places/ChIJ123'));

          return http.Response(
            json.encode({
              'id': 'ChIJ123',
              'displayName': {'text': 'Test Place'},
              'formattedAddress': '123 Test St',
              'location': {'latitude': 45.5, 'longitude': -73.5},
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getPlaceDetails('ChIJ123');

        expect(result, isNotNull);
        expect(result!.placeId, 'ChIJ123');
        expect(result.name, 'Test Place');
        expect(result.formattedAddress, '123 Test St');
        expect(result.location.latitude, 45.5);
        expect(result.location.longitude, -73.5);
      });

      test('adds places/ prefix when not present', () async {
        final mockClient = MockHttpClient((request) {
          expect(request.url.path, contains('/places/ChIJ123'));
          return http.Response(
            json.encode({
              'id': 'ChIJ123',
              'displayName': {'text': 'Test Place'},
              'location': {'latitude': 45.5, 'longitude': -73.5},
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        await service.getPlaceDetails('ChIJ123');
      });

      test('handles place ID that already has places/ prefix', () async {
        final mockClient = MockHttpClient((request) {
          expect(request.url.path, contains('/places/ChIJ456'));
          return http.Response(
            json.encode({
              'id': 'places/ChIJ456',
              'displayName': {'text': 'Test Place'},
              'location': {'latitude': 45.5, 'longitude': -73.5},
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        await service.getPlaceDetails('places/ChIJ456');
      });

      test('returns null when HTTP status is not 200', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response('Not Found', 404);
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getPlaceDetails('ChIJ123');

        expect(result, isNull);
      });

      test('returns null when exception occurs', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Network error');
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getPlaceDetails('ChIJ123');

        expect(result, isNull);
      });

      test('handles missing optional fields', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'location': {'latitude': 45.5, 'longitude': -73.5},
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getPlaceDetails('ChIJ123');

        expect(result, isNotNull);
        expect(result!.placeId, 'ChIJ123');
        expect(result.name, 'Unknown');
      });

      test('handles null location', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'id': 'ChIJ123',
              'displayName': {'text': 'Test Place'},
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getPlaceDetails('ChIJ123');

        expect(result, isNotNull);
        expect(result!.location.latitude, 0.0);
        expect(result.location.longitude, 0.0);
      });
    });

    group('getAutocompletePredictions method', () {
      test('returns empty list when query is empty', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Should not be called');
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('');

        expect(result, isEmpty);
      });

      test('returns empty list when query is only whitespace', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Should not be called');
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('   ');

        expect(result, isEmpty);
      });

      test('returns predictions when API returns valid response', () async {
        final mockClient = MockHttpClient((request) {
          expect(request.method, 'POST');
          expect(request.url.path, contains('/places:autocomplete'));

          final body = json.decode(request.body);
          expect(body['input'], 'test');
          expect(body['languageCode'], 'en');

          return http.Response(
            json.encode({
              'suggestions': [
                {
                  'placePrediction': {
                    'placeId': 'place1',
                    'text': {'text': 'Test Place 1'},
                    'structuredFormat': {
                      'mainText': {'text': 'Test Place 1'},
                      'secondaryText': {'text': 'Montreal, QC'},
                    },
                  },
                },
                {
                  'placePrediction': {
                    'place': 'place2',
                    'text': {'text': 'Test Place 2'},
                    'structuredFormat': {
                      'mainText': {'text': 'Test Place 2'},
                    },
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, hasLength(2));
        expect(result[0].placeId, 'place1');
        expect(result[0].description, 'Test Place 1');
        expect(result[0].mainText, 'Test Place 1');
        expect(result[0].secondaryText, 'Montreal, QC');
      });

      test('uses custom location bias when provided', () async {
        final mockClient = MockHttpClient((request) {
          final body = json.decode(request.body);
          expect(body['locationBias']['circle']['center']['latitude'], 45.5);
          expect(body['locationBias']['circle']['center']['longitude'], -73.5);
          expect(body['locationBias']['circle']['radius'], 3000.0);

          return http.Response(json.encode({'suggestions': []}), 200);
        });

        final service = GooglePlacesService(client: mockClient);
        await service.getAutocompletePredictions(
          'test',
          location: const LatLng(45.5, -73.5),
          radius: 3000,
        );
      });

      test(
        'uses default Concordia location bias when no location provided',
        () async {
          final mockClient = MockHttpClient((request) {
            final body = json.decode(request.body);
            expect(
              body['locationBias']['circle']['center']['latitude'],
              45.4958,
            );
            expect(
              body['locationBias']['circle']['center']['longitude'],
              -73.5711,
            );
            expect(body['locationBias']['circle']['radius'], 15000.0);

            return http.Response(json.encode({'suggestions': []}), 200);
          });

          final service = GooglePlacesService(client: mockClient);
          await service.getAutocompletePredictions('test');
        },
      );

      test('returns empty list when no suggestions in response', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(json.encode({}), 200);
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, isEmpty);
      });

      test('handles HTTP errors gracefully', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response('Error', 500);
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, isEmpty);
      });

      test('handles malformed JSON gracefully', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response('Not valid JSON', 200);
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, isEmpty);
      });

      test('handles exceptions gracefully', () async {
        final mockClient = MockHttpClient((request) {
          throw Exception('Network error');
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, isEmpty);
      });

      test('handles suggestion without placePrediction field', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'suggestions': [
                {'otherField': 'value'},
              ],
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, isEmpty);
      });

      test('handles missing optional fields in predictions', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'suggestions': [
                {
                  'placePrediction': {'placeId': 'place1'},
                },
              ],
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, hasLength(1));
        expect(result[0].placeId, 'place1');
        expect(result[0].description, '');
        expect(result[0].mainText, '');
      });

      test('handles error in API response', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'error': {'code': 400, 'message': 'Invalid request'},
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, isEmpty);
      });

      test('handles suggestion parsing error', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'suggestions': [
                {
                  'placePrediction': {
                    'placeId': 'place1',
                    'text': {'text': 'Valid Place'},
                    'structuredFormat': {
                      'mainText': {'text': 'Valid'},
                    },
                  },
                },
                {'placePrediction': 'invalid'},
              ],
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, hasLength(1));
        expect(result[0].mainText, 'Valid');
      });

      test('handles text field fallback chain', () async {
        final mockClient = MockHttpClient((request) {
          return http.Response(
            json.encode({
              'suggestions': [
                {
                  'placePrediction': {
                    'placeId': 'place1',
                    'text': {'text': 'Fallback Text'},
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = GooglePlacesService(client: mockClient);
        final result = await service.getAutocompletePredictions('test');

        expect(result, hasLength(1));
        expect(result[0].mainText, 'Fallback Text');
      });
    });

    group('PlacePrediction class', () {
      test('fromJson creates prediction correctly', () {
        final json = {
          'place_id': 'ChIJ123',
          'description': 'Test Place, Montreal',
          'structured_formatting': {
            'main_text': 'Test Place',
            'secondary_text': 'Montreal, QC',
          },
        };

        final prediction = PlacePrediction.fromJson(json);

        expect(prediction.placeId, 'ChIJ123');
        expect(prediction.description, 'Test Place, Montreal');
        expect(prediction.mainText, 'Test Place');
        expect(prediction.secondaryText, 'Montreal, QC');
      });

      test('fromJson handles missing structured_formatting', () {
        final json = {'place_id': 'ChIJ123', 'description': 'Test Place'};

        final prediction = PlacePrediction.fromJson(json);

        expect(prediction.placeId, 'ChIJ123');
        expect(prediction.description, 'Test Place');
        expect(prediction.mainText, 'Test Place');
        expect(prediction.secondaryText, isNull);
      });
    });
  });
}
