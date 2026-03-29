import 'package:campus_app/services/indoors_routing/core/indoor_route_plan_models.dart';
import 'package:campus_app/services/indoors_routing/indoor_multi_floor_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorMultiFloorRouter', () {
    final router = IndoorMultiFloorRouter();

    test('buildRoute returns a single walk segment for same-floor rooms', () {
      final floor = _sameFloorGeoJson();
      final plan = router.buildRoute(
        originRoom: _resolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'A101',
          floorLabel: '8',
          floorAssetPath: 'floor_8',
          floorGeoJson: floor,
          center: const LatLng(45.000025, -72.999975),
        ),
        destinationRoom: _resolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'B101',
          floorLabel: '8',
          floorAssetPath: 'floor_8',
          floorGeoJson: floor,
          center: const LatLng(45.000025, -72.999875),
        ),
      );

      expect(plan, isNotNull);
      expect(plan!.segments, hasLength(1));
      expect(plan.segments.single.kind, IndoorRouteSegmentKind.walk);
      expect(plan.segments.single.floorAssetPath, 'floor_8');
      expect(plan.totalDistanceMeters, greaterThan(0));
    });

    test('buildRoute stitches two walk segments with a transition step', () {
      final originFloor = _originFloorGeoJson();
      final destinationFloor = _destinationFloorGeoJson();

      final plan = router.buildRoute(
        originRoom: _resolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'A801',
          floorLabel: '8',
          floorAssetPath: 'floor_8',
          floorGeoJson: originFloor,
          center: const LatLng(45.000025, -72.999975),
        ),
        destinationRoom: _resolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'B901',
          floorLabel: '9',
          floorAssetPath: 'floor_9',
          floorGeoJson: destinationFloor,
          center: const LatLng(45.000025, -72.999975),
        ),
      );

      expect(plan, isNotNull);
      expect(plan!.segments, hasLength(3));
      expect(plan.segments[0].kind, IndoorRouteSegmentKind.walk);
      expect(plan.segments[1].kind, IndoorRouteSegmentKind.transition);
      expect(plan.segments[2].kind, IndoorRouteSegmentKind.walk);
      expect(plan.segments[1].transitionMode, IndoorTransitionMode.stairs);
      expect(
        plan.segments[1].instruction,
        'Take the stairs from floor 8 to floor 9',
      );

      final originTransition = router.sameFloorRouter
          .transitionNodesOnFloor(floorGeoJson: originFloor)
          .single;
      final destinationTransition = router.sameFloorRouter
          .transitionNodesOnFloor(floorGeoJson: destinationFloor)
          .single;

      expect(
        router.geometry.areSameLatLng(
          plan.segments[0].points.last,
          originTransition.center,
        ),
        isFalse,
        reason:
            'Origin segment should end at the corridor portal, not the transition center.',
      );
      expect(
        router.geometry.areSameLatLng(
          plan.segments[2].points.first,
          destinationTransition.center,
        ),
        isFalse,
        reason:
            'Destination segment should start from the corridor portal, not the transition center.',
      );
    });

    test(
      'buildRoute returns null when compatible transitions do not exist',
      () {
        final plan = router.buildRoute(
          originRoom: _resolvedRoom(
            buildingCode: 'HALL',
            roomCode: 'A801',
            floorLabel: '8',
            floorAssetPath: 'floor_8',
            floorGeoJson: _originFloorGeoJson(),
            center: const LatLng(45.000025, -72.999975),
          ),
          destinationRoom: _resolvedRoom(
            buildingCode: 'HALL',
            roomCode: 'B901',
            floorLabel: '9',
            floorAssetPath: 'floor_9',
            floorGeoJson: _destinationFloorGeoJson(
              transitionProperties: {'highway': 'elevator', 'level': '9'},
            ),
            center: const LatLng(45.000025, -72.999975),
          ),
        );

        expect(plan, isNull);
      },
    );

    test('buildRoute respects a preferred transition mode when available', () {
      final plan = router.buildRoute(
        originRoom: _resolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'A801',
          floorLabel: '8',
          floorAssetPath: 'floor_8',
          floorGeoJson: _originFloorGeoJson(
            extraTransitionProperties: const [
              {'highway': 'elevator', 'level': '8'},
            ],
          ),
          center: const LatLng(45.000025, -72.999975),
        ),
        destinationRoom: _resolvedRoom(
          buildingCode: 'HALL',
          roomCode: 'B901',
          floorLabel: '9',
          floorAssetPath: 'floor_9',
          floorGeoJson: _destinationFloorGeoJson(
            extraTransitionProperties: const [
              {'highway': 'elevator', 'level': '9'},
            ],
          ),
          center: const LatLng(45.000025, -72.999975),
        ),
        preferredTransitionMode: IndoorTransitionMode.elevator,
      );

      expect(plan, isNotNull);
      expect(plan!.segments[1].transitionMode, IndoorTransitionMode.elevator);
      expect(
        plan.segments[1].instruction,
        'Take the elevator from floor 8 to floor 9',
      );
    });
  });
}

IndoorResolvedRoom _resolvedRoom({
  required String buildingCode,
  required String roomCode,
  required String floorLabel,
  required String floorAssetPath,
  required Map<String, dynamic> floorGeoJson,
  required LatLng center,
}) {
  return IndoorResolvedRoom(
    buildingCode: buildingCode,
    roomCode: roomCode,
    floorLabel: floorLabel,
    floorLevel: floorLabel,
    floorAssetPath: floorAssetPath,
    floorGeoJson: floorGeoJson,
    center: center,
  );
}

Map<String, dynamic> _sameFloorGeoJson() {
  return {
    'type': 'FeatureCollection',
    'features': [
      _roomFeature('A101', '8', -73.00000, -72.99995),
      _corridorFeature('8', -72.99995, -72.99990),
      _roomFeature('B101', '8', -72.99990, -72.99985),
    ],
  };
}

Map<String, dynamic> _originFloorGeoJson({
  List<Map<String, dynamic>> extraTransitionProperties = const [],
}) {
  return {
    'type': 'FeatureCollection',
    'features': [
      _roomFeature('A801', '8', -73.00000, -72.99995),
      _corridorFeature('8', -72.99995, -72.99990),
      _transitionFeature(
        level: '8',
        leftLng: -72.99990,
        rightLng: -72.99985,
        properties: {'highway': 'steps', 'level': '8'},
      ),
      for (final properties in extraTransitionProperties)
        _transitionFeature(
          level: '8',
          leftLng: -72.99990,
          rightLng: -72.99985,
          properties: properties,
        ),
    ],
  };
}

Map<String, dynamic> _destinationFloorGeoJson({
  Map<String, dynamic>? transitionProperties,
  List<Map<String, dynamic>> extraTransitionProperties = const [],
}) {
  return {
    'type': 'FeatureCollection',
    'features': [
      _transitionFeature(
        level: '9',
        leftLng: -73.00000,
        rightLng: -72.99995,
        properties: transitionProperties ?? {'highway': 'steps', 'level': '9'},
      ),
      _corridorFeature('9', -72.99995, -72.99990),
      _roomFeature('B901', '9', -72.99990, -72.99985),
      for (final properties in extraTransitionProperties)
        _transitionFeature(
          level: '9',
          leftLng: -73.00000,
          rightLng: -72.99995,
          properties: properties,
        ),
    ],
  };
}

Map<String, dynamic> _roomFeature(
  String ref,
  String level,
  double leftLng,
  double rightLng,
) {
  return {
    'type': 'Feature',
    'properties': {'indoor': 'room', 'ref': ref, 'level': level},
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        [
          [leftLng, 45.00000],
          [rightLng, 45.00000],
          [rightLng, 45.00005],
          [leftLng, 45.00005],
          [leftLng, 45.00000],
        ],
      ],
    },
  };
}

Map<String, dynamic> _corridorFeature(
  String level,
  double leftLng,
  double rightLng,
) {
  return {
    'type': 'Feature',
    'properties': {'indoor': 'corridor', 'level': level},
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        [
          [leftLng, 45.00000],
          [rightLng, 45.00000],
          [rightLng, 45.00005],
          [leftLng, 45.00005],
          [leftLng, 45.00000],
        ],
      ],
    },
  };
}

Map<String, dynamic> _transitionFeature({
  required String level,
  required double leftLng,
  required double rightLng,
  required Map<String, dynamic> properties,
}) {
  return {
    'type': 'Feature',
    'properties': properties,
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        [
          [leftLng, 45.00000],
          [rightLng, 45.00000],
          [rightLng, 45.00005],
          [leftLng, 45.00005],
          [leftLng, 45.00000],
        ],
      ],
    },
  };
}
