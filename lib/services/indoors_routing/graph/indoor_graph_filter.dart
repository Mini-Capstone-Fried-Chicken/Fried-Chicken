import '../core/indoor_routing_models.dart';

class IndoorGraphFilter {
  const IndoorGraphFilter();

  Map<int, List<IndoorRoutingEdge>> withoutIntermediateRooms({
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required List<IndoorRoutingNode> nodes,
    required Set<int> allowedRoomIds,
  }) {
    final blockedRoomIds = <int>{};

    for (final node in nodes) {
      if (node.nodeType == IndoorRoutingNodeType.room &&
          !allowedRoomIds.contains(node.id)) {
        blockedRoomIds.add(node.id);
      }
    }

    final filtered = <int, List<IndoorRoutingEdge>>{};

    for (final entry in adjacency.entries) {
      final fromNodeId = entry.key;

      if (blockedRoomIds.contains(fromNodeId)) {
        filtered[fromNodeId] = const [];
        continue;
      }

      final keptEdges = <IndoorRoutingEdge>[];
      for (final edge in entry.value) {
        if (!blockedRoomIds.contains(edge.toNodeId)) {
          keptEdges.add(edge);
        }
      }

      filtered[fromNodeId] = keptEdges;
    }

    return filtered;
  }
}
