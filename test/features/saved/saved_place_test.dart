import 'package:campus_app/features/saved/saved_place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedPlace', () {
    test('copyWith updates selected fields and keeps others', () {
      const original = SavedPlace(
        id: 'p1',
        name: 'Original',
        category: 'restaurant',
        latitude: 45.497,
        longitude: -73.579,
        openingHoursToday: 'Open today: 8:00 AM - 8:00 PM',
        googlePlaceType: 'restaurant',
      );

      final updated = original.copyWith(
        const SavedPlaceChanges(name: 'Updated', category: 'cafe'),
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated');
      expect(updated.category, 'cafe');
      expect(updated.latitude, original.latitude);
      expect(updated.longitude, original.longitude);
      expect(updated.openingHoursToday, original.openingHoursToday);
      expect(updated.googlePlaceType, original.googlePlaceType);
    });

    test('toJson serializes all fields including optional type', () {
      const place = SavedPlace(
        id: 'p2',
        name: 'Cafe',
        category: 'cafe',
        latitude: 45.5,
        longitude: -73.6,
        openingHoursToday: 'Open today: 9:00 AM - 6:00 PM',
        googlePlaceType: 'internet_cafe',
      );

      final json = place.toJson();

      expect(json['id'], 'p2');
      expect(json['name'], 'Cafe');
      expect(json['category'], 'cafe');
      expect(json['latitude'], 45.5);
      expect(json['longitude'], -73.6);
      expect(json['openingHoursToday'], 'Open today: 9:00 AM - 6:00 PM');
      expect(json['googlePlaceType'], 'internet_cafe');
    });

    test('fromJson parses valid data', () {
      final place = SavedPlace.fromJson(<String, dynamic>{
        'id': 'p3',
        'name': 'Library',
        'category': 'concordia building',
        'latitude': 45.49,
        'longitude': -73.58,
        'openingHoursToday': 'Open today: 7:00 AM - 11:00 PM',
        'googlePlaceType': 'university',
      });

      expect(place.id, 'p3');
      expect(place.name, 'Library');
      expect(place.category, 'concordia building');
      expect(place.latitude, 45.49);
      expect(place.longitude, -73.58);
      expect(place.openingHoursToday, 'Open today: 7:00 AM - 11:00 PM');
      expect(place.googlePlaceType, 'university');
    });

    test('fromJson applies defaults for missing fields', () {
      final place = SavedPlace.fromJson(<String, dynamic>{});

      expect(place.id, '');
      expect(place.name, '');
      expect(place.category, 'all');
      expect(place.latitude, 0);
      expect(place.longitude, 0);
      expect(place.openingHoursToday, 'Hours unavailable today');
      expect(place.googlePlaceType, isNull);
    });
  });
}
