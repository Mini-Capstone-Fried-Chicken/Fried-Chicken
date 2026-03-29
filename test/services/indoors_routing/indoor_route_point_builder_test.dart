import 'package:campus_app/services/indoors_routing/core/indoor_dijkstra.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_geometry.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_routing_models.dart';
import 'package:campus_app/services/indoors_routing/graph/indoor_floor_graph_builder.dart';
import 'package:campus_app/services/indoors_routing/routing/indoor_corridor_path_builder.dart';
import 'package:campus_app/services/indoors_routing/routing/indoor_portal_selector.dart';
import 'package:campus_app/services/indoors_routing/routing/indoor_route_point_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorRoutePointBuilder', () {
    test('returns empty when path ids are empty', () {
      final builder = _buildBuilder();

      final points = builder.buildRoutePointsFromNodePath(
        pathNodeIds: const [],
        nodes: const [],
        allowedRoomIds: const {},
      );

      expect(points, isEmpty);
    });

    test('returns empty when path ids do not resolve to nodes', () {
      final builder = _buildBuilder();

      final points = builder.buildRoutePointsFromNodePath(
        pathNodeIds: const [99],
        nodes: [_roomNode(id: 1, center: const LatLng(0, 0))],
        allowedRoomIds: const {},
      );

      expect(points, isEmpty);
    });

    test('deduplicates points on 2-node path', () {
      final end = _roomNode(id: 2, center: const LatLng(0.00002, 0.00002));
      final portal = _ScriptedPortalSelector(scriptedPortals: [end.center]);
      final builder = _buildBuilder(portalSelector: portal);

      final points = builder.buildRoutePointsFromNodePath(
        pathNodeIds: const [1, 2],
        nodes: [
          _roomNode(id: 1, center: const LatLng(0, 0)),
          end,
        ],
        allowedRoomIds: const {},
      );

      expect(points.length, 2);
      expect(points.first, const LatLng(0, 0));
      expect(points.last, end.center);
    });

    test(
      'uses boundary-constrained corridor path when sparse and long segment',
      () {
        const entry = LatLng(0.00001, 0.00001);
        const boundaryMid = LatLng(0.00002, 0.00002);
        const exit = LatLng(0.00003, 0.00003);

        final corridorNode = _corridorNode(
          id: 2,
          center: const LatLng(0.00002, 0.000015),
        );

        final portal = _ScriptedPortalSelector(
          scriptedPortals: [entry, entry, exit],
        );
        final corridorPathBuilder = _ScriptedCorridorPathBuilder(
          boundaryPath: [entry, boundaryMid, exit],
        );
        final geometry = _ScriptedGeometry(distances: [25.0]);

        final builder = _buildBuilder(
          portalSelector: portal,
          corridorPathBuilder: corridorPathBuilder,
          geometry: geometry,
        );

        final points = builder.buildRoutePointsFromNodePath(
          pathNodeIds: const [1, 2, 3],
          nodes: [
            _roomNode(id: 1, center: const LatLng(0, 0)),
            corridorNode,
            _roomNode(id: 3, center: const LatLng(0.00004, 0.00004)),
          ],
          allowedRoomIds: const {},
        );

        expect(points, contains(boundaryMid));
      },
    );

    test('uses boundary fallback when direct and bend paths fail', () {
      const entry = LatLng(0.00001, 0.00001);
      const fallbackMid = LatLng(0.00002, 0.00002);
      const exit = LatLng(0.00003, 0.00003);

      final portal = _ScriptedPortalSelector(
        scriptedPortals: [entry, entry, exit],
      );
      final corridorPathBuilder = _ScriptedCorridorPathBuilder(
        boundaryPath: null,
        oneBend: null,
        twoBend: null,
        boundaryFallback: [entry, fallbackMid, exit],
      );
      final geometry = _ScriptedGeometry(
        distances: [5.0],
        segmentInsideResponses: [false, false, false],
      );

      final builder = _buildBuilder(
        portalSelector: portal,
        corridorPathBuilder: corridorPathBuilder,
        geometry: geometry,
      );

      final points = builder.buildRoutePointsFromNodePath(
        pathNodeIds: const [1, 2, 3],
        nodes: [
          _roomNode(id: 1, center: const LatLng(0, 0)),
          _corridorNode(id: 2, center: const LatLng(0.00002, 0.000015)),
          _roomNode(id: 3, center: const LatLng(0.00004, 0.00004)),
          _corridorNode(id: 4, center: const LatLng(0.00005, 0.00005)),
          _corridorNode(id: 5, center: const LatLng(0.00006, 0.00006)),
        ],
        allowedRoomIds: const {},
      );

      expect(points, contains(fallbackMid));
    });

    test(
      'still returns start/end when intermediate portal resolution fails',
      () {
        final portal = _ScriptedPortalSelector(
          scriptedPortals: [const LatLng(0.00001, 0.00001), null],
        );
        final builder = _buildBuilder(portalSelector: portal);

        final points = builder.buildRoutePointsFromNodePath(
          pathNodeIds: const [1, 2, 3],
          nodes: [
            _roomNode(id: 1, center: const LatLng(0, 0)),
            _corridorNode(id: 2, center: const LatLng(0.00002, 0.000015)),
            _roomNode(id: 3, center: const LatLng(0.00004, 0.00004)),
          ],
          allowedRoomIds: const {},
        );

        expect(points.first, const LatLng(0, 0));
        expect(points.last, const LatLng(0.00004, 0.00004));
      },
    );
  });
}

IndoorRoutePointBuilder _buildBuilder({
  IndoorPortalSelector? portalSelector,
  IndoorCorridorPathBuilder? corridorPathBuilder,
  IndoorGeometry? geometry,
}) {
  final graphBuilder = IndoorFloorGraphBuilder();
  final geo = geometry ?? const IndoorGeometry();

  return IndoorRoutePointBuilder(
    portalSelector:
        portalSelector ??
        IndoorPortalSelector(floorGraphBuilder: graphBuilder, geometry: geo),
    corridorPathBuilder:
        corridorPathBuilder ??
        IndoorCorridorPathBuilder(
          floorGraphBuilder: graphBuilder,
          indoorDijkstra: IndoorDijkstra(),
          geometry: geo,
        ),
    geometry: geo,
  );
}

IndoorRoutingNode _roomNode({required int id, required LatLng center}) {
  return IndoorRoutingNode(
    id: id,
    nodeType: IndoorRoutingNodeType.room,
    roomCode: 'R$id',
    transitionType: null,
    level: '1',
    center: center,
    polygonPoints: const [
      LatLng(0, 0),
      LatLng(0, 0.0001),
      LatLng(0.0001, 0.0001),
      LatLng(0.0001, 0),
      LatLng(0, 0),
    ],
  );
}

IndoorRoutingNode _corridorNode({required int id, required LatLng center}) {
  return IndoorRoutingNode(
    id: id,
    nodeType: IndoorRoutingNodeType.corridor,
    roomCode: null,
    transitionType: null,
    level: '1',
    center: center,
    polygonPoints: const [
      LatLng(0, 0),
      LatLng(0, 0.0001),
      LatLng(0.0001, 0.0001),
      LatLng(0.0001, 0),
      LatLng(0, 0),
    ],
  );
}

class _ScriptedPortalSelector extends IndoorPortalSelector {
  final List<LatLng?> scriptedPortals;

  _ScriptedPortalSelector({required this.scriptedPortals})
    : super(
        floorGraphBuilder: IndoorFloorGraphBuilder(),
        geometry: const IndoorGeometry(),
      );

  @override
  LatLng? portalBetweenTowardTarget({
    required IndoorRoutingNode from,
    required IndoorRoutingNode to,
    required LatLng target,
  }) {
    if (scriptedPortals.isEmpty) {
      return null;
    }
    return scriptedPortals.removeAt(0);
  }
}

class _ScriptedCorridorPathBuilder extends IndoorCorridorPathBuilder {
  final List<LatLng>? boundaryPath;
  final LatLng? oneBend;
  final (LatLng, LatLng)? twoBend;
  final List<LatLng>? boundaryFallback;

  _ScriptedCorridorPathBuilder({
    this.boundaryPath,
    this.oneBend,
    this.twoBend,
    this.boundaryFallback,
  }) : super(
         floorGraphBuilder: IndoorFloorGraphBuilder(),
         indoorDijkstra: IndoorDijkstra(),
         geometry: const IndoorGeometry(),
       );

  @override
  List<LatLng>? findBoundaryConstrainedCorridorPath({
    required LatLng entry,
    required LatLng exit,
    required List<LatLng> corridorPolygon,
  }) {
    return boundaryPath;
  }

  @override
  LatLng? findCorridorBendPoint(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon, {
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
  }) {
    return oneBend;
  }

  @override
  (LatLng, LatLng)? findCorridorTwoBendPath(
    LatLng entry,
    LatLng exit,
    List<LatLng> corridorPolygon, {
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
  }) {
    return twoBend;
  }

  @override
  List<LatLng>? fallbackAlongCorridorBoundary({
    required LatLng entry,
    required LatLng exit,
    required List<LatLng> corridorPolygon,
  }) {
    return boundaryFallback;
  }
}

class _ScriptedGeometry extends IndoorGeometry {
  final List<double> distances;
  final List<bool> segmentInsideResponses;

  _ScriptedGeometry({
    this.distances = const [5.0],
    this.segmentInsideResponses = const [true],
  });

  @override
  double distanceMeters(LatLng a, LatLng b) {
    if (distances.isEmpty) {
      return 0.0;
    }
    return distances.length == 1 ? distances.first : distances.removeAt(0);
  }

  @override
  bool segmentInsideCorridor({
    required LatLng a,
    required LatLng b,
    required List<LatLng> corridorPolygon,
    required List<List<LatLng>> blockedRoomPolygons,
    required bool avoidBlockedRooms,
    required int minSamples,
    required double sampleSpacingMeters,
  }) {
    if (segmentInsideResponses.isEmpty) {
      return false;
    }
    return segmentInsideResponses.length == 1
        ? segmentInsideResponses.first
        : segmentInsideResponses.removeAt(0);
  }
}
