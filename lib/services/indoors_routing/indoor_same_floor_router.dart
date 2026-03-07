import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/geo.dart' as geo;
import 'indoor_boundary_adjacency.dart';
import 'indoor_dijkstra.dart';
import 'indoor_floor_graph_builder.dart';
import 'indoor_routing_models.dart';

// Main public service for same-floor indoor routing.
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

  // Returns true if the room exists on the currently loaded floor.
  bool roomExistsOnFloor({
    required Map<String, dynamic> floorGeoJson,
    required String roomCode,
  }) {
    return roomCenterOnFloor(floorGeoJson: floorGeoJson, roomCode: roomCode) !=
        null;
  }

  // Finds the center point of a given room on the current floor.
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

  // Builds the graph from GeoJSON, finds the shortest node path,
  // then converts that node path into drawable route points.
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

      if (node.roomCode == originCode) {
        originNode = node;
      }

      if (node.roomCode == destinationCode) {
        destinationNode = node;
      }
    }

    if (originNode == null || destinationNode == null) {
      return null;
    }

    // If start and end are the same room, return that single point.
    if (originNode.id == destinationNode.id) {
      return [originNode.center];
    }

    final adjacency = floorGraphBuilder.buildAdjacencyList(nodes);

    // Prevent the graph from using other rooms as hallway shortcuts.
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

    // ---------- DEBUG OUTPUT ----------
    print('--- INDOOR ROUTE DEBUG ---');
    print('Origin room: $originCode (node ${originNode.id})');
    print('Destination room: $destinationCode (node ${destinationNode.id})');
    print('Path node IDs: $pathNodeIds');

    if (pathNodeIds != null) {
      for (final nodeId in pathNodeIds) {
        final node = nodes[nodeId];
        print(
          'Node $nodeId | type=${node.nodeType} | room=${node.roomCode} | center=${node.center}',
        );
      }

      print(
        'Total chosen path weight: ${_pathWeight(pathNodeIds, filteredAdjacency)}',
      );
    }

    print('Origin neighbors:');
    for (final edge in filteredAdjacency[originNode.id] ?? const []) {
      final n = nodes[edge.toNodeId];
      print(
        '  -> node ${n.id} | type=${n.nodeType} | room=${n.roomCode} | weight=${edge.weightMeters}',
      );
    }

    print('Destination neighbors:');
    for (final edge in filteredAdjacency[destinationNode.id] ?? const []) {
      final n = nodes[edge.toNodeId];
      print(
        '  -> node ${n.id} | type=${n.nodeType} | room=${n.roomCode} | weight=${edge.weightMeters}',
      );
    }

    print('--- CORRIDOR GRAPH ---');
    for (final node in nodes) {
      if (node.nodeType != IndoorRoutingNodeType.corridor) continue;

      print('Corridor node ${node.id} center=${node.center}');
      for (final edge in filteredAdjacency[node.id] ?? const []) {
        final neighbor = nodes[edge.toNodeId];
        print(
          '  -> ${neighbor.id} type=${neighbor.nodeType} room=${neighbor.roomCode} weight=${edge.weightMeters}',
        );
      }
    }
    print('----------------------');
    // ---------- END DEBUG OUTPUT ----------

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

  // Removes all rooms from the graph except the origin and destination rooms.
  // This prevents the shortest path from cutting through unrelated rooms.
  Map<int, List<IndoorRoutingEdge>> _withoutIntermediateRooms({
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required List<IndoorRoutingNode> nodes,
    required Set<int> allowedRoomIds,
  }) {
    final blockedRoomIds = <int>{};

    for (final node in nodes) {
      final isRoom = node.nodeType == IndoorRoutingNodeType.room;
      if (isRoom && !allowedRoomIds.contains(node.id)) {
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
        if (blockedRoomIds.contains(edge.toNodeId)) {
          continue;
        }
        keptEdges.add(edge);
      }

      filtered[fromNodeId] = keptEdges;
    }

    return filtered;
  }

  // Builds the final drawn route from the node path.
  // Route shape:
  // room center -> portal -> corridor center/bend -> portal -> ... -> room center
  List<LatLng> buildRoutePointsFromNodePath({
    required List<int> pathNodeIds,
    required List<IndoorRoutingNode> nodes,
  }) {
    if (pathNodeIds.isEmpty) return const [];

    final nodeById = <int, IndoorRoutingNode>{
      for (final node in nodes) node.id: node,
    };

    final orderedNodes = <IndoorRoutingNode>[];
    for (final nodeId in pathNodeIds) {
      final node = nodeById[nodeId];
      if (node != null) {
        orderedNodes.add(node);
      }
    }

    if (orderedNodes.isEmpty) return const [];

    final startNode = orderedNodes.first;
    final endNode = orderedNodes.last;

    final points = <LatLng>[startNode.center];

    // Single-edge path: room -> portal -> room/walkable target.
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

      // Guard: intermediate room nodes should not normally happen anymore.
      if (currentNode.nodeType == IndoorRoutingNodeType.room) {
        if (exitPortal != null && !areSameLatLng(points.last, exitPortal)) {
          points.add(exitPortal);
        }
        continue;
      }

      // If we do not have enough portal information, fall back gently.
      if (entryPortal == null || exitPortal == null) {
        if (entryPortal != null && !areSameLatLng(points.last, entryPortal)) {
          points.add(entryPortal);
        }
        if (!areSameLatLng(points.last, currentNode.center)) {
          points.add(currentNode.center);
        }
        if (exitPortal != null && !areSameLatLng(points.last, exitPortal)) {
          points.add(exitPortal);
        }
        continue;
      }

      // Best case: go directly from entry portal to exit portal inside corridor.
      final directInside = _segmentInsidePolygon(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
      );

      if (directInside) {
        if (!areSameLatLng(points.last, entryPortal)) {
          points.add(entryPortal);
        }
        if (!areSameLatLng(points.last, exitPortal)) {
          points.add(exitPortal);
        }
        continue;
      }

      // Next best: try a single bend point from the corridor polygon.
      final bendPoint = _findCorridorBendPoint(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
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
        continue;
      }

      // Next best after that: try two bend points.
      final bendPair = _findCorridorTwoBendPath(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
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
        continue;
      }

      // Next best: route through corridor center only if safe.
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
        if (!areSameLatLng(points.last, entryPortal)) {
          points.add(entryPortal);
        }
        if (!areSameLatLng(points.last, currentNode.center)) {
          points.add(currentNode.center);
        }
        if (!areSameLatLng(points.last, exitPortal)) {
          points.add(exitPortal);
        }
        continue;
      }

      // Final visual fallback.
      if (!areSameLatLng(points.last, entryPortal)) {
        points.add(entryPortal);
      }
      if (!areSameLatLng(points.last, currentNode.center)) {
        points.add(currentNode.center);
      }
      if (!areSameLatLng(points.last, exitPortal)) {
        points.add(exitPortal);
      }
    }

    if (!areSameLatLng(points.last, endNode.center)) {
      points.add(endNode.center);
    }

    return removeConsecutiveDuplicatePoints(points);
  }

  LatLng? _portalBetween(IndoorRoutingNode a, IndoorRoutingNode b) {
    final minSharedBoundary =
        (a.nodeType == IndoorRoutingNodeType.room ||
            b.nodeType == IndoorRoutingNodeType.room)
        ? minimumSharedBoundaryRoomToWalkableMeters
        : minimumSharedBoundaryWalkableToWalkableMeters;

    return floorGraphBuilder.boundaryAdjacency.sharedBoundaryMidpoint(
      polygonA: a.polygonPoints,
      polygonB: b.polygonPoints,
      minimumSharedBoundaryMeters: minSharedBoundary,
    );
  }

  // Tries to find a bend point inside a corridor polygon so the route can turn
  // without cutting through walls.
  LatLng? _findCorridorBendPoint(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon,
  ) {
    LatLng? bestCandidate;
    double bestScore = double.infinity;

    for (final candidate in corridorPolygon) {
      if (areSameLatLng(candidate, entry) || areSameLatLng(candidate, exit)) {
        continue;
      }

      final entryOk = _segmentInsidePolygon(entry, candidate, corridorPolygon);
      final exitOk = _segmentInsidePolygon(candidate, exit, corridorPolygon);

      if (!entryOk || !exitOk) {
        continue;
      }

      final score =
          _distanceScore(entry, candidate) + _distanceScore(candidate, exit);

      if (score < bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    return bestCandidate;
  }

  (LatLng, LatLng)? _findCorridorTwoBendPath(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon,
  ) {
    LatLng? bestA;
    LatLng? bestB;
    double bestScore = double.infinity;

    for (final candidateA in corridorPolygon) {
      if (areSameLatLng(candidateA, entry) || areSameLatLng(candidateA, exit)) {
        continue;
      }

      for (final candidateB in corridorPolygon) {
        if (areSameLatLng(candidateB, entry) ||
            areSameLatLng(candidateB, exit) ||
            areSameLatLng(candidateA, candidateB)) {
          continue;
        }

        final firstOk = _segmentInsidePolygon(
          entry,
          candidateA,
          corridorPolygon,
        );
        final secondOk = _segmentInsidePolygon(
          candidateA,
          candidateB,
          corridorPolygon,
        );
        final thirdOk = _segmentInsidePolygon(
          candidateB,
          exit,
          corridorPolygon,
        );

        if (!firstOk || !secondOk || !thirdOk) {
          continue;
        }

        final score =
            _distanceScore(entry, candidateA) +
            _distanceScore(candidateA, candidateB) +
            _distanceScore(candidateB, exit);

        if (score < bestScore) {
          bestScore = score;
          bestA = candidateA;
          bestB = candidateB;
        }
      }
    }

    if (bestA == null || bestB == null) {
      return null;
    }

    return (bestA, bestB);
  }

  // Checks whether a segment stays inside a polygon by sampling points along it.
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

      if (!geo.pointInPolygon(p, polygon)) {
        return false;
      }
    }

    return true;
  }

  double _distanceScore(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }

  double _pathWeight(
    List<int> pathNodeIds,
    Map<int, List<IndoorRoutingEdge>> adjacency,
  ) {
    double total = 0.0;

    for (int i = 0; i < pathNodeIds.length - 1; i++) {
      final from = pathNodeIds[i];
      final to = pathNodeIds[i + 1];

      final edges = adjacency[from] ?? const [];
      IndoorRoutingEdge? found;

      for (final edge in edges) {
        if (edge.toNodeId == to) {
          found = edge;
          break;
        }
      }

      if (found != null) {
        total += found.weightMeters;
      }
    }

    return total;
  }

  // Cleans up repeated consecutive points before drawing the polyline.
  List<LatLng> removeConsecutiveDuplicatePoints(List<LatLng> points) {
    if (points.length <= 1) {
      return points;
    }

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
