import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_route_plan_models.dart';
import 'package:campus_app/services/indoors_routing/indoor_multi_floor_router.dart';
import 'package:campus_app/services/indoors_routing/indoor_same_floor_router.dart';
import 'package:campus_app/services/location/indoor_route_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorRouteService', () {
    final service = IndoorRouteService();
    test('buildIndoorRoutePolylines returns empty for less than 2 points', () {
      expect(service.buildIndoorRoutePolylines(const [LatLng(0, 0)]), isEmpty);
    });

    test('buildIndoorRoutePolylines creates polyline with expected id', () {
      final polylines = service.buildIndoorRoutePolylines(const [
        LatLng(45.0, -73.0),
        LatLng(45.0, -72.9999),
      ]);

      expect(polylines.length, 1);
      expect(polylines.first.polylineId.value, 'indoor_same_floor_route');
    });

    test('buildIndoorNavigation returns summary with arrival step', () {
      final summary = service.buildIndoorNavigation(const [
        LatLng(45.00000, -73.00000),
        LatLng(45.00000, -72.99990),
        LatLng(45.00010, -72.99990),
      ]);

      expect(summary.steps, isNotEmpty);
      expect(summary.steps.last.instruction, 'Arrive at your destination room');
      expect(summary.distanceText, isNotNull);
      expect(summary.durationText, isNotNull);
    });

    test('buildIndoorNavigation empty when less than 2 points', () {
      final summary = service.buildIndoorNavigation(const [
        LatLng(45.0, -73.0),
      ]);
      expect(summary.steps, isEmpty);
      expect(summary.distanceText, isNull);
      expect(summary.durationText, isNull);
    });

    test('room lookup and same-floor path delegate to router', () {
      final geoJson = _simpleFloorGeoJson();

      final roomCenter = service.findRoomCenterOnFloor(
        floorGeoJson: geoJson,
        roomCode: 'A101',
      );
      final path = service.findSameFloorPath(
        floorGeoJson: geoJson,
        originRoomCode: 'A101',
        destinationRoomCode: 'B101',
      );

      expect(roomCenter, isNotNull);
      expect(path, isNotNull);
      expect(path!.length, greaterThanOrEqualTo(2));
    });

    test('builds origin and destination room markers', () {
      final origin = service.buildOriginRoomMarker('A101', const LatLng(1, 1));
      final destination = service.buildDestinationRoomMarker(
        'B101',
        const LatLng(2, 2),
      );

      expect(origin.markerId.value, 'origin_room');
      expect(destination.markerId.value, 'destination_room');
      expect(origin.infoWindow.title, 'Room A101');
      expect(destination.infoWindow.title, 'Room B101');
    });

    test('buildIndoorProgressMarker creates a reusable progress marker', () {
      final marker = service.buildIndoorProgressMarker(
        const LatLng(45.5, -73.6),
        title: 'Current step',
      );

      expect(marker.markerId.value, 'indoor_progress');
      expect(marker.infoWindow.title, 'Current step');
      expect(marker.position, const LatLng(45.5, -73.6));
    });

    test('arrival step keeps the destination point for manual progression', () {
      final summary = service.buildIndoorNavigation(const [
        LatLng(45.00000, -73.00000),
        LatLng(45.00005, -72.99995),
      ]);

      expect(summary.steps.last.instruction, 'Arrive at your destination room');
      expect(summary.steps.last.startPoint, const LatLng(45.00005, -72.99995));
    });

    test(
      'buildIndoorNavigationSession builds steps, transition point, and per-floor polylines',
      () async {
        final originRoom = IndoorResolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'A801',
          floorLabel: '8',
          floorLevel: '8',
          floorAssetPath: 'floor_8',
          floorGeoJson: _simpleFloorGeoJson(),
          center: const LatLng(45.000025, -72.999975),
        );
        final destinationRoom = IndoorResolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'B901',
          floorLabel: '9',
          floorLevel: '9',
          floorAssetPath: 'floor_9',
          floorGeoJson: _simpleFloorGeoJson(),
          center: const LatLng(45.000025, -72.999875),
        );

        final routePlan = IndoorRoutePlan(
          buildingCode: 'HALL',
          originRoomCode: 'A801',
          destinationRoomCode: 'B901',
          originRoom: originRoom,
          destinationRoom: destinationRoom,
          segments: const [
            IndoorRouteSegment(
              kind: IndoorRouteSegmentKind.walk,
              floorAssetPath: 'floor_8',
              floorLabel: '8',
              points: [
                LatLng(45.00000, -73.00000),
                LatLng(45.00000, -72.99995),
                LatLng(45.00000, -72.99990),
              ],
            ),
            IndoorRouteSegment(
              kind: IndoorRouteSegmentKind.transition,
              floorAssetPath: 'floor_9',
              floorLabel: '9',
              points: [],
              transitionMode: IndoorTransitionMode.stairs,
              instruction: 'Take the stairs from floor 8 to floor 9',
            ),
            IndoorRouteSegment(
              kind: IndoorRouteSegmentKind.walk,
              floorAssetPath: 'floor_9',
              floorLabel: '9',
              points: [
                LatLng(45.00010, -72.99990),
                LatLng(45.00010, -72.99985),
                LatLng(45.00010, -72.99980),
              ],
            ),
          ],
          totalDistanceMeters: 30,
        );

        final session =
            await IndoorRouteService(
              sameFloorRouter: IndoorSameFloorRouter(),
              multiFloorRouter: _FakeIndoorMultiFloorRouter(routePlan),
              indoorRepository: _FakeIndoorMapRepository({
                'A801': originRoom,
                'B901': destinationRoom,
              }),
            ).buildIndoorNavigationSession(
              buildingCode: 'HALL',
              originRoomCode: 'A801',
              destinationRoomCode: 'B901',
              preferredTransitionMode: IndoorTransitionMode.stairs,
            );

        expect(session, isNotNull);
        expect(session!.initialFloorAssetPath, 'floor_8');
        expect(
          session.polylinesByFloorAsset.keys,
          containsAll(['floor_8', 'floor_9']),
        );
        expect(session.steps, isNotEmpty);
        expect(
          session.steps.where((step) => step.indoorTransitionMode == 'stairs'),
          hasLength(1),
        );
        expect(
          session.steps
              .firstWhere((step) => step.indoorTransitionMode == 'stairs')
              .startPoint,
          const LatLng(45.00010, -72.99990),
        );
        expect(session.originMarker.infoWindow.title, 'Room A801');
        expect(session.destinationMarker.infoWindow.title, 'Room B901');
      },
    );

    test(
      'buildIndoorNavigationSession forwards preferred transition mode',
      () async {
        final originRoom = IndoorResolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'A801',
          floorLabel: '8',
          floorLevel: '8',
          floorAssetPath: 'floor_8',
          floorGeoJson: _simpleFloorGeoJson(),
          center: const LatLng(45.000025, -72.999975),
        );
        final destinationRoom = IndoorResolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'B901',
          floorLabel: '9',
          floorLevel: '9',
          floorAssetPath: 'floor_9',
          floorGeoJson: _simpleFloorGeoJson(),
          center: const LatLng(45.000025, -72.999875),
        );
        final fakeRouter = _FakeIndoorMultiFloorRouter(
          IndoorRoutePlan(
            buildingCode: 'HALL',
            originRoomCode: 'A801',
            destinationRoomCode: 'B901',
            originRoom: originRoom,
            destinationRoom: destinationRoom,
            segments: const [
              IndoorRouteSegment(
                kind: IndoorRouteSegmentKind.walk,
                floorAssetPath: 'floor_8',
                floorLabel: '8',
                points: [
                  LatLng(45.00000, -73.00000),
                  LatLng(45.00000, -72.99995),
                ],
              ),
            ],
            totalDistanceMeters: 12,
          ),
        );

        await IndoorRouteService(
          sameFloorRouter: IndoorSameFloorRouter(),
          multiFloorRouter: fakeRouter,
          indoorRepository: _FakeIndoorMapRepository({
            'A801': originRoom,
            'B901': destinationRoom,
          }),
        ).buildIndoorNavigationSession(
          buildingCode: 'HALL',
          originRoomCode: 'A801',
          destinationRoomCode: 'B901',
          preferredTransitionMode: IndoorTransitionMode.elevator,
        );

        expect(
          fakeRouter.lastPreferredTransitionMode,
          IndoorTransitionMode.elevator,
        );
      },
    );
  });
}

class _FakeIndoorMultiFloorRouter extends IndoorMultiFloorRouter {
  final IndoorRoutePlan routePlan;
  IndoorTransitionMode? lastPreferredTransitionMode;

  _FakeIndoorMultiFloorRouter(this.routePlan);

  @override
  IndoorRoutePlan? buildRoute({
    required IndoorResolvedRoom originRoom,
    required IndoorResolvedRoom destinationRoom,
    IndoorTransitionMode? preferredTransitionMode,
  }) {
    lastPreferredTransitionMode = preferredTransitionMode;
    return routePlan;
  }
}

class _FakeIndoorMapRepository extends IndoorMapRepository {
  final Map<String, IndoorResolvedRoom> roomsByCode;

  _FakeIndoorMapRepository(this.roomsByCode);

  @override
  Future<IndoorResolvedRoom?> resolveRoom(
    String buildingCode,
    String roomCode,
  ) async {
    return roomsByCode[roomCode];
  }

  @override
  List<IndoorFloorOption> getFloorOptionsForBuilding(String buildingCode) {
    return const [];
  }
}

Map<String, dynamic> _simpleFloorGeoJson() {
  return {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': {'indoor': 'room', 'ref': 'A101', 'level': '1'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-73.00000, 45.00000],
              [-72.99995, 45.00000],
              [-72.99995, 45.00005],
              [-73.00000, 45.00005],
              [-73.00000, 45.00000],
            ],
          ],
        },
      },
      {
        'type': 'Feature',
        'properties': {'indoor': 'corridor', 'level': '1'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-72.99995, 45.00000],
              [-72.99990, 45.00000],
              [-72.99990, 45.00005],
              [-72.99995, 45.00005],
              [-72.99995, 45.00000],
            ],
          ],
        },
      },
      {
        'type': 'Feature',
        'properties': {'indoor': 'room', 'ref': 'B101', 'level': '1'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-72.99990, 45.00000],
              [-72.99985, 45.00000],
              [-72.99985, 45.00005],
              [-72.99990, 45.00005],
              [-72.99990, 45.00000],
            ],
          ],
        },
      },
    ],
  };
}
