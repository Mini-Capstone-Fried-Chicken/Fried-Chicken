import 'package:flutter/foundation.dart';

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
    final destinationNodesByMode = _groupNodesByMode(
      destinationTransitions,
      source: 'destination',
    );

    for (final originNode in originTransitions) {
      final mode = _modeFromNode(originNode);
      if (mode == null) {
        _debugUnsupportedTransition(source: 'origin', node: originNode);
        continue;
      }

      for (final destinationNode in destinationNodesByMode[mode] ?? const []) {
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

  Map<IndoorTransitionMode, List<IndoorRoutingNode>> _groupNodesByMode(
    List<IndoorRoutingNode> nodes, {
    required String source,
  }) {
    final grouped = <IndoorTransitionMode, List<IndoorRoutingNode>>{};

    for (final node in nodes) {
      final mode = _modeFromNode(node);
      if (mode == null) {
        _debugUnsupportedTransition(source: source, node: node);
        continue;
      }
      grouped.putIfAbsent(mode, () => <IndoorRoutingNode>[]).add(node);
    }

    return grouped;
  }

  IndoorTransitionMode? _modeFromNode(IndoorRoutingNode node) {
    return switch (node.transitionType) {
      IndoorTransitionType.stairs => IndoorTransitionMode.stairs,
      IndoorTransitionType.elevator => IndoorTransitionMode.elevator,
      IndoorTransitionType.escalator => IndoorTransitionMode.escalator,
      _ => null,
    };
  }

  void _debugUnsupportedTransition({
    required String source,
    required IndoorRoutingNode node,
  }) {
    if (kDebugMode) {
      debugPrint(
        'IndoorTransitionMatcher: skipping $source transition '
        '${node.id} with unsupported type ${node.transitionType}',
      );
    }
  }
}
