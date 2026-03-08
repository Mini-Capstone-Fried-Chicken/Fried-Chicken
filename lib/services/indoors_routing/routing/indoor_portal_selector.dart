import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/indoor_geometry.dart';
import '../core/indoor_routing_models.dart';
import '../graph/indoor_boundary_adjacency.dart';
import '../graph/indoor_floor_graph_builder.dart';

class IndoorPortalSelector {
  static const int sharedBoundaryPortalSamples = 5;

  final IndoorFloorGraphBuilder floorGraphBuilder;
  final IndoorGeometry geometry;

  const IndoorPortalSelector({
    required this.floorGraphBuilder,
    required this.geometry,
  });

  LatLng? portalBetween(IndoorRoutingNode a, IndoorRoutingNode b) {
    final minShared =
        (a.nodeType == IndoorRoutingNodeType.room ||
            b.nodeType == IndoorRoutingNodeType.room)
        ? IndoorSameFloorThresholds.minimumSharedBoundaryRoomToWalkableMeters
        : IndoorSameFloorThresholds
              .minimumSharedBoundaryWalkableToWalkableMeters;

    return floorGraphBuilder.boundaryAdjacency.sharedBoundaryMidpoint(
      polygonA: a.polygonPoints,
      polygonB: b.polygonPoints,
      minimumSharedBoundaryMeters: minShared,
    );
  }

  LatLng? portalBetweenTowardTarget({
    required IndoorRoutingNode from,
    required IndoorRoutingNode to,
    required LatLng target,
  }) {
    final defaultPortal = portalBetween(from, to);
    if (defaultPortal == null) return null;

    final isRoomCorridorPair =
        (from.nodeType == IndoorRoutingNodeType.room &&
            to.nodeType == IndoorRoutingNodeType.corridor) ||
        (from.nodeType == IndoorRoutingNodeType.corridor &&
            to.nodeType == IndoorRoutingNodeType.room);

    if (!isRoomCorridorPair) {
      return defaultPortal;
    }

    final candidates = sampleSharedBoundaryPortals(from, to);
    if (candidates.isEmpty) {
      return defaultPortal;
    }

    var best = defaultPortal;
    var bestScore = geometry.distanceMeters(defaultPortal, target);

    for (final candidate in candidates) {
      final score = geometry.distanceMeters(candidate, target);
      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best;
  }

  List<LatLng> sampleSharedBoundaryPortals(
    IndoorRoutingNode a,
    IndoorRoutingNode b,
  ) {
    final minShared =
        (a.nodeType == IndoorRoutingNodeType.room ||
            b.nodeType == IndoorRoutingNodeType.room)
        ? IndoorSameFloorThresholds.minimumSharedBoundaryRoomToWalkableMeters
        : IndoorSameFloorThresholds
              .minimumSharedBoundaryWalkableToWalkableMeters;

    final sharedSegments = sharedBoundarySegments(
      polygonA: a.polygonPoints,
      polygonB: b.polygonPoints,
      minimumSharedBoundaryMeters: minShared,
    );

    if (sharedSegments.isEmpty) {
      final midpoint = portalBetween(a, b);
      return midpoint == null ? const [] : [midpoint];
    }

    final candidates = <LatLng>[];

    for (final segment in sharedSegments) {
      final start = segment.$1;
      final end = segment.$2;

      if (candidates.isEmpty ||
          !geometry.areSameLatLng(candidates.last, start)) {
        candidates.add(start);
      }

      for (int i = 1; i < sharedBoundaryPortalSamples - 1; i++) {
        final t = i / (sharedBoundaryPortalSamples - 1);
        candidates.add(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * t,
            start.longitude + (end.longitude - start.longitude) * t,
          ),
        );
      }

      candidates.add(end);
    }

    return geometry.removeConsecutiveDuplicatePoints(candidates);
  }

  List<(LatLng, LatLng)> sharedBoundarySegments({
    required List<LatLng> polygonA,
    required List<LatLng> polygonB,
    required double minimumSharedBoundaryMeters,
  }) {
    final closedA = floorGraphBuilder.ensureClosedPolygon(polygonA);
    final closedB = floorGraphBuilder.ensureClosedPolygon(polygonB);

    if (closedA.length < 2 || closedB.length < 2) return const [];

    final segments = <(LatLng, LatLng)>[];

    for (int i = 0; i < closedA.length - 1; i++) {
      final a1 = closedA[i];
      final a2 = closedA[i + 1];

      for (int j = 0; j < closedB.length - 1; j++) {
        final b1 = closedB[j];
        final b2 = closedB[j + 1];

        final overlap = overlappingCollinearSegment(a1, a2, b1, b2);
        if (overlap == null) continue;

        final overlapLength = geometry.distanceMeters(overlap.$1, overlap.$2);
        if (overlapLength + IndoorSameFloorThresholds.adjacencyEpsilonMeters <
            minimumSharedBoundaryMeters) {
          continue;
        }

        segments.add(overlap);
      }
    }

    return segments;
  }

  (LatLng, LatLng)? overlappingCollinearSegment(
    LatLng a1,
    LatLng a2,
    LatLng b1,
    LatLng b2,
  ) {
    final ax = a2.longitude - a1.longitude;
    final ay = a2.latitude - a1.latitude;
    final bx = b2.longitude - b1.longitude;
    final by = b2.latitude - b1.latitude;

    final aLenSq = ax * ax + ay * ay;
    final bLenSq = bx * bx + by * by;
    if (aLenSq == 0.0 || bLenSq == 0.0) return null;

    final crossDir = (ax * by - ay * bx).abs();
    if (crossDir > 1e-10) return null;

    final crossStart =
        ((b1.longitude - a1.longitude) * ay - (b1.latitude - a1.latitude) * ax)
            .abs();
    final crossEnd =
        ((b2.longitude - a1.longitude) * ay - (b2.latitude - a1.latitude) * ax)
            .abs();
    if (crossStart > 1e-10 || crossEnd > 1e-10) return null;

    final useLatAxis = ay.abs() >= ax.abs();

    double proj(LatLng p) => useLatAxis ? p.latitude : p.longitude;

    final aStart = proj(a1);
    final aEnd = proj(a2);
    final bStart = proj(b1);
    final bEnd = proj(b2);

    final aMin = math.min(aStart, aEnd);
    final aMax = math.max(aStart, aEnd);
    final bMin = math.min(bStart, bEnd);
    final bMax = math.max(bStart, bEnd);

    final overlapMin = math.max(aMin, bMin);
    final overlapMax = math.min(aMax, bMax);

    if (overlapMax - overlapMin <= 1e-12) return null;

    final start = pointAtProjection(a1, a2, overlapMin, useLatAxis: useLatAxis);
    final end = pointAtProjection(a1, a2, overlapMax, useLatAxis: useLatAxis);

    if (geometry.areSameLatLng(start, end)) return null;
    return (start, end);
  }

  LatLng pointAtProjection(
    LatLng a,
    LatLng b,
    double projectionValue, {
    required bool useLatAxis,
  }) {
    final delta = useLatAxis
        ? (b.latitude - a.latitude)
        : (b.longitude - a.longitude);
    if (delta.abs() < 1e-12) return a;

    final t =
        ((projectionValue - (useLatAxis ? a.latitude : a.longitude)) / delta)
            .clamp(0.0, 1.0);

    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }
}

class IndoorSameFloorThresholds {
  static const double adjacencyEpsilonMeters =
      IndoorBoundaryAdjacency.adjacencyEpsilonMeters;
  static const double minimumSharedBoundaryRoomToWalkableMeters =
      IndoorBoundaryAdjacency.minimumSharedBoundaryRoomToWalkableMeters;
  static const double minimumSharedBoundaryWalkableToWalkableMeters =
      IndoorBoundaryAdjacency.minimumSharedBoundaryWalkableToWalkableMeters;
}
