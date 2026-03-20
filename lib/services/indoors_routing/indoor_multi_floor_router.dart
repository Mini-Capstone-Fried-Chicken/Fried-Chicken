import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'core/indoor_geometry.dart';
import 'core/indoor_route_plan_models.dart';
import 'core/indoor_routing_models.dart';
import 'indoor_same_floor_router.dart';
import 'routing/indoor_transition_matcher.dart';

class IndoorMultiFloorRouter {
  final IndoorSameFloorRouter sameFloorRouter;
  final IndoorGeometry geometry;
  final IndoorTransitionMatcher transitionMatcher;

  IndoorMultiFloorRouter({
    IndoorSameFloorRouter? sameFloorRouter,
    IndoorGeometry? geometry,
    IndoorTransitionMatcher? transitionMatcher,
  }) : sameFloorRouter = sameFloorRouter ?? IndoorSameFloorRouter(),
       geometry = geometry ?? const IndoorGeometry(),
       transitionMatcher =
           transitionMatcher ??
           IndoorTransitionMatcher(
             geometry: geometry ?? const IndoorGeometry(),
           );

  IndoorRoutePlan? buildRoute({
    required IndoorResolvedRoom originRoom,
    required IndoorResolvedRoom destinationRoom,
  }) {
    if (originRoom.floorAssetPath == destinationRoom.floorAssetPath) {
      return _buildSameFloorRoute(
        originRoom: originRoom,
        destinationRoom: destinationRoom,
      );
    }

    return _buildDifferentFloorRoute(
      originRoom: originRoom,
      destinationRoom: destinationRoom,
    );
  }

  IndoorRoutePlan? _buildSameFloorRoute({
    required IndoorResolvedRoom originRoom,
    required IndoorResolvedRoom destinationRoom,
  }) {
    final path = sameFloorRouter.findShortestPath(
      floorGeoJson: originRoom.floorGeoJson,
      originRoomCode: originRoom.roomCode,
      destinationRoomCode: destinationRoom.roomCode,
    );

    if (path == null || path.length < 2) {
      return null;
    }

    return IndoorRoutePlan(
      buildingCode: originRoom.buildingCode,
      originRoomCode: originRoom.roomCode,
      destinationRoomCode: destinationRoom.roomCode,
      originRoom: originRoom,
      destinationRoom: destinationRoom,
      segments: [
        IndoorRouteSegment(
          kind: IndoorRouteSegmentKind.walk,
          floorAssetPath: originRoom.floorAssetPath,
          floorLabel: originRoom.floorLabel,
          points: path,
        ),
      ],
      totalDistanceMeters: geometry.polylineLengthMeters(path),
    );
  }

  IndoorRoutePlan? _buildDifferentFloorRoute({
    required IndoorResolvedRoom originRoom,
    required IndoorResolvedRoom destinationRoom,
  }) {
    final originNodes = sameFloorRouter.buildNodesFromFloorGeoJson(
      originRoom.floorGeoJson,
    );
    final destinationNodes = sameFloorRouter.buildNodesFromFloorGeoJson(
      destinationRoom.floorGeoJson,
    );

    if (originNodes.isEmpty || destinationNodes.isEmpty) {
      return null;
    }

    final originRoomNode = _findRoomNode(originNodes, originRoom.roomCode);
    final destinationRoomNode = _findRoomNode(
      destinationNodes,
      destinationRoom.roomCode,
    );

    if (originRoomNode == null || destinationRoomNode == null) {
      return null;
    }

    final transitionCandidates = transitionMatcher.compatiblePairs(
      originTransitions: originNodes
          .where((node) => node.isTransition)
          .toList(),
      destinationTransitions: destinationNodes
          .where((node) => node.isTransition)
          .toList(),
    );

    _ScoredRouteCandidate? bestCandidate;

    for (final candidate in transitionCandidates) {
      final originWalkPath = sameFloorRouter.findShortestPathBetweenNodeIds(
        nodes: originNodes,
        startNodeId: originRoomNode.id,
        endNodeId: candidate.originNodeId,
        allowedRoomIds: {originRoomNode.id},
      );
      if (originWalkPath == null || originWalkPath.length < 2) {
        continue;
      }

      final destinationWalkPath = sameFloorRouter
          .findShortestPathBetweenNodeIds(
            nodes: destinationNodes,
            startNodeId: candidate.destinationNodeId,
            endNodeId: destinationRoomNode.id,
            allowedRoomIds: {destinationRoomNode.id},
          );
      if (destinationWalkPath == null || destinationWalkPath.length < 2) {
        continue;
      }

      final score =
          geometry.polylineLengthMeters(originWalkPath) +
          geometry.polylineLengthMeters(destinationWalkPath) +
          candidate.alignmentDistanceMeters;

      if (bestCandidate == null || score < bestCandidate.score) {
        bestCandidate = _ScoredRouteCandidate(
          score: score,
          transitionCandidate: candidate,
          originWalkPath: originWalkPath,
          destinationWalkPath: destinationWalkPath,
        );
      }
    }

    if (bestCandidate == null) {
      return null;
    }

    final transitionInstruction = _transitionInstruction(
      mode: bestCandidate.transitionCandidate.mode,
      originFloorLabel: originRoom.floorLabel,
      destinationFloorLabel: destinationRoom.floorLabel,
    );

    return IndoorRoutePlan(
      buildingCode: originRoom.buildingCode,
      originRoomCode: originRoom.roomCode,
      destinationRoomCode: destinationRoom.roomCode,
      originRoom: originRoom,
      destinationRoom: destinationRoom,
      segments: [
        IndoorRouteSegment(
          kind: IndoorRouteSegmentKind.walk,
          floorAssetPath: originRoom.floorAssetPath,
          floorLabel: originRoom.floorLabel,
          points: bestCandidate.originWalkPath,
        ),
        IndoorRouteSegment(
          kind: IndoorRouteSegmentKind.transition,
          floorAssetPath: destinationRoom.floorAssetPath,
          floorLabel: destinationRoom.floorLabel,
          points: const [],
          transitionMode: bestCandidate.transitionCandidate.mode,
          fromFloorLabel: originRoom.floorLabel,
          toFloorLabel: destinationRoom.floorLabel,
          instruction: transitionInstruction,
        ),
        IndoorRouteSegment(
          kind: IndoorRouteSegmentKind.walk,
          floorAssetPath: destinationRoom.floorAssetPath,
          floorLabel: destinationRoom.floorLabel,
          points: bestCandidate.destinationWalkPath,
        ),
      ],
      totalDistanceMeters:
          geometry.polylineLengthMeters(bestCandidate.originWalkPath) +
          geometry.polylineLengthMeters(bestCandidate.destinationWalkPath),
    );
  }

  IndoorRoutingNode? _findRoomNode(
    List<IndoorRoutingNode> nodes,
    String roomCode,
  ) {
    final indexedRooms = sameFloorRouter.roomLookup.indexByRoomCode(nodes);
    return sameFloorRouter.roomLookup.findRoomNode(indexedRooms, roomCode);
  }

  String _transitionInstruction({
    required IndoorTransitionMode mode,
    required String originFloorLabel,
    required String destinationFloorLabel,
  }) {
    final modeLabel = switch (mode) {
      IndoorTransitionMode.stairs => 'stairs',
      IndoorTransitionMode.elevator => 'elevator',
      IndoorTransitionMode.escalator => 'escalator',
    };

    return 'Take the $modeLabel from floor '
        '$originFloorLabel to floor $destinationFloorLabel';
  }
}

class _ScoredRouteCandidate {
  final double score;
  final IndoorTransitionCandidate transitionCandidate;
  final List<LatLng> originWalkPath;
  final List<LatLng> destinationWalkPath;

  const _ScoredRouteCandidate({
    required this.score,
    required this.transitionCandidate,
    required this.originWalkPath,
    required this.destinationWalkPath,
  });
}
