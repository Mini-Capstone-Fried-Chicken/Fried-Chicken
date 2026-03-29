import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:campus_app/models/campus.dart';

class OutdoorBottomControls extends StatelessWidget {
  final LatLng? currentLocation;
  final Campus currentCampus;
  final bool highContrastMode;

  final VoidCallback onGoToMyLocation;
  final VoidCallback onCenterOnUser;

  const OutdoorBottomControls({
    super.key,
    required this.currentLocation,
    required this.currentCampus,
    required this.onGoToMyLocation,
    required this.onCenterOnUser,
    this.highContrastMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highContrastMode ? const Color(0xFF002620) : null;
    final fgColor = highContrastMode ? const Color(0xFF89D9C2) : null;

    String campusLabel;
    if (currentCampus == Campus.sgw) {
      campusLabel = 'SGW Campus';
    } else if (currentCampus == Campus.loyola) {
      campusLabel = 'Loyola Campus';
    } else {
      campusLabel = 'Off Campus';
    }

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
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'campus_button',
              onPressed: onGoToMyLocation,
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              icon: const Icon(Icons.school),
              label: Text(campusLabel),
            ),
          ],
        ),
      ),
    );
  }
}
