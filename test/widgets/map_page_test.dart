import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Interactive map loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(45.4973, -73.5790),
              zoom: 14,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(GoogleMap), findsOneWidget);
  });
}