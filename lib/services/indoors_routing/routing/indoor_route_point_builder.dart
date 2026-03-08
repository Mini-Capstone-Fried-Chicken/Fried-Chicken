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

    final nodeById = {for (final n in nodes) n.id: n};
    final orderedNodes = <IndoorRoutingNode>[];

    for (final id in pathNodeIds) {
      final node = nodeById[id];
      if (node != null) {
        orderedNodes.add(node);
      }
    }

    if (orderedNodes.isEmpty) return const [];

    final startNode = orderedNodes.first;
    final endNode = orderedNodes.last;

    final corridorCount = nodes
        .where((n) => n.nodeType == IndoorRoutingNodeType.corridor)
        .length;

    final useSparseGeometryGuard =
        corridorCount <= IndoorRouteGeometryTuning.sparseGeometryMaxCorridors;

    final blockedRoomPolygons = useSparseGeometryGuard
        ? nodes
              .where(
                (n) =>
                    n.nodeType == IndoorRoutingNodeType.room &&
                    n.id != startNode.id &&
                    n.id != endNode.id &&
                    !allowedRoomIds.contains(n.id),
              )
              .map((n) => n.polygonPoints)
              .toList(growable: false)
        : const <List<LatLng>>[];

    final points = <LatLng>[startNode.center];

    if (orderedNodes.length == 2) {
      final portal = portalSelector.portalBetweenTowardTarget(
        from: orderedNodes[0],
        to: orderedNodes[1],
        target: endNode.center,
      );

      appendIfDistinct(points, portal);
      appendIfDistinct(points, endNode.center);
      return geometry.removeConsecutiveDuplicatePoints(points);
    }

    final firstPortal = portalSelector.portalBetweenTowardTarget(
      from: orderedNodes[0],
      to: orderedNodes[1],
      target: orderedNodes.length > 2 ? orderedNodes[2].center : endNode.center,
    );
    appendIfDistinct(points, firstPortal);

    for (int i = 1; i < orderedNodes.length - 1; i++) {
      final currentNode = orderedNodes[i];
      final previousNode = orderedNodes[i - 1];
      final nextNode = orderedNodes[i + 1];

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
        continue;
      }

      final portalDistanceMeters = geometry.distanceMeters(
        entryPortal,
        exitPortal,
      );

      if (useSparseGeometryGuard &&
          portalDistanceMeters >=
              IndoorRouteGeometryTuning.longSparsePortalSegmentMeters) {
        final boundaryPath = corridorPathBuilder
            .findBoundaryConstrainedCorridorPath(
              entry: entryPortal,
              exit: exitPortal,
              corridorPolygon: currentNode.polygonPoints,
            );

        if (boundaryPath != null && boundaryPath.length >= 2) {
          appendAllDistinct(points, boundaryPath);
          continue;
        }
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
        continue;
      }

      final boundaryFallback = corridorPathBuilder
          .fallbackAlongCorridorBoundary(
            entry: entryPortal,
            exit: exitPortal,
            corridorPolygon: currentNode.polygonPoints,
          );

      if (boundaryFallback != null && boundaryFallback.isNotEmpty) {
        appendAllDistinct(points, boundaryFallback);
        continue;
      }

      appendIfDistinct(points, entryPortal);
      appendIfDistinct(points, exitPortal);
    }

    appendIfDistinct(points, endNode.center);

    return geometry.removeConsecutiveDuplicatePoints(points);
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
    final strictModes = useSparseGeometryGuard
        ? (enforceRoomSafeSegments ? const [true] : const [true, false])
        : const [false];

    for (final avoidRooms in strictModes) {
      final directInside = geometry.segmentInsideCorridor(
        a: entryPortal,
        b: exitPortal,
        corridorPolygon: currentNode.polygonPoints,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidRooms,
        minSamples: IndoorRouteGeometryTuning.segmentSamples,
        sampleSpacingMeters:
            IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
      );

      if (directInside) {
        appendIfDistinct(points, entryPortal);
        appendIfDistinct(points, exitPortal);
        return true;
      }

      final bendPoint = corridorPathBuilder.findCorridorBendPoint(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidRooms,
      );

      if (bendPoint != null) {
        appendIfDistinct(points, entryPortal);
        appendIfDistinct(points, bendPoint);
        appendIfDistinct(points, exitPortal);
        return true;
      }

      final bendPair = corridorPathBuilder.findCorridorTwoBendPath(
        entryPortal,
        exitPortal,
        currentNode.polygonPoints,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidRooms,
      );

      if (bendPair != null) {
        appendIfDistinct(points, entryPortal);
        appendIfDistinct(points, bendPair.$1);
        appendIfDistinct(points, bendPair.$2);
        appendIfDistinct(points, exitPortal);
        return true;
      }

      final entryToCenterInside = geometry.segmentInsideCorridor(
        a: entryPortal,
        b: currentNode.center,
        corridorPolygon: currentNode.polygonPoints,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidRooms,
        minSamples: IndoorRouteGeometryTuning.segmentSamples,
        sampleSpacingMeters:
            IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
      );

      final centerToExitInside = geometry.segmentInsideCorridor(
        a: currentNode.center,
        b: exitPortal,
        corridorPolygon: currentNode.polygonPoints,
        blockedRoomPolygons: blockedRoomPolygons,
        avoidBlockedRooms: avoidRooms,
        minSamples: IndoorRouteGeometryTuning.segmentSamples,
        sampleSpacingMeters:
            IndoorRouteGeometryTuning.segmentSampleSpacingMeters,
      );

      if (entryToCenterInside && centerToExitInside) {
        appendIfDistinct(points, entryPortal);
        appendIfDistinct(points, currentNode.center);
        appendIfDistinct(points, exitPortal);
        return true;
      }
    }

    return false;
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
