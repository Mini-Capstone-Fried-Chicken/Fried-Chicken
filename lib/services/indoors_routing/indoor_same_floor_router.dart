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
  }) {
    if (pathNodeIds.isEmpty) return const [];

    final nodeById = {for (final n in nodes) n.id: n};

    final orderedNodes = <IndoorRoutingNode>[];

    for (final id in pathNodeIds) {
      final node = nodeById[id];
      if (node != null) orderedNodes.add(node);
    }

    if (orderedNodes.isEmpty) return const [];

    final startNode = orderedNodes.first;
    final endNode = orderedNodes.last;

    final points = <LatLng>[startNode.center];

    if (orderedNodes.length == 2) {
      final portal = _portalBetween(orderedNodes[0], orderedNodes[1]);

      if (portal != null && !areSameLatLng(points.last, portal)) {
        points.add(portal);
      }

      if (!areSameLatLng(points.last, endNode.center)) {
        points.add(endNode.center);
      }

      return removeConsecutiveDuplicatePoints(points);
    }

    final firstPortal = _portalBetween(orderedNodes[0], orderedNodes[1]);

    if (firstPortal != null && !areSameLatLng(points.last, firstPortal)) {
      points.add(firstPortal);
    }

    for (int i = 1; i < orderedNodes.length - 1; i++) {
      final currentNode = orderedNodes[i];
      final previousNode = orderedNodes[i - 1];
      final nextNode = orderedNodes[i + 1];

      final entryPortal = _portalBetween(previousNode, currentNode);
      final exitPortal = _portalBetween(currentNode, nextNode);

      if (entryPortal == null || exitPortal == null) continue;

      final directInside = _segmentInsidePolygon(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
      );

      if (directInside) {
        points.add(entryPortal);
        points.add(exitPortal);
        continue;
      }

      final bendPoint = _findCorridorBendPoint(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
      );

      if (bendPoint != null) {
        points.add(entryPortal);
        points.add(bendPoint);
        points.add(exitPortal);
        continue;
      }

      final bendPair = _findCorridorTwoBendPath(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
      );

      if (bendPair != null) {
        points.add(entryPortal);
        points.add(bendPair.$1);
        points.add(bendPair.$2);
        points.add(exitPortal);
        continue;
      }

      final entryToCenterInside = _segmentInsidePolygon(
        entryPortal,
        currentNode.center,
        currentNode.polygonPoints,
      );

      final centerToExitInside = _segmentInsidePolygon(
        currentNode.center,
        exitPortal,
        currentNode.polygonPoints,
      );

      if (entryToCenterInside && centerToExitInside) {
        points.add(entryPortal);
        points.add(currentNode.center);
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

  LatLng? _findCorridorBendPoint(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon,
  ) {
    LatLng? best;
    double bestScore = double.infinity;

    for (final candidate in corridorPolygon) {
      if (areSameLatLng(candidate, entry) || areSameLatLng(candidate, exit)) {
        continue;
      }

      final entryOk = _segmentInsidePolygon(entry, candidate, corridorPolygon);
      final exitOk = _segmentInsidePolygon(candidate, exit, corridorPolygon);

      if (!entryOk || !exitOk) continue;

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
    List<LatLng> corridorPolygon,
  ) {
    LatLng? bestA;
    LatLng? bestB;
    double bestScore = double.infinity;

    for (final a in corridorPolygon) {
      if (areSameLatLng(a, entry) || areSameLatLng(a, exit)) continue;

      for (final b in corridorPolygon) {
        if (areSameLatLng(b, entry) ||
            areSameLatLng(b, exit) ||
            areSameLatLng(a, b))
          continue;

        final firstOk = _segmentInsidePolygon(entry, a, corridorPolygon);
        final secondOk = _segmentInsidePolygon(a, b, corridorPolygon);
        final thirdOk = _segmentInsidePolygon(b, exit, corridorPolygon);

        if (!firstOk || !secondOk || !thirdOk) continue;

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

    if (bestA == null || bestB == null) return null;

    return (bestA, bestB);
  }

  bool _segmentInsidePolygon(
    LatLng a,
    LatLng b,
    List<LatLng> polygon, {
    int samples = 12,
  }) {
    for (int i = 1; i < samples; i++) {
      final t = i / samples;
      final p = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

      if (!geo.pointInPolygon(p, polygon)) return false;
    }

    return true;
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
