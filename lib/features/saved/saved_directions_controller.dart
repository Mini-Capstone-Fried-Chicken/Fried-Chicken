import 'package:flutter/foundation.dart';

import '../../data/building_polygons.dart';
import 'saved_place.dart';

class SavedDirectionsController {
  SavedDirectionsController._();

  static final ValueNotifier<SavedPlace?> notifier = ValueNotifier<SavedPlace?>(
    null,
  );

  static void requestDirections(SavedPlace place) {
    notifier.value = place;
  }

  /// Convenience helper to request directions to a Concordia building by its code.
  ///
  /// This reuses the existing directions pipeline in `OutdoorMapPage` which listens
  /// to [notifier] and starts a route preview from the user's current location.
  static void requestDirectionsToBuildingCode(String buildingCode) {
    final code = buildingCode.trim();
    if (code.isEmpty) return;

    BuildingPolygon? building;
    for (final item in buildingPolygons) {
      if (item.code.toUpperCase() == code.toUpperCase()) {
        building = item;
        break;
      }
    }
    if (building == null) return;

    requestDirections(
      SavedPlace(
        id: building.code,
        name: building.name.isNotEmpty ? building.name : building.code,
        category: 'all',
        latitude: building.center.latitude,
        longitude: building.center.longitude,
        openingHoursToday: 'Hours unavailable today',
      ),
    );
  }

  /// Request directions to a building and prefill the destination room field.
  ///
  /// Uses the same Explore directions pipeline as [requestDirectionsToBuildingCode].
  /// The room is passed via the [SavedPlace.category] field to avoid changing the
  /// existing notifier payload type.
  static void requestDirectionsToBuildingRoom({
    required String buildingCode,
    required String roomCode,
  }) {
    final code = buildingCode.trim();
    final room = roomCode.trim();
    if (code.isEmpty) return;

    BuildingPolygon? building;
    for (final item in buildingPolygons) {
      if (item.code.toUpperCase() == code.toUpperCase()) {
        building = item;
        break;
      }
    }
    if (building == null) return;

    requestDirections(
      SavedPlace(
        id: building.code,
        name: building.name.isNotEmpty ? building.name : building.code,
        category: 'all',
        latitude: building.center.latitude,
        longitude: building.center.longitude,
        openingHoursToday: 'Hours unavailable today',
        roomCode: room,
      ),
    );
  }

  static void clear() {
    notifier.value = null;
  }
}
