import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/services/google_places_service.dart';

typedef SavedPlaceMetadataResolver = Future<PlaceResult?> Function({
  required String query,
  required LatLng location,
});

const String _concordiaBuildingCategory = 'concordia building';

class SavedPlaceMetadataService {
  SavedPlaceMetadataService._();

  static Future<SavedPlace> enrichFromGoogle(
    SavedPlace place, {
    SavedPlaceMetadataResolver? metadataResolver,
  }) async {
    final isConcordiaBuilding = _isConcordiaBuildingFromKnownList(place);
    final resolver = metadataResolver ??
        ({required String query, required LatLng location}) {
          return GooglePlacesService.instance.resolvePlaceMetadata(
            query: query,
            location: location,
          );
        };

    try {
      final metadata = await resolver(
        query: place.name,
        location: LatLng(place.latitude, place.longitude),
      );

      if (metadata == null) {
        if (isConcordiaBuilding) {
          return place.copyWith(category: _concordiaBuildingCategory);
        }
        return place;
      }

      final category = _categoryFromGoogleTypes(
        primaryType: metadata.primaryType,
        types: metadata.types,
      );

      final openingHours = _todayOpeningHours(metadata.weekdayDescriptions);

      final resolvedCategory = isConcordiaBuilding
          ? _concordiaBuildingCategory
          : (category ?? place.category);

      return place.copyWith(
        category: resolvedCategory,
        openingHoursToday: openingHours ?? place.openingHoursToday,
        googlePlaceType: metadata.primaryType,
      );
    } catch (_) {
      if (isConcordiaBuilding) {
        return place.copyWith(category: _concordiaBuildingCategory);
      }
      return place;
    }
  }

  static bool _isConcordiaBuildingFromKnownList(SavedPlace place) {
    final normalizedId = place.id.trim().toLowerCase();
    final normalizedName = place.name.trim().toLowerCase();

    for (final building in concordiaBuildingNames) {
      if (building.code.trim().toLowerCase() == normalizedId) {
        return true;
      }
      if (building.name.trim().toLowerCase() == normalizedName) {
        return true;
      }
    }

    return false;
  }

  static String? _categoryFromGoogleTypes({
    required String? primaryType,
    required List<String> types,
  }) {
    final normalizedPrimary = _normalizeCategory(primaryType);
    if (normalizedPrimary != null) return normalizedPrimary;

    for (final type in types) {
      final normalizedType = _normalizeCategory(type);
      if (normalizedType != null) return normalizedType;
    }

    return null;
  }

  static String? _normalizeCategory(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final tokenized = trimmed.toLowerCase().replaceAll('-', '_');

    // Collapse cuisine-specific restaurant subtypes (e.g. japanese_restaurant)
    // into a broad category so filters remain useful.
    if (tokenized == 'restaurant' || tokenized.endsWith('_restaurant')) {
      return 'restaurant';
    }

    if (tokenized == 'cafe' || tokenized.endsWith('_cafe')) {
      return 'cafe';
    }

    if (tokenized == 'bar' || tokenized.endsWith('_bar')) {
      return 'bar';
    }

    if (tokenized == 'university' || tokenized == 'school' || tokenized == 'college') {
      return _concordiaBuildingCategory;
    }

    return tokenized.replaceAll('_', ' ');
  }

  static String? _todayOpeningHours(List<String> weekdayDescriptions) {
    if (weekdayDescriptions.isEmpty) return null;

    const names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final weekdayName = names[DateTime.now().weekday - 1];

    for (final row in weekdayDescriptions) {
      if (row.toLowerCase().startsWith(weekdayName.toLowerCase())) {
        final idx = row.indexOf(':');
        if (idx < 0 || idx + 1 >= row.length) {
          return 'Open today: $row';
        }
        return 'Open today:${row.substring(idx + 1)}';
      }
    }

    return null;
  }
}
