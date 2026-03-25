import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'core/indoor_dijkstra.dart';
import 'core/indoor_geometry.dart';
import 'core/indoor_routing_models.dart';
import 'graph/indoor_floor_graph_builder.dart';
import 'graph/indoor_graph_filter.dart';
import 'routing/indoor_corridor_path_builder.dart';
import 'routing/indoor_portal_selector.dart';
import 'routing/indoor_room_lookup.dart';
import 'routing/indoor_route_point_builder.dart';

class IndoorSameFloorRouter {
  final IndoorFloorGraphBuilder floorGraphBuilder;
  final IndoorDijkstra indoorDijkstra;
  final IndoorRoomLookup roomLookup;
  final IndoorGraphFilter graphFilter;
  final IndoorGeometry geometry;
  final IndoorPortalSelector portalSelector;
  final IndoorCorridorPathBuilder corridorPathBuilder;
  final IndoorRoutePointBuilder routePointBuilder;

  factory IndoorSameFloorRouter({
    IndoorFloorGraphBuilder? floorGraphBuilder,
    IndoorDijkstra? indoorDijkstra,
    IndoorRoomLookup? roomLookup,
    IndoorGraphFilter? graphFilter,
    IndoorGeometry? geometry,
    IndoorPortalSelector? portalSelector,
    IndoorCorridorPathBuilder? corridorPathBuilder,
    IndoorRoutePointBuilder? routePointBuilder,
  }) {
    final resolvedFloorBuilder = floorGraphBuilder ?? IndoorFloorGraphBuilder();
    final resolvedDijkstra = indoorDijkstra ?? IndoorDijkstra();
    final resolvedRoomLookup = roomLookup ?? const IndoorRoomLookup();
    final resolvedGraphFilter = graphFilter ?? const IndoorGraphFilter();
    final resolvedGeometry = geometry ?? const IndoorGeometry();
    final resolvedPortalSelector =
        portalSelector ??
        IndoorPortalSelector(
          floorGraphBuilder: resolvedFloorBuilder,
          geometry: resolvedGeometry,
        );
    final resolvedCorridorPathBuilder =
        corridorPathBuilder ??
        IndoorCorridorPathBuilder(
          floorGraphBuilder: resolvedFloorBuilder,
          indoorDijkstra: resolvedDijkstra,
          geometry: resolvedGeometry,
        );
    final resolvedRoutePointBuilder =
        routePointBuilder ??
        IndoorRoutePointBuilder(
          portalSelector: resolvedPortalSelector,
          corridorPathBuilder: resolvedCorridorPathBuilder,
          geometry: resolvedGeometry,
        );

    return IndoorSameFloorRouter._(
      floorGraphBuilder: resolvedFloorBuilder,
      indoorDijkstra: resolvedDijkstra,
      roomLookup: resolvedRoomLookup,
      graphFilter: resolvedGraphFilter,
      geometry: resolvedGeometry,
      portalSelector: resolvedPortalSelector,
      corridorPathBuilder: resolvedCorridorPathBuilder,
      routePointBuilder: resolvedRoutePointBuilder,
    );
  }

  const IndoorSameFloorRouter._({
    required this.floorGraphBuilder,
    required this.indoorDijkstra,
    required this.roomLookup,
    required this.graphFilter,
    required this.geometry,
    required this.portalSelector,
    required this.corridorPathBuilder,
    required this.routePointBuilder,
  });

  bool roomExistsOnFloor({
    required Map<String, dynamic> floorGeoJson,
    required String roomCode,
  }) {
    return roomCenterOnFloor(floorGeoJson: floorGeoJson, roomCode: roomCode) !=
        null;
  }

  List<IndoorRoutingNode> buildNodesFromFloorGeoJson(
    Map<String, dynamic> floorGeoJson,
  ) {
    return floorGraphBuilder.buildNodesFromFloorGeoJson(floorGeoJson);
  }

  LatLng? roomCenterOnFloor({
    required Map<String, dynamic> floorGeoJson,
    required String roomCode,
  }) {
    final nodes = buildNodesFromFloorGeoJson(floorGeoJson);
    if (nodes.isEmpty) return null;

    final byRoomCode = roomLookup.indexByRoomCode(nodes);
    return roomLookup.findRoomCenter(byRoomCode, roomCode);
  }

  IndoorRoutingNode? roomNodeOnFloor({
    required Map<String, dynamic> floorGeoJson,
    required String roomCode,
  }) {
    final nodes = buildNodesFromFloorGeoJson(floorGeoJson);
    if (nodes.isEmpty) return null;

    final byRoomCode = roomLookup.indexByRoomCode(nodes);
    return roomLookup.findRoomNode(byRoomCode, roomCode);
  }

  List<IndoorRoutingNode> transitionNodesOnFloor({
    required Map<String, dynamic> floorGeoJson,
    String? transitionType,
  }) {
    return buildNodesFromFloorGeoJson(floorGeoJson)
        .where(
          (node) =>
              node.nodeType == IndoorRoutingNodeType.transition &&
              (transitionType == null || node.transitionType == transitionType),
        )
        .toList(growable: false);
  }

  List<LatLng>? findShortestPath({
    required Map<String, dynamic> floorGeoJson,
    required String originRoomCode,
    required String destinationRoomCode,
    bool enforceRoomSafeSegments = false,
  }) {
    final nodes = buildNodesFromFloorGeoJson(floorGeoJson);
    if (nodes.isEmpty) return null;

    final byRoomCode = roomLookup.indexByRoomCode(nodes);
    final originNode = roomLookup.findRoomNode(byRoomCode, originRoomCode);
    final destinationNode = roomLookup.findRoomNode(
      byRoomCode,
      destinationRoomCode,
    );

    if (originNode == null || destinationNode == null) {
      return null;
    }

    if (originNode.id == destinationNode.id) {
      return [originNode.center];
    }

    return findShortestPathBetweenNodeIds(
      nodes: nodes,
      startNodeId: originNode.id,
      endNodeId: destinationNode.id,
      allowedRoomIds: {originNode.id, destinationNode.id},
      enforceRoomSafeSegments: enforceRoomSafeSegments,
    );
  }

  List<LatLng>? findShortestPathBetweenNodeIds({
    required List<IndoorRoutingNode> nodes,
    required int startNodeId,
    required int endNodeId,
    required Set<int> allowedRoomIds,
    bool enforceRoomSafeSegments = false,
  }) {
    if (nodes.isEmpty) {
      return null;
    }

    if (startNodeId == endNodeId) {
      for (final node in nodes) {
        if (node.id == startNodeId) {
          return [node.center];
        }
      }
      return null;
    }

    final adjacency = floorGraphBuilder.buildAdjacencyList(nodes);
    final filteredAdjacency = graphFilter.withoutIntermediateRooms(
      adjacency: adjacency,
      nodes: nodes,
      allowedRoomIds: allowedRoomIds,
    );

    final pathNodeIds = indoorDijkstra.shortestPathNodeIds(
      adjacency: filteredAdjacency,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );

    if (pathNodeIds == null || pathNodeIds.isEmpty) {
      return null;
    }

    final routePoints = routePointBuilder.buildRoutePointsFromNodePath(
      pathNodeIds: pathNodeIds,
      nodes: nodes,
      allowedRoomIds: allowedRoomIds,
      enforceRoomSafeSegments: enforceRoomSafeSegments,
    );

    if (routePoints.length < 2) {
      return null;
    }

    return geometry.removeConsecutiveDuplicatePoints(routePoints);
  }

  List<LatLng> buildRoutePointsFromNodePath({
    required List<int> pathNodeIds,
    required List<IndoorRoutingNode> nodes,
    required Set<int> allowedRoomIds,
    bool enforceRoomSafeSegments = false,
  }) {
    return routePointBuilder.buildRoutePointsFromNodePath(
      pathNodeIds: pathNodeIds,
      nodes: nodes,
      allowedRoomIds: allowedRoomIds,
      enforceRoomSafeSegments: enforceRoomSafeSegments,
    );
  }

  List<LatLng> removeConsecutiveDuplicatePoints(List<LatLng> points) {
    return geometry.removeConsecutiveDuplicatePoints(points);
  }

  bool areSameLatLng(LatLng a, LatLng b) {
    return geometry.areSameLatLng(a, b);
  }
}
