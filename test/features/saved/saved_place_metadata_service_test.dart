import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_place_metadata_service.dart';
import 'package:campus_app/services/google_places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('SavedPlaceMetadataService', () {
    SavedPlace basePlace({
      String id = 'external_place_id',
      String name = 'Sample Place',
    }) {
      return SavedPlace(
        id: id,
        name: name,
        category: 'all',
        latitude: 45.497,
        longitude: -73.579,
        openingHoursToday: 'Open today: Hours unavailable',
      );
    }

    List<String> weekHours() {
      return const <String>[
        'Monday: 8:00 AM - 8:00 PM',
        'Tuesday: 8:00 AM - 8:00 PM',
        'Wednesday: 8:00 AM - 8:00 PM',
        'Thursday: 8:00 AM - 8:00 PM',
        'Friday: 8:00 AM - 8:00 PM',
        'Saturday: 10:00 AM - 6:00 PM',
        'Sunday: Closed',
      ];
    }

    test('collapses cuisine-specific restaurant categories', () async {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'p1',
            name: 'Sushi Spot',
            location: const LatLng(45.497, -73.579),
            primaryType: 'japanese_restaurant',
            types: const <String>['point_of_interest'],
            weekdayDescriptions: weekHours(),
          );
        },
      );

      expect(enriched.category, 'restaurant');
    });

    test('forces concordia building category when id matches building code', () async {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(id: 'HALL', name: 'Hall Building'),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'p2',
            name: 'Hall Building',
            location: const LatLng(45.497, -73.579),
            primaryType: 'restaurant',
            types: const <String>['restaurant'],
            weekdayDescriptions: weekHours(),
          );
        },
      );

      expect(enriched.category, 'concordia building');
    });

    test('forces concordia building category when metadata is unavailable', () async {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(id: 'MB', name: 'JSMB Building'),
        metadataResolver: ({required query, required location}) async => null,
      );

      expect(enriched.category, 'concordia building');
    });

    test('forces concordia building category when name matches known list', () async {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(id: 'external', name: 'Hall Building'),
        metadataResolver: ({required query, required location}) async => null,
      );

      expect(enriched.category, 'concordia building');
    });

    test('updates opening hours from current weekday descriptions when present', () async {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'p3',
            name: 'Coffee Place',
            location: const LatLng(45.497, -73.579),
            primaryType: 'cafe',
            types: const <String>['food'],
            weekdayDescriptions: weekHours(),
          );
        },
      );

      expect(enriched.openingHoursToday.startsWith('Open today:'), isTrue);
      expect(enriched.openingHoursToday, isNot('Open today: Hours unavailable'));
    });

    test('normalizes cafe and bar subtype categories', () async {
      final cafe = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(id: 'c1'),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'c1',
            name: 'Cafe Place',
            location: const LatLng(45.497, -73.579),
            primaryType: 'internet_cafe',
            types: const <String>[],
            weekdayDescriptions: const <String>[],
          );
        },
      );

      final bar = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(id: 'b1'),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'b1',
            name: 'Bar Place',
            location: const LatLng(45.497, -73.579),
            primaryType: 'sports_bar',
            types: const <String>[],
            weekdayDescriptions: const <String>[],
          );
        },
      );

      expect(cafe.category, 'cafe');
      expect(bar.category, 'bar');
    });

    test('uses types fallback when primary type is absent', () async {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'p4',
            name: 'Fallback Type Place',
            location: const LatLng(45.497, -73.579),
            primaryType: null,
            types: const <String>['japanese_restaurant'],
            weekdayDescriptions: const <String>[],
          );
        },
      );

      expect(enriched.category, 'restaurant');
    });

    test('maps school/university categories to concordia building label', () async {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'p5',
            name: 'Campus',
            location: const LatLng(45.497, -73.579),
            primaryType: 'university',
            types: const <String>[],
            weekdayDescriptions: const <String>[],
          );
        },
      );

      expect(enriched.category, 'concordia building');
    });

    test('keeps original opening hours when current day row does not match', () async {
      const originalHours = 'Open today: Hours unavailable';
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace().copyWith(openingHoursToday: originalHours),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'p6',
            name: 'No Match Place',
            location: const LatLng(45.497, -73.579),
            primaryType: 'restaurant',
            types: const <String>[],
            weekdayDescriptions: const <String>['Funday: 9:00 AM - 5:00 PM'],
          );
        },
      );

      expect(enriched.openingHoursToday, originalHours);
    });

    test('supports opening-hours rows without colon separator', () async {
      final dayNames = const <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final today = dayNames[DateTime.now().weekday - 1];

      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        basePlace(),
        metadataResolver: ({required query, required location}) async {
          return PlaceResult(
            placeId: 'p7',
            name: 'No Colon Place',
            location: const LatLng(45.497, -73.579),
            primaryType: 'restaurant',
            types: const <String>[],
            weekdayDescriptions: <String>['$today Open 24 hours'],
          );
        },
      );

      expect(enriched.openingHoursToday, startsWith('Open today: '));
    });

    test('keeps original values when resolver throws for non-concordia place', () async {
      final original = basePlace();
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
        original,
        metadataResolver: ({required query, required location}) {
          throw Exception('network failure');
        },
      );

      expect(enriched.category, original.category);
      expect(enriched.openingHoursToday, original.openingHoursToday);
    });
  });
}
