import 'package:campus_app/services/navigation_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('stripHtml', () {
    test('removes tags, collapses spaces, and decodes entities', () {
      const html =
          '<b>Head</b> north&nbsp;on <div>Main &amp; 1st</div> &quot;Street&quot; &#39;A&#39; &lt;go&gt;';
      final result = stripHtml(html);

      expect(result, 'Head north on Main & 1st "Street" \'A\' <go>');
    });

    test('handles plain text', () {
      expect(stripHtml('Continue straight'), 'Continue straight');
    });
  });

  group('NavigationStep model', () {
    test('startPoint and endPoint are null when points are empty', () {
      const step = NavigationStep(
        instruction: 'Walk forward',
        travelMode: 'walking',
      );

      expect(step.startPoint, isNull);
      expect(step.endPoint, isNull);
    });

    test('startPoint and endPoint return first and last points', () {
      final points = [
        const LatLng(45.0, -73.0),
        const LatLng(45.1, -73.1),
        const LatLng(45.2, -73.2),
      ];

      final step = NavigationStep(
        instruction: 'Drive',
        travelMode: 'driving',
        points: points,
      );

      expect(step.startPoint, points.first);
      expect(step.endPoint, points.last);
    });

    test('secondaryLine joins distance and duration', () {
      const step = NavigationStep(
        instruction: 'Walk',
        travelMode: 'walking',
        distanceText: ' 200 m ',
        durationText: ' 3 min ',
      );

      expect(step.secondaryLine, '200 m • 3 min');
    });

    test('secondaryLine ignores blank values', () {
      const step1 = NavigationStep(
        instruction: 'Walk',
        travelMode: 'walking',
        distanceText: ' 200 m ',
        durationText: '   ',
      );

      const step2 = NavigationStep(
        instruction: 'Walk',
        travelMode: 'walking',
        distanceText: null,
        durationText: ' 5 min ',
      );

      const step3 = NavigationStep(
        instruction: 'Walk',
        travelMode: 'walking',
        distanceText: '   ',
        durationText: '   ',
      );

      expect(step1.secondaryLine, '200 m');
      expect(step2.secondaryLine, '5 min');
      expect(step3.secondaryLine, '');
    });

    test('transitLabel returns Transit when line info is missing', () {
      const step = NavigationStep(
        instruction: 'Board transit',
        travelMode: 'transit',
      );

      expect(step.transitLabel, 'Transit');
    });

    test('transitLabel prefers bus short name', () {
      const step = NavigationStep(
        instruction: 'Board bus',
        travelMode: 'transit',
        transitVehicleType: 'BUS',
        transitLineShortName: '165',
        transitLineName: 'STM 165',
      );

      expect(step.transitLabel, 'Bus 165');
    });

    test('transitLabel treats rail types as Metro', () {
      const step = NavigationStep(
        instruction: 'Board metro',
        travelMode: 'transit',
        transitVehicleType: 'SUBWAY',
        transitLineShortName: 'Orange',
      );

      expect(step.transitLabel, 'Metro Orange');
    });

    test('transitLabel falls back to line name for generic transit', () {
      const step = NavigationStep(
        instruction: 'Board transit',
        travelMode: 'transit',
        transitVehicleType: 'FERRY',
        transitLineName: 'River Shuttle',
      );

      expect(step.transitLabel, 'Transit River Shuttle');
    });

    test('indoor fields are preserved for manual indoor navigation', () {
      const step = NavigationStep(
        instruction: 'Take the elevator',
        travelMode: 'walking',
        indoorFloorAssetPath: 'floor_9',
        indoorFloorLabel: '9',
        indoorTransitionMode: 'elevator',
        points: [LatLng(45.0, -73.0)],
      );

      expect(step.indoorFloorAssetPath, 'floor_9');
      expect(step.indoorFloorLabel, '9');
      expect(step.indoorTransitionMode, 'elevator');
      expect(step.startPoint, const LatLng(45.0, -73.0));
    });
  });

  group('NavigationStepsSheet widgets', () {
    Widget makeApp(Widget child) {
      return MaterialApp(
        home: Scaffold(body: SizedBox.expand(child: child)),
      );
    }

    testWidgets('shows header, subtitle, and empty state', (tester) async {
      await tester.pumpWidget(
        makeApp(
          const NavigationStepsSheet(
            title: 'Walking',
            totalDuration: '12 min',
            totalDistance: '850 m',
            steps: [],
          ),
        ),
      );

      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('12 min • 850 m'), findsOneWidget);
      expect(find.text('No steps available'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders walking and transit steps with expected text', (
      tester,
    ) async {
      final steps = [
        const NavigationStep(
          instruction: 'Turn left onto Main St',
          travelMode: 'walking',
          maneuver: 'turn-left',
          distanceText: '120 m',
          durationText: '2 min',
        ),
        const NavigationStep(
          instruction: 'Board bus',
          travelMode: 'transit',
          transitVehicleType: 'BUS',
          transitLineShortName: '165',
          transitHeadsign: 'Downtown',
          distanceText: '4 stops',
          durationText: '10 min',
        ),
      ];

      await tester.pumpWidget(
        makeApp(
          NavigationStepsSheet(
            title: 'Transit',
            totalDuration: '15 min',
            totalDistance: '2.1 km',
            steps: steps,
          ),
        ),
      );

      expect(find.text('Transit'), findsOneWidget);
      expect(find.text('15 min • 2.1 km'), findsOneWidget);

      expect(find.text('Turn left onto Main St'), findsOneWidget);
      expect(find.text('120 m • 2 min'), findsOneWidget);

      expect(find.text('Bus 165'), findsOneWidget);
      expect(find.text('Downtown'), findsOneWidget);
      expect(find.text('4 stops • 10 min'), findsOneWidget);

      expect(find.byIcon(Icons.turn_left), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    });

    testWidgets('renders maneuver and transport icons for more branches', (
      tester,
    ) async {
      final steps = [
        const NavigationStep(
          instruction: 'Merge onto Highway',
          travelMode: 'driving',
          maneuver: 'merge',
        ),
        const NavigationStep(
          instruction: 'Keep straight',
          travelMode: 'bicycling',
          maneuver: 'straight',
        ),
        const NavigationStep(
          instruction: 'Board metro',
          travelMode: 'transit',
          transitVehicleType: 'SUBWAY',
          transitLineShortName: 'Green',
        ),
        const NavigationStep(
          instruction: 'Unknown mode',
          travelMode: 'hovercraft',
        ),
      ];

      await tester.pumpWidget(
        makeApp(NavigationStepsSheet(title: 'Mixed', steps: steps)),
      );

      expect(find.byIcon(Icons.merge), findsOneWidget);
      expect(find.byIcon(Icons.straight), findsOneWidget);
      expect(find.byIcon(Icons.directions_subway), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('renders indoor transition icons for stairs and elevator', (
      tester,
    ) async {
      final steps = [
        const NavigationStep(
          instruction: 'Take the stairs',
          travelMode: 'walking',
          indoorTransitionMode: 'stairs',
        ),
        const NavigationStep(
          instruction: 'Take the elevator',
          travelMode: 'walking',
          indoorTransitionMode: 'elevator',
        ),
      ];

      await tester.pumpWidget(
        makeApp(NavigationStepsSheet(title: 'Indoor', steps: steps)),
      );

      expect(find.byIcon(Icons.stairs), findsOneWidget);
      expect(find.byIcon(Icons.elevator), findsOneWidget);
    });

    testWidgets(
      'close button dismisses modal opened by showNavigationStepsModal',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showNavigationStepsModal(
                        context,
                        title: 'Walking',
                        totalDuration: '6 min',
                        totalDistance: '400 m',
                        steps: const [
                          NavigationStep(
                            instruction: 'Continue straight',
                            travelMode: 'walking',
                          ),
                        ],
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Walking'), findsOneWidget);
        expect(find.text('Continue straight'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Continue straight'), findsNothing);
      },
    );
  });

  group('NavigationNextStepHeader widgets', () {
    Widget makeHeaderApp({
      required NavigationStep? nextStep,
      required VoidCallback onStop,
      required VoidCallback onShowSteps,
      String? nextDistance,
      String modeLabel = 'Walking',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: NavigationNextStepHeader(
            modeLabel: modeLabel,
            nextStep: nextStep,
            onStop: onStop,
            onShowSteps: onShowSteps,
            nextDistance: nextDistance,
          ),
        ),
      );
    }

    testWidgets('shows fallback text when nextStep is null', (tester) async {
      var stopTapped = false;
      var stepsTapped = false;

      await tester.pumpWidget(
        makeHeaderApp(
          nextStep: null,
          onStop: () => stopTapped = true,
          onShowSteps: () => stepsTapped = true,
          modeLabel: 'Walking',
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);

      await tester.tap(find.text('Steps'));
      await tester.tap(find.text('Stop'));
      await tester.pump();

      expect(stepsTapped, isTrue);
      expect(stopTapped, isTrue);
    });

    testWidgets('shows transit label, headsign, and nextDistance override', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeHeaderApp(
          nextStep: const NavigationStep(
            instruction: 'Board bus',
            travelMode: 'transit',
            transitVehicleType: 'BUS',
            transitLineShortName: '24',
            transitHeadsign: 'Westbound',
            distanceText: '500 m',
          ),
          nextDistance: '250 m',
          onStop: () {},
          onShowSteps: () {},
          modeLabel: 'Transit',
        ),
      );

      expect(find.text('Bus 24'), findsOneWidget);
      expect(find.text('Westbound • 250 m'), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('falls back to step distance when nextDistance is blank', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeHeaderApp(
          nextStep: const NavigationStep(
            instruction: 'Turn right on Pine Ave',
            travelMode: 'driving',
            distanceText: '80 m',
          ),
          nextDistance: '   ',
          onStop: () {},
          onShowSteps: () {},
          modeLabel: 'Driving',
        ),
      );

      expect(find.text('Turn right on Pine Ave'), findsOneWidget);
      expect(find.text('80 m'), findsOneWidget);
    });

    testWidgets('shows indoor floor label and manual previous/next controls', (
      tester,
    ) async {
      var previousTapped = false;
      var nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationNextStepHeader(
              modeLabel: 'Indoor',
              nextStep: const NavigationStep(
                instruction: 'Take the stairs',
                travelMode: 'walking',
                indoorFloorLabel: '9',
                indoorTransitionMode: 'stairs',
                points: [LatLng(45.0, -73.0)],
              ),
              onStop: () {},
              onShowSteps: () {},
              onPrevious: () => previousTapped = true,
              onNext: () => nextTapped = true,
              canGoPrevious: true,
              canGoNext: true,
              progressLabel: '5/11',
            ),
          ),
        ),
      );

      expect(find.text('Floor 9'), findsOneWidget);
      expect(find.text('5/11'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);

      await tester.tap(find.text('Previous'));
      await tester.tap(find.text('Next Step'));
      await tester.pump();

      expect(previousTapped, isTrue);
      expect(nextTapped, isTrue);
    });
  });
}
