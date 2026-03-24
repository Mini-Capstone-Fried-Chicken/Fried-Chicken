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
  }) : this._resolved(
         sameFloorRouter: sameFloorRouter ?? IndoorSameFloorRouter(),
         geometry: geometry ?? const IndoorGeometry(),
         transitionMatcher: transitionMatcher,
       );

  IndoorMultiFloorRouter._resolved({
    required this.sameFloorRouter,
    required this.geometry,
    IndoorTransitionMatcher? transitionMatcher,
  }) : transitionMatcher =
           transitionMatcher ?? IndoorTransitionMatcher(geometry: geometry);

  IndoorRoutePlan? buildRoute({
    required IndoorResolvedRoom originRoom,
    required IndoorResolvedRoom destinationRoom,
    IndoorTransitionMode? preferredTransitionMode,
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
      preferredTransitionMode: preferredTransitionMode,
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
    IndoorTransitionMode? preferredTransitionMode,
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

    final transitionCandidates = _compatibleTransitionCandidates(
      originNodes: originNodes,
      destinationNodes: destinationNodes,
      preferredTransitionMode: preferredTransitionMode,
    );

    _ScoredRouteCandidate? bestCandidate;

    for (final candidate in transitionCandidates) {
      final scoredCandidate = _buildScoredRouteCandidate(
        candidate: candidate,
        originNodes: originNodes,
        destinationNodes: destinationNodes,
        originRoomNode: originRoomNode,
        destinationRoomNode: destinationRoomNode,
      );
      if (scoredCandidate == null) {
        continue;
      }

      if (bestCandidate == null ||
          scoredCandidate.score < bestCandidate.score) {
        bestCandidate = scoredCandidate;
      }
    }

    if (bestCandidate == null) {
      return null;
    }

    final originTransitionNode = _nodeById(
      originNodes,
      bestCandidate.transitionCandidate.originNodeId,
    );
    final destinationTransitionNode = _nodeById(
      destinationNodes,
      bestCandidate.transitionCandidate.destinationNodeId,
    );

    final originWalkPath = _trimTrailingTransitionCenter(
      bestCandidate.originWalkPath,
      originTransitionNode,
    );
    final destinationWalkPath = _trimLeadingTransitionCenter(
      bestCandidate.destinationWalkPath,
      destinationTransitionNode,
    );

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
          points: originWalkPath,
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
          points: destinationWalkPath,
        ),
      ],
      totalDistanceMeters:
          geometry.polylineLengthMeters(originWalkPath) +
          geometry.polylineLengthMeters(destinationWalkPath),
    );
  }

  List<IndoorTransitionCandidate> _compatibleTransitionCandidates({
    required List<IndoorRoutingNode> originNodes,
    required List<IndoorRoutingNode> destinationNodes,
    required IndoorTransitionMode? preferredTransitionMode,
  }) {
    var transitionCandidates = transitionMatcher.compatiblePairs(
      originTransitions: originNodes
          .where((node) => node.isTransition)
          .toList(),
      destinationTransitions: destinationNodes
          .where((node) => node.isTransition)
          .toList(),
    );

    if (preferredTransitionMode != null) {
      transitionCandidates = transitionCandidates
          .where((candidate) => candidate.mode == preferredTransitionMode)
          .toList();
    }

    return transitionCandidates;
  }

  _ScoredRouteCandidate? _buildScoredRouteCandidate({
    required IndoorTransitionCandidate candidate,
    required List<IndoorRoutingNode> originNodes,
    required List<IndoorRoutingNode> destinationNodes,
    required IndoorRoutingNode originRoomNode,
    required IndoorRoutingNode destinationRoomNode,
  }) {
    final originWalkPath = sameFloorRouter.findShortestPathBetweenNodeIds(
      nodes: originNodes,
      startNodeId: originRoomNode.id,
      endNodeId: candidate.originNodeId,
      allowedRoomIds: {originRoomNode.id},
    );
    if (originWalkPath == null || originWalkPath.length < 2) {
      return null;
    }

    final destinationWalkPath = sameFloorRouter.findShortestPathBetweenNodeIds(
      nodes: destinationNodes,
      startNodeId: candidate.destinationNodeId,
      endNodeId: destinationRoomNode.id,
      allowedRoomIds: {destinationRoomNode.id},
    );
    if (destinationWalkPath == null || destinationWalkPath.length < 2) {
      return null;
    }

    final score =
        geometry.polylineLengthMeters(originWalkPath) +
        geometry.polylineLengthMeters(destinationWalkPath) +
        candidate.alignmentDistanceMeters;

    return _ScoredRouteCandidate(
      score: score,
      transitionCandidate: candidate,
      originWalkPath: originWalkPath,
      destinationWalkPath: destinationWalkPath,
    );
  }

  IndoorRoutingNode? _nodeById(List<IndoorRoutingNode> nodes, int nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        return node;
      }
    }
    return null;
  }

  List<LatLng> _trimLeadingTransitionCenter(
    List<LatLng> path,
    IndoorRoutingNode? transitionNode,
  ) {
    if (transitionNode == null || path.length < 2) {
      return path;
    }

    if (!geometry.areSameLatLng(path.first, transitionNode.center)) {
      return path;
    }

    return path.sublist(1);
  }

  List<LatLng> _trimTrailingTransitionCenter(
    List<LatLng> path,
    IndoorRoutingNode? transitionNode,
  ) {
    if (transitionNode == null || path.length < 2) {
      return path;
    }

    if (!geometry.areSameLatLng(path.last, transitionNode.center)) {
      return path;
    }

    return path.sublist(0, path.length - 1);
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
