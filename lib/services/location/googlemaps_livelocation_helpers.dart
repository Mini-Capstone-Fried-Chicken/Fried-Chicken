import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';

Campus campusFromPoint(LatLng p) {
  final dSgw = Geolocator.distanceBetween(
    p.latitude,
    p.longitude,
    concordiaSGW.latitude,
    concordiaSGW.longitude,
  );

  final dLoy = Geolocator.distanceBetween(
    p.latitude,
    p.longitude,
    concordiaLoyola.latitude,
    concordiaLoyola.longitude,
  );

  final minDist = dSgw < dLoy ? dSgw : dLoy;
  if (minDist > campusAutoSwitchRadius) return Campus.none;

  return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
}

Uri? validateUrl(String url) {
  if (url.trim().isEmpty) return null;
  return Uri.tryParse(url);
}
