import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/indoor_dijkstra.dart';
import '../core/indoor_geometry.dart';
import '../core/indoor_routing_models.dart';
import '../graph/indoor_floor_graph_builder.dart';

class IndoorCorridorPathBuilder {
  static const double boundaryAnchorStepMeters = 2.0;

  final IndoorFloorGraphBuilder floorGraphBuilder;
  final IndoorDijkstra indoorDijkstra;
  final IndoorGeometry geometry;

  const IndoorCorridorPathBuilder({
    required this.floorGraphBuilder,
    required this.indoorDijkstra,
    required this.geometry,
  });

  List<LatLng>? findBoundaryConstrainedCorridorPath({
    required LatLng entry,
    required LatLng exit,
    required List<LatLng> corridorPolygon,
  }) {
    final anchors = buildBoundaryAnchors(corridorPolygon);
    if (anchors.length < 3) return null;

    final graphPoints = <LatLng>[entry, exit, ...anchors];
    final adjacency = <int, List<IndoorRoutingEdge>>{
      for (int i = 0; i < graphPoints.length; i++) i: <IndoorRoutingEdge>[],
    };

    void addEdge(int a, int b) {
      final w = geometry.distanceMeters(graphPoints[a], graphPoints[b]);
      adjacency[a]!.add(IndoorRoutingEdge(toNodeId: b, weightMeters: w));
      adjacency[b]!.add(IndoorRoutingEdge(toNodeId: a, weightMeters: w));
    }

    final base = 2;

    for (int i = 0; i < anchors.length; i++) {
      final a = base + i;
      final b = base + ((i + 1) % anchors.length);
      addEdge(a, b);
    }

    for (final source in const [0, 1]) {
      for (int i = 0; i < anchors.length; i++) {
        final anchorId = base + i;
        if (geometry.segmentInsidePolygon(
          graphPoints[source],
          graphPoints[anchorId],
          corridorPolygon,
          minSamples: IndoorRouteGeometryTuning.segmentSamples,
          sampleSpacingMeters:
              IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
        )) {
          addEdge(source, anchorId);
        }
      }
    }

    if (geometry.distanceMeters(entry, exit) <= 8.0 &&
        geometry.segmentInsidePolygon(
          entry,
          exit,
          corridorPolygon,
          minSamples: IndoorRouteGeometryTuning.segmentSamples,
          sampleSpacingMeters:
              IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
        )) {
      addEdge(0, 1);
    }

    final idPath = indoorDijkstra.shortestPathNodeIds(
      adjacency: adjacency,
      startNodeId: 0,
      endNodeId: 1,
    );

    if (idPath == null || idPath.isEmpty) return null;
    return idPath.map((id) => graphPoints[id]).toList(growable: false);
  }

  LatLng? findCorridorBendPoint(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon, {
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
  }) {
    LatLng? best;
    double bestScore = double.infinity;

    for (final candidate in corridorPolygon) {
      if (geometry.areSameLatLng(candidate, entry) ||
          geometry.areSameLatLng(candidate, exit)) {
        continue;
      }

      final entryOk = geometry.segmentInsideCorridor(
        a: entry,
        b: candidate,
        corridorPolygon: corridorPolygon,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidBlockedRooms,
        minSamples: IndoorRouteGeometryTuning.segmentSamples,
        sampleSpacingMeters:
            IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
      );

      final exitOk = geometry.segmentInsideCorridor(
        a: candidate,
        b: exit,
        corridorPolygon: corridorPolygon,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidBlockedRooms,
        minSamples: IndoorRouteGeometryTuning.segmentSamples,
        sampleSpacingMeters:
            IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
      );

      if (!entryOk || !exitOk) {
        continue;
      }

      final score =
          geometry.distanceScore(entry, candidate) +
          geometry.distanceScore(candidate, exit);

      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best;
  }

  (LatLng, LatLng)? findCorridorTwoBendPath(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon, {
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
  }) {
    LatLng? bestA;
    LatLng? bestB;
    double bestScore = double.infinity;

    for (final a in corridorPolygon) {
      if (geometry.areSameLatLng(a, entry) || geometry.areSameLatLng(a, exit)) {
        continue;
      }

      for (final b in corridorPolygon) {
        if (geometry.areSameLatLng(b, entry) ||
            geometry.areSameLatLng(b, exit) ||
            geometry.areSameLatLng(a, b)) {
          continue;
        }

        final firstOk = geometry.segmentInsideCorridor(
          a: entry,
          b: a,
          corridorPolygon: corridorPolygon,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidBlockedRooms,
          minSamples: IndoorRouteGeometryTuning.segmentSamples,
          sampleSpacingMeters:
              IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
        );

        final secondOk = geometry.segmentInsideCorridor(
          a: a,
          b: b,
          corridorPolygon: corridorPolygon,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidBlockedRooms,
          minSamples: IndoorRouteGeometryTuning.segmentSamples,
          sampleSpacingMeters:
              IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
        );

        final thirdOk = geometry.segmentInsideCorridor(
          a: b,
          b: exit,
          corridorPolygon: corridorPolygon,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidBlockedRooms,
          minSamples: IndoorRouteGeometryTuning.segmentSamples,
          sampleSpacingMeters:
              IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
        );

        if (!firstOk || !secondOk || !thirdOk) {
          continue;
        }

        final score =
            geometry.distanceScore(entry, a) +
            geometry.distanceScore(a, b) +
            geometry.distanceScore(b, exit);

        if (score < bestScore) {
          bestScore = score;
          bestA = a;
          bestB = b;
        }
      }
    }

    if (bestA == null || bestB == null) {
      return null;
    }

    return (bestA, bestB);
  }

  List<LatLng>? fallbackAlongCorridorBoundary({
    required LatLng entry,
    required LatLng exit,
    required List<LatLng> corridorPolygon,
  }) {
    final ring = floorGraphBuilder.ensureClosedPolygon(corridorPolygon);
    if (ring.length < 4) return null;

    final vertices = ring.sublist(0, ring.length - 1);
    if (vertices.length < 3) return null;

    final startIdx = nearestVertexIndex(entry, vertices);
    final endIdx = nearestVertexIndex(exit, vertices);

    final forward = ringPath(vertices, startIdx, endIdx, forward: true);
    final backward = ringPath(vertices, startIdx, endIdx, forward: false);

    final forwardCost =
        geometry.distanceMeters(entry, vertices[startIdx]) +
        geometry.polylineLengthMeters(forward) +
        geometry.distanceMeters(vertices[endIdx], exit);

    final backwardCost =
        geometry.distanceMeters(entry, vertices[startIdx]) +
        geometry.polylineLengthMeters(backward) +
        geometry.distanceMeters(vertices[endIdx], exit);

    final best = forwardCost <= backwardCost ? forward : backward;

    return <LatLng>[entry, ...best, exit];
  }

  List<LatLng> buildBoundaryAnchors(List<LatLng> polygon) {
    final closed = floorGraphBuilder.ensureClosedPolygon(polygon);
    if (closed.length < 4) return const [];

    final anchors = <LatLng>[];

    for (int i = 0; i < closed.length - 1; i++) {
      final a = closed[i];
      final b = closed[i + 1];

      if (anchors.isEmpty || !geometry.areSameLatLng(anchors.last, a)) {
        anchors.add(a);
      }

      final d = geometry.distanceMeters(a, b);
      if (d <= boundaryAnchorStepMeters) continue;

      final steps = (d / boundaryAnchorStepMeters).floor();
      for (int k = 1; k < steps; k++) {
        final t = k / steps;
        anchors.add(
          LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          ),
        );
      }
    }

    return anchors;
  }

  int nearestVertexIndex(LatLng point, List<LatLng> vertices) {
    var bestIdx = 0;
    var bestDist = double.infinity;

    for (int i = 0; i < vertices.length; i++) {
      final d = geometry.distanceMeters(point, vertices[i]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }

    return bestIdx;
  }

  List<LatLng> ringPath(
    List<LatLng> vertices,
    int startIdx,
    int endIdx, {
    required bool forward,
  }) {
    final out = <LatLng>[];
    final n = vertices.length;

    int i = startIdx;
    while (true) {
      out.add(vertices[i]);
      if (i == endIdx) break;
      i = forward ? (i + 1) % n : (i - 1 + n) % n;
    }

    return out;
  }
}

class IndoorRouteGeometryTuning {
  static const int segmentSamples = 12;
  static const int sparseGeometryMaxCorridors = 2;
  static const double longSparsePortalSegmentMeters = 12.0;
  static const double segmentSampleSpacingMeters = 0.75;
}
