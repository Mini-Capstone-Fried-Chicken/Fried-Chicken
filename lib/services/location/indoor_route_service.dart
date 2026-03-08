import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../indoors_routing/indoor_same_floor_router.dart';
import '../navigation_steps.dart';

class IndoorRouteService {
  final IndoorSameFloorRouter sameFloorRouter;

  IndoorRouteService({IndoorSameFloorRouter? sameFloorRouter})
    : sameFloorRouter = sameFloorRouter ?? IndoorSameFloorRouter();

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

  Set<Polyline> buildIndoorRoutePolylines(List<LatLng> routePoints) {
    if (routePoints.length < 2) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('indoor_same_floor_route'),
        points: routePoints,
        color: const Color(0xFF0A7E4D),
        width: 6,
        zIndex: 50,
      ),
    };
  }

  IndoorNavigationSummary buildIndoorNavigation(List<LatLng> routePoints) {
    if (routePoints.length < 2) {
      return const IndoorNavigationSummary.empty();
    }

    const walkingMetersPerSecond = 1.35;
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

      if (meters < 1.0) continue;
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

      final stepSeconds = (meters / walkingMetersPerSecond).round();
      steps.add(
        NavigationStep(
          instruction: instruction,
          travelMode: 'walking',
          distanceText: _metersText(meters),
          durationText: _durationTextFromSeconds(stepSeconds),
          maneuver: maneuver,
          points: [a, b],
        ),
      );
    }

    final totalSeconds = (totalMeters / walkingMetersPerSecond).round();
    return IndoorNavigationSummary(
      steps: [
        ...steps,
        const NavigationStep(
          instruction: 'Arrive at your destination room',
          travelMode: 'walking',
        ),
      ],
      distanceText: _metersText(totalMeters),
      durationText: _durationTextFromSeconds(totalSeconds),
    );
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
