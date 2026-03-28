import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';
import 'package:campus_app/services/location/shuttle_route_service.dart';
import 'package:campus_app/services/concordia_shuttle_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MockShuttleDeparture extends Mock implements ShuttleDeparture {}

void main() {
  late MockShuttleDeparture mockDeparture;

  setUp(() {
    mockDeparture = MockShuttleDeparture();
    when(() => mockDeparture.statusLabel).thenReturn('in 30 min');
    when(() => mockDeparture.departureTimeDisplay).thenReturn('2:45 PM');
  });

  group('RouteTravelModeBar - No Service', () {
    testWidgets('isNoService = true displays all buses in tertiary color', (
      tester,
    ) async {
      final mockDeparture1 = MockShuttleDeparture();
      final mockDeparture2 = MockShuttleDeparture();
      final mockDeparture3 = MockShuttleDeparture();
      final mockDeparture4 = MockShuttleDeparture();
      when(() => mockDeparture1.statusLabel).thenReturn('8:00 AM');
      when(() => mockDeparture2.statusLabel).thenReturn('8:30 AM');
      when(() => mockDeparture3.statusLabel).thenReturn('9:00 AM');
      when(() => mockDeparture4.statusLabel).thenReturn('9:30 AM');

      final outOfServiceRoute = ShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttlePoints: [],
        shuttleRoutePoints: [],
        walkFromShuttlePoints: [],
        buses: [mockDeparture1, mockDeparture2, mockDeparture3, mockDeparture4],
        walkingToShuttleMinutes: null,
        walkingFromShuttleMinutes: null,
        isInService: false,
        shuttleDurationLabel: 'No service',
        totalTripDuration: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteTravelModeBar(
              selectedTravelMode: RouteTravelMode.shuttle,
              onTravelModeSelected: (_) {},
              modeDurations: {'shuttle': 'No service'},
              isLoadingDurations: false,
              onClose: () {},
              transitDetails: const [],
              modeDistances: {},
              modeArrivalTimes: {},
              onShowSteps: () {},
              onStart: () {},
              isNavigating: false,
              highContrastMode: false,
              shuttleRouteData: outOfServiceRoute,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final busTimeTexts = find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data != null && widget.data!.contains(':'),
      );
      expect(busTimeTexts, findsNWidgets(4));
      for (final element in busTimeTexts.evaluate()) {
        final textWidget = element.widget as Text;
        expect(textWidget.style?.color, Colors.white60);
      }
    });
  });
}
