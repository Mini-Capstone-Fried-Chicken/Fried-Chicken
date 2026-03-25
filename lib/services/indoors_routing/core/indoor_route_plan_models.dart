import 'package:google_maps_flutter/google_maps_flutter.dart';

enum IndoorTransitionMode { stairs, elevator, escalator }

enum IndoorRouteSegmentKind { walk, transition }

class IndoorResolvedRoom {
  final String buildingCode;
  final String roomCode;
  final String floorLabel;
  final String floorLevel;
  final String floorAssetPath;
  final Map<String, dynamic> floorGeoJson;
  final LatLng center;

  const IndoorResolvedRoom({
    required this.buildingCode,
    required this.roomCode,
    required this.floorLabel,
    required this.floorLevel,
    required this.floorAssetPath,
    required this.floorGeoJson,
    required this.center,
  });
}

class IndoorRouteSegment {
  final IndoorRouteSegmentKind kind;
  final String floorAssetPath;
  final String floorLabel;
  final List<LatLng> points;
  final IndoorTransitionMode? transitionMode;
  final String? fromFloorLabel;
  final String? toFloorLabel;
  final String? instruction;

  const IndoorRouteSegment({
    required this.kind,
    required this.floorAssetPath,
    required this.floorLabel,
    required this.points,
    this.transitionMode,
    this.fromFloorLabel,
    this.toFloorLabel,
    this.instruction,
  });
}

class IndoorRoutePlan {
  final String buildingCode;
  final String originRoomCode;
  final String destinationRoomCode;
  final IndoorResolvedRoom originRoom;
  final IndoorResolvedRoom destinationRoom;
  final List<IndoorRouteSegment> segments;
  final double totalDistanceMeters;

  const IndoorRoutePlan({
    required this.buildingCode,
    required this.originRoomCode,
    required this.destinationRoomCode,
    required this.originRoom,
    required this.destinationRoom,
    required this.segments,
    required this.totalDistanceMeters,
  });
}

class IndoorTransitionCandidate {
  final IndoorTransitionMode mode;
  final int originNodeId;
  final int destinationNodeId;
  final double alignmentDistanceMeters;

  const IndoorTransitionCandidate({
    required this.mode,
    required this.originNodeId,
    required this.destinationNodeId,
    required this.alignmentDistanceMeters,
  });
}
