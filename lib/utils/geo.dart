import 'package:flutter/material.dart';
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

double polygonArea(List<LatLng> pts) {
  double area = 0;
  int j = pts.length - 1;

  for (int i = 0; i < pts.length; i++) {
    area +=
        (pts[j].longitude + pts[i].longitude) *
        (pts[j].latitude - pts[i].latitude);
    j = i;
  }
  return area.abs() / 2;
}

LatLng polygonCenter(List<LatLng> pts) {
  if (pts.isEmpty) {
    throw ArgumentError('polygonCenter: pts must not be empty');
  }
  if (pts.length < 3) return pts.first;

  // 1) average point
  double lat = 0;
  double lng = 0;
  for (final p in pts) {
    lat += p.latitude;
    lng += p.longitude;
  }
  final avg = LatLng(lat / pts.length, lng / pts.length);

  // if avg is inside polygon, use it
  if (pointInPolygon(avg, pts)) return avg;

  // 2) fallback: midpoint of longest diagonal that lies inside polygon
  double maxDist = 0;
  LatLng best = avg;

  for (int i = 0; i < pts.length; i++) {
    for (int j = i + 1; j < pts.length; j++) {
      final mid = LatLng(
        (pts[i].latitude + pts[j].latitude) / 2,
        (pts[i].longitude + pts[j].longitude) / 2,
      );

      final dist =
          (pts[i].latitude - pts[j].latitude) *
              (pts[i].latitude - pts[j].latitude) +
          (pts[i].longitude - pts[j].longitude) *
              (pts[i].longitude - pts[j].longitude);

      if (dist > maxDist && pointInPolygon(mid, pts)) {
        maxDist = dist;
        best = mid;
      }
    }
  }

  return best;
}

LatLngBounds calculateBounds(List<LatLng> points) {
  if (points.isEmpty) {
    throw ArgumentError('calculateBounds: points must not be empty');
  }

  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;

  for (final p in points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

Color? parseHexColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;

  final normalized = hex.trim().replaceFirst('#', '');
  if (normalized.length != 6) return null;

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;

  return Color(0xFF000000 | value);
}