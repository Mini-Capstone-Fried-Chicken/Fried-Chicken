import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:campus_app/data/building_polygons.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/shared/widgets/outdoor/outdoor_bottom_bar.dart';
import 'package:campus_app/shared/widgets/outdoor/outdoor_bottom_controls.dart';
import 'package:campus_app/shared/widgets/outdoor/outdoor_building_popup.dart';
import 'package:campus_app/shared/widgets/outdoor/outdoor_top_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  FakeGeolocatorPlatform({
    required Position initialPosition,
    this.locationServiceEnabled = true,
    this.permission = LocationPermission.whileInUse,
  }) : _currentPosition = initialPosition;

  final bool locationServiceEnabled;
  final LocationPermission permission;
  Position _currentPosition;

  @override
  Future<bool> isLocationServiceEnabled() async => locationServiceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return _currentPosition;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return const Stream<Position>.empty();
  }

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _degToRad(endLatitude - startLatitude);
    final dLon = _degToRad(endLongitude - startLongitude);
    final lat1 = _degToRad(startLatitude);
    final lat2 = _degToRad(endLatitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    return _currentPosition;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async {
    return LocationAccuracyStatus.precise;
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() {
    return const Stream<ServiceStatus>.empty();
  }
}

Position makePosition({
  required double latitude,
  required double longitude,
  double accuracy = 5,
  double heading = 0,
}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime(2026, 3, 8, 12),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

Future<void> mockAssetBundle() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WlAbwAAAABJRU5ErkJggg==';
  final Uint8List pngBytes = base64Decode(base64Png);

  final Map<String, Object> manifest = {
    'assets/images/shuttle_icon.png': <Map<String, Object>>[
      <String, Object>{'asset': 'assets/images/shuttle_icon.png'},
    ],
  };

  final ByteData manifestBin = const StandardMessageCodec().encodeMessage(
    manifest,
  )!;

  ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (ByteData? message) async {
      if (message == null) return null;

      final String key = utf8.decode(message.buffer.asUint8List());

      if (key == 'AssetManifest.bin') {
        return manifestBin;
      }

      if (key == 'AssetManifest.json') {
        final bytes = Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
        return ByteData.view(bytes.buffer);
      }

      if (key == 'FontManifest.json') {
        final bytes = Uint8List.fromList(utf8.encode('[]'));
        return ByteData.view(bytes.buffer);
      }

      if (key == 'assets/images/shuttle_icon.png') {
        return ByteData.view(pngBytes.buffer);
      }

      final empty = Uint8List(0);
      return ByteData.view(empty.buffer);
    },
  );
}

Future<void> pumpPage(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
  BuildingPolygon? debugSelectedBuilding,
  Offset? debugAnchorOffset,
  bool debugDisableMap = true,
  bool isLoggedIn = true,
  String? debugLinkOverride,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        debugSelectedBuilding: debugSelectedBuilding,
        debugAnchorOffset: debugAnchorOffset,
        debugDisableMap: debugDisableMap,
        debugLinkOverride: debugLinkOverride,
        isLoggedIn: isLoggedIn,
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await mockAssetBundle();
  });

  setUp(() {
    GeolocatorPlatform.instance = FakeGeolocatorPlatform(
      initialPosition: makePosition(
        latitude: concordiaSGW.latitude,
        longitude: concordiaSGW.longitude,
      ),
    );
  });

  group('detectCampus', () {
    test('returns SGW when point is within SGW campus radius', () {
      final campus = detectCampus(const LatLng(45.4973, -73.5789));
      expect(campus, Campus.sgw);
    });

    test('returns Loyola when point is within Loyola campus radius', () {
      final campus = detectCampus(const LatLng(45.4582, -73.6405));
      expect(campus, Campus.loyola);
    });

    test('returns none when point is outside both campuses', () {
      final campus = detectCampus(const LatLng(45.5200, -73.7000));
      expect(campus, Campus.none);
    });
  });

  group('mergeMapPolylines', () {
    test('merges outdoor and indoor polylines', () {
      final outdoor = {
        const Polyline(
          polylineId: PolylineId('outdoor'),
          points: [LatLng(45.0, -73.0), LatLng(45.1, -73.1)],
        ),
      };

      final indoor = {
        const Polyline(
          polylineId: PolylineId('indoor'),
          points: [LatLng(45.2, -73.2), LatLng(45.3, -73.3)],
        ),
      };

      final merged = mergeMapPolylines(
        outdoorPolylines: outdoor,
        indoorPolylines: indoor,
      );

      expect(merged.length, 2);
      expect(merged.map((p) => p.polylineId.value).toSet(), {
        'outdoor',
        'indoor',
      });
    });

    test('returns only outdoor when indoor is empty', () {
      final outdoor = {
        const Polyline(
          polylineId: PolylineId('outdoor'),
          points: [LatLng(45.0, -73.0), LatLng(45.1, -73.1)],
        ),
      };

      final merged = mergeMapPolylines(
        outdoorPolylines: outdoor,
        indoorPolylines: const {},
      );

      expect(merged.length, 1);
      expect(merged.first.polylineId.value, 'outdoor');
    });

    test('returns only indoor when outdoor is empty', () {
      final indoor = {
        const Polyline(
          polylineId: PolylineId('indoor'),
          points: [LatLng(45.2, -73.2), LatLng(45.3, -73.3)],
        ),
      };

      final merged = mergeMapPolylines(
        outdoorPolylines: const {},
        indoorPolylines: indoor,
      );

      expect(merged.length, 1);
      expect(merged.first.polylineId.value, 'indoor');
    });

    test('returns empty set when both inputs are empty', () {
      final merged = mergeMapPolylines(
        outdoorPolylines: const {},
        indoorPolylines: const {},
      );

      expect(merged, isEmpty);
    });
  });

  group('OutdoorMapPage widget rendering', () {
    testWidgets('renders main idle UI widgets', (tester) async {
      await pumpPage(tester);

      expect(find.byType(OutdoorTopSearch), findsOneWidget);
      expect(find.byType(OutdoorBottomControls), findsOneWidget);
      expect(find.byType(OutdoorBottomBar), findsOneWidget);
      expect(find.byType(OutdoorBuildingPopup), findsNothing);
    });

    testWidgets('renders all building gesture detectors', (tester) async {
      await pumpPage(tester);

      for (final building in buildingPolygons) {
        expect(
          find.byKey(Key('building_detector_${building.code}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('shows popup when debug selected building is in view', (
      tester,
    ) async {
      final building = buildingPolygons.first;

      await pumpPage(
        tester,
        debugSelectedBuilding: building,
        debugAnchorOffset: const Offset(200, 300),
      );

      expect(find.byType(OutdoorBuildingPopup), findsOneWidget);
    });

    testWidgets('does not show popup when debug anchor is outside screen', (
      tester,
    ) async {
      final building = buildingPolygons.first;

      await pumpPage(
        tester,
        debugSelectedBuilding: building,
        debugAnchorOffset: const Offset(-500, -500),
      );

      expect(find.byType(OutdoorBuildingPopup), findsNothing);
    });
  });
}
