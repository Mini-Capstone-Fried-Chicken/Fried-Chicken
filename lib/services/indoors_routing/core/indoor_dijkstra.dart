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

    final distances = <int, double>{
      for (final id in adjacency.keys) id: double.infinity,
    };
    final previous = <int, int?>{};
    for (final nodeId in adjacency.keys) {
      previous[nodeId] = null;
    }
    distances[startNodeId] = 0.0;

    final heap = _MinNodeHeap();
    heap.push((startNodeId, 0.0));

    while (!heap.isEmpty) {
      final current = heap.pop();
      if (current == null) break;

      final currentNodeId = current.$1;
      final currentDistance = current.$2;
      if (currentDistance > (distances[currentNodeId] ?? double.infinity)) {
        continue;
      }
      if (currentNodeId == endNodeId) break;

      for (final edge
          in adjacency[currentNodeId] ?? const <IndoorRoutingEdge>[]) {
        final candidateDistance = currentDistance + edge.weightMeters;
        if (candidateDistance < (distances[edge.toNodeId] ?? double.infinity)) {
          distances[edge.toNodeId] = candidateDistance;
          previous[edge.toNodeId] = currentNodeId;
          heap.push((edge.toNodeId, candidateDistance));
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

class _MinNodeHeap {
  final List<(int, double)> _items = <(int, double)>[];

  bool get isEmpty => _items.isEmpty;

  void push((int, double) item) {
    _items.add(item);
    _siftUp(_items.length - 1);
  }

  (int, double)? pop() {
    if (_items.isEmpty) return null;
    final root = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      _siftDown(0);
    }
    return root;
  }

  void _siftUp(int index) {
    var child = index;
    while (child > 0) {
      final parent = (child - 1) ~/ 2;
      if (_items[parent].$2 <= _items[child].$2) break;
      _swap(parent, child);
      child = parent;
    }
  }

  void _siftDown(int index) {
    var parent = index;
    while (true) {
      final left = parent * 2 + 1;
      final right = left + 1;
      var smallest = parent;

      if (left < _items.length && _items[left].$2 < _items[smallest].$2) {
        smallest = left;
      }
      if (right < _items.length && _items[right].$2 < _items[smallest].$2) {
        smallest = right;
      }
      if (smallest == parent) break;

      _swap(parent, smallest);
      parent = smallest;
    }
  }

  void _swap(int a, int b) {
    final tmp = _items[a];
    _items[a] = _items[b];
    _items[b] = tmp;
  }
}
