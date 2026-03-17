import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/models/campus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';

void main() {
  testWidgets('OutdoorMapPage builds when map is disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.none,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true, 
        ),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
  });

  test('detectCampus returns SGW and Loyola around campus anchors', () {
    expect(detectCampus(concordiaSGW), Campus.sgw);
    expect(detectCampus(concordiaLoyola), Campus.loyola);
    expect(detectCampus(const LatLng(0, 0)), Campus.none);
  });

  test('RouteTravelMode maps to expected api and labels', () {
    expect(RouteTravelMode.driving.apiValue, 'driving');
    expect(RouteTravelMode.walking.apiValue, 'walking');
    expect(RouteTravelMode.bicycling.apiValue, 'bicycling');
    expect(RouteTravelMode.transit.apiValue, 'transit');
    expect(RouteTravelMode.shuttle.apiValue, 'shuttle');

    expect(RouteTravelMode.driving.label, 'Driving');
    expect(RouteTravelMode.walking.label, 'Walking');
    expect(RouteTravelMode.bicycling.label, 'Biking');
    expect(RouteTravelMode.transit.label, 'Transit');
    expect(RouteTravelMode.shuttle.label, 'Shuttle');
  });

  test('OutdoorMapPage stores debug constructor parameters', () {
    const widget = OutdoorMapPage(
      initialCampus: Campus.loyola,
      isLoggedIn: true,
      debugDisableMap: true,
      debugDisableLocation: true,
      debugAnchorOffset: Offset(10, 20),
      debugLinkOverride: 'https://www.concordia.ca',
    );

    expect(widget.initialCampus, Campus.loyola);
    expect(widget.isLoggedIn, isTrue);
    expect(widget.debugDisableMap, isTrue);
    expect(widget.debugDisableLocation, isTrue);
    expect(widget.debugAnchorOffset, const Offset(10, 20));
    expect(widget.debugLinkOverride, 'https://www.concordia.ca');
  });
}