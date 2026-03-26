import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/google_directions_service.dart';
import 'package:campus_app/services/location/shuttle_route_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_app/services/concordia_shuttle_service.dart';

class MockShuttleDeparture extends Mock implements ShuttleDeparture {}

void main() {
  late DirectionsRouteResult walkToShuttleRoute;
  late DirectionsRouteResult walkFromShuttleRoute;
  late DirectionsRouteResult shuttleDrivingRoute;
  late DirectionsRouteResult directWalkRoute;
  late MockShuttleDeparture mockDeparture;

  setUp(() {
    walkToShuttleRoute = DirectionsRouteResult(
      points: [LatLng(45.497, -73.578)],
      durationText: '3 min',
      durationSeconds: 3 * 60,
    );

    walkFromShuttleRoute = DirectionsRouteResult(
      points: [LatLng(45.458, -73.639)],
      durationText: '2 min',
      durationSeconds: 2 * 60,
    );

    shuttleDrivingRoute = DirectionsRouteResult(
      points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
      durationText: '20 min',
      durationSeconds: 20 * 60,
    );

    directWalkRoute = DirectionsRouteResult(
      points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
      durationText: '25 min',
      durationSeconds: 25 * 60,
    );

    mockDeparture = MockShuttleDeparture();
    when(() => mockDeparture.statusLabel).thenReturn('in 10 min');
  });

  group('ShuttleRouteService', () {
    test('returns null when walking is faster than shuttle', () async {
      final fastWalk = DirectionsRouteResult(
        points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
        durationText: '1 min',
        durationSeconds: 60,
      );

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: walkFromShuttleRoute,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: fastWalk,
        testBuses: [mockDeparture],
        forceInService: true,
      );

      expect(result, isNull);
    });

    test('returns null if shuttle is out of service', () async {
      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: walkFromShuttleRoute,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: directWalkRoute,
        testBuses: [mockDeparture],
        forceInService: false,
      );
      expect(result, isNotNull);
      expect(result!.isInService, isFalse);
      expect(result.totalTripDuration, isNull);
      expect(result.walkingToShuttleMinutes, isNull);
      expect(result.walkingFromShuttleMinutes, isNull);
      expect(result.shuttleDurationLabel, 'No service');
    });

    test('extractWaitMinutesFromStatusLabel parses correctly', () {
      expect(
        ShuttleRouteService.extractWaitMinutesFromStatusLabel('in 5 min'),
        5,
      );
      expect(
        ShuttleRouteService.extractWaitMinutesFromStatusLabel('In 12 min'),
        12,
      );
      expect(
        ShuttleRouteService.extractWaitMinutesFromStatusLabel('departed'),
        0,
      );
    });

    test('extractTimeFromStatusLabel parses "hh:mm am/pm"', () {
      final result = ShuttleRouteService.extractTimeFromStatusLabel('1:05 PM');
      expect(result, '1:05 pm');
    });

    test('extractTimeFromStatusLabel parses "in X min"', () {
      final result = ShuttleRouteService.extractTimeFromStatusLabel(
        'in 10 min',
      );
      expect(result.contains(':'), isTrue);
    });

    test(
      'extractTimeFromStatusLabel returns original string if unrecognized',
      () {
        final unknownLabel = 'departing soon';
        final result = ShuttleRouteService.extractTimeFromStatusLabel(
          unknownLabel,
        );
        expect(result, unknownLabel);
      },
    );

    test('ShuttleDeparture.departureTimeDisplay returns formattedTime', () {
      final now = DateTime(2026, 3, 25, 14, 5);
      final departure = ShuttleDeparture(
        time: now,
        fromStop: 'SGW',
        toStop: 'Loyola',
        walkingTime: Duration(minutes: 3),
      );

      expect(departure.departureTimeDisplay, departure.formattedTime);
      expect(departure.formattedTime, '2:05 PM');
    });
    test('calculates total trip duration correctly', () async {
      final slowerWalk = DirectionsRouteResult(
        points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
        durationText: '35 min',
        durationSeconds: 35 * 60,
      );

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute, // 3 min
        walkFromShuttleRoute: walkFromShuttleRoute, // 2 min
        shuttleDrivingRoute: shuttleDrivingRoute, // 20 min
        directWalkRoute: slowerWalk, // 35 min
        testBuses: [mockDeparture], // 'in 10 min'
        forceInService: true,
      );

      expect(result, isNotNull);
      expect(result!.isInService, isTrue);
      // waitMinutes = (10 - 3).clamp(0, 999) = 7
      // totalTripDuration = 7 + 3 + 18 + 2 = 30 min
      expect(result.totalTripDuration, 30);
      expect(result.walkingToShuttleMinutes, 3);
      expect(result.walkingFromShuttleMinutes, 2);
    });

    test('formats duration label for less than 60 minutes', () async {
      final slowerWalk = DirectionsRouteResult(
        points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
        durationText: '35 min',
        durationSeconds: 35 * 60,
      );
      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: walkFromShuttleRoute,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: slowerWalk,
        testBuses: [mockDeparture], // 'in 10 min'
        forceInService: true,
      );
      expect(result, isNotNull);
      expect(result!.shuttleDurationLabel, '30min');
    });

    test('formats duration label for <60 minutes', () async {
      final longWalkFrom = DirectionsRouteResult(
        points: [LatLng(45.458, -73.639)],
        durationText: '30 min',
        durationSeconds: 30 * 60,
      );

      final slowerWalk = DirectionsRouteResult(
        points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
        durationText: '60 min',
        durationSeconds: 60 * 60,
      );

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: longWalkFrom,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: slowerWalk,
        testBuses: [mockDeparture],
        forceInService: true,
      );
      expect(result, isNotNull);
      expect(result!.shuttleDurationLabel, '58min');
    });

    test('formats duration label with hours when >= 60 minutes', () async {
      final longWalk = DirectionsRouteResult(
        points: [LatLng(45.458, -73.639)],
        durationText: '45 min',
        durationSeconds: 45 * 60,
      );

      final slowerWalk = DirectionsRouteResult(
        points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
        durationText: '80 min',
        durationSeconds: 80 * 60,
      );

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: longWalk,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: slowerWalk,
        testBuses: [mockDeparture],
        forceInService: true,
      );
      expect(result, isNotNull);
      // totalTripDuration = 7 + 3 + 18 + 45 = 73 min = 1h 13m
      expect(result!.shuttleDurationLabel, '1h 13m');
    });

    test('subtracts walking time from bus wait time', () async {
      // bus in 5min, walk for 3min, so wait 2min
      final shortWait = MockShuttleDeparture();
      when(() => shortWait.statusLabel).thenReturn('in 5 min');

      final slowerWalk = DirectionsRouteResult(
        points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
        durationText: '30 min',
        durationSeconds: 30 * 60,
      );

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute, // 3 min walk
        walkFromShuttleRoute: walkFromShuttleRoute, // 2 min
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: slowerWalk,
        testBuses: [shortWait], // 'in 5 min'
        forceInService: true,
      );

      expect(result, isNotNull);
      // waitMinutes = (5 - 3).clamp(0, 999) = 2
      // totalTripDuration = 2 + 3 + 18 + 2 = 25 min
      expect(result!.totalTripDuration, 25);
    });

    test('clamps wait time to minimum 0', () async {
      // Bus arrives in 2 minutes, but we walk for 3 minutes
      // So wait time should be clamped to 0
      final veryShortWait = MockShuttleDeparture();
      when(() => veryShortWait.statusLabel).thenReturn('in 2 min');

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute, // 3 min walk
        walkFromShuttleRoute: walkFromShuttleRoute,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: directWalkRoute,
        testBuses: [veryShortWait], // 'in 2 min'
        forceInService: true,
      );

      expect(result, isNotNull);
      // waitMinutes = (2 - 3).clamp(0, 999) = 0
      // totalTripDuration = 0 + 3 + 18 + 2 = 23 min
      expect(result!.totalTripDuration, 23);
    });

    test('returns null when shuttle is slower than direct walk', () async {
      final veryFastWalk = DirectionsRouteResult(
        points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
        durationText: '15 min',
        durationSeconds: 15 * 60,
      );

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute, // 3 min
        walkFromShuttleRoute: walkFromShuttleRoute, // 2 min
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: veryFastWalk, // 15 min
        testBuses: [mockDeparture], // 'in 10 min'
        forceInService: true,
      );
      expect(result, isNull);
    });

    test(
      'returns null when direct walk duration equals total shuttle trip duration',
      () async {
        final equalWalk = DirectionsRouteResult(
          points: [LatLng(45.497, -73.578), LatLng(45.458, -73.639)],
          durationText: '30 min',
          durationSeconds: 30 * 60,
        );

        final result = await ShuttleRouteService.fetchShuttleRouteData(
          nearestStop: 'SGW',
          stopLatLng: const LatLng(45.497, -73.579),
          walkToShuttleRoute: walkToShuttleRoute,
          walkFromShuttleRoute: walkFromShuttleRoute,
          shuttleDrivingRoute: shuttleDrivingRoute,
          directWalkRoute: equalWalk, // Equal duration
          testBuses: [mockDeparture],
          forceInService: true,
        );
        expect(result, isNull);
      },
    );

    test('does not calculate duration when no buses available', () async {
      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: walkFromShuttleRoute,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: directWalkRoute,
        testBuses: [],
        forceInService: true,
      );
      expect(result, isNotNull);
      expect(result!.isInService, isTrue);
      expect(result.totalTripDuration, isNull);
      expect(result.shuttleDurationLabel, isNotNull);
    });
  });
}
