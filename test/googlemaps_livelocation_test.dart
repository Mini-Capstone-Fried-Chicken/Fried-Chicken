import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';

void main() {
  group('detectCampus', () {
    test('SGW center -> Campus.sgw', () {
      const sgw = LatLng(45.4973, -73.5789);
      expect(detectCampus(sgw), Campus.sgw);
    });

    test('Loyola center -> Campus.loyola', () {
      const loyola = LatLng(45.4582, -73.6405);
      expect(detectCampus(loyola), Campus.loyola);
    });

    test('Near SGW (still within radius) -> Campus.sgw', () {
    
      const nearSgw = LatLng(45.4981, -73.5789);
      expect(detectCampus(nearSgw), Campus.sgw);
    });

    test('Far away -> Campus.none', () {
      const far = LatLng(0, 0);
      expect(detectCampus(far), Campus.none);
    });
  });
}
