import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class FakeGeolocator extends GeolocatorPlatform {
  bool _isLocationServiceEnabled = true;
  LocationPermission _permissionStatus = LocationPermission.always;
  LocationPermission _requestedPermission = LocationPermission.always;
  Position? _currentPosition;
  final StreamController<Position> _positionStreamController = 
      StreamController<Position>.broadcast();

  void setLocationServiceEnabled(bool enabled) {
    _isLocationServiceEnabled = enabled;
  }

  void setPermissionStatus(LocationPermission permission) {
    _permissionStatus = permission;
    _requestedPermission = permission;
  }

  void setCurrentPosition(Position position) {
    _currentPosition = position;
  }

  StreamController<Position> get positionController => _positionStreamController;

  @override
  Future<bool> isLocationServiceEnabled() async => _isLocationServiceEnabled;
  
  @override
  Future<LocationPermission> checkPermission() async => _permissionStatus;
  
  @override
  Future<LocationPermission> requestPermission() async => _requestedPermission;
  
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => _currentPosition ?? _createPosition(45.4973, -73.5789);
  
  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) => _positionStreamController.stream;

  Future<void> dispose() async {
    await _positionStreamController.close();
  }
}

//creating fake position objects to test live location tracking
Position _createPosition(double lat, double lng) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  //ensure the campus are being generated and they're detected
  group('Campus Detection Tests', () {
    test('Detect SGW campus at center', () {
      final result = detectCampus(const LatLng(45.4973, -73.5789));
      expect(result, Campus.sgw);
    });

    test('Detect SGW campus at boundary', () {
      final result = detectCampus(const LatLng(45.497, -73.578));
      expect(result, isIn([Campus.sgw, Campus.none]));
    });

    test('Detect Loyola campus at center', () {
      final result = detectCampus(const LatLng(45.4582, -73.6405));
      expect(result, Campus.loyola);
    });

    test('Detect Loyola campus at boundary', () {
      final result = detectCampus(const LatLng(45.458, -73.640));
      expect(result, isIn([Campus.loyola, Campus.none]));
    });

    test('Detect Off Campus - far away', () {
      final result = detectCampus(const LatLng(40.0, -70.0));
      expect(result, Campus.none);
    });

    test('Detect Off Campus - between campuses', () {
      final result = detectCampus(const LatLng(45.48, -73.60));
      expect(result, Campus.none);
    });
  });

  group('Live Location Tracking Tests', () {
    late FakeGeolocator fakeGeolocator;

    setUp(() {
      fakeGeolocator = FakeGeolocator();
      GeolocatorPlatform.instance = fakeGeolocator;
    });

    tearDown(() async {
      await fakeGeolocator.dispose();
    });

    testWidgets('Initial location loads correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('Location stream updates continuously', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();

      //move to loyola campus
      fakeGeolocator.positionController.add(_createPosition(45.4582, -73.6405));
      await tester.pump(const Duration(milliseconds: 100));

      //move around loyola campus
      fakeGeolocator.positionController.add(_createPosition(45.4583, -73.6406));
      await tester.pump(const Duration(milliseconds: 100));

      //move off-campus
      fakeGeolocator.positionController.add(_createPosition(45.48, -73.60));
      await tester.pump(const Duration(milliseconds: 100));

      //ensure widgets are there while continuously updating location
      expect(find.byType(OutdoorMapPage), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
    });
    //testing campus location changed and detected and displayed
    testWidgets('Location updates trigger campus change detection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();

      //moving from sgw to loyola
      fakeGeolocator.positionController.add(_createPosition(45.4582, -73.6405));
      await tester.pump(const Duration(milliseconds: 100));

      //moving from loyola to off-campus
      fakeGeolocator.positionController.add(_createPosition(40.0, -70.0));
      await tester.pump(const Duration(milliseconds: 100));

      // move from off-campus to sgw
      fakeGeolocator.positionController.add(_createPosition(45.4973, -73.5789));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('Rapid location updates handled gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();

      //replicating gps updates
      for (int i = 0; i < 10; i++) {
        fakeGeolocator.positionController.add(_createPosition(
          45.4582 + (i * 0.0001),
          -73.6405 + (i * 0.0001),
        ));
      }

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    test('Position stream provides accurate location data', () async {
      final positions = <Position>[];
      
      final subscription = fakeGeolocator.positionController.stream.listen((position) {
        positions.add(position);
      });

      //post fake test positions
      fakeGeolocator.positionController.add(_createPosition(45.4973, -73.5789));
      fakeGeolocator.positionController.add(_createPosition(45.4582, -73.6405));
      
      await Future.delayed(const Duration(milliseconds: 100));

      expect(positions.length, 2);
      expect(positions[0].latitude, 45.4973);
      expect(positions[0].longitude, -73.5789);
      expect(positions[1].latitude, 45.4582);
      expect(positions[1].longitude, -73.6405);

      await subscription.cancel();
    });
  });
  //location permission is properly accessed
  group('Location Permission Tests', () {
    testWidgets('Handles denied location permission', (tester) async {
      final fakeGeolocator = FakeGeolocator();
      GeolocatorPlatform.instance = fakeGeolocator;
      
      fakeGeolocator.setPermissionStatus(LocationPermission.denied);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
      
      await fakeGeolocator.dispose();
    });
    //when no location permission is given
    testWidgets('Handles location service disabled', (tester) async {
      final fakeGeolocator = FakeGeolocator();
      GeolocatorPlatform.instance = fakeGeolocator;
      
      fakeGeolocator.setLocationServiceEnabled(false);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
      
      await fakeGeolocator.dispose();
    });

    testWidgets('Handles permission granted after initial denial', (tester) async {
      final fakeGeolocator = FakeGeolocator();
      GeolocatorPlatform.instance = fakeGeolocator;
      
      fakeGeolocator.setPermissionStatus(LocationPermission.denied);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      //location permission and location enabled and displayed
      fakeGeolocator.setPermissionStatus(LocationPermission.always);
      fakeGeolocator.positionController.add(_createPosition(45.4973, -73.5789));

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
      
      await fakeGeolocator.dispose();
    });
  });

  group('Edge Cases and Error Handling', () {
    testWidgets('Handles null or invalid position data', (tester) async {
      final fakeGeolocator = FakeGeolocator();
      GeolocatorPlatform.instance = fakeGeolocator;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();

      //a random coordinate 
      fakeGeolocator.positionController.add(_createPosition(0, 0));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
      
      await fakeGeolocator.dispose();
    });

    testWidgets('Handles location accuracy variations', (tester) async {
      final fakeGeolocator = FakeGeolocator();
      GeolocatorPlatform.instance = fakeGeolocator;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutdoorMapPage(initialCampus: Campus.sgw),
          ),
        ),
      );

      await tester.pump();

      // Add positions with varying accuracy
      fakeGeolocator.positionController.add(Position(
        latitude: 45.4973,
        longitude: -73.5789,
        timestamp: DateTime.now(),
        accuracy: 50.0, // Poor accuracy
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ));

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OutdoorMapPage), findsOneWidget);
      
      await fakeGeolocator.dispose();
    });
  });
}