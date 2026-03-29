class SavedPlace {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String openingHoursToday;
  final String? googlePlaceType;

  /// Optional destination room code to prefill in Explore's route preview.
  ///
  /// This is used by Calendar "Go to Room" and should not be confused with
  /// [category] which is metadata for Saved places (e.g. "concordia building").
  final String? roomCode;

  const SavedPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.openingHoursToday,
    this.googlePlaceType,
    this.roomCode,
  });

  SavedPlace copyWith([SavedPlaceChanges changes = const SavedPlaceChanges()]) {
    return SavedPlace(
      id: changes.id ?? id,
      name: changes.name ?? name,
      category: changes.category ?? category,
      latitude: changes.latitude ?? latitude,
      longitude: changes.longitude ?? longitude,
      openingHoursToday: changes.openingHoursToday ?? openingHoursToday,
      googlePlaceType: changes.googlePlaceType is _UnsetValue
          ? googlePlaceType
          : changes.googlePlaceType as String?,
      roomCode: changes.roomCode is _UnsetValue
          ? roomCode
          : changes.roomCode as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'openingHoursToday': openingHoursToday,
      'googlePlaceType': googlePlaceType,
      'roomCode': roomCode,
    };
  }

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      category: (json['category'] ?? 'all') as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      openingHoursToday:
          (json['openingHoursToday'] ?? 'Hours unavailable today') as String,
      googlePlaceType: json['googlePlaceType'] as String?,
      roomCode: (json['roomCode'] as String?)?.trim().isEmpty == true
          ? null
          : json['roomCode'] as String?,
    );
  }
}

class SavedPlaceChanges {
  final String? id;
  final String? name;
  final String? category;
  final double? latitude;
  final double? longitude;
  final String? openingHoursToday;
  final Object? googlePlaceType;
  final Object? roomCode;

  const SavedPlaceChanges({
    this.id,
    this.name,
    this.category,
    this.latitude,
    this.longitude,
    this.openingHoursToday,
    this.googlePlaceType = _unsetValue,
    this.roomCode = _unsetValue,
  });
}

class _UnsetValue {
  const _UnsetValue();
}

const _unsetValue = _UnsetValue();
