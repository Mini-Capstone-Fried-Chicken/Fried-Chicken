import 'package:campus_app/services/indoors_routing/core/indoor_dijkstra.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_routing_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndoorDijkstra', () {
    final dijkstra = IndoorDijkstra();

    test('returns shortest path with weighted edges', () {
      final adjacency = <int, List<IndoorRoutingEdge>>{
        1: const [
          IndoorRoutingEdge(toNodeId: 2, weightMeters: 10),
          IndoorRoutingEdge(toNodeId: 3, weightMeters: 1),
        ],
        2: const [IndoorRoutingEdge(toNodeId: 4, weightMeters: 1)],
        3: const [
          IndoorRoutingEdge(toNodeId: 2, weightMeters: 1),
          IndoorRoutingEdge(toNodeId: 4, weightMeters: 10),
        ],
        4: const [],
      };

      final path = dijkstra.shortestPathNodeIds(
        adjacency: adjacency,
        startNodeId: 1,
        endNodeId: 4,
      );

      expect(path, [1, 3, 2, 4]);
    });

    test('returns null when destination is unreachable', () {
      final path = dijkstra.shortestPathNodeIds(
        adjacency: {
          1: const [IndoorRoutingEdge(toNodeId: 2, weightMeters: 1)],
          2: const [],
          3: const [],
        },
        startNodeId: 1,
        endNodeId: 3,
      );

      expect(path, isNull);
    });

    test('returns null for missing start or end node', () {
      final adjacency = <int, List<IndoorRoutingEdge>>{
        1: const [],
        2: const [],
      };

      expect(
        dijkstra.shortestPathNodeIds(
          adjacency: adjacency,
          startNodeId: 99,
          endNodeId: 2,
        ),
        isNull,
      );
    });
  });
}
