import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/models/campus.dart';

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
}