import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/indoor_routing_models.dart';

class IndoorBoundaryAdjacency {
  static const double adjacencyEpsilonMeters = 0.25;
  static const double boundarySampleStepMeters = 0.30;
  static const double minimumSharedBoundaryRoomToWalkableMeters = 0.80;
  static const double minimumSharedBoundaryWalkableToWalkableMeters = 1.20;

  bool polygonsAreAdjacentByBoundaryShare({
    required List<LatLng> polygonA,
    required List<LatLng> polygonB,
    required double minimumSharedBoundaryMeters,
  }) {
    if (polygonA.length < 3 || polygonB.length < 3) return false;

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

  LatLng? sharedBoundaryMidpoint({
    required List<LatLng> polygonA,
    required List<LatLng> polygonB,
    required double minimumSharedBoundaryMeters,
  }) {
    if (polygonA.length < 3 || polygonB.length < 3) return null;

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

    final runA = _longestTouchingRunOneWay(sourcePolygon: localA, targetPolygon: localB);
    final runB = _longestTouchingRunOneWay(sourcePolygon: localB, targetPolygon: localA);

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

  double maxSharedBoundaryMetersOneWay({
    required List<LocalPointMeters> sourcePolygon,
    required List<LocalPointMeters> targetPolygon,
  }) {
    final run = _longestTouchingRunOneWay(
      sourcePolygon: sourcePolygon,
      targetPolygon: targetPolygon,
    );
    return run?.lengthMeters ?? 0.0;
  }

  // Helper extracted to reduce cognitive complexity of _longestTouchingRunOneWay

  /// Returns the longer of [current] and a new candidate run ending at
  /// [currentPoint] with the accumulated [runLength].
  /// Returns [current] unchanged when [runLength] is not an improvement.
  _TouchRunLocal _bestRun(
    _TouchRunLocal? current,
    LocalPointMeters runStart,
    LocalPointMeters currentPoint,
    double runLength,
  ) {
    if (current == null || runLength > current.lengthMeters) {
      return _TouchRunLocal(
        start: runStart,
        end: currentPoint,
        lengthMeters: runLength,
      );
    }
    return current;
  }

  _TouchRunLocal? _longestTouchingRunOneWay({
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
          pointTouchesPolygonBoundary(previousPoint, target) ? previousPoint : null;
      double runLength = 0.0;

      for (int s = 1; s <= sampleCount; s++) {
        final currentPoint = interpolateLocalPoints(segmentStart, segmentEnd, s / sampleCount);
        final touches = pointTouchesPolygonBoundary(currentPoint, target);
        final interval = distanceLocalPoints(previousPoint, currentPoint);

        if (touches) {
          runStart ??= previousPoint;
          runLength += interval;
          bestRun = _bestRun(bestRun, runStart, currentPoint, runLength);
        } else {
          runStart = null;
          runLength = 0.0;
        }

        previousPoint = currentPoint;
      }
    }

    return bestRun;
  }

  bool pointTouchesPolygonBoundary(
    LocalPointMeters point,
    List<LocalPointMeters> polygon,
  ) {
    return minimumDistanceFromPointToPolygonBoundaryMeters(
          point: point,
          polygon: polygon,
        ) <=
        adjacencyEpsilonMeters;
  }

  double minimumDistanceFromPointToPolygonBoundaryMeters({
    required LocalPointMeters point,
    required List<LocalPointMeters> polygon,
  }) {
    final closedPolygon = ensureClosedLocalPolygon(polygon);
    double minimumDistance = double.infinity;

    for (int i = 0; i < closedPolygon.length - 1; i++) {
      final distance = distancePointToSegmentMeters(
        point: point,
        segmentStart: closedPolygon[i],
        segmentEnd: closedPolygon[i + 1],
      );
      if (distance < minimumDistance) minimumDistance = distance;
    }

    return minimumDistance;
  }

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

  List<LocalPointMeters> ensureClosedLocalPolygon(List<LocalPointMeters> polygon) {
    if (polygon.isEmpty) return polygon;
    final first = polygon.first;
    final last = polygon.last;
    if (areSameLocalPoint(first, last)) return polygon;
    return [...polygon, first];
  }

  bool areSameLocalPoint(LocalPointMeters a, LocalPointMeters b) {
    return (a.x - b.x).abs() < 1e-9 && (a.y - b.y).abs() < 1e-9;
  }

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

  double degToRad(double degrees) => degrees * (math.pi / 180.0);
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
