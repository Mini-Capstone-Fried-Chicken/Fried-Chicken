class IndoorFloorOption {
  final String label;     // what user sees (ex: "1", "2", "8")
  final String assetPath; // geojson asset path

  const IndoorFloorOption({
    required this.label,
    required this.assetPath,
  });
}

class IndoorFloorConfig {
  static const Map<String, List<IndoorFloorOption>> _floorsByBuilding = {
    'HALL': [
      IndoorFloorOption(label: '1', assetPath: 'assets/indoor_maps/geojson/Hall/h1.geojson.json'),
      IndoorFloorOption(label: '2', assetPath: 'assets/indoor_maps/geojson/Hall/h2.geojson.json'),
      IndoorFloorOption(label: '8', assetPath: 'assets/indoor_maps/geojson/Hall/h8.geojson.json'),
      IndoorFloorOption(label: '9', assetPath: 'assets/indoor_maps/geojson/Hall/h9.geojson.json'),
    ],
    'MB': [
      IndoorFloorOption(label: '1', assetPath: 'assets/indoor_maps/geojson/MB/mb1.geojson.json'),
      IndoorFloorOption(label: '2', assetPath: 'assets/indoor_maps/geojson/MB/mb2.geojson.json'),
    ],
    'VE': [
      IndoorFloorOption(label: '1', assetPath: 'assets/indoor_maps/geojson/VE/ve1.geojson.json'),
      IndoorFloorOption(label: '2', assetPath: 'assets/indoor_maps/geojson/VE/ve2.geojson.json'),
    ],
    'VL': [
      IndoorFloorOption(label: '1', assetPath: 'assets/indoor_maps/geojson/VL/vl1.geojson.json'),
      IndoorFloorOption(label: '2', assetPath: 'assets/indoor_maps/geojson/VL/vl2.geojson.json'),
    ],
    'CC': [
      IndoorFloorOption(label: '1', assetPath: 'assets/indoor_maps/geojson/CC/cc1.geojson.json'),
    ],
  };

  static List<IndoorFloorOption> floorsForBuilding(String code) {
    final key = code.toUpperCase().trim();
    return _floorsByBuilding[key] ?? const [];
  }
}