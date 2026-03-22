import 'package:campus_app/services/indoors_routing/core/indoor_route_plan_models.dart';
import 'package:campus_app/services/location/indoor_manual_navigation_controller.dart';
import 'package:campus_app/services/location/indoor_navigation_session.dart';
import 'package:campus_app/services/navigation_steps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorManualNavigationController', () {
    late IndoorManualNavigationController controller;
    late IndoorNavigationSession session;

    setUp(() {
      controller = IndoorManualNavigationController();
      session = _buildSession();
    });

    test('start initializes session, first step, and displayed floor', () {
      controller.start(session);

      expect(controller.isActive, isTrue);
      expect(controller.session, same(session));
      expect(controller.currentStepIndex, 0);
      expect(controller.currentStep?.instruction, 'Walk ahead');
      expect(controller.displayedFloorAssetPath, 'floor_8');
      expect(controller.currentFloorPolylines, hasLength(1));
    });

    test('nextStep and previousStep update index and floor', () {
      controller.start(session);

      controller.nextStep();
      expect(controller.currentStepIndex, 1);
      expect(controller.displayedFloorAssetPath, 'floor_9');
      expect(controller.canGoPrevious, isTrue);

      controller.nextStep();
      expect(controller.currentStepIndex, 2);
      expect(controller.displayedFloorAssetPath, 'floor_9');
      expect(controller.canGoNext, isFalse);

      controller.previousStep();
      expect(controller.currentStepIndex, 1);
      expect(controller.displayedFloorAssetPath, 'floor_9');

      controller.previousStep();
      expect(controller.currentStepIndex, 0);
      expect(controller.displayedFloorAssetPath, 'floor_8');
    });

    test('setDisplayedFloorAssetPath overrides current floor view', () {
      controller.start(session);

      controller.setDisplayedFloorAssetPath('floor_9');

      expect(controller.displayedFloorAssetPath, 'floor_9');
      expect(controller.currentFloorPolylines, hasLength(1));
    });

    test('stop clears state', () {
      controller.start(session);

      controller.stop();

      expect(controller.isActive, isFalse);
      expect(controller.session, isNull);
      expect(controller.currentStep, isNull);
      expect(controller.currentStepIndex, 0);
      expect(controller.displayedFloorAssetPath, isNull);
      expect(controller.currentFloorPolylines, isEmpty);
    });
  });
}

IndoorNavigationSession _buildSession() {
  final originRoom = IndoorResolvedRoom(
    buildingCode: 'HALL',
    roomCode: 'A801',
    floorLabel: '8',
    floorLevel: '8',
    floorAssetPath: 'floor_8',
    floorGeoJson: const {},
    center: const LatLng(45.0, -73.0),
  );
  final destinationRoom = IndoorResolvedRoom(
    buildingCode: 'HALL',
    roomCode: 'B901',
    floorLabel: '9',
    floorLevel: '9',
    floorAssetPath: 'floor_9',
    floorGeoJson: const {},
    center: const LatLng(45.1, -73.1),
  );

  return IndoorNavigationSession(
    routePlan: IndoorRoutePlan(
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
          points: [LatLng(45.0, -73.0), LatLng(45.0, -72.9999)],
        ),
        IndoorRouteSegment(
          kind: IndoorRouteSegmentKind.transition,
          floorAssetPath: 'floor_9',
          floorLabel: '9',
          points: [],
          transitionMode: IndoorTransitionMode.stairs,
        ),
        IndoorRouteSegment(
          kind: IndoorRouteSegmentKind.walk,
          floorAssetPath: 'floor_9',
          floorLabel: '9',
          points: [LatLng(45.1, -73.1), LatLng(45.1, -73.0999)],
        ),
      ],
      totalDistanceMeters: 24,
    ),
    steps: const [
      NavigationStep(
        instruction: 'Walk ahead',
        travelMode: 'walking',
        indoorFloorAssetPath: 'floor_8',
        indoorFloorLabel: '8',
        points: [LatLng(45.0, -73.0), LatLng(45.0, -72.9999)],
      ),
      NavigationStep(
        instruction: 'Take the stairs',
        travelMode: 'walking',
        indoorFloorAssetPath: 'floor_9',
        indoorFloorLabel: '9',
        indoorTransitionMode: 'stairs',
        points: [LatLng(45.1, -73.1)],
      ),
      NavigationStep(
        instruction: 'Arrive at your destination room',
        travelMode: 'walking',
        indoorFloorAssetPath: 'floor_9',
        indoorFloorLabel: '9',
        points: [LatLng(45.1, -73.0999)],
      ),
    ],
    polylinesByFloorAsset: {
      'floor_8': {
        const Polyline(
          polylineId: PolylineId('f8'),
          points: [LatLng(45.0, -73.0), LatLng(45.0, -72.9999)],
        ),
      },
      'floor_9': {
        const Polyline(
          polylineId: PolylineId('f9'),
          points: [LatLng(45.1, -73.1), LatLng(45.1, -73.0999)],
        ),
      },
    },
    originMarker: const Marker(
      markerId: MarkerId('origin_room'),
      position: LatLng(45.0, -73.0),
    ),
    destinationMarker: const Marker(
      markerId: MarkerId('destination_room'),
      position: LatLng(45.1, -73.1),
    ),
    initialFloorAssetPath: 'floor_8',
    distanceText: '24 m',
    durationText: '1 min',
  );
}
