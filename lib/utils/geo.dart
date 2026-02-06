import 'package:google_maps_flutter/google_maps_flutter.dart';

bool pointInPolygon(LatLng point, List<LatLng> polygon) {
  // Ray casting algorithm
  final x = point.longitude;
  final y = point.latitude;

  bool inside = false;

  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].longitude, yi = polygon[i].latitude;
    final xj = polygon[j].longitude, yj = polygon[j].latitude;

    final intersect = ((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);

    if (intersect) inside = !inside;
  }

  return inside;
}