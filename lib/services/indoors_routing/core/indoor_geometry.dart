import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../utils/geo.dart' as geo;

class IndoorGeometry {
  const IndoorGeometry();

  bool areSameLatLng(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 1e-12 &&
        (a.longitude - b.longitude).abs() < 1e-12;
  }

  List<LatLng> removeConsecutiveDuplicatePoints(List<LatLng> points) {
    if (points.length <= 1) return points;

    final cleaned = <LatLng>[points.first];

    for (int i = 1; i < points.length; i++) {
      if (!areSameLatLng(cleaned.last, points[i])) {
        cleaned.add(points[i]);
      }
    }

    return cleaned;
  }

  double distanceMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
    final dLng = (b.longitude - a.longitude) * (math.pi / 180.0);
    final lat1 = a.latitude * (math.pi / 180.0);
    final lat2 = b.latitude * (math.pi / 180.0);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return earthRadiusMeters * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double distanceScore(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }

  bool segmentInsidePolygon(
    LatLng a,
    LatLng b,
    List<LatLng> polygon, {
    required int minSamples,
    required double sampleSpacingMeters,
  }) {
    final adaptiveSamples = math.max(
      minSamples,
      (distanceMeters(a, b) / sampleSpacingMeters).ceil(),
    );

    for (int i = 1; i < adaptiveSamples; i++) {
      final t = i / adaptiveSamples;
      final p = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

      if (!geo.pointInPolygon(p, polygon)) return false;
    }

    return true;
  }

  bool segmentInsideCorridor({
    required LatLng a,
    required LatLng b,
    required List<LatLng> corridorPolygon,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
    required int minSamples,
    required double sampleSpacingMeters,
  }) {
    if (!segmentInsidePolygon(
      a,
      b,
      corridorPolygon,
      minSamples: minSamples,
      sampleSpacingMeters: sampleSpacingMeters,
    )) {
      return false;
    }

    if (!avoidBlockedRooms || blockedRoomPolygons.isEmpty) {
      return true;
    }

    for (int i = 1; i < minSamples; i++) {
      final t = i / minSamples;
      final p = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

      for (final roomPolygon in blockedRoomPolygons) {
        if (geo.pointInPolygon(p, roomPolygon)) {
          return false;
        }
      }
    }

    return true;
  }

  double polylineLengthMeters(List<LatLng> pts) {
    if (pts.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < pts.length; i++) {
      total += distanceMeters(pts[i - 1], pts[i]);
    }
    return total;
  }
}
