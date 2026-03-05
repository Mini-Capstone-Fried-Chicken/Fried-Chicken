import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:campus_app/models/campus.dart';
import '../../../services/location/googlemaps_livelocation.dart' show Campus, RouteTravelMode;

class OutdoorBottomControls extends StatelessWidget {
  final LatLng? currentLocation;
  final Campus currentCampus;

  final VoidCallback onGoToMyLocation;
  final VoidCallback onCenterOnUser;

  const OutdoorBottomControls({
    super.key,
    required this.currentLocation,
    required this.currentCampus,
    required this.onGoToMyLocation,
    required this.onCenterOnUser,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 70,
      left: 20,
      child: PointerInterceptor(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'location_button',
              mini: true,
              onPressed: onCenterOnUser,
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'campus_button',
              onPressed: onGoToMyLocation,
              icon: const Icon(Icons.school),
              label: Text(
                currentCampus == Campus.sgw
                    ? 'SGW Campus'
                    : currentCampus == Campus.loyola
                        ? 'Loyola Campus'
                        : 'Off Campus',
              ),
            ),
          ],
        ),
      ),
    );
  }
}