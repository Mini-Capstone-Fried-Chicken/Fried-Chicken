import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/indoor_geometry.dart';
import '../core/indoor_routing_models.dart';
import 'indoor_corridor_path_builder.dart';
import 'indoor_portal_selector.dart';

class IndoorRoutePointBuilder {
  final IndoorPortalSelector portalSelector;
  final IndoorCorridorPathBuilder corridorPathBuilder;
  final IndoorGeometry geometry;

  const IndoorRoutePointBuilder({
    required this.portalSelector,
    required this.corridorPathBuilder,
    required this.geometry,
  });

  List<LatLng> buildRoutePointsFromNodePath({
    required List<int> pathNodeIds,
    required List<IndoorRoutingNode> nodes,
    required Set<int> allowedRoomIds,
    bool enforceRoomSafeSegments = false,
  }) {
    if (pathNodeIds.isEmpty) return const [];

    final orderedNodes = _orderedNodesFromPath(
      pathNodeIds: pathNodeIds,
      nodes: nodes,
    );
    if (orderedNodes.isEmpty) return const [];

    final startNode = orderedNodes.first;
    final endNode = orderedNodes.last;
    final useSparseGeometryGuard = _useSparseGeometryGuard(nodes);
    final blockedRoomPolygons = _blockedRoomPolygons(
      nodes: nodes,
      startNode: startNode,
      endNode: endNode,
      allowedRoomIds: allowedRoomIds,
      useSparseGeometryGuard: useSparseGeometryGuard,
    );

    final points = <LatLng>[startNode.center];

    if (orderedNodes.length == 2) {
      _appendTwoNodePath(
        points: points,
        orderedNodes: orderedNodes,
        endNode: endNode,
      );
      return geometry.removeConsecutiveDuplicatePoints(points);
    }

    _appendFirstPortal(
      points: points,
      orderedNodes: orderedNodes,
      endNode: endNode,
    );
    _appendIntermediateCorridorSegments(
      points: points,
      orderedNodes: orderedNodes,
      endNode: endNode,
      blockedRoomPolygons: blockedRoomPolygons,
      useSparseGeometryGuard: useSparseGeometryGuard,
      enforceRoomSafeSegments: enforceRoomSafeSegments,
    );

    appendIfDistinct(points, endNode.center);
    return geometry.removeConsecutiveDuplicatePoints(points);
  }

  List<IndoorRoutingNode> _orderedNodesFromPath({
    required List<int> pathNodeIds,
    required List<IndoorRoutingNode> nodes,
  }) {
    final nodeById = {for (final n in nodes) n.id: n};
    final ordered = <IndoorRoutingNode>[];

    for (final id in pathNodeIds) {
      final node = nodeById[id];
      if (node != null) {
        ordered.add(node);
      }
    }

    return ordered;
  }

  bool _useSparseGeometryGuard(List<IndoorRoutingNode> nodes) {
    final corridorCount = nodes
        .where((n) => n.nodeType == IndoorRoutingNodeType.corridor)
        .length;
    return corridorCount <=
        IndoorRouteGeometryTuning.sparseGeometryMaxCorridors;
  }

  List<List<LatLng>> _blockedRoomPolygons({
    required List<IndoorRoutingNode> nodes,
    required IndoorRoutingNode startNode,
    required IndoorRoutingNode endNode,
    required Set<int> allowedRoomIds,
    required bool useSparseGeometryGuard,
  }) {
    if (!useSparseGeometryGuard) {
      return const <List<LatLng>>[];
    }

    return nodes
        .where(
          (n) =>
              n.nodeType == IndoorRoutingNodeType.room &&
              n.id != startNode.id &&
              n.id != endNode.id &&
              !allowedRoomIds.contains(n.id),
        )
        .map((n) => n.polygonPoints)
        .toList(growable: false);
  }

  void _appendTwoNodePath({
    required List<LatLng> points,
    required List<IndoorRoutingNode> orderedNodes,
    required IndoorRoutingNode endNode,
  }) {
    final portal = portalSelector.portalBetweenTowardTarget(
      from: orderedNodes[0],
      to: orderedNodes[1],
      target: endNode.center,
    );

    appendIfDistinct(points, portal);
    appendIfDistinct(points, endNode.center);
  }

  void _appendFirstPortal({
    required List<LatLng> points,
    required List<IndoorRoutingNode> orderedNodes,
    required IndoorRoutingNode endNode,
  }) {
    final firstPortal = portalSelector.portalBetweenTowardTarget(
      from: orderedNodes[0],
      to: orderedNodes[1],
      target: orderedNodes.length > 2 ? orderedNodes[2].center : endNode.center,
    );
    appendIfDistinct(points, firstPortal);
  }

  void _appendIntermediateCorridorSegments({
    required List<LatLng> points,
    required List<IndoorRoutingNode> orderedNodes,
    required IndoorRoutingNode endNode,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool useSparseGeometryGuard,
    required bool enforceRoomSafeSegments,
  }) {
    for (int i = 1; i < orderedNodes.length - 1; i++) {
      _appendSingleIntermediateSegment(
        points: points,
        orderedNodes: orderedNodes,
        index: i,
        endNode: endNode,
        blockedRoomPolygons: blockedRoomPolygons,
        useSparseGeometryGuard: useSparseGeometryGuard,
        enforceRoomSafeSegments: enforceRoomSafeSegments,
      );
    }
  }

  void _appendSingleIntermediateSegment({
    required List<LatLng> points,
    required List<IndoorRoutingNode> orderedNodes,
    required int index,
    required IndoorRoutingNode endNode,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool useSparseGeometryGuard,
    required bool enforceRoomSafeSegments,
  }) {
    final currentNode = orderedNodes[index];
    final previousNode = orderedNodes[index - 1];
    final nextNode = orderedNodes[index + 1];

    final entryPortal = portalSelector.portalBetweenTowardTarget(
      from: previousNode,
      to: currentNode,
      target: nextNode.center,
    );
    final exitPortal = portalSelector.portalBetweenTowardTarget(
      from: currentNode,
      to: nextNode,
      target: endNode.center,
    );

    if (entryPortal == null || exitPortal == null) {
      return;
    }

    if (_appendBoundaryConstrainedPathIfNeeded(
      points: points,
      entryPortal: entryPortal,
      exitPortal: exitPortal,
      currentNode: currentNode,
      useSparseGeometryGuard: useSparseGeometryGuard,
    )) {
      return;
    }

    if (_appendPreferredCorridorPath(
      points: points,
      entryPortal: entryPortal,
      exitPortal: exitPortal,
      currentNode: currentNode,
      blockedRoomPolygons: blockedRoomPolygons,
      useSparseGeometryGuard: useSparseGeometryGuard,
      enforceRoomSafeSegments: enforceRoomSafeSegments,
    )) {
      return;
    }

    final boundaryFallback = corridorPathBuilder.fallbackAlongCorridorBoundary(
      entry: entryPortal,
      exit: exitPortal,
      corridorPolygon: currentNode.polygonPoints,
    );

    if (boundaryFallback != null && boundaryFallback.isNotEmpty) {
      appendAllDistinct(points, boundaryFallback);
      return;
    }

    appendIfDistinct(points, entryPortal);
    appendIfDistinct(points, exitPortal);
  }

  bool _appendBoundaryConstrainedPathIfNeeded({
    required List<LatLng> points,
    required LatLng entryPortal,
    required LatLng exitPortal,
    required IndoorRoutingNode currentNode,
    required bool useSparseGeometryGuard,
  }) {
    if (!useSparseGeometryGuard) {
      return false;
    }

    final portalDistanceMeters = geometry.distanceMeters(
      entryPortal,
      exitPortal,
    );
    if (portalDistanceMeters <
        IndoorRouteGeometryTuning.longSparsePortalSegmentMeters) {
      return false;
    }

    final boundaryPath = corridorPathBuilder
        .findBoundaryConstrainedCorridorPath(
          entry: entryPortal,
          exit: exitPortal,
          corridorPolygon: currentNode.polygonPoints,
        );

    if (boundaryPath == null || boundaryPath.length < 2) {
      return false;
    }

    appendAllDistinct(points, boundaryPath);
    return true;
  }

  bool _appendPreferredCorridorPath({
    required List<LatLng> points,
    required LatLng entryPortal,
    required LatLng exitPortal,
    required IndoorRoutingNode currentNode,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool useSparseGeometryGuard,
    required bool enforceRoomSafeSegments,
  }) {
    final strictModes = _strictAvoidRoomModes(
      useSparseGeometryGuard: useSparseGeometryGuard,
      enforceRoomSafeSegments: enforceRoomSafeSegments,
    );

    for (final avoidRooms in strictModes) {
      if (_appendDirectPathIfPossible(
        points: points,
        entryPortal: entryPortal,
        exitPortal: exitPortal,
        currentNode: currentNode,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidRooms: avoidRooms,
      )) {
        return true;
      }

      if (_appendOneBendPathIfPossible(
        points: points,
        entryPortal: entryPortal,
        exitPortal: exitPortal,
        currentNode: currentNode,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidRooms: avoidRooms,
      )) {
        return true;
      }

      if (_appendTwoBendPathIfPossible(
        points: points,
        entryPortal: entryPortal,
        exitPortal: exitPortal,
        currentNode: currentNode,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidRooms: avoidRooms,
      )) {
        return true;
      }

      if (_appendThroughCenterIfPossible(
        points: points,
        entryPortal: entryPortal,
        exitPortal: exitPortal,
        currentNode: currentNode,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidRooms: avoidRooms,
      )) {
        return true;
      }
    }

    return false;
  }

  List<bool> _strictAvoidRoomModes({
    required bool useSparseGeometryGuard,
    required bool enforceRoomSafeSegments,
  }) {
    if (!useSparseGeometryGuard) {
      return const [false];
    }
    if (enforceRoomSafeSegments) {
      return const [true];
    }
    return const [true, false];
  }

  bool _appendDirectPathIfPossible({
    required List<LatLng> points,
    required LatLng entryPortal,
    required LatLng exitPortal,
    required IndoorRoutingNode currentNode,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidRooms,
  }) {
    final directInside = geometry.segmentInsideCorridor(
      a: entryPortal,
      b: exitPortal,
      corridorPolygon: currentNode.polygonPoints,
      blockedRoomPolygons: blockedRoomPolygons,
      avoidBlockedRooms: avoidRooms,
      minSamples: IndoorRouteGeometryTuning.segmentSamples,
      sampleSpacingMeters: IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
    );

    if (!directInside) {
      return false;
    }

    appendIfDistinct(points, entryPortal);
    appendIfDistinct(points, exitPortal);
    return true;
  }

  bool _appendOneBendPathIfPossible({
    required List<LatLng> points,
    required LatLng entryPortal,
    required LatLng exitPortal,
    required IndoorRoutingNode currentNode,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidRooms,
  }) {
    final bendPoint = corridorPathBuilder.findCorridorBendPoint(
      entryPortal,
      exitPortal,
      currentNode.polygonPoints,
      blockedRoomPolygons: blockedRoomPolygons,
      avoidBlockedRooms: avoidRooms,
    );

    if (bendPoint == null) {
      return false;
    }

    appendIfDistinct(points, entryPortal);
    appendIfDistinct(points, bendPoint);
    appendIfDistinct(points, exitPortal);
    return true;
  }

  bool _appendTwoBendPathIfPossible({
    required List<LatLng> points,
    required LatLng entryPortal,
    required LatLng exitPortal,
    required IndoorRoutingNode currentNode,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidRooms,
  }) {
    final bendPair = corridorPathBuilder.findCorridorTwoBendPath(
      entryPortal,
      exitPortal,
      currentNode.polygonPoints,
      blockedRoomPolygons: blockedRoomPolygons,
      avoidBlockedRooms: avoidRooms,
    );

    if (bendPair == null) {
      return false;
    }

    appendIfDistinct(points, entryPortal);
    appendIfDistinct(points, bendPair.$1);
    appendIfDistinct(points, bendPair.$2);
    appendIfDistinct(points, exitPortal);
    return true;
  }

  bool _appendThroughCenterIfPossible({
    required List<LatLng> points,
    required LatLng entryPortal,
    required LatLng exitPortal,
    required IndoorRoutingNode currentNode,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidRooms,
  }) {
    final entryToCenterInside = geometry.segmentInsideCorridor(
      a: entryPortal,
      b: currentNode.center,
      corridorPolygon: currentNode.polygonPoints,
      blockedRoomPolygons: blockedRoomPolygons,
      avoidBlockedRooms: avoidRooms,
      minSamples: IndoorRouteGeometryTuning.segmentSamples,
      sampleSpacingMeters: IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
    );

    final centerToExitInside = geometry.segmentInsideCorridor(
      a: currentNode.center,
      b: exitPortal,
      corridorPolygon: currentNode.polygonPoints,
      blockedRoomPolygons: blockedRoomPolygons,
      avoidBlockedRooms: avoidRooms,
      minSamples: IndoorRouteGeometryTuning.segmentSamples,
      sampleSpacingMeters: IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
    );

    if (!entryToCenterInside || !centerToExitInside) {
      return false;
    }

    appendIfDistinct(points, entryPortal);
    appendIfDistinct(points, currentNode.center);
    appendIfDistinct(points, exitPortal);
    return true;
  }

  void appendAllDistinct(List<LatLng> destination, List<LatLng> candidates) {
    for (final point in candidates) {
      appendIfDistinct(destination, point);
    }
  }

  void appendIfDistinct(List<LatLng> destination, LatLng? candidate) {
    if (candidate == null) return;
    if (destination.isEmpty ||
        !geometry.areSameLatLng(destination.last, candidate)) {
      destination.add(candidate);
    }
  }
}
