class IndoorFloorOption {
  final String label; // what user sees (ex: "1", "2", "8")
  final String assetPath; // geojson asset path

  const IndoorFloorOption({required this.label, required this.assetPath});
}

class IndoorFloorConfig {
  static const Map<String, List<IndoorFloorOption>> _floorsByBuilding = {
    'HALL': [
      IndoorFloorOption(
        label: '1',
        assetPath: 'assets/indoor_maps/geojson/Hall/h1.geojson.json',
      ),
      IndoorFloorOption(
        label: '2',
        assetPath: 'assets/indoor_maps/geojson/Hall/h2.geojson.json',
      ),
      IndoorFloorOption(
        label: '8',
        assetPath: 'assets/indoor_maps/geojson/Hall/h8.geojson.json',
      ),
      IndoorFloorOption(
        label: '9',
        assetPath: 'assets/indoor_maps/geojson/Hall/h9.geojson.json',
      ),
    ],
    'MB': [
      IndoorFloorOption(
        label: '1',
        assetPath: 'assets/indoor_maps/geojson/MB/mb1.geojson.json',
      ),
      IndoorFloorOption(
        label: 'S2',
        assetPath: 'assets/indoor_maps/geojson/MB/mbS2.geojson.json',
      ),
    ],
    'VE': [
      IndoorFloorOption(
        label: '1',
        assetPath: 'assets/indoor_maps/geojson/VE/ve1.geojson.json',
      ),
      IndoorFloorOption(
        label: '2',
        assetPath: 'assets/indoor_maps/geojson/VE/ve2.geojson.json',
      ),
    ],
    'VL': [
      IndoorFloorOption(
        label: '1',
        assetPath: 'assets/indoor_maps/geojson/VL/vl1.geojson.json',
      ),
      IndoorFloorOption(
        label: '2',
        assetPath: 'assets/indoor_maps/geojson/VL/vl2.geojson.json',
      ),
    ],
    'CC': [
      IndoorFloorOption(
        label: '1',
        assetPath: 'assets/indoor_maps/geojson/CC/cc1.geojson.json',
      ),
    ],
  };

  static List<IndoorFloorOption> floorsForBuilding(String code) {
    final key = code.toUpperCase().trim();
    return _floorsByBuilding[key] ?? const [];
  }

  static IndoorFloorOption? optionForAssetPath(
    String buildingCode,
    String assetPath,
  ) {
    for (final option in floorsForBuilding(buildingCode)) {
      if (option.assetPath == assetPath) {
        return option;
      }
    }
    return null;
  }

  static String normalizeFloorLabel(String label) {
    final normalized = label.trim().toUpperCase();
    if (normalized == 'S2') return '-2';
    if (normalized == 'B2') return '-2';
    if (normalized == 'S1') return '-1';
    if (normalized == 'B1') return '-1';
    return normalized;
  }

  static bool matchesLevel({
    required IndoorFloorOption option,
    required String? level,
  }) {
    if (level == null || level.trim().isEmpty) {
      return false;
    }
    return normalizeFloorLabel(option.label) == normalizeFloorLabel(level);
  }
}
