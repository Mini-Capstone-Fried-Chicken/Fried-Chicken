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

  static BuildingPolygon? _findBuildingByCode(String buildingCode) {
    final code = buildingCode.trim();
    if (code.isEmpty) return null;

    for (final item in buildingPolygons) {
      if (item.code.toUpperCase() == code.toUpperCase()) {
        return item;
      }
    }

    return null;
  }

  static SavedPlace _toSavedPlace(
    BuildingPolygon building, {
    String? roomCode,
  }) {
    return SavedPlace(
      id: building.code,
      name: building.name.isNotEmpty ? building.name : building.code,
      category: 'all',
      latitude: building.center.latitude,
      longitude: building.center.longitude,
      openingHoursToday: 'Hours unavailable today',
      roomCode: roomCode?.trim().isEmpty == true ? null : roomCode?.trim(),
    );
  }

  /// Convenience helper to request directions to a Concordia building by its code.
  ///
  /// This reuses the existing directions pipeline in `OutdoorMapPage` which listens
  /// to [notifier] and starts a route preview from the user's current location.
  static void requestDirectionsToBuildingCode(String buildingCode) {
    final building = _findBuildingByCode(buildingCode);
    if (building == null) return;

    requestDirections(_toSavedPlace(building));
  }

  /// Request directions to a building and prefill the destination room field.
  static void requestDirectionsToBuildingRoom({
    required String buildingCode,
    required String roomCode,
  }) {
    final building = _findBuildingByCode(buildingCode);
    if (building == null) return;

    requestDirections(_toSavedPlace(building, roomCode: roomCode));
  }

  static void clear() {
    notifier.value = null;
  }
}
