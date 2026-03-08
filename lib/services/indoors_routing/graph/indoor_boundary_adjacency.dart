import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/indoor_routing_models.dart';

// Handles the geometry logic used to decide whether 2 polygons
// should be considered connected in the routing graph.
class IndoorBoundaryAdjacency {
  // Small tolerance for minor GeoJSON inaccuracies.
  static const double adjacencyEpsilonMeters = 0.25;

  // How often to sample along a polygon edge when estimating shared boundary.
  static const double boundarySampleStepMeters = 0.30;

  // Minimum shared boundary required for room <-> walkable connections.
  static const double minimumSharedBoundaryRoomToWalkableMeters = 0.80;

  // Minimum shared boundary required for walkable <-> walkable connections.
  static const double minimumSharedBoundaryWalkableToWalkableMeters = 1.20;

  // Main adjacency check:
  // returns true if the 2 polygons share enough boundary to be connected.
  bool polygonsAreAdjacentByBoundaryShare({
    required List<LatLng> polygonA,
    required List<LatLng> polygonB,
    required double minimumSharedBoundaryMeters,
  }) {
    if (polygonA.length < 3 || polygonB.length < 3) {
      return false;
    }

    final referenceLat =
        (polygonA.first.latitude + polygonB.first.latitude) / 2.0;
    final referenceLng =
        (polygonA.first.longitude + polygonB.first.longitude) / 2.0;

    final localPolygonA = convertPolygonToLocalMeters(
      polygon: polygonA,
      referenceLat: referenceLat,
      referenceLng: referenceLng,
    );

    final localPolygonB = convertPolygonToLocalMeters(
      polygon: polygonB,
      referenceLat: referenceLat,
      referenceLng: referenceLng,
    );

    final boundsA = buildPolygonBounds(localPolygonA);
    final boundsB = buildPolygonBounds(localPolygonB);

    if (!boundsOverlapWithTolerance(boundsA, boundsB, adjacencyEpsilonMeters)) {
      return false;
    }

    final sharedBoundaryMeters = maxSharedBoundaryMeters(
      localPolygonA: localPolygonA,
      localPolygonB: localPolygonB,
    );

    return sharedBoundaryMeters >= minimumSharedBoundaryMeters;
  }

  // Returns a point near the middle of the longest shared boundary segment.
  // This gives a better visual "portal" between adjacent polygons than using
  // polygon centers only.
  LatLng? sharedBoundaryMidpoint({
    required List<LatLng> polygonA,
    required List<LatLng> polygonB,
    required double minimumSharedBoundaryMeters,
  }) {
    if (polygonA.length < 3 || polygonB.length < 3) {
      return null;
    }

    final referenceLat =
        (polygonA.first.latitude + polygonB.first.latitude) / 2.0;
    final referenceLng =
        (polygonA.first.longitude + polygonB.first.longitude) / 2.0;

    final localA = convertPolygonToLocalMeters(
      polygon: polygonA,
      referenceLat: referenceLat,
      referenceLng: referenceLng,
    );
    final localB = convertPolygonToLocalMeters(
      polygon: polygonB,
      referenceLat: referenceLat,
      referenceLng: referenceLng,
    );

    final boundsA = buildPolygonBounds(localA);
    final boundsB = buildPolygonBounds(localB);

    if (!boundsOverlapWithTolerance(boundsA, boundsB, adjacencyEpsilonMeters)) {
      return null;
    }

    final runA = longestTouchingRunOneWay(
      sourcePolygon: localA,
      targetPolygon: localB,
    );
    final runB = longestTouchingRunOneWay(
      sourcePolygon: localB,
      targetPolygon: localA,
    );

    _TouchRunLocal? bestRun;
    if (runA == null) {
      bestRun = runB;
    } else if (runB == null) {
      bestRun = runA;
    } else {
      bestRun = runA.lengthMeters >= runB.lengthMeters ? runA : runB;
    }

    if (bestRun == null || bestRun.lengthMeters < minimumSharedBoundaryMeters) {
      return null;
    }

    final midpoint = interpolateLocalPoints(bestRun.start, bestRun.end, 0.5);

    return localMetersToLatLng(
      localPoint: midpoint,
      referenceLat: referenceLat,
      referenceLng: referenceLng,
    );
  }

  // Computes the largest shared boundary length between 2 polygons.
  // Done both ways to reduce asymmetry from edge sampling.
  double maxSharedBoundaryMeters({
    required List<LocalPointMeters> localPolygonA,
    required List<LocalPointMeters> localPolygonB,
  }) {
    final sharedAtoB = maxSharedBoundaryMetersOneWay(
      sourcePolygon: localPolygonA,
      targetPolygon: localPolygonB,
    );

    final sharedBtoA = maxSharedBoundaryMetersOneWay(
      sourcePolygon: localPolygonB,
      targetPolygon: localPolygonA,
    );

    return math.max(sharedAtoB, sharedBtoA);
  }

  // Measures how much of sourcePolygon's boundary is continuously close
  // to the targetPolygon boundary.
  double maxSharedBoundaryMetersOneWay({
    required List<LocalPointMeters> sourcePolygon,
    required List<LocalPointMeters> targetPolygon,
  }) {
    final run = longestTouchingRunOneWay(
      sourcePolygon: sourcePolygon,
      targetPolygon: targetPolygon,
    );
    return run?.lengthMeters ?? 0.0;
  }

  // Finds the longest continuous touching run from one polygon boundary
  // against another polygon boundary.
  _TouchRunLocal? longestTouchingRunOneWay({
    required List<LocalPointMeters> sourcePolygon,
    required List<LocalPointMeters> targetPolygon,
  }) {
    final source = ensureClosedLocalPolygon(sourcePolygon);
    final target = ensureClosedLocalPolygon(targetPolygon);

    _TouchRunLocal? bestRun;

    for (int i = 0; i < source.length - 1; i++) {
      final segmentStart = source[i];
      final segmentEnd = source[i + 1];

      final segmentLength = distanceLocalPoints(segmentStart, segmentEnd);
      if (segmentLength <= 0.0) continue;

      final sampleCount = math.max(
        1,
        (segmentLength / boundarySampleStepMeters).ceil(),
      );

      var previousPoint = segmentStart;
      LocalPointMeters? runStart =
          pointTouchesPolygonBoundary(previousPoint, target)
          ? previousPoint
          : null;
      double runLength = 0.0;

      for (int s = 1; s <= sampleCount; s++) {
        final t = s / sampleCount;
        final currentPoint = interpolateLocalPoints(
          segmentStart,
          segmentEnd,
          t,
        );
        final touches = pointTouchesPolygonBoundary(currentPoint, target);
        final interval = distanceLocalPoints(previousPoint, currentPoint);

        if (touches) {
          runStart ??= previousPoint;
          runLength += interval;

          if (bestRun == null || runLength > bestRun.lengthMeters) {
            bestRun = _TouchRunLocal(
              start: runStart,
              end: currentPoint,
              lengthMeters: runLength,
            );
          }
        } else {
          runStart = null;
          runLength = 0.0;
        }

        previousPoint = currentPoint;
      }
    }

    return bestRun;
  }

  // Checks whether a sampled point is close enough to the target boundary.
  bool pointTouchesPolygonBoundary(
    LocalPointMeters point,
    List<LocalPointMeters> polygon,
  ) {
    final distance = minimumDistanceFromPointToPolygonBoundaryMeters(
      point: point,
      polygon: polygon,
    );

    return distance <= adjacencyEpsilonMeters;
  }

  // Returns the minimum distance from a point to any edge of a polygon.
  double minimumDistanceFromPointToPolygonBoundaryMeters({
    required LocalPointMeters point,
    required List<LocalPointMeters> polygon,
  }) {
    final closedPolygon = ensureClosedLocalPolygon(polygon);

    double minimumDistance = double.infinity;

    for (int i = 0; i < closedPolygon.length - 1; i++) {
      final segmentStart = closedPolygon[i];
      final segmentEnd = closedPolygon[i + 1];

      final distance = distancePointToSegmentMeters(
        point: point,
        segmentStart: segmentStart,
        segmentEnd: segmentEnd,
      );

      if (distance < minimumDistance) {
        minimumDistance = distance;
      }
    }

    return minimumDistance;
  }

  // Standard point-to-segment distance in local XY meter space.
  double distancePointToSegmentMeters({
    required LocalPointMeters point,
    required LocalPointMeters segmentStart,
    required LocalPointMeters segmentEnd,
  }) {
    final dx = segmentEnd.x - segmentStart.x;
    final dy = segmentEnd.y - segmentStart.y;

    if (dx == 0.0 && dy == 0.0) {
      return distanceLocalPoints(point, segmentStart);
    }

    final numerator =
        (point.x - segmentStart.x) * dx + (point.y - segmentStart.y) * dy;
    final denominator = dx * dx + dy * dy;
    final projection = (numerator / denominator).clamp(0.0, 1.0).toDouble();

    final closestPoint = LocalPointMeters(
      x: segmentStart.x + projection * dx,
      y: segmentStart.y + projection * dy,
    );

    return distanceLocalPoints(point, closestPoint);
  }

  // Converts lat/lng polygon points into local XY meter coordinates.
  // This makes distance and boundary calculations much easier.
  List<LocalPointMeters> convertPolygonToLocalMeters({
    required List<LatLng> polygon,
    required double referenceLat,
    required double referenceLng,
  }) {
    final referenceLatRadians = degToRad(referenceLat);

    final xMetersPerDegree = 111320.0 * math.cos(referenceLatRadians);
    const yMetersPerDegree = 111132.0;

    final localPolygon = <LocalPointMeters>[];

    for (final point in polygon) {
      localPolygon.add(
        LocalPointMeters(
          x: (point.longitude - referenceLng) * xMetersPerDegree,
          y: (point.latitude - referenceLat) * yMetersPerDegree,
        ),
      );
    }

    return ensureClosedLocalPolygon(localPolygon);
  }

  // Converts local XY meters back into LatLng.
  LatLng localMetersToLatLng({
    required LocalPointMeters localPoint,
    required double referenceLat,
    required double referenceLng,
  }) {
    final referenceLatRadians = degToRad(referenceLat);
    final xMetersPerDegree = 111320.0 * math.cos(referenceLatRadians);
    const yMetersPerDegree = 111132.0;

    return LatLng(
      referenceLat + (localPoint.y / yMetersPerDegree),
      referenceLng + (localPoint.x / xMetersPerDegree),
    );
  }

  // Builds a bounding box around a polygon in local XY space.
  PolygonBoundsMeters buildPolygonBounds(List<LocalPointMeters> polygon) {
    final closed = ensureClosedLocalPolygon(polygon);

    double minX = closed.first.x;
    double minY = closed.first.y;
    double maxX = closed.first.x;
    double maxY = closed.first.y;

    for (final point in closed) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    return PolygonBoundsMeters(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  // Checks whether 2 bounding boxes overlap, allowing for a small tolerance.
  bool boundsOverlapWithTolerance(
    PolygonBoundsMeters a,
    PolygonBoundsMeters b,
    double toleranceMeters,
  ) {
    if (a.maxX + toleranceMeters < b.minX) return false;
    if (b.maxX + toleranceMeters < a.minX) return false;
    if (a.maxY + toleranceMeters < b.minY) return false;
    if (b.maxY + toleranceMeters < a.minY) return false;
    return true;
  }

  // Ensures the local polygon is explicitly closed.
  List<LocalPointMeters> ensureClosedLocalPolygon(
    List<LocalPointMeters> polygon,
  ) {
    if (polygon.isEmpty) return polygon;

    final first = polygon.first;
    final last = polygon.last;

    if (areSameLocalPoint(first, last)) {
      return polygon;
    }

    return [...polygon, first];
  }

  bool areSameLocalPoint(LocalPointMeters a, LocalPointMeters b) {
    return (a.x - b.x).abs() < 1e-9 && (a.y - b.y).abs() < 1e-9;
  }

  // Linear interpolation between 2 local points.
  LocalPointMeters interpolateLocalPoints(
    LocalPointMeters start,
    LocalPointMeters end,
    double t,
  ) {
    return LocalPointMeters(
      x: start.x + (end.x - start.x) * t,
      y: start.y + (end.y - start.y) * t,
    );
  }

  double distanceLocalPoints(LocalPointMeters a, LocalPointMeters b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double degToRad(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

class _TouchRunLocal {
  final LocalPointMeters start;
  final LocalPointMeters end;
  final double lengthMeters;

  const _TouchRunLocal({
    required this.start,
    required this.end,
    required this.lengthMeters,
  });
}
