import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../shared/widgets/campus_toggle.dart';
import '../../../shared/widgets/route_preview_panel.dart';
import '../../../services/navigation_steps.dart';
import '../../../services/location/googlemaps_livelocation.dart' show RouteTravelMode;
import 'package:campus_app/models/campus.dart';

class OutdoorBottomBar extends StatelessWidget {
  final bool showRoutePreview;
  final bool isNavigating;

  final Campus selectedCampus;
  final void Function(Campus) onCampusChanged;

  // route bar props
  final RouteTravelMode selectedTravelMode;
  final void Function(RouteTravelMode) onTravelModeSelected;
  final Map<String, String?> routeDurations;
  final Map<String, String?> routeDistances;
  final Map<String, String?> routeArrivalTimes;
  final bool isLoadingRouteData;

  final VoidCallback onCloseRoutePreview;
  final VoidCallback onStartNavigation;
  final VoidCallback onShowSteps;

  final List<TransitDetailItem> transitDetails;

  const OutdoorBottomBar({
    super.key,
    required this.showRoutePreview,
    required this.isNavigating,
    required this.selectedCampus,
    required this.onCampusChanged,
    required this.selectedTravelMode,
    required this.onTravelModeSelected,
    required this.routeDurations,
    required this.routeDistances,
    required this.routeArrivalTimes,
    required this.isLoadingRouteData,
    required this.onCloseRoutePreview,
    required this.onStartNavigation,
    required this.onShowSteps,
    required this.transitDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (showRoutePreview) {
      return Positioned(
        bottom: 25,
        left: 0,
        right: 0,
        child: PointerInterceptor(
          child: Center(
            child: RouteTravelModeBar(
              selectedTravelMode: selectedTravelMode,
              onTravelModeSelected: onTravelModeSelected,
              modeDurations: routeDurations,
              isLoadingDurations: isLoadingRouteData,
              onClose: onCloseRoutePreview,
              onStart: onStartNavigation,
              isNavigating: isNavigating,
              onShowSteps: onShowSteps,
              transitDetails: transitDetails,
              modeDistances: routeDistances,
              modeArrivalTimes: routeArrivalTimes,
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 25,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 280,
          child: CampusToggle(
            currentCampus: selectedCampus,
            onCampusChanged: onCampusChanged,
          ),
        ),
      ),
    );
  }
}