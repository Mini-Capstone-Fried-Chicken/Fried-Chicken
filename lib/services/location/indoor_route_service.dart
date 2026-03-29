import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../indoor_maps/indoor_map_repository.dart';
import '../indoors_routing/core/indoor_route_plan_models.dart';
import '../indoors_routing/indoor_multi_floor_router.dart';
import '../indoors_routing/indoor_same_floor_router.dart';
import '../navigation_steps.dart';
import 'indoor_navigation_session.dart';

class IndoorRouteService {
  static const double _walkingMetersPerSecond = 1.35;

  final IndoorSameFloorRouter sameFloorRouter;
  final IndoorMultiFloorRouter multiFloorRouter;
  final IndoorMapRepository indoorRepository;

  IndoorRouteService({
    IndoorSameFloorRouter? sameFloorRouter,
    IndoorMultiFloorRouter? multiFloorRouter,
    IndoorMapRepository? indoorRepository,
  }) : this._resolved(
         sameFloorRouter ?? IndoorSameFloorRouter(),
         multiFloorRouter,
         indoorRepository,
       );

  IndoorRouteService._resolved(
    IndoorSameFloorRouter resolvedSameFloorRouter,
    IndoorMultiFloorRouter? multiFloorRouter,
    IndoorMapRepository? indoorRepository,
  ) : sameFloorRouter = resolvedSameFloorRouter,
      multiFloorRouter =
          multiFloorRouter ??
          IndoorMultiFloorRouter(sameFloorRouter: resolvedSameFloorRouter),
      indoorRepository = indoorRepository ?? IndoorMapRepository();

  LatLng? findRoomCenterOnFloor({
    required Map<String, dynamic> floorGeoJson,
    required String roomCode,
  }) {
    return sameFloorRouter.roomCenterOnFloor(
      floorGeoJson: floorGeoJson,
      roomCode: roomCode,
    );
  }

  List<LatLng>? findSameFloorPath({
    required Map<String, dynamic> floorGeoJson,
    required String originRoomCode,
    required String destinationRoomCode,
  }) {
    return sameFloorRouter.findShortestPath(
      floorGeoJson: floorGeoJson,
      originRoomCode: originRoomCode,
      destinationRoomCode: destinationRoomCode,
    );
  }

  Future<IndoorNavigationSession?> buildIndoorNavigationSession({
    required String buildingCode,
    required String originRoomCode,
    required String destinationRoomCode,
    IndoorTransitionMode? preferredTransitionMode,
  }) async {
    final originRoom = await indoorRepository.resolveRoom(
      buildingCode,
      originRoomCode,
    );
    final destinationRoom = await indoorRepository.resolveRoom(
      buildingCode,
      destinationRoomCode,
    );

    if (originRoom == null || destinationRoom == null) {
      return null;
    }

    if (originRoom.floorAssetPath != destinationRoom.floorAssetPath &&
        preferredTransitionMode == null) {
      return null;
    }

    final routePlan = multiFloorRouter.buildRoute(
      originRoom: originRoom,
      destinationRoom: destinationRoom,
      preferredTransitionMode: preferredTransitionMode,
    );
    if (routePlan == null) {
      return null;
    }

    return IndoorNavigationSession(
      routePlan: routePlan,
      steps: _buildStepsForRoutePlan(routePlan),
      polylinesByFloorAsset: _buildPolylinesByFloorAsset(routePlan),
      originMarker: buildOriginRoomMarker(
        originRoom.roomCode,
        originRoom.center,
      ),
      destinationMarker: buildDestinationRoomMarker(
        destinationRoom.roomCode,
        destinationRoom.center,
      ),
      initialFloorAssetPath: routePlan.segments.first.floorAssetPath,
      distanceText: _metersText(routePlan.totalDistanceMeters),
      durationText: _durationTextFromSeconds(
        (routePlan.totalDistanceMeters / _walkingMetersPerSecond).round(),
      ),
    );
  }

  Marker buildOriginRoomMarker(String roomCode, LatLng point) {
    return Marker(
      markerId: const MarkerId('origin_room'),
      position: point,
      infoWindow: InfoWindow(title: 'Room $roomCode'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  Marker buildDestinationRoomMarker(String roomCode, LatLng point) {
    return Marker(
      markerId: const MarkerId('destination_room'),
      position: point,
      infoWindow: InfoWindow(title: 'Room $roomCode'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }

  Marker buildIndoorProgressMarker(LatLng point, {String? title}) {
    return Marker(
      markerId: const MarkerId('indoor_progress'),
      position: point,
      infoWindow: InfoWindow(title: title ?? 'Current step'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  Set<Polyline> buildIndoorRoutePolylines(
    List<LatLng> routePoints, {
    String polylineId = 'indoor_same_floor_route',
  }) {
    if (routePoints.length < 2) {
      return {};
    }

    return {
      Polyline(
        polylineId: PolylineId(polylineId),
        points: routePoints,
        color: const Color(0xFF0A7E4D),
        width: 6,
        zIndex: 50,
      ),
    };
  }

  IndoorNavigationSummary buildIndoorNavigation(
    List<LatLng> routePoints, {
    String? floorAssetPath,
    String? floorLabel,
    bool includeArrivalStep = true,
    String arrivalInstruction = 'Arrive at your destination room',
  }) {
    if (routePoints.length < 2) {
      return const IndoorNavigationSummary.empty();
    }

    final steps = <NavigationStep>[];
    double totalMeters = 0;

    for (var i = 1; i < routePoints.length; i++) {
      final a = routePoints[i - 1];
      final b = routePoints[i];
      final meters = Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );

      if (meters < 1.0) {
        continue;
      }
      totalMeters += meters;

      String instruction;
      String? maneuver;
      if (i == 1) {
        instruction = 'Walk ahead';
        maneuver = 'straight';
      } else {
        final prevA = routePoints[i - 2];
        final prevB = routePoints[i - 1];
        final previousBearing = _bearingDegrees(prevA, prevB);
        final currentBearing = _bearingDegrees(a, b);
        final turn = _normalizeTurnDelta(currentBearing - previousBearing);

        if (turn > 25 && turn < 140) {
          instruction = 'Turn right';
          maneuver = 'turn-right';
        } else if (turn < -25 && turn > -140) {
          instruction = 'Turn left';
          maneuver = 'turn-left';
        } else if (turn.abs() >= 140) {
          instruction = 'Make a U-turn';
          maneuver = 'uturn-right';
        } else {
          instruction = 'Continue straight';
          maneuver = 'straight';
        }
      }

      final stepSeconds = (meters / _walkingMetersPerSecond).round();
      steps.add(
        NavigationStep(
          instruction: instruction,
          travelMode: 'walking',
          distanceText: _metersText(meters),
          durationText: _durationTextFromSeconds(stepSeconds),
          maneuver: maneuver,
          points: [a, b],
          indoorFloorAssetPath: floorAssetPath,
          indoorFloorLabel: floorLabel,
        ),
      );
    }

    if (includeArrivalStep) {
      steps.add(
        NavigationStep(
          instruction: arrivalInstruction,
          travelMode: 'walking',
          indoorFloorAssetPath: floorAssetPath,
          indoorFloorLabel: floorLabel,
          points: routePoints.isEmpty ? const [] : [routePoints.last],
        ),
      );
    }

    final totalSeconds = (totalMeters / _walkingMetersPerSecond).round();
    return IndoorNavigationSummary(
      steps: steps,
      distanceText: _metersText(totalMeters),
      durationText: _durationTextFromSeconds(totalSeconds),
    );
  }

  Map<String, Set<Polyline>> _buildPolylinesByFloorAsset(
    IndoorRoutePlan routePlan,
  ) {
    final polylinesByFloor = <String, Set<Polyline>>{};

    for (var i = 0; i < routePlan.segments.length; i++) {
      final segment = routePlan.segments[i];
      if (segment.kind != IndoorRouteSegmentKind.walk ||
          segment.points.length < 2) {
        continue;
      }

      polylinesByFloor.putIfAbsent(segment.floorAssetPath, () => <Polyline>{});
      polylinesByFloor[segment.floorAssetPath]!.addAll(
        buildIndoorRoutePolylines(
          segment.points,
          polylineId: 'indoor_route_${segment.floorAssetPath}_$i',
        ),
      );
    }

    return polylinesByFloor;
  }

  List<NavigationStep> _buildStepsForRoutePlan(IndoorRoutePlan routePlan) {
    final steps = <NavigationStep>[];

    for (var i = 0; i < routePlan.segments.length; i++) {
      final segment = routePlan.segments[i];

      switch (segment.kind) {
        case IndoorRouteSegmentKind.walk:
          final includeArrivalStep = i == routePlan.segments.length - 1;
          final summary = buildIndoorNavigation(
            segment.points,
            floorAssetPath: segment.floorAssetPath,
            floorLabel: segment.floorLabel,
            includeArrivalStep: includeArrivalStep,
          );
          steps.addAll(summary.steps);
          break;
        case IndoorRouteSegmentKind.transition:
          final transitionPoint = _transitionStepPoint(routePlan.segments, i);
          steps.add(
            NavigationStep(
              instruction:
                  segment.instruction ??
                  'Change floors and continue to your destination',
              travelMode: 'walking',
              indoorFloorAssetPath: segment.floorAssetPath,
              indoorFloorLabel: segment.floorLabel,
              indoorTransitionMode: _transitionModeName(segment.transitionMode),
              points: transitionPoint == null ? const [] : [transitionPoint],
            ),
          );
          break;
      }
    }

    return steps;
  }

  String? _transitionModeName(IndoorTransitionMode? mode) {
    return switch (mode) {
      IndoorTransitionMode.stairs => 'stairs',
      IndoorTransitionMode.elevator => 'elevator',
      IndoorTransitionMode.escalator => 'escalator',
      null => null,
    };
  }

  LatLng? _transitionStepPoint(List<IndoorRouteSegment> segments, int index) {
    for (var i = index + 1; i < segments.length; i++) {
      final nextSegment = segments[i];
      if (nextSegment.kind == IndoorRouteSegmentKind.walk &&
          nextSegment.points.isNotEmpty) {
        return nextSegment.points.first;
      }
    }

    for (var i = index - 1; i >= 0; i--) {
      final previousSegment = segments[i];
      if (previousSegment.kind == IndoorRouteSegmentKind.walk &&
          previousSegment.points.isNotEmpty) {
        return previousSegment.points.last;
      }
    }

    return null;
  }

  String _metersText(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _durationTextFromSeconds(int seconds) {
    final mins = (seconds / 60).ceil();
    return mins <= 1 ? '1 min' : '$mins min';
  }

  double _bearingDegrees(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final dLon = (to.longitude - from.longitude) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  double _normalizeTurnDelta(double delta) {
    var value = delta;
    while (value > 180) {
      value -= 360;
    }
    while (value < -180) {
      value += 360;
    }
    return value;
  }
}

class IndoorNavigationSummary {
  final List<NavigationStep> steps;
  final String? distanceText;
  final String? durationText;

  const IndoorNavigationSummary({
    required this.steps,
    required this.distanceText,
    required this.durationText,
  });

  const IndoorNavigationSummary.empty()
    : steps = const [],
      distanceText = null,
      durationText = null;
}
