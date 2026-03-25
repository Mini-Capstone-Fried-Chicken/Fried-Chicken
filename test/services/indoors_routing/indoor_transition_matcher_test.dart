import 'package:campus_app/services/indoors_routing/core/indoor_geometry.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_routing_models.dart';
import 'package:campus_app/services/indoors_routing/routing/indoor_transition_matcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorTransitionMatcher', () {
    final matcher = IndoorTransitionMatcher(geometry: const IndoorGeometry());

    test('compatiblePairs keeps only transitions with matching modes', () {
      final pairs = matcher.compatiblePairs(
        originTransitions: [
          _transitionNode(
            id: 1,
            center: const LatLng(45.0000, -73.0000),
            transitionType: IndoorTransitionType.stairs,
          ),
          _transitionNode(
            id: 2,
            center: const LatLng(45.0000, -72.9990),
            transitionType: IndoorTransitionType.elevator,
          ),
        ],
        destinationTransitions: [
          _transitionNode(
            id: 3,
            center: const LatLng(45.0001, -73.0000),
            transitionType: IndoorTransitionType.stairs,
          ),
          _transitionNode(
            id: 4,
            center: const LatLng(45.0001, -72.9990),
            transitionType: IndoorTransitionType.escalator,
          ),
        ],
      );

      expect(pairs, hasLength(1));
      expect(pairs.single.mode.name, 'stairs');
      expect(pairs.single.originNodeId, 1);
      expect(pairs.single.destinationNodeId, 3);
    });

    test('compatiblePairs sorts matching pairs by alignment distance', () {
      final pairs = matcher.compatiblePairs(
        originTransitions: [
          _transitionNode(
            id: 1,
            center: const LatLng(45.0000, -73.0000),
            transitionType: IndoorTransitionType.stairs,
          ),
        ],
        destinationTransitions: [
          _transitionNode(
            id: 10,
            center: const LatLng(45.0001, -73.0000),
            transitionType: IndoorTransitionType.stairs,
          ),
          _transitionNode(
            id: 11,
            center: const LatLng(45.0100, -73.0100),
            transitionType: IndoorTransitionType.stairs,
          ),
        ],
      );

      expect(pairs, hasLength(2));
      expect(pairs.first.destinationNodeId, 10);
      expect(
        pairs.first.alignmentDistanceMeters,
        lessThan(pairs.last.alignmentDistanceMeters),
      );
    });

    test('compatiblePairs ignores transition nodes with unknown types', () {
      final pairs = matcher.compatiblePairs(
        originTransitions: [
          _transitionNode(
            id: 1,
            center: const LatLng(45.0000, -73.0000),
            transitionType: null,
          ),
        ],
        destinationTransitions: [
          _transitionNode(
            id: 2,
            center: const LatLng(45.0001, -73.0000),
            transitionType: IndoorTransitionType.stairs,
          ),
        ],
      );

      expect(pairs, isEmpty);
    });
  });
}

IndoorRoutingNode _transitionNode({
  required int id,
  required LatLng center,
  required String? transitionType,
}) {
  return IndoorRoutingNode(
    id: id,
    nodeType: IndoorRoutingNodeType.transition,
    roomCode: null,
    transitionType: transitionType,
    level: '8',
    center: center,
    polygonPoints: const [
      LatLng(45.0, -73.0),
      LatLng(45.0, -72.9999),
      LatLng(45.0001, -72.9999),
      LatLng(45.0001, -73.0),
    ],
    holePolygons: const [],
  );
}
