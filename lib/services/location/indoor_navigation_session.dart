import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../indoors_routing/core/indoor_route_plan_models.dart';
import '../navigation_steps.dart';

class IndoorNavigationSession {
  final IndoorRoutePlan routePlan;
  final List<NavigationStep> steps;
  final Map<String, Set<Polyline>> polylinesByFloorAsset;
  final Marker originMarker;
  final Marker destinationMarker;
  final String initialFloorAssetPath;
  final String? distanceText;
  final String? durationText;

  const IndoorNavigationSession({
    required this.routePlan,
    required this.steps,
    required this.polylinesByFloorAsset,
    required this.originMarker,
    required this.destinationMarker,
    required this.initialFloorAssetPath,
    required this.distanceText,
    required this.durationText,
  });
}
