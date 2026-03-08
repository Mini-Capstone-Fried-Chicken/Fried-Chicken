import 'package:campus_app/services/indoors_routing/core/indoor_dijkstra.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_geometry.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_routing_models.dart';
import 'package:campus_app/services/indoors_routing/graph/indoor_floor_graph_builder.dart';
import 'package:campus_app/services/indoors_routing/routing/indoor_corridor_path_builder.dart';
import 'package:campus_app/services/indoors_routing/routing/indoor_portal_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorPortalSelector', () {
    final floorGraphBuilder = IndoorFloorGraphBuilder();
    const geometry = IndoorGeometry();
    final selector = IndoorPortalSelector(
      floorGraphBuilder: floorGraphBuilder,
      geometry: geometry,
    );

    final roomPolygon = <LatLng>[
      const LatLng(45.0, -73.0),
      const LatLng(45.0, -72.99995),
      const LatLng(45.00005, -72.99995),
      const LatLng(45.00005, -73.0),
      const LatLng(45.0, -73.0),
    ];
    final corridorPolygon = <LatLng>[
      const LatLng(45.0, -72.99995),
      const LatLng(45.0, -72.9999),
      const LatLng(45.00005, -72.9999),
      const LatLng(45.00005, -72.99995),
      const LatLng(45.0, -72.99995),
    ];

    final roomNode = IndoorRoutingNode(
      id: 1,
      nodeType: IndoorRoutingNodeType.room,
      roomCode: 'A1',
      transitionType: null,
      level: '1',
      center: const LatLng(45.000025, -72.999975),
      polygonPoints: roomPolygon,
    );
    final corridorNode = IndoorRoutingNode(
      id: 2,
      nodeType: IndoorRoutingNodeType.corridor,
      roomCode: null,
      transitionType: null,
      level: '1',
      center: const LatLng(45.000025, -72.999925),
      polygonPoints: corridorPolygon,
    );

    test('samples portal candidates along shared boundary', () {
      final candidates = selector.sampleSharedBoundaryPortals(
        roomNode,
        corridorNode,
      );

      expect(candidates.length, greaterThanOrEqualTo(5));
    });

    test('chooses portal toward target on shared edge', () {
      final topTarget = const LatLng(45.00006, -72.9999);
      final bottomTarget = const LatLng(44.99999, -72.9999);

      final topPortal = selector.portalBetweenTowardTarget(
        from: roomNode,
        to: corridorNode,
        target: topTarget,
      );
      final bottomPortal = selector.portalBetweenTowardTarget(
        from: roomNode,
        to: corridorNode,
        target: bottomTarget,
      );

      expect(topPortal, isNotNull);
      expect(bottomPortal, isNotNull);
      expect(topPortal!.latitude, greaterThan(bottomPortal!.latitude));
    });
  });

  group('IndoorCorridorPathBuilder', () {
    final floorGraphBuilder = IndoorFloorGraphBuilder();
    const geometry = IndoorGeometry();
    final builder = IndoorCorridorPathBuilder(
      floorGraphBuilder: floorGraphBuilder,
      indoorDijkstra: IndoorDijkstra(),
      geometry: geometry,
    );

    final corridor = <LatLng>[
      const LatLng(0, 0),
      const LatLng(0, 0.00006),
      const LatLng(0.00004, 0.00006),
      const LatLng(0.00004, 0),
      const LatLng(0, 0),
    ];

    test('finds a one-bend path candidate when direct segment is blocked', () {
      final blockedRoom = <LatLng>[
        const LatLng(0.000015, 0.00002),
        const LatLng(0.000015, 0.00004),
        const LatLng(0.00003, 0.00004),
        const LatLng(0.00003, 0.00002),
        const LatLng(0.000015, 0.00002),
      ];

      final bend = builder.findCorridorBendPoint(
        const LatLng(0.00001, 0.000005),
        const LatLng(0.000035, 0.000055),
        corridor,
        blockedRoomPolygons: [blockedRoom],
        avoidBlockedRooms: true,
      );

      expect(bend, isNotNull);
    });

    test('builds boundary fallback path with entry and exit preserved', () {
      const entry = LatLng(0.00001, 0.000005);
      const exit = LatLng(0.000035, 0.000055);

      final path = builder.fallbackAlongCorridorBoundary(
        entry: entry,
        exit: exit,
        corridorPolygon: corridor,
      );

      expect(path, isNotNull);
      expect(path!.first, entry);
      expect(path.last, exit);
      expect(path.length, greaterThanOrEqualTo(3));
    });
  });
}
