class SavedPlace {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String openingHoursToday;
  final String? googlePlaceType;

  const SavedPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.openingHoursToday,
    this.googlePlaceType,
  });

  SavedPlace copyWith({
    String? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    String? openingHoursToday,
    String? googlePlaceType,
  }) {
    return SavedPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingHoursToday: openingHoursToday ?? this.openingHoursToday,
      googlePlaceType: googlePlaceType ?? this.googlePlaceType,
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
    };
  }

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      category: (json['category'] ?? 'all') as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      openingHoursToday: (json['openingHoursToday'] ?? 'Hours unavailable today') as String,
      googlePlaceType: json['googlePlaceType'] as String?,
    );
  }
}
