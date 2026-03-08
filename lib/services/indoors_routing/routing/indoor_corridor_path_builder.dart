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
    final adjacency = _initializeAdjacency(graphPoints.length);

    void addEdge(int a, int b) {
      final w = geometry.distanceMeters(graphPoints[a], graphPoints[b]);
      adjacency[a]!.add(IndoorRoutingEdge(toNodeId: b, weightMeters: w));
      adjacency[b]!.add(IndoorRoutingEdge(toNodeId: a, weightMeters: w));
    }

    const base = 2;
    _connectAnchorRing(anchors: anchors, base: base, addEdge: addEdge);
    _connectEntryAndExitToAnchors(
      anchors: anchors,
      base: base,
      graphPoints: graphPoints,
      corridorPolygon: corridorPolygon,
      addEdge: addEdge,
    );

    if (_canConnectEntryExitDirectly(
      entry: entry,
      exit: exit,
      corridorPolygon: corridorPolygon,
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

  Map<int, List<IndoorRoutingEdge>> _initializeAdjacency(int pointCount) {
    return <int, List<IndoorRoutingEdge>>{
      for (int i = 0; i < pointCount; i++) i: <IndoorRoutingEdge>[],
    };
  }

  void _connectAnchorRing({
    required List<LatLng> anchors,
    required int base,
    required void Function(int a, int b) addEdge,
  }) {
    for (int i = 0; i < anchors.length; i++) {
      final a = base + i;
      final b = base + ((i + 1) % anchors.length);
      addEdge(a, b);
    }
  }

  void _connectEntryAndExitToAnchors({
    required List<LatLng> anchors,
    required int base,
    required List<LatLng> graphPoints,
    required List<LatLng> corridorPolygon,
    required void Function(int a, int b) addEdge,
  }) {
    for (final source in const [0, 1]) {
      for (int i = 0; i < anchors.length; i++) {
        final anchorId = base + i;
        if (!_segmentInsideCorridorPolygon(
          graphPoints[source],
          graphPoints[anchorId],
          corridorPolygon,
        )) {
          continue;
        }
        addEdge(source, anchorId);
      }
    }
  }

  bool _canConnectEntryExitDirectly({
    required LatLng entry,
    required LatLng exit,
    required List<LatLng> corridorPolygon,
  }) {
    return geometry.distanceMeters(entry, exit) <= 8.0 &&
        _segmentInsideCorridorPolygon(entry, exit, corridorPolygon);
  }

  bool _segmentInsideCorridorPolygon(
    LatLng a,
    LatLng b,
    List<LatLng> corridorPolygon,
  ) {
    return geometry.segmentInsidePolygon(
      a,
      b,
      corridorPolygon,
      minSamples: IndoorRouteGeometryTuning.segmentSamples,
      sampleSpacingMeters: IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
    );
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
      if (!_isDistinctCandidate(candidate, entry, exit)) {
        continue;
      }

      if (!_isValidCorridorSegmentPath(
        points: [entry, candidate, exit],
        corridorPolygon: corridorPolygon,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidBlockedRooms,
      )) {
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
    (LatLng, LatLng)? bestPair;
    double bestScore = double.infinity;

    for (final a in corridorPolygon) {
      if (!_isDistinctCandidate(a, entry, exit)) {
        continue;
      }

      for (final b in corridorPolygon) {
        if (!_isDistinctTwoBendCandidate(
          first: a,
          second: b,
          entry: entry,
          exit: exit,
        )) {
          continue;
        }

        if (!_isValidCorridorSegmentPath(
          points: [entry, a, b, exit],
          corridorPolygon: corridorPolygon,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidBlockedRooms,
        )) {
          continue;
        }

        final score =
            geometry.distanceScore(entry, a) +
            geometry.distanceScore(a, b) +
            geometry.distanceScore(b, exit);

        if (score < bestScore) {
          bestScore = score;
          bestPair = (a, b);
        }
      }
    }

    return bestPair;
  }

  bool _isDistinctCandidate(LatLng candidate, LatLng entry, LatLng exit) {
    return !geometry.areSameLatLng(candidate, entry) &&
        !geometry.areSameLatLng(candidate, exit);
  }

  bool _isDistinctTwoBendCandidate({
    required LatLng first,
    required LatLng second,
    required LatLng entry,
    required LatLng exit,
  }) {
    return _isDistinctCandidate(second, entry, exit) &&
        !geometry.areSameLatLng(first, second);
  }

  bool _isValidCorridorSegmentPath({
    required List<LatLng> points,
    required List<LatLng> corridorPolygon,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
  }) {
    for (int i = 1; i < points.length; i++) {
      if (!geometry.segmentInsideCorridor(
        a: points[i - 1],
        b: points[i],
        corridorPolygon: corridorPolygon,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidBlockedRooms,
        minSamples: IndoorRouteGeometryTuning.segmentSamples,
        sampleSpacingMeters:
            IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
      )) {
        return false;
      }
    }
    return true;
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
