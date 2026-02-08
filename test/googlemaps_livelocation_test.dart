import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';

void main() {
  group('detectCampus', () {
    test('returns Campus.sgw for SGW location', () {
      final sgw = LatLng(45.4973, -73.5789);
      expect(detectCampus(sgw), Campus.sgw);
    });

    test('returns Campus.loyola for Loyola location', () {
      final loyola = LatLng(45.4582, -73.6405);
      expect(detectCampus(loyola), Campus.loyola);
    });

    test('returns Campus.none for far location', () {
      final far = LatLng(0, 0);
      expect(detectCampus(far), Campus.none);
    });
  });
}
