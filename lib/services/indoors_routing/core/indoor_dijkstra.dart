import 'indoor_routing_models.dart';

// Handles shortest-path computation on the indoor routing graph.
class IndoorDijkstra {
  List<int>? shortestPathNodeIds({
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required int startNodeId,
    required int endNodeId,
  }) {
    if (!_hasValidEndpoints(
      adjacency: adjacency,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    )) {
      return null;
    }

    final distances = _initializeDistances(adjacency, startNodeId);
    final previous = _initializePrevious(adjacency);

    _runDijkstra(
      adjacency: adjacency,
      distances: distances,
      previous: previous,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );

    if (distances[endNodeId] == double.infinity) {
      return null;
    }

    return _reconstructPath(
      previous: previous,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
  }

  bool _hasValidEndpoints({
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required int startNodeId,
    required int endNodeId,
  }) {
    return adjacency.isNotEmpty &&
        adjacency.containsKey(startNodeId) &&
        adjacency.containsKey(endNodeId);
  }

  Map<int, double> _initializeDistances(
    Map<int, List<IndoorRoutingEdge>> adjacency,
    int startNodeId,
  ) {
    final distances = <int, double>{
      for (final id in adjacency.keys) id: double.infinity,
    };
    distances[startNodeId] = 0.0;
    return distances;
  }

  Map<int, int?> _initializePrevious(
    Map<int, List<IndoorRoutingEdge>> adjacency,
  ) {
    return <int, int?>{for (final nodeId in adjacency.keys) nodeId: null};
  }

  void _runDijkstra({
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required Map<int, double> distances,
    required Map<int, int?> previous,
    required int startNodeId,
    required int endNodeId,
  }) {
    final heap = _MinNodeHeap();
    heap.push((startNodeId, 0.0));

    while (!heap.isEmpty) {
      final current = heap.pop();
      if (current == null) break;

      final currentNodeId = current.$1;
      final currentDistance = current.$2;

      if (_isOutdatedHeapEntry(
        currentNodeId: currentNodeId,
        currentDistance: currentDistance,
        distances: distances,
      )) {
        continue;
      }

      if (currentNodeId == endNodeId) {
        break;
      }

      _relaxNeighbors(
        currentNodeId: currentNodeId,
        currentDistance: currentDistance,
        adjacency: adjacency,
        distances: distances,
        previous: previous,
        heap: heap,
      );
    }
  }

  bool _isOutdatedHeapEntry({
    required int currentNodeId,
    required double currentDistance,
    required Map<int, double> distances,
  }) {
    return currentDistance > (distances[currentNodeId] ?? double.infinity);
  }

  void _relaxNeighbors({
    required int currentNodeId,
    required double currentDistance,
    required Map<int, List<IndoorRoutingEdge>> adjacency,
    required Map<int, double> distances,
    required Map<int, int?> previous,
    required _MinNodeHeap heap,
  }) {
    for (final edge
        in adjacency[currentNodeId] ?? const <IndoorRoutingEdge>[]) {
      final candidateDistance = currentDistance + edge.weightMeters;
      final knownDistance = distances[edge.toNodeId] ?? double.infinity;
      if (candidateDistance >= knownDistance) {
        continue;
      }

      distances[edge.toNodeId] = candidateDistance;
      previous[edge.toNodeId] = currentNodeId;
      heap.push((edge.toNodeId, candidateDistance));
    }
  }

  List<int>? _reconstructPath({
    required Map<int, int?> previous,
    required int startNodeId,
    required int endNodeId,
  }) {
    final reversedPath = <int>[];
    int? cursor = endNodeId;

    while (cursor != null) {
      reversedPath.add(cursor);
      if (cursor == startNodeId) {
        break;
      }
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
