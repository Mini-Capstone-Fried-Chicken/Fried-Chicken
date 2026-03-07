import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/geo.dart' as geo;
import 'indoor_boundary_adjacency.dart';
import 'indoor_dijkstra.dart';
import 'indoor_floor_graph_builder.dart';
import 'indoor_routing_models.dart';

class IndoorSameFloorRouter {
  static const double adjacencyEpsilonMeters =
      IndoorBoundaryAdjacency.adjacencyEpsilonMeters;
  static const double minimumSharedBoundaryRoomToWalkableMeters =
      IndoorBoundaryAdjacency.minimumSharedBoundaryRoomToWalkableMeters;
  static const double minimumSharedBoundaryWalkableToWalkableMeters =
      IndoorBoundaryAdjacency.minimumSharedBoundaryWalkableToWalkableMeters;
  static const int segmentSamples = 12;
  static const int sparseGeometryMaxCorridors = 2;
  static const double longSparsePortalSegmentMeters = 12.0;
  static const double boundaryAnchorStepMeters = 2.0;
  static const double segmentSampleSpacingMeters = 0.75;
  static const int sharedBoundaryPortalSamples = 5;

  final IndoorFloorGraphBuilder floorGraphBuilder;
  final IndoorDijkstra indoorDijkstra;

  IndoorSameFloorRouter({
    IndoorFloorGraphBuilder? floorGraphBuilder,
    IndoorDijkstra? indoorDijkstra,
  }) : floorGraphBuilder = floorGraphBuilder ?? IndoorFloorGraphBuilder(),
       indoorDijkstra = indoorDijkstra ?? IndoorDijkstra();

  bool roomExistsOnFloor({
    required Map<String, dynamic> floorGeoJson,
    required String roomCode,
  }) {
    return roomCenterOnFloor(floorGeoJson: floorGeoJson, roomCode: roomCode) !=
        null;
  }

  LatLng? roomCenterOnFloor({
    required Map<String, dynamic> floorGeoJson,
    required String roomCode,
  }) {
    final normalizedCode = roomCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    final nodes = floorGraphBuilder.buildNodesFromFloorGeoJson(floorGeoJson);

    for (final node in nodes) {
      if (node.nodeType == IndoorRoutingNodeType.room &&
          node.roomCode == normalizedCode) {
        return node.center;
      }
    }

    return null;
  }

  List<LatLng>? findShortestPath({
    required Map<String, dynamic> floorGeoJson,
    required String originRoomCode,
    required String destinationRoomCode,
    bool enforceRoomSafeSegments = false,
  }) {
    final originCode = originRoomCode.trim().toUpperCase();
    final destinationCode = destinationRoomCode.trim().toUpperCase();

    if (originCode.isEmpty || destinationCode.isEmpty) {
      return null;
    }

    final nodes = floorGraphBuilder.buildNodesFromFloorGeoJson(floorGeoJson);
    if (nodes.isEmpty) {
      return null;
    }

    IndoorRoutingNode? originNode;
    IndoorRoutingNode? destinationNode;

    for (final node in nodes) {
      if (node.nodeType != IndoorRoutingNodeType.room) continue;

      if (node.roomCode == originCode) originNode = node;
      if (node.roomCode == destinationCode) destinationNode = node;
    }

    if (originNode == null || destinationNode == null) {
      return null;
    }

    if (originNode.id == destinationNode.id) {
      return [originNode.center];
    }

    final adjacency = floorGraphBuilder.buildAdjacencyList(nodes);

    final filteredAdjacency = _withoutIntermediateRooms(
      adjacency: adjacency,
      nodes: nodes,
      allowedRoomIds: {originNode.id, destinationNode.id},
    );

    final pathNodeIds = indoorDijkstra.shortestPathNodeIds(
      adjacency: filteredAdjacency,
      startNodeId: originNode.id,
      endNodeId: destinationNode.id,
    );

    if (pathNodeIds == null || pathNodeIds.isEmpty) {
      return null;
    }

    final routePoints = buildRoutePointsFromNodePath(
      pathNodeIds: pathNodeIds,
      nodes: nodes,
      allowedRoomIds: {originNode.id, destinationNode.id},
      enforceRoomSafeSegments: enforceRoomSafeSegments,
    );

    if (routePoints.length < 2) {
      return null;
    }

    return removeConsecutiveDuplicatePoints(routePoints);
  }

  Map<int, List<IndoorRoutingEdge>> _withoutIntermediateRooms({
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required List<IndoorRoutingNode> nodes,
    required Set<int> allowedRoomIds,
  }) {
    final blockedRoomIds = <int>{};

    for (final node in nodes) {
      if (node.nodeType == IndoorRoutingNodeType.room &&
          !allowedRoomIds.contains(node.id)) {
        blockedRoomIds.add(node.id);
      }
    }

    final filtered = <int, List<IndoorRoutingEdge>>{};

    for (final entry in adjacency.entries) {
      final fromNodeId = entry.key;

      if (blockedRoomIds.contains(fromNodeId)) {
        filtered[fromNodeId] = const [];
        continue;
      }

      final keptEdges = <IndoorRoutingEdge>[];

      for (final edge in entry.value) {
        if (!blockedRoomIds.contains(edge.toNodeId)) {
          keptEdges.add(edge);
        }
      }

      filtered[fromNodeId] = keptEdges;
    }

    return filtered;
  }

  List<LatLng> buildRoutePointsFromNodePath({
    required List<int> pathNodeIds,
    required List<IndoorRoutingNode> nodes,
    required Set<int> allowedRoomIds,
    bool enforceRoomSafeSegments = false,
  }) {
    if (pathNodeIds.isEmpty) return const [];

    final nodeById = {for (final n in nodes) n.id: n};

    final orderedNodes = <IndoorRoutingNode>[];
    for (final id in pathNodeIds) {
      final node = nodeById[id];
      if (node != null) {
        orderedNodes.add(node);
      }
    }

    if (orderedNodes.isEmpty) return const [];

    final startNode = orderedNodes.first;
    final endNode = orderedNodes.last;

    final corridorCount = nodes
        .where((n) => n.nodeType == IndoorRoutingNodeType.corridor)
        .length;

    final useSparseGeometryGuard = corridorCount <= sparseGeometryMaxCorridors;

    final blockedRoomPolygons = useSparseGeometryGuard
        ? nodes
              .where(
                (n) =>
                    n.nodeType == IndoorRoutingNodeType.room &&
                    n.id != startNode.id &&
                    n.id != endNode.id,
              )
              .map((n) => n.polygonPoints)
              .toList(growable: false)
        : const <List<LatLng>>[];

    final points = <LatLng>[startNode.center];

    if (orderedNodes.length == 2) {
      final portal = _portalBetweenTowardTarget(
        from: orderedNodes[0],
        to: orderedNodes[1],
        target: endNode.center,
      );

      if (portal != null && !areSameLatLng(points.last, portal)) {
        points.add(portal);
      }

      if (!areSameLatLng(points.last, endNode.center)) {
        points.add(endNode.center);
      }

      return removeConsecutiveDuplicatePoints(points);
    }

    final firstPortal = _portalBetweenTowardTarget(
      from: orderedNodes[0],
      to: orderedNodes[1],
      target: orderedNodes.length > 2 ? orderedNodes[2].center : endNode.center,
    );
    if (firstPortal != null && !areSameLatLng(points.last, firstPortal)) {
      points.add(firstPortal);
    }

    for (int i = 1; i < orderedNodes.length - 1; i++) {
      final currentNode = orderedNodes[i];
      final previousNode = orderedNodes[i - 1];
      final nextNode = orderedNodes[i + 1];

      final entryPortal = _portalBetweenTowardTarget(
        from: previousNode,
        to: currentNode,
        target: nextNode.center,
      );
      final exitPortal = _portalBetweenTowardTarget(
        from: currentNode,
        to: nextNode,
        target: endNode.center,
      );

      if (entryPortal == null || exitPortal == null) {
        continue;
      }

      final portalDistanceMeters = _distanceMeters(entryPortal, exitPortal);

      if (useSparseGeometryGuard &&
          portalDistanceMeters >= longSparsePortalSegmentMeters) {
        final boundaryPath = _findBoundaryConstrainedCorridorPath(
          entry: entryPortal,
          exit: exitPortal,
          corridorPolygon: currentNode.polygonPoints,
        );

        if (boundaryPath != null && boundaryPath.length >= 2) {
          for (final p in boundaryPath) {
            if (!areSameLatLng(points.last, p)) {
              points.add(p);
            }
          }
          continue;
        }
      }

      final strictModes = useSparseGeometryGuard
          ? (enforceRoomSafeSegments ? const [true] : const [true, false])
          : const [false];

      var appended = false;

      for (final avoidRooms in strictModes) {
        final directInside = _segmentInsideCorridor(
          a: entryPortal,
          b: exitPortal,
          corridorPolygon: currentNode.polygonPoints,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidRooms,
        );

        if (directInside) {
          if (!areSameLatLng(points.last, entryPortal)) {
            points.add(entryPortal);
          }
          if (!areSameLatLng(points.last, exitPortal)) {
            points.add(exitPortal);
          }
          appended = true;
          break;
        }

        final bendPoint = _findCorridorBendPoint(
          entryPortal,
          exitPortal,
          currentNode.polygonPoints,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidRooms,
        );

        if (bendPoint != null) {
          if (!areSameLatLng(points.last, entryPortal)) {
            points.add(entryPortal);
          }
          if (!areSameLatLng(points.last, bendPoint)) {
            points.add(bendPoint);
          }
          if (!areSameLatLng(points.last, exitPortal)) {
            points.add(exitPortal);
          }
          appended = true;
          break;
        }

        final bendPair = _findCorridorTwoBendPath(
          entryPortal,
          exitPortal,
          currentNode.polygonPoints,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidRooms,
        );

        if (bendPair != null) {
          if (!areSameLatLng(points.last, entryPortal)) {
            points.add(entryPortal);
          }
          if (!areSameLatLng(points.last, bendPair.$1)) {
            points.add(bendPair.$1);
          }
          if (!areSameLatLng(points.last, bendPair.$2)) {
            points.add(bendPair.$2);
          }
          if (!areSameLatLng(points.last, exitPortal)) {
            points.add(exitPortal);
          }
          appended = true;
          break;
        }

        final entryToCenterInside = _segmentInsideCorridor(
          a: entryPortal,
          b: currentNode.center,
          corridorPolygon: currentNode.polygonPoints,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidRooms,
        );

        final centerToExitInside = _segmentInsideCorridor(
          a: currentNode.center,
          b: exitPortal,
          corridorPolygon: currentNode.polygonPoints,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidRooms,
        );

        if (entryToCenterInside && centerToExitInside) {
          if (!areSameLatLng(points.last, entryPortal)) {
            points.add(entryPortal);
          }
          if (!areSameLatLng(points.last, currentNode.center)) {
            points.add(currentNode.center);
          }
          if (!areSameLatLng(points.last, exitPortal)) {
            points.add(exitPortal);
          }
          appended = true;
          break;
        }
      }

      if (!appended) {
        final boundaryFallback = _fallbackAlongCorridorBoundary(
          entry: entryPortal,
          exit: exitPortal,
          corridorPolygon: currentNode.polygonPoints,
        );

        if (boundaryFallback != null && boundaryFallback.isNotEmpty) {
          for (final p in boundaryFallback) {
            if (!areSameLatLng(points.last, p)) {
              points.add(p);
            }
          }
          continue;
        }

        points.add(entryPortal);
        points.add(exitPortal);
        continue;
      }
    }

    if (!areSameLatLng(points.last, endNode.center)) {
      points.add(endNode.center);
    }

    return removeConsecutiveDuplicatePoints(points);
  }

  LatLng? _portalBetween(IndoorRoutingNode a, IndoorRoutingNode b) {
    final minShared =
        (a.nodeType == IndoorRoutingNodeType.room ||
            b.nodeType == IndoorRoutingNodeType.room)
        ? minimumSharedBoundaryRoomToWalkableMeters
        : minimumSharedBoundaryWalkableToWalkableMeters;

    return floorGraphBuilder.boundaryAdjacency.sharedBoundaryMidpoint(
      polygonA: a.polygonPoints,
      polygonB: b.polygonPoints,
      minimumSharedBoundaryMeters: minShared,
    );
  }

  LatLng? _portalBetweenTowardTarget({
    required IndoorRoutingNode from,
    required IndoorRoutingNode to,
    required LatLng target,
  }) {
    final defaultPortal = _portalBetween(from, to);
    if (defaultPortal == null) return null;

    final isRoomCorridorPair =
        (from.nodeType == IndoorRoutingNodeType.room &&
            to.nodeType == IndoorRoutingNodeType.corridor) ||
        (from.nodeType == IndoorRoutingNodeType.corridor &&
            to.nodeType == IndoorRoutingNodeType.room);

    if (!isRoomCorridorPair) {
      return defaultPortal;
    }

    final candidates = _sampleSharedBoundaryPortals(from, to);
    if (candidates.isEmpty) {
      return defaultPortal;
    }

    var best = defaultPortal;
    var bestScore = _distanceMeters(defaultPortal, target);

    for (final candidate in candidates) {
      final score = _distanceMeters(candidate, target);
      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best;
  }

  List<LatLng> _sampleSharedBoundaryPortals(
    IndoorRoutingNode a,
    IndoorRoutingNode b,
  ) {
    final minShared =
        (a.nodeType == IndoorRoutingNodeType.room ||
            b.nodeType == IndoorRoutingNodeType.room)
        ? minimumSharedBoundaryRoomToWalkableMeters
        : minimumSharedBoundaryWalkableToWalkableMeters;

    final sharedSegments = _sharedBoundarySegments(
      polygonA: a.polygonPoints,
      polygonB: b.polygonPoints,
      minimumSharedBoundaryMeters: minShared,
    );

    if (sharedSegments.isEmpty) {
      final midpoint = _portalBetween(a, b);
      return midpoint == null ? const [] : [midpoint];
    }

    final candidates = <LatLng>[];

    for (final segment in sharedSegments) {
      final start = segment.$1;
      final end = segment.$2;

      if (candidates.isEmpty || !areSameLatLng(candidates.last, start)) {
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

    return removeConsecutiveDuplicatePoints(candidates);
  }

  List<(LatLng, LatLng)> _sharedBoundarySegments({
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

        final overlap = _overlappingCollinearSegment(a1, a2, b1, b2);
        if (overlap == null) continue;

        final overlapLength = _distanceMeters(overlap.$1, overlap.$2);
        if (overlapLength + adjacencyEpsilonMeters <
            minimumSharedBoundaryMeters) {
          continue;
        }

        segments.add(overlap);
      }
    }

    return segments;
  }

  (LatLng, LatLng)? _overlappingCollinearSegment(
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

    final start = _pointAtProjection(
      a1,
      a2,
      overlapMin,
      useLatAxis: useLatAxis,
    );
    final end = _pointAtProjection(a1, a2, overlapMax, useLatAxis: useLatAxis);

    if (areSameLatLng(start, end)) return null;
    return (start, end);
  }

  LatLng _pointAtProjection(
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

  LatLng? _findCorridorBendPoint(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon, {
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
  }) {
    LatLng? best;
    double bestScore = double.infinity;

    for (final candidate in corridorPolygon) {
      if (areSameLatLng(candidate, entry) || areSameLatLng(candidate, exit)) {
        continue;
      }

      final entryOk = _segmentInsideCorridor(
        a: entry,
        b: candidate,
        corridorPolygon: corridorPolygon,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidBlockedRooms,
      );

      final exitOk = _segmentInsideCorridor(
        a: candidate,
        b: exit,
        corridorPolygon: corridorPolygon,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidBlockedRooms,
      );

      if (!entryOk || !exitOk) {
        continue;
      }

      final score =
          _distanceScore(entry, candidate) + _distanceScore(candidate, exit);

      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best;
  }

  (LatLng, LatLng)? _findCorridorTwoBendPath(
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
      if (areSameLatLng(a, entry) || areSameLatLng(a, exit)) continue;

      for (final b in corridorPolygon) {
        if (areSameLatLng(b, entry) ||
            areSameLatLng(b, exit) ||
            areSameLatLng(a, b)) {
          continue;
        }

        final firstOk = _segmentInsideCorridor(
          a: entry,
          b: a,
          corridorPolygon: corridorPolygon,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidBlockedRooms,
        );

        final secondOk = _segmentInsideCorridor(
          a: a,
          b: b,
          corridorPolygon: corridorPolygon,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidBlockedRooms,
        );

        final thirdOk = _segmentInsideCorridor(
          a: b,
          b: exit,
          corridorPolygon: corridorPolygon,
          blockedRoomPolygons: blockedRoomPolygons,
          avoidBlockedRooms: avoidBlockedRooms,
        );

        if (!firstOk || !secondOk || !thirdOk) {
          continue;
        }

        final score =
            _distanceScore(entry, a) +
            _distanceScore(a, b) +
            _distanceScore(b, exit);

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

  bool _segmentInsideCorridor({
    required LatLng a,
    required LatLng b,
    required List<LatLng> corridorPolygon,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
  }) {
    if (!_segmentInsidePolygon(
      a,
      b,
      corridorPolygon,
      samples: segmentSamples,
    )) {
      return false;
    }

    if (!avoidBlockedRooms || blockedRoomPolygons.isEmpty) {
      return true;
    }

    for (int i = 1; i < segmentSamples; i++) {
      final t = i / segmentSamples;
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

  bool _segmentInsidePolygon(
    LatLng a,
    LatLng b,
    List<LatLng> polygon, {
    int samples = 12,
  }) {
    final adaptiveSamples = math.max(
      samples,
      (_distanceMeters(a, b) / segmentSampleSpacingMeters).ceil(),
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

  List<LatLng>? _findBoundaryConstrainedCorridorPath({
    required LatLng entry,
    required LatLng exit,
    required List<LatLng> corridorPolygon,
  }) {
    final anchors = _buildBoundaryAnchors(corridorPolygon);
    if (anchors.length < 3) return null;

    final graphPoints = <LatLng>[entry, exit, ...anchors];
    final adjacency = <int, List<IndoorRoutingEdge>>{
      for (int i = 0; i < graphPoints.length; i++) i: <IndoorRoutingEdge>[],
    };

    void addEdge(int a, int b) {
      final w = _distanceMeters(graphPoints[a], graphPoints[b]);
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
        if (_segmentInsidePolygon(
          graphPoints[source],
          graphPoints[anchorId],
          corridorPolygon,
        )) {
          addEdge(source, anchorId);
        }
      }
    }

    if (_distanceMeters(entry, exit) <= 8.0 &&
        _segmentInsidePolygon(entry, exit, corridorPolygon)) {
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

  List<LatLng> _buildBoundaryAnchors(List<LatLng> polygon) {
    final closed = floorGraphBuilder.ensureClosedPolygon(polygon);
    if (closed.length < 4) return const [];

    final anchors = <LatLng>[];

    for (int i = 0; i < closed.length - 1; i++) {
      final a = closed[i];
      final b = closed[i + 1];

      if (anchors.isEmpty || !areSameLatLng(anchors.last, a)) {
        anchors.add(a);
      }

      final d = _distanceMeters(a, b);
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

  List<LatLng>? _fallbackAlongCorridorBoundary({
    required LatLng entry,
    required LatLng exit,
    required List<LatLng> corridorPolygon,
  }) {
    final ring = floorGraphBuilder.ensureClosedPolygon(corridorPolygon);
    if (ring.length < 4) return null;

    final vertices = ring.sublist(0, ring.length - 1);
    if (vertices.length < 3) return null;

    final startIdx = _nearestVertexIndex(entry, vertices);
    final endIdx = _nearestVertexIndex(exit, vertices);

    final forward = _ringPath(vertices, startIdx, endIdx, forward: true);
    final backward = _ringPath(vertices, startIdx, endIdx, forward: false);

    final forwardCost =
        _distanceMeters(entry, vertices[startIdx]) +
        _polylineLengthMeters(forward) +
        _distanceMeters(vertices[endIdx], exit);

    final backwardCost =
        _distanceMeters(entry, vertices[startIdx]) +
        _polylineLengthMeters(backward) +
        _distanceMeters(vertices[endIdx], exit);

    final best = forwardCost <= backwardCost ? forward : backward;

    return <LatLng>[entry, ...best, exit];
  }

  int _nearestVertexIndex(LatLng point, List<LatLng> vertices) {
    var bestIdx = 0;
    var bestDist = double.infinity;

    for (int i = 0; i < vertices.length; i++) {
      final d = _distanceMeters(point, vertices[i]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }

    return bestIdx;
  }

  List<LatLng> _ringPath(
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

  double _polylineLengthMeters(List<LatLng> pts) {
    if (pts.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < pts.length; i++) {
      total += _distanceMeters(pts[i - 1], pts[i]);
    }
    return total;
  }

  double _distanceMeters(LatLng a, LatLng b) {
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

  double _distanceScore(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
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

  bool areSameLatLng(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 1e-12 &&
        (a.longitude - b.longitude).abs() < 1e-12;
  }
}
