import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/geo.dart' as geo;
import 'indoor_boundary_adjacency.dart';
import 'indoor_routing_models.dart';

// Converts floor GeoJSON into indoor routing nodes + edges.
class IndoorFloorGraphBuilder {
  static const double _minCorridorAnchorSpacingMeters = 1.0;
  static const double _minCorridorTurnAngleDegrees = 20.0;
  static const int _maxCorridorAnchorsPerPolygon = 14;

  final IndoorBoundaryAdjacency boundaryAdjacency;

  IndoorFloorGraphBuilder({IndoorBoundaryAdjacency? boundaryAdjacency})
    : boundaryAdjacency = boundaryAdjacency ?? IndoorBoundaryAdjacency();

  // Parses the current floor GeoJSON and extracts only the polygons
  // relevant to indoor routing.
  List<IndoorRoutingNode> buildNodesFromFloorGeoJson(
    Map<String, dynamic> floorGeoJson,
  ) {
    final featuresRaw = floorGeoJson['features'];
    if (featuresRaw is! List) return const [];

    final nodes = <IndoorRoutingNode>[];

    for (final featureRaw in featuresRaw) {
      if (featureRaw is! Map) continue;
      final feature = featureRaw.cast<String, dynamic>();

      final rings = extractPolygonRingsFromFeature(feature);
      if (rings == null) continue;

      final outerRing = rings.outerRing;
      final holeRings = rings.holeRings;

      if (outerRing.length < 3) continue;

      final properties =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

      final indoorType = properties['indoor']?.toString();
      final highwayType = properties['highway']?.toString();
      final escalatorFlag =
          properties['escalators']?.toString().toLowerCase() == 'yes';
      final level = properties['level']?.toString();

      if (indoorType == 'room') {
        final ref = properties['ref']?.toString().trim().toUpperCase();
        final roomCode = (ref == null || ref.isEmpty) ? null : ref;
        final center = geo.polygonCenter(outerRing);

        nodes.add(
          IndoorRoutingNode(
            id: nodes.length,
            nodeType: IndoorRoutingNodeType.room,
            roomCode: roomCode,
            transitionType: null,
            level: level,
            center: center,
            polygonPoints: outerRing,
            holePolygons: holeRings,
          ),
        );
        continue;
      }

      if (indoorType == 'corridor') {
        _addCorridorNodes(
          nodes: nodes,
          corridorPolygon: outerRing,
          holePolygons: holeRings,
          level: level,
        );
        continue;
      }

      // US-5.4 same-floor only: skip transitions for now.
      if (highwayType == 'steps' ||
          highwayType == 'elevator' ||
          escalatorFlag) {
        continue;
      }
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

        final sameCorridorPolygon =
            nodeA.nodeType == IndoorRoutingNodeType.corridor &&
            nodeB.nodeType == IndoorRoutingNodeType.corridor &&
            identical(nodeA.polygonPoints, nodeB.polygonPoints);

        // If both nodes belong to the exact same corridor polygon,
        // only connect them if the segment stays inside that corridor
        // and outside all its holes.
        if (sameCorridorPolygon) {
          final inside = _segmentInsidePolygonWithHoles(
            nodeA.center,
            nodeB.center,
            nodeA.polygonPoints,
            nodeA.holePolygons,
          );

          if (inside) {
            final edgeWeightMeters = latLngDistanceMeters(
              nodeA.center,
              nodeB.center,
            );

            adjacency[nodeA.id]!.add(
              IndoorRoutingEdge(
                toNodeId: nodeB.id,
                weightMeters: edgeWeightMeters,
              ),
            );

            adjacency[nodeB.id]!.add(
              IndoorRoutingEdge(
                toNodeId: nodeA.id,
                weightMeters: edgeWeightMeters,
              ),
            );
          }
          continue;
        }

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

        final edgeWeightMeters = latLngDistanceMeters(
          nodeA.center,
          nodeB.center,
        );

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

  void _addCorridorNodes({
    required List<IndoorRoutingNode> nodes,
    required List<LatLng> corridorPolygon,
    required List<List<LatLng>> holePolygons,
    required String? level,
  }) {
    final center = geo.polygonCenter(corridorPolygon);

    nodes.add(
      IndoorRoutingNode(
        id: nodes.length,
        nodeType: IndoorRoutingNodeType.corridor,
        roomCode: null,
        transitionType: null,
        level: level,
        center: center,
        polygonPoints: corridorPolygon,
        holePolygons: holePolygons,
      ),
    );

    final anchors = _extractMeaningfulCorridorVertices(corridorPolygon);

    for (final anchor in anchors) {
      if (latLngDistanceMeters(center, anchor) <
          _minCorridorAnchorSpacingMeters) {
        continue;
      }

      nodes.add(
        IndoorRoutingNode(
          id: nodes.length,
          nodeType: IndoorRoutingNodeType.corridor,
          roomCode: null,
          transitionType: null,
          level: level,
          center: anchor,
          polygonPoints: corridorPolygon,
          holePolygons: holePolygons,
        ),
      );
    }
  }

  List<LatLng> _extractMeaningfulCorridorVertices(List<LatLng> polygon) {
    final ring = _openRing(polygon);
    if (ring.length < 3) return const [];

    final anchors = <LatLng>[];

    for (int i = 0; i < ring.length; i++) {
      final prev = ring[(i - 1 + ring.length) % ring.length];
      final curr = ring[i];
      final next = ring[(i + 1) % ring.length];

      final turn = _turnAngleDegrees(prev, curr, next);
      if (turn < _minCorridorTurnAngleDegrees) {
        continue;
      }

      final tooClose = anchors.any(
        (p) => latLngDistanceMeters(p, curr) < _minCorridorAnchorSpacingMeters,
      );

      if (!tooClose) {
        anchors.add(curr);
      }
    }

    if (anchors.isEmpty) {
      final stride = math.max(1, ring.length ~/ 4);
      for (int i = 0; i < ring.length; i += stride) {
        anchors.add(ring[i]);
        if (anchors.length == 4) break;
      }
    }

    if (anchors.length <= _maxCorridorAnchorsPerPolygon) {
      return anchors;
    }

    final reduced = <LatLng>[];
    final step = (anchors.length / _maxCorridorAnchorsPerPolygon).ceil();

    for (int i = 0; i < anchors.length; i += step) {
      reduced.add(anchors[i]);
    }

    return reduced;
  }

  List<LatLng> _openRing(List<LatLng> polygon) {
    if (polygon.length > 1 && areSameLatLng(polygon.first, polygon.last)) {
      return polygon.sublist(0, polygon.length - 1);
    }
    return List<LatLng>.from(polygon);
  }

  double _turnAngleDegrees(LatLng prev, LatLng curr, LatLng next) {
    final ax = curr.longitude - prev.longitude;
    final ay = curr.latitude - prev.latitude;
    final bx = next.longitude - curr.longitude;
    final by = next.latitude - curr.latitude;

    final normA = math.sqrt(ax * ax + ay * ay);
    final normB = math.sqrt(bx * bx + by * by);
    if (normA == 0.0 || normB == 0.0) return 0.0;

    final cosTheta = ((ax * bx + ay * by) / (normA * normB)).clamp(-1.0, 1.0);
    return math.acos(cosTheta) * (180.0 / math.pi);
  }

  bool _segmentInsidePolygonWithHoles(
    LatLng a,
    LatLng b,
    List<LatLng> outerPolygon,
    List<List<LatLng>> holePolygons, {
    int samples = 14,
  }) {
    for (int i = 1; i < samples; i++) {
      final t = i / samples;
      final p = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

      final insideOuter = geo.pointInPolygon(p, outerPolygon);
      if (!insideOuter) {
        if (_distancePointToBoundaryMeters(p, outerPolygon) >
            IndoorBoundaryAdjacency.adjacencyEpsilonMeters) {
          return false;
        }
      }

      final insideHole = holePolygons.any(
        (hole) => geo.pointInPolygon(p, hole),
      );
      if (insideHole) {
        return false;
      }
    }

    return true;
  }

  double _distancePointToBoundaryMeters(LatLng point, List<LatLng> polygon) {
    final referenceLat = polygon.first.latitude;
    final referenceLng = polygon.first.longitude;

    final localPolygon = boundaryAdjacency.convertPolygonToLocalMeters(
      polygon: polygon,
      referenceLat: referenceLat,
      referenceLng: referenceLng,
    );

    final localPoint = boundaryAdjacency
        .convertPolygonToLocalMeters(
          polygon: [point],
          referenceLat: referenceLat,
          referenceLng: referenceLng,
        )
        .first;

    return boundaryAdjacency.minimumDistanceFromPointToPolygonBoundaryMeters(
      point: localPoint,
      polygon: localPolygon,
    );
  }

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

  ({List<LatLng> outerRing, List<List<LatLng>> holeRings})?
  extractPolygonRingsFromFeature(Map<String, dynamic> feature) {
    final geometryRaw = feature['geometry'];
    if (geometryRaw is! Map) return null;
    final geometry = geometryRaw.cast<String, dynamic>();

    if (geometry['type'] != 'Polygon') return null;

    final coordinatesRaw = geometry['coordinates'];
    if (coordinatesRaw is! List || coordinatesRaw.isEmpty) return null;

    final parsedRings = <List<LatLng>>[];

    for (final ringRaw in coordinatesRaw) {
      if (ringRaw is! List) continue;

      final points = <LatLng>[];

      for (final pointRaw in ringRaw) {
        if (pointRaw is! List || pointRaw.length < 2) continue;

        final lngRaw = pointRaw[0];
        final latRaw = pointRaw[1];

        if (lngRaw is! num || latRaw is! num) continue;

        points.add(LatLng(latRaw.toDouble(), lngRaw.toDouble()));
      }

      if (points.length >= 3) {
        parsedRings.add(ensureClosedPolygon(points));
      }
    }

    if (parsedRings.isEmpty) return null;

    return (
      outerRing: parsedRings.first,
      holeRings: parsedRings.length > 1 ? parsedRings.sublist(1) : const [],
    );
  }

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
