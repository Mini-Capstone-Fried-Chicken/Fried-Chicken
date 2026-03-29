import 'package:google_maps_flutter/google_maps_flutter.dart';

// String constants for the supported indoor node types.
// Keeping these in one place avoids hardcoding raw strings everywhere.
class IndoorRoutingNodeType {
  static const String room = 'room';
  static const String corridor = 'corridor';
  static const String transition = 'transition';
}

class IndoorTransitionType {
  static const String stairs = 'stairs';
  static const String elevator = 'elevator';
  static const String escalator = 'escalator';
}

// A node used in the indoor routing graph.
// Each node comes from one polygon in the floor GeoJSON.
class IndoorRoutingNode {
  final int id;
  final String nodeType;
  final String? roomCode;
  final String? transitionType;
  final String? level;
  final LatLng center;

  // Outer polygon ring.
  final List<LatLng> polygonPoints;

  // Inner polygon rings (holes), if any.
  final List<List<LatLng>> holePolygons;

  const IndoorRoutingNode({
    required this.id,
    required this.nodeType,
    required this.roomCode,
    required this.transitionType,
    required this.level,
    required this.center,
    required this.polygonPoints,
    this.holePolygons = const [],
  });

  // Rooms are not considered walkable connectors in the graph.
  // Corridors and transitions are.
  bool get isWalkable => nodeType != IndoorRoutingNodeType.room;

  bool get isTransition => nodeType == IndoorRoutingNodeType.transition;
}

// A weighted edge from one routing node to another.
class IndoorRoutingEdge {
  final int toNodeId;
  final double weightMeters;

  const IndoorRoutingEdge({required this.toNodeId, required this.weightMeters});
}

// A local XY point in meters.
// Used for geometry calculations after converting from lat/lng.
class LocalPointMeters {
  final double x;
  final double y;

  const LocalPointMeters({required this.x, required this.y});
}

// Bounding box in local meter space.
// Used as a quick filter before doing more expensive polygon checks.
class PolygonBoundsMeters {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const PolygonBoundsMeters({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });
}
