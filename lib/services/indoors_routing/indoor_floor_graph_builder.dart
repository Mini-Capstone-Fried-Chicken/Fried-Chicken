import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/geo.dart' as geo;
import 'indoor_boundary_adjacency.dart';
import 'indoor_routing_models.dart';

// Converts floor GeoJSON into indoor routing nodes + edges.
class IndoorFloorGraphBuilder {
  final IndoorBoundaryAdjacency boundaryAdjacency;

  IndoorFloorGraphBuilder({IndoorBoundaryAdjacency? boundaryAdjacency})
    : boundaryAdjacency = boundaryAdjacency ?? IndoorBoundaryAdjacency();

  // Parses the current floor GeoJSON and extracts only the polygons
  // relevant to indoor routing (rooms, corridors, transitions).
  List<IndoorRoutingNode> buildNodesFromFloorGeoJson(
    Map<String, dynamic> floorGeoJson,
  ) {
    final featuresRaw = floorGeoJson['features'];
    if (featuresRaw is! List) return const [];

    final nodes = <IndoorRoutingNode>[];

    for (final featureRaw in featuresRaw) {
      if (featureRaw is! Map) continue;
      final feature = featureRaw.cast<String, dynamic>();

      final polygonPoints = extractPolygonPointsFromFeature(feature);
      if (polygonPoints == null || polygonPoints.length < 3) continue;

      final properties =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

      final indoorType = properties['indoor']?.toString();
      final highwayType = properties['highway']?.toString();
      final escalatorFlag =
          properties['escalators']?.toString().toLowerCase() == 'yes';

      String? nodeType;
      String? roomCode;
      String? transitionType;

      if (indoorType == 'room' && properties['ref'] != null) {
        nodeType = IndoorRoutingNodeType.room;
        roomCode = properties['ref'].toString().trim().toUpperCase();
      } else if (indoorType == 'corridor') {
        nodeType = IndoorRoutingNodeType.corridor;
      } else if (highwayType == 'steps' ||
          highwayType == 'elevator' ||
          escalatorFlag) {
        // US-5.4 same-floor only: skip floor-transition nodes.
        continue;
      } else {
        continue;
      }

      final center = geo.polygonCenter(polygonPoints);
      final level = properties['level']?.toString();

      nodes.add(
        IndoorRoutingNode(
          id: nodes.length,
          nodeType: nodeType,
          roomCode: roomCode,
          transitionType: transitionType,
          level: level,
          center: center,
          polygonPoints: polygonPoints,
        ),
      );
    }

    return nodes;
  }

  // Builds the graph adjacency list by checking which nodes should connect.
  Map<int, List<IndoorRoutingEdge>> buildAdjacencyList(
    List<IndoorRoutingNode> nodes,
  ) {
    final adjacency = <int, List<IndoorRoutingEdge>>{};

    for (final node in nodes) {
      adjacency[node.id] = <IndoorRoutingEdge>[];
    }

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final nodeA = nodes[i];
        final nodeB = nodes[j];

        // Skip invalid node-type combinations.
        if (!shouldCreateEdge(nodeA, nodeB)) {
          continue;
        }

        final minimumSharedBoundaryMeters =
            nodeA.nodeType == IndoorRoutingNodeType.room ||
                nodeB.nodeType == IndoorRoutingNodeType.room
            ? IndoorBoundaryAdjacency.minimumSharedBoundaryRoomToWalkableMeters
            : IndoorBoundaryAdjacency
                  .minimumSharedBoundaryWalkableToWalkableMeters;

        final adjacent = boundaryAdjacency.polygonsAreAdjacentByBoundaryShare(
          polygonA: nodeA.polygonPoints,
          polygonB: nodeB.polygonPoints,
          minimumSharedBoundaryMeters: minimumSharedBoundaryMeters,
        );

        if (!adjacent) {
          continue;
        }

        // final edgeWeightMeters = latLngDistanceMeters(
        //   nodeA.center,
        //   nodeB.center,
        // );
        double edgeWeightMeters = latLngDistanceMeters(
          nodeA.center,
          nodeB.center,
        );

        // Trial fix:
        // corridor-to-corridor jumps are currently too cheap, which can create
        // fake shortcuts through large hallway polygons.
        // Penalize them for now so Dijkstra prefers more realistic paths.
        final bothCorridors =
            nodeA.nodeType == IndoorRoutingNodeType.corridor &&
            nodeB.nodeType == IndoorRoutingNodeType.corridor;

        if (bothCorridors) {
          edgeWeightMeters *= 2.5;
        }
        // Undirected edge: connect both ways.
        adjacency[nodeA.id]!.add(
          IndoorRoutingEdge(toNodeId: nodeB.id, weightMeters: edgeWeightMeters),
        );

        adjacency[nodeB.id]!.add(
          IndoorRoutingEdge(toNodeId: nodeA.id, weightMeters: edgeWeightMeters),
        );
      }
    }

    return adjacency;
  }

  // Rules for what kinds of nodes are allowed to connect.
  bool shouldCreateEdge(IndoorRoutingNode nodeA, IndoorRoutingNode nodeB) {
    final aRoom = nodeA.nodeType == IndoorRoutingNodeType.room;
    final bRoom = nodeB.nodeType == IndoorRoutingNodeType.room;

    if (aRoom && bRoom) {
      return false;
    }

    if (aRoom || bRoom) {
      return nodeA.isWalkable || nodeB.isWalkable;
    }

    return nodeA.isWalkable && nodeB.isWalkable;
  }

  // Extracts the outer polygon ring from a GeoJSON Polygon feature.
  List<LatLng>? extractPolygonPointsFromFeature(Map<String, dynamic> feature) {
    final geometryRaw = feature['geometry'];
    if (geometryRaw is! Map) return null;
    final geometry = geometryRaw.cast<String, dynamic>();

    if (geometry['type'] != 'Polygon') return null;

    final coordinatesRaw = geometry['coordinates'];
    if (coordinatesRaw is! List || coordinatesRaw.isEmpty) return null;

    final outerRingRaw = coordinatesRaw.first;
    if (outerRingRaw is! List) return null;

    final points = <LatLng>[];

    for (final pointRaw in outerRingRaw) {
      if (pointRaw is! List || pointRaw.length < 2) continue;

      final lngRaw = pointRaw[0];
      final latRaw = pointRaw[1];

      if (lngRaw is! num || latRaw is! num) continue;

      points.add(LatLng(latRaw.toDouble(), lngRaw.toDouble()));
    }

    if (points.length < 3) return null;

    return ensureClosedPolygon(points);
  }

  // Ensures the polygon is closed.
  List<LatLng> ensureClosedPolygon(List<LatLng> polygon) {
    if (polygon.isEmpty) return polygon;

    final first = polygon.first;
    final last = polygon.last;

    if (areSameLatLng(first, last)) {
      return polygon;
    }

    return [...polygon, first];
  }

  bool areSameLatLng(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 1e-12 &&
        (a.longitude - b.longitude).abs() < 1e-12;
  }

  // Great-circle distance between 2 node centers.
  double latLngDistanceMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;

    final dLat = degToRad(b.latitude - a.latitude);
    final dLng = degToRad(b.longitude - a.longitude);

    final lat1 = degToRad(a.latitude);
    final lat2 = degToRad(b.latitude);

    final haversine =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final centralAngle =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));

    return earthRadiusMeters * centralAngle;
  }

  double degToRad(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
