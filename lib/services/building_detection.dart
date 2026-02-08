import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/building_polygons.dart';

/// Ray-casting point in polygon.
/// Returns true if [point] is inside [polygon].
bool pointInPolygon(LatLng point, List<LatLng> polygon) {
  bool inside = false;

  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].latitude;
    final yi = polygon[i].longitude;
    final xj = polygon[j].latitude;
    final yj = polygon[j].longitude;

    final intersects = ((yi > point.longitude) != (yj > point.longitude)) &&
        (point.latitude <
            (xj - xi) *
                    (point.longitude - yi) /
                    ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                xi);

    if (intersects) inside = !inside;
  }

  return inside;
}

/// Finds the building polygon containing [userLocation], else null.
BuildingPolygon? detectBuildingPoly(LatLng userLocation) {
  for (final b in buildingPolygons) {
    if (pointInPolygon(userLocation, b.points)) return b;
  }
  return null;
}