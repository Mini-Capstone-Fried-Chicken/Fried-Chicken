class IndoorFloorOption {
  final String label;
  final String assetPath;

  const IndoorFloorOption({required this.label, required this.assetPath});
}

class IndoorFloorConfig {
  static List<IndoorFloorOption> floorsForBuilding(String buildingCode) {
    switch (buildingCode.toUpperCase()) {
      case 'HALL':
        return const [
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
        ];

      case 'MB':
        return const [
          IndoorFloorOption(
            label: '1',
            assetPath: 'assets/indoor_maps/geojson/MB/mb1.geojson.json',
          ),
          IndoorFloorOption(
            label: '2',
            assetPath: 'assets/indoor_maps/geojson/MB/mbS2.geojson.json',
          ),
        ];

      case 'VE':
        return const [
          IndoorFloorOption(
            label: '1',
            assetPath: 'assets/indoor_maps/geojson/VE/ve1.geojson.json',
          ),
          IndoorFloorOption(
            label: '2',
            assetPath: 'assets/indoor_maps/geojson/VE/ve2.geojson.json',
          ),
        ];

      case 'VL':
        return const [
          IndoorFloorOption(
            label: '1',
            assetPath: 'assets/indoor_maps/geojson/VL/vl1.geojson.json',
          ),
          IndoorFloorOption(
            label: '2',
            assetPath: 'assets/indoor_maps/geojson/VL/vl2.geojson.json',
          ),
        ];

      case 'CC':
        return const [
          IndoorFloorOption(
            label: '1',
            assetPath: 'assets/indoor_maps/geojson/CC/cc1.geojson.json',
          ),
        ];

      default:
        return const [];
    }
  }
}
