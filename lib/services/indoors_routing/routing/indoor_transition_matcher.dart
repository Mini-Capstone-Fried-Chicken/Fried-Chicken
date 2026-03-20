import '../core/indoor_geometry.dart';
import '../core/indoor_route_plan_models.dart';
import '../core/indoor_routing_models.dart';

class IndoorTransitionMatcher {
  final IndoorGeometry geometry;

  const IndoorTransitionMatcher({required this.geometry});

  List<IndoorTransitionCandidate> compatiblePairs({
    required List<IndoorRoutingNode> originTransitions,
    required List<IndoorRoutingNode> destinationTransitions,
  }) {
    final pairs = <IndoorTransitionCandidate>[];

    for (final originNode in originTransitions) {
      final mode = _modeFromNode(originNode);
      if (mode == null) {
        continue;
      }

      for (final destinationNode in destinationTransitions) {
        if (_modeFromNode(destinationNode) != mode) {
          continue;
        }

        pairs.add(
          IndoorTransitionCandidate(
            mode: mode,
            originNodeId: originNode.id,
            destinationNodeId: destinationNode.id,
            alignmentDistanceMeters: geometry.distanceMeters(
              originNode.center,
              destinationNode.center,
            ),
          ),
        );
      }
    }

    pairs.sort(
      (a, b) => a.alignmentDistanceMeters.compareTo(b.alignmentDistanceMeters),
    );
    return pairs;
  }

  IndoorTransitionMode? _modeFromNode(IndoorRoutingNode node) {
    return switch (node.transitionType) {
      IndoorTransitionType.stairs => IndoorTransitionMode.stairs,
      IndoorTransitionType.elevator => IndoorTransitionMode.elevator,
      IndoorTransitionType.escalator => IndoorTransitionMode.escalator,
      _ => null,
    };
  }
}
