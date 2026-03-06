import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OutdoorMapView extends StatelessWidget {
  final LatLng initialTarget;
  final bool showIndoorStyle;
  final String? indoorMapStyle;

  final void Function(GoogleMapController) onMapCreated;
  final void Function(CameraPosition) onCameraMove;
  final VoidCallback onCameraMoveStarted;
  final VoidCallback onCameraIdle;

  final Set<Marker> markers;
  final Set<Circle> circles;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;

  const OutdoorMapView({
    super.key,
    required this.initialTarget,
    required this.showIndoorStyle,
    required this.indoorMapStyle,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraMoveStarted,
    required this.onCameraIdle,
    required this.markers,
    required this.circles,
    required this.polygons,
    required this.polylines,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialTarget, zoom: 16),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      style: showIndoorStyle ? indoorMapStyle : null,
      onMapCreated: onMapCreated,
      onCameraMove: onCameraMove,
      onCameraMoveStarted: onCameraMoveStarted,
      onCameraIdle: onCameraIdle,
      markers: markers,
      circles: circles,
      polygons: polygons,
      polylines: polylines,
    );
  }
}