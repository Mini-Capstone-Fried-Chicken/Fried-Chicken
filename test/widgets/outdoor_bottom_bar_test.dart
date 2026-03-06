import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/shared/widgets/campus_toggle.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';
import 'package:campus_app/services/navigation_steps.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart' show RouteTravelMode;
import 'package:campus_app/shared/widgets/outdoor/outdoor_bottom_bar.dart';

void main() {
  group('OutdoorBottomBar', () {
    testWidgets('when showRoutePreview=false shows CampusToggle (not RouteTravelModeBar)',
        (tester) async {
      Campus? changedTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorBottomBar(
                  showRoutePreview: false,
                  isNavigating: false,
                  selectedCampus: Campus.sgw,
                  onCampusChanged: (c) => changedTo = c,

                  selectedTravelMode: RouteTravelMode.driving,
                  onTravelModeSelected: (_) {},
                  routeDurations: const {},
                  routeDistances: const {},
                  routeArrivalTimes: const {},
                  isLoadingRouteData: false,
                  onCloseRoutePreview: () {},
                  onStartNavigation: () {},
                  onShowSteps: () {},
                  transitDetails: const <TransitDetailItem>[],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CampusToggle), findsOneWidget);
      expect(find.byType(RouteTravelModeBar), findsNothing);

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(of: find.byType(CampusToggle), matching: find.byType(SizedBox)),
      );
      expect(sizedBox.width, 280);
      expect(changedTo, isNull);
    });

    testWidgets('when showRoutePreview=true shows RouteTravelModeBar (not CampusToggle)',
        (tester) async {
      var closeCalled = false;
      var startCalled = false;
      var showStepsCalled = false;
      RouteTravelMode? modeSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                OutdoorBottomBar(
                  showRoutePreview: true,
                  isNavigating: false,
                  selectedCampus: Campus.sgw,
                  onCampusChanged: (_) {},

                  selectedTravelMode: RouteTravelMode.walking,
                  onTravelModeSelected: (m) => modeSelected = m,
                  routeDurations: const {
                    'walking': '10 min',
                    'driving': '4 min',
                  },
                  routeDistances: const {
                    'walking': '0.8 km',
                    'driving': '1.2 km',
                  },
                  routeArrivalTimes: const {
                    'walking': '12:10 pm',
                    'driving': '12:04 pm',
                  },
                  isLoadingRouteData: false,
                  onCloseRoutePreview: () => closeCalled = true,
                  onStartNavigation: () => startCalled = true,
                  onShowSteps: () => showStepsCalled = true,
                  transitDetails: const <TransitDetailItem>[],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RouteTravelModeBar), findsOneWidget);
      expect(find.byType(CampusToggle), findsNothing);
      expect(find.byType(PointerInterceptor), findsOneWidget);
      expect(closeCalled, isFalse);
      expect(startCalled, isFalse);
      expect(showStepsCalled, isFalse);
      expect(modeSelected, isNull);
    });
  });
}