import 'indoor_routing_models.dart';

// Handles shortest-path computation on the indoor routing graph.
class IndoorDijkstra {
  List<int>? shortestPathNodeIds({
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required int startNodeId,
    required int endNodeId,
  }) {
    if (adjacency.isEmpty) return null;
    if (!adjacency.containsKey(startNodeId) ||
        !adjacency.containsKey(endNodeId)) {
      return null;
    }

    final distances = <int, double>{};
    final previous = <int, int?>{};
    final visited = <int>{};

    // Initialize all nodes with infinite distance.
    for (final nodeId in adjacency.keys) {
      distances[nodeId] = double.infinity;
      previous[nodeId] = null;
    }
    distances[startNodeId] = 0.0;

    while (visited.length < adjacency.length) {
      int? currentNodeId;
      double smallestDistance = double.infinity;

      // Pick the unvisited node with the smallest known distance.
      for (final entry in distances.entries) {
        if (visited.contains(entry.key)) continue;
        if (entry.value < smallestDistance) {
          smallestDistance = entry.value;
          currentNodeId = entry.key;
        }
      }

      if (currentNodeId == null) break;
      if (currentNodeId == endNodeId) break;

      visited.add(currentNodeId);

      final neighbors = adjacency[currentNodeId] ?? const [];
      for (final edge in neighbors) {
        final currentDistance = distances[currentNodeId]!;
        final candidateDistance = currentDistance + edge.weightMeters;

        // Relax the edge if a shorter path is found.
        if (candidateDistance < distances[edge.toNodeId]!) {
          distances[edge.toNodeId] = candidateDistance;
          previous[edge.toNodeId] = currentNodeId;
        }
      }
    }

    if (distances[endNodeId] == double.infinity) {
      return null;
    }

    // Reconstruct the path from end back to start.
    final reversedPath = <int>[];
    int? cursor = endNodeId;

    while (cursor != null) {
      reversedPath.add(cursor);
      if (cursor == startNodeId) break;
      cursor = previous[cursor];
    }

    if (reversedPath.isEmpty || reversedPath.last != startNodeId) {
      return null;
    }

    return reversedPath.reversed.toList(growable: false);
  }
}
