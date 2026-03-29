import 'package:campus_app/services/indoors_routing/core/indoor_routing_models.dart';
import 'package:campus_app/services/indoors_routing/graph/indoor_graph_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorGraphFilter', () {
    final graphFilter = IndoorGraphFilter();
    final polygon = <LatLng>[
      const LatLng(45, -73),
      const LatLng(45, -72.9999),
      const LatLng(45.0001, -72.9999),
      const LatLng(45.0001, -73),
      const LatLng(45, -73),
    ];

    test('removes edges to intermediate room nodes', () {
      final nodes = <IndoorRoutingNode>[
        IndoorRoutingNode(
          id: 1,
          nodeType: IndoorRoutingNodeType.room,
          roomCode: 'A',
          transitionType: null,
          level: '1',
          center: const LatLng(45.0, -73.0),
          polygonPoints: polygon,
        ),
        IndoorRoutingNode(
          id: 2,
          nodeType: IndoorRoutingNodeType.room,
          roomCode: 'B',
          transitionType: null,
          level: '1',
          center: const LatLng(45.0, -72.9999),
          polygonPoints: polygon,
        ),
        IndoorRoutingNode(
          id: 3,
          nodeType: IndoorRoutingNodeType.corridor,
          roomCode: null,
          transitionType: null,
          level: '1',
          center: const LatLng(45.0, -72.9998),
          polygonPoints: polygon,
        ),
      ];

      final adjacency = <int, List<IndoorRoutingEdge>>{
        1: const [
          IndoorRoutingEdge(toNodeId: 3, weightMeters: 1),
          IndoorRoutingEdge(toNodeId: 2, weightMeters: 1),
        ],
        2: const [IndoorRoutingEdge(toNodeId: 3, weightMeters: 1)],
        3: const [
          IndoorRoutingEdge(toNodeId: 1, weightMeters: 1),
          IndoorRoutingEdge(toNodeId: 2, weightMeters: 1),
        ],
      };

      final filtered = graphFilter.withoutIntermediateRooms(
        adjacency: adjacency,
        nodes: nodes,
        allowedRoomIds: {1},
      );

      expect(filtered[2], isEmpty);
      expect(filtered[1]!.any((e) => e.toNodeId == 2), isFalse);
      expect(filtered[3]!.any((e) => e.toNodeId == 2), isFalse);
    });
  });
}
