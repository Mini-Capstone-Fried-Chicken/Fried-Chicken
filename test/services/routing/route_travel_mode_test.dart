// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/shared/widgets/route_preview_panel.dart';
import 'package:campus_app/services/location/shuttle_route_service.dart';
import 'package:campus_app/services/concordia_shuttle_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  // ---------------------------------------------------------------------------
  // RouteTravelMode enum — apiValue
  // ---------------------------------------------------------------------------
  group('RouteTravelMode.apiValue', () {
    test('driving returns "driving"', () {
      expect(RouteTravelMode.driving.apiValue, equals('driving'));
    });

    test('walking returns "walking"', () {
      expect(RouteTravelMode.walking.apiValue, equals('walking'));
    });

    test('bicycling returns "bicycling"', () {
      expect(RouteTravelMode.bicycling.apiValue, equals('bicycling'));
    });

    test('transit returns "transit"', () {
      expect(RouteTravelMode.transit.apiValue, equals('transit'));
    });

    test('shuttle returns "shuttle"', () {
      expect(RouteTravelMode.shuttle.apiValue, equals('shuttle'));
    });

    test('all modes have distinct apiValues', () {
      final values = RouteTravelMode.values.map((m) => m.apiValue).toList();
      final unique = values.toSet();
      expect(
        unique.length,
        equals(values.length),
        reason: 'Each mode must have a unique apiValue',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // RouteTravelMode enum — label
  // ---------------------------------------------------------------------------
  group('RouteTravelMode.label', () {
    test('driving label is "Driving"', () {
      expect(RouteTravelMode.driving.label, equals('Driving'));
    });

    test('walking label is "Walking"', () {
      expect(RouteTravelMode.walking.label, equals('Walking'));
    });

    test('bicycling label is "Biking"', () {
      expect(RouteTravelMode.bicycling.label, equals('Biking'));
    });

    test('transit label is "Transit"', () {
      expect(RouteTravelMode.transit.label, equals('Transit'));
    });

    test('shuttle label is "Shuttle"', () {
      expect(RouteTravelMode.shuttle.label, equals('Shuttle'));
    });

    test('all modes have non-empty labels', () {
      for (final mode in RouteTravelMode.values) {
        expect(
          mode.label.isNotEmpty,
          isTrue,
          reason: '${mode.name} label must not be empty',
        );
      }
    });

    test('enum contains exactly 5 modes', () {
      expect(RouteTravelMode.values.length, equals(5));
    });
  });

  // ---------------------------------------------------------------------------
  // RouteTravelModeBar widget — shuttle button present
  // ---------------------------------------------------------------------------
  group('RouteTravelModeBar widget — shuttle button', () {
    Widget buildBar({
      RouteTravelMode selected = RouteTravelMode.driving,
      List<String> shuttleNextBuses = const [],
      int? shuttleWalkingMinutes,
      String? shuttleNearestStop,
      ShuttleRouteData? shuttleRouteData,
      VoidCallback? onViewSchedule,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: RouteTravelModeBar(
                selectedTravelMode: selected,
                onTravelModeSelected: (_) {},
                modeDurations: const {
                  'driving': '10 min',
                  'walking': '25 min',
                  'bicycling': '15 min',
                  'transit': '20 min',
                  'shuttle': '20 min',
                },
                isLoadingDurations: false,
                onClose: () {},
                transitDetails: const [],
                modeDistances: const {},
                modeArrivalTimes: const {},
                onShowSteps: () {},
                onStart: () {},
                isNavigating: false,
                shuttleNextBuses: shuttleNextBuses,
                shuttleWalkingToDestinationMinutes: shuttleWalkingMinutes,
                shuttleNearestStop: shuttleNearestStop,
                shuttleRouteData: shuttleRouteData,
                onViewSchedule: onViewSchedule,
              ),
            ),
          ),
        ),
      );
    }

    late ShuttleRouteData mockShuttleRouteData;

    setUp(() {
      final now = DateTime.now();
      mockShuttleRouteData = ShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(0, 0),
        walkToShuttlePoints: [],
        walkFromShuttlePoints: [],
        shuttleRoutePoints: [],
        walkingToShuttleMinutes: 2,
        walkingFromShuttleMinutes: 3,
        shuttleDurationLabel: '20 min',
        totalTripDuration: 20,
        isInService: true,
        buses: [
          ShuttleDeparture(
            time: now.add(Duration(minutes: 10)),
            fromStop: 'SGW',
            toStop: 'Loyola',
          ),
          ShuttleDeparture(
            time: now.add(Duration(minutes: 30)),
            fromStop: 'SGW',
            toStop: 'Loyola',
          ),
        ],
      );
    });

    testWidgets('renders the Shuttle mode button', (tester) async {
      // Mode buttons show the duration label under the icon, not the mode name.
      // The mode name only appears in the header when that mode is selected.
      // Locate the button by its unique icon instead.
      await tester.pumpWidget(buildBar());
      expect(find.byIcon(Icons.directions_bus_filled), findsOneWidget);
    });

    testWidgets('renders all 5 travel mode buttons', (tester) async {
      await tester.pumpWidget(buildBar());
      // When driving is selected its name appears in the header — that is expected.
      // Verify every mode has its icon rendered in the mode row.
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
      expect(find.byIcon(Icons.directions_bike), findsOneWidget);
      expect(find.byIcon(Icons.directions_transit), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus_filled), findsOneWidget);
    });

    testWidgets('tapping Shuttle calls onTravelModeSelected with shuttle', (
      tester,
    ) async {
      RouteTravelMode? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RouteTravelModeBar(
                selectedTravelMode: RouteTravelMode.driving,
                onTravelModeSelected: (m) => selected = m,
                modeDurations: const {},
                isLoadingDurations: false,
                onClose: () {},
                transitDetails: const [],
                modeDistances: const {},
                modeArrivalTimes: const {},
                onShowSteps: () {},
                onStart: () {},
                isNavigating: false,
              ),
            ),
          ),
        ),
      );

      // Tap the shuttle mode button by its unique bus icon
      await tester.tap(find.byIcon(Icons.directions_bus_filled));
      await tester.pump();

      expect(selected, equals(RouteTravelMode.shuttle));
    });

    testWidgets('shows "Schedule" button text when shuttle mode is selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar(selected: RouteTravelMode.shuttle));
      await tester.pump();
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets(
      'shows "Steps" button text when a non-shuttle mode is selected',
      (tester) async {
        await tester.pumpWidget(buildBar(selected: RouteTravelMode.driving));
        await tester.pump();
        expect(find.text('Steps'), findsOneWidget);
      },
    );

    testWidgets('Start button is disabled when shuttle mode is active', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar(selected: RouteTravelMode.shuttle));
      await tester.pump();

      // The "Start" button should exist but its onPressed should be null
      final startButtons = tester.widgetList<TextButton>(
        find.widgetWithText(TextButton, 'Start'),
      );
      expect(startButtons, isNotEmpty);
      final startBtn = startButtons.first;
      expect(
        startBtn.onPressed,
        isNull,
        reason: 'Start should be disabled for shuttle mode',
      );
    });

    testWidgets(
      'Start button is enabled when a regular mode is selected (not navigating)',
      (tester) async {
        bool startCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RouteTravelModeBar(
                  selectedTravelMode: RouteTravelMode.walking,
                  onTravelModeSelected: (_) {},
                  modeDurations: const {'walking': '10 min'},
                  isLoadingDurations: false,
                  onClose: () {},
                  transitDetails: const [],
                  modeDistances: const {},
                  modeArrivalTimes: const {},
                  onShowSteps: () {},
                  onStart: () => startCalled = true,
                  isNavigating: false,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Start'));
        await tester.pump();
        expect(startCalled, isTrue);
      },
    );

    testWidgets('shows walking time notice when shuttleWalkingMinutes is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBar(
          selected: RouteTravelMode.shuttle,
          shuttleRouteData: mockShuttleRouteData,
          shuttleWalkingMinutes: mockShuttleRouteData.walkingToShuttleMinutes,
          shuttleNearestStop: 'SGW',
        ),
      );
      await tester.pump();

      expect(find.textContaining('2 min walk'), findsOneWidget);
    });
    testWidgets(
      'does not show walking time notice when shuttleWalkingMinutes is null',
      (tester) async {
        await tester.pumpWidget(
          buildBar(
            selected: RouteTravelMode.shuttle,
            shuttleNextBuses: ['In 10 min'],
            shuttleWalkingMinutes: null,
          ),
        );
        await tester.pump();

        expect(find.textContaining('walk to'), findsNothing);
      },
    );

    testWidgets(
      'shows "No shuttle service" message when shuttleNextBuses is empty and not loading',
      (tester) async {
        await tester.pumpWidget(
          buildBar(
            selected: RouteTravelMode.shuttle,
            shuttleNextBuses: const [],
          ),
        );
        await tester.pump();
        expect(
          find.textContaining(
            RegExp(r'no shuttle required', caseSensitive: false),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('onViewSchedule is called when "Schedule" is tapped', (
      tester,
    ) async {
      bool scheduleTapped = false;

      await tester.pumpWidget(
        buildBar(
          selected: RouteTravelMode.shuttle,
          shuttleNextBuses: ['In 5 min'],
          shuttleRouteData: mockShuttleRouteData,
          onViewSchedule: () => scheduleTapped = true,
        ),
      );
      await tester.pump();

      // Look for the button by the text that is actually rendered
      final scheduleButton = find.widgetWithText(TextButton, 'Schedule');
      expect(scheduleButton, findsOneWidget);

      await tester.tap(scheduleButton);
      await tester.pump();

      expect(scheduleTapped, isTrue);
    });
    testWidgets(
      'Schedule button triggers onViewSchedule when shuttle mode is active',
      (tester) async {
        bool scheduleTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RouteTravelModeBar(
                  selectedTravelMode: RouteTravelMode.shuttle,
                  onTravelModeSelected: (_) {},
                  modeDurations: const {'shuttle': 'In 8 min'},
                  isLoadingDurations: false,
                  onClose: () {},
                  transitDetails: const [],
                  modeDistances: const {},
                  modeArrivalTimes: const {},
                  onShowSteps: () {},
                  onStart: () {},
                  isNavigating: false,
                  shuttleNextBuses: const ['In 8 min'],
                  onViewSchedule: () => scheduleTapped = true,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Schedule'));
        await tester.pump();

        expect(scheduleTapped, isTrue);
      },
    );

    testWidgets('shows loading text when isLoadingDurations is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RouteTravelModeBar(
                selectedTravelMode: RouteTravelMode.shuttle,
                onTravelModeSelected: (_) {},
                modeDurations: const {},
                isLoadingDurations: true,
                onClose: () {},
                transitDetails: const [],
                modeDistances: const {},
                modeArrivalTimes: const {},
                onShowSteps: () {},
                onStart: () {},
                isNavigating: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading shuttle times…'), findsOneWidget);
    });

    testWidgets('shuttle mode label reads "Shuttle" in the header row', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar(selected: RouteTravelMode.shuttle));
      await tester.pump();

      // The header shows the selected label
      expect(find.text('Shuttle'), findsWidgets);
    });

    testWidgets('walking time includes the nearest stop name', (tester) async {
      await tester.pumpWidget(
        buildBar(
          selected: RouteTravelMode.shuttle,
          shuttleRouteData: mockShuttleRouteData,
          shuttleNextBuses: ['In 2 min'],
        ),
      );
      await tester.pump();
      expect(
        find.textContaining(mockShuttleRouteData.nearestStop),
        findsWidgets,
      );
      expect(
        find.textContaining(
          '${mockShuttleRouteData.walkingToShuttleMinutes} min walk',
        ),
        findsWidgets,
      );
    });

    testWidgets('does not show walking time if shuttle is not in service', (
      tester,
    ) async {
      final outOfServiceData = ShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(0, 0),
        walkToShuttlePoints: [],
        walkFromShuttlePoints: [],
        shuttleRoutePoints: [],
        walkingToShuttleMinutes: 2,
        walkingFromShuttleMinutes: 3,
        shuttleDurationLabel: 'N/A',
        totalTripDuration: null,
        isInService: false,
        buses: [],
      );

      await tester.pumpWidget(
        buildBar(
          selected: RouteTravelMode.shuttle,
          shuttleRouteData: outOfServiceData,
        ),
      );
      await tester.pump();

      expect(find.textContaining('walk to'), findsNothing);
      expect(find.textContaining('walk from'), findsNothing);
    });
  });
}
