import '../../indoor/data/building_info.dart';
import '../../../data/building_names.dart';

String resolveBuildingCode(String? location) {
  final rawLocation = (location ?? '').trim();
  if (rawLocation.isEmpty) return '';

  final buildingQuery = extractBuildingQuery(rawLocation);
  if (buildingQuery.isEmpty) return '';

  final normalizedQuery = normalizeBuildingValue(buildingQuery);

  for (final code in buildingInfoByCode.keys) {
    if (normalizeBuildingValue(code) == normalizedQuery) {
      return code;
    }
  }

  for (final building in concordiaBuildingNames) {
    if (normalizeBuildingValue(building.code) == normalizedQuery) {
      return building.code;
    }

    if (normalizeBuildingValue(building.name) == normalizedQuery) {
      return building.code;
    }

    for (final term in building.searchTerms) {
      if (normalizeBuildingValue(term) == normalizedQuery) {
        return building.code;
      }
    }
  }

  return '';
}

String extractBuildingQuery(String rawLocation) {
  final upper = rawLocation.trim().toUpperCase();

  final dashMatch = RegExp(r'^([A-Z]+)\s*-\s*').firstMatch(upper);
  if (dashMatch != null) {
    final token = dashMatch.group(1)!;
    return normalizeSpecialBuildingCode(token);
  }

  final spaceMatch = RegExp(r'^([A-Z]+)\s+\d').firstMatch(upper);
  if (spaceMatch != null) {
    final token = spaceMatch.group(1)!;
    return normalizeSpecialBuildingCode(token);
  }

  return normalizeSpecialBuildingCode(rawLocation);
}

String normalizeSpecialBuildingCode(String value) {
  final upper = value.trim().toUpperCase();

  if (upper == 'H') return 'HALL';

  return upper;
}

String normalizeBuildingValue(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
