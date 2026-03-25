// test/services/shuttle_route_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/google_directions_service.dart';
import 'package:campus_app/services/location/shuttle_route_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_app/services/concordia_shuttle_service.dart';

// Mocks
class MockShuttleService extends Mock implements ConcordiaShuttleService {}

class MockShuttleDeparture extends Mock implements ShuttleDeparture {}

void main() {
  late DirectionsRouteResult walkToShuttleRoute;
  late DirectionsRouteResult walkFromShuttleRoute;
  late DirectionsRouteResult shuttleDrivingRoute;
  late DirectionsRouteResult directWalkRoute;

  setUp(() {
    walkToShuttleRoute = DirectionsRouteResult(
      points: [],
      durationText: '3 min',
      durationSeconds: 3 * 60,
    );
    walkFromShuttleRoute = DirectionsRouteResult(
      points: [],
      durationText: '2 min',
      durationSeconds: 2 * 60,
    );
    shuttleDrivingRoute = DirectionsRouteResult(
      points: [],
      durationText: '20 min',
      durationSeconds: 20 * 60,
    );
    directWalkRoute = DirectionsRouteResult(
      points: [],
      durationText: '25 min',
      durationSeconds: 25 * 60,
    );
  });

  group('ShuttleRouteService', () {
    test('returns null when walking is faster than shuttle', () async {
      final fastDirectWalk = DirectionsRouteResult(
        points: [],
        durationText: '1 min',
        durationSeconds: 1 * 60,
      );

      final result = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: 'SGW',
        stopLatLng: const LatLng(45.497, -73.579),
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: walkFromShuttleRoute,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: fastDirectWalk,
      );

      expect(result, isNull);
    });

    test('extractWaitMinutesFromStatusLabel parses minutes correctly', () {
      expect(
        ShuttleRouteService.extractWaitMinutesFromStatusLabel('in 5 min'),
        5,
      );
      expect(
        ShuttleRouteService.extractWaitMinutesFromStatusLabel('in 12 min'),
        12,
      );
      expect(
        ShuttleRouteService.extractWaitMinutesFromStatusLabel('departed'),
        0,
      );
    });

    test('extractTimeFromStatusLabel parses "hh:mm am/pm"', () {
      final time = ShuttleRouteService.extractTimeFromStatusLabel('1:05 PM');
      expect(time, '1:05 pm');
    });

    test('extractTimeFromStatusLabel parses "in X min"', () {
      final time = ShuttleRouteService.extractTimeFromStatusLabel('in 10 min');
      expect(time.contains(':'), isTrue);
    });

    test(
      'fetchShuttleRouteData returns null if shuttle is out of service (no bus in service)',
      () async {
        final result = await ShuttleRouteService.fetchShuttleRouteData(
          nearestStop: 'SGW',
          stopLatLng: const LatLng(45.497, -73.579),
          walkToShuttleRoute: walkToShuttleRoute,
          walkFromShuttleRoute: walkFromShuttleRoute,
          shuttleDrivingRoute: shuttleDrivingRoute,
          directWalkRoute: directWalkRoute,
        );

        // Out-of-service scenario returns null
        expect(result, isNull);
      },
    );
    test('ShuttleDeparture departureTimeDisplay returns formattedTime', () {
      final now = DateTime(2026, 3, 25, 14, 5); // 2:05 PM
      final departure = ShuttleDeparture(
        time: now,
        fromStop: 'SGW',
        toStop: 'Loyola',
        walkingTime: Duration(minutes: 3),
      );

      // Access departureTimeDisplay
      final display = departure.departureTimeDisplay;

      // Should equal the formatted time
      expect(
        display,
        ShuttleDeparture(
          time: now,
          fromStop: 'SGW',
          toStop: 'Loyola',
        ).formattedTime,
      );
    });
  });
}
