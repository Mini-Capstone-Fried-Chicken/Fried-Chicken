// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/services/google_directions_service.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';
import 'package:campus_app/data/building_polygons.dart';         // BuildingPolygon
import 'package:campus_app/shared/widgets/outdoor/outdoor_building_popup.dart'; // OutdoorBuildingPopup

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DirectionsRouteSegment _seg({
  String travelMode = 'TRANSIT',
  String? vehicleType,
  String? shortName,
  String? lineName,
  String? colorHex,
  List<LatLng>? points,
}) {
  return DirectionsRouteSegment(
    travelMode: travelMode,
    transitVehicleType: vehicleType,
    transitLineShortName: shortName,
    transitLineName: lineName,
    transitLineColorHex: colorHex,
    points: points ?? const [LatLng(45.50, -73.60), LatLng(45.51, -73.61)],
  );
}

// ---------------------------------------------------------------------------
// Pure-logic mirrors of private state methods
// ---------------------------------------------------------------------------

Color? _parseHexColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  final normalized = hex.trim().replaceFirst('#', '');
  if (normalized.length != 6) return null;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

Color _resolveTransitSegmentColor(DirectionsRouteSegment seg) {
  const defaultRed = Color(0xFF76263D);
  if (seg.travelMode.toUpperCase() == 'WALKING') return defaultRed;
  if (seg.transitVehicleType?.toUpperCase() == 'BUS') return Colors.blue;
  final lineColor = _parseHexColor(seg.transitLineColorHex);
  return lineColor ?? defaultRed;
}

String _formatTransitSegmentTitle(DirectionsRouteSegment seg) {
  final vehicleType = seg.transitVehicleType?.toUpperCase();
  final label = seg.transitLineShortName ?? seg.transitLineName ?? 'Route';
  if (vehicleType == 'BUS') return 'Bus $label';
  if ({'SUBWAY', 'METRO_RAIL', 'HEAVY_RAIL', 'COMMUTER_TRAIN', 'RAIL',
      'TRAM', 'LIGHT_RAIL', 'MONORAIL'}.contains(vehicleType)) {
    return 'Metro $label';
  }
  return 'Transit $label';
}

String? _formatArrivalTime(int? durationSeconds) {
  if (durationSeconds == null) return null;
  final arrival = DateTime.now().add(Duration(seconds: durationSeconds));
  int hour = arrival.hour;
  final minute = arrival.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'pm' : 'am';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '$hour:$minute $period';
}

bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
  bool inside = false;
  int j = polygon.length - 1;
  for (int i = 0; i < polygon.length; i++) {
    final xi = polygon[i].latitude;
    final yi = polygon[i].longitude;
    final xj = polygon[j].latitude;
    final yj = polygon[j].longitude;
    if (((yi > point.longitude) != (yj > point.longitude)) &&
        (point.latitude <
            (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

List<TransitDetailItem> _buildTransitDetailItems(
    List<DirectionsRouteSegment> segs) {
  final items = <TransitDetailItem>[];
  for (final seg in segs) {
    if (seg.points.isEmpty) continue;
    if (seg.travelMode.toUpperCase() == 'WALKING') continue;
    final vehicleType = seg.transitVehicleType?.toUpperCase();
    final label = seg.transitLineShortName ?? seg.transitLineName ?? 'Route';
    const defaultRed = Color(0xFF76263D);
    IconData icon = Icons.directions_transit;
    String title = 'Transit $label';
    Color color = defaultRed;
    if (vehicleType == 'BUS') {
      icon = Icons.directions_bus;
      title = 'Bus $label';
      color = Colors.blue;
    } else if ({'SUBWAY', 'METRO_RAIL', 'HEAVY_RAIL', 'COMMUTER_TRAIN',
        'RAIL', 'TRAM', 'LIGHT_RAIL', 'MONORAIL'}.contains(vehicleType)) {
      icon = Icons.directions_subway;
      title = 'Metro $label';
    }
    items.add(TransitDetailItem(icon: icon, color: color, title: title));
  }
  return items;
}

Offset? _computePopupPosition({
  required Size screen,
  required double topPad,
  required Offset anchor,
  bool cameraMoving = false,
  double popupW = 300,
  double popupH = 260,
  double margin = 8,
}) {
  if (cameraMoving) return null;
  if (anchor.dx < 0 || anchor.dx > screen.width ||
      anchor.dy < topPad || anchor.dy > screen.height) return null;
  double left = anchor.dx - (popupW / 2);
  double top = anchor.dy - (popupH / 2);
  if (left < margin) left = margin;
  if (left > screen.width - popupW - margin) left = screen.width - popupW - margin;
  if (top < topPad + margin) top = topPad + margin;
  if (top > screen.height - popupH - margin) top = screen.height - popupH - margin;
  return Offset(left, top);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // detectCampus
  // =========================================================================
  group('detectCampus', () {
    test('returns Campus.sgw when at SGW centre', () {
      expect(detectCampus(const LatLng(45.4973, -73.5789)), Campus.sgw);
    });

    test('returns Campus.loyola when at Loyola centre', () {
      expect(detectCampus(const LatLng(45.4582, -73.6405)), Campus.loyola);
    });

    test('returns Campus.none for a location far from both campuses', () {
      expect(detectCampus(const LatLng(45.474, -73.579)), Campus.none);
    });

    test('returns Campus.sgw for a point ~10m north of SGW', () {
      expect(detectCampus(const LatLng(45.4974, -73.5789)), Campus.sgw);
    });

    test('returns Campus.loyola for a point ~10m north of Loyola', () {
      expect(detectCampus(const LatLng(45.4583, -73.6405)), Campus.loyola);
    });

    test('returns Campus.none when >500m from both campuses', () {
      expect(detectCampus(const LatLng(45.506, -73.579)), Campus.none);
    });
  });

  // =========================================================================
  // parseHexColor
  // =========================================================================
  group('parseHexColor', () {
    test('returns null for null input', () {
      expect(_parseHexColor(null), isNull);
    });

    test('returns null for empty string', () {
      expect(_parseHexColor(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(_parseHexColor('   '), isNull);
    });

    test('parses 6-digit hex without # prefix', () {
      expect(_parseHexColor('FF0000'), const Color(0xFFFF0000));
    });

    test('parses 6-digit hex with # prefix', () {
      expect(_parseHexColor('#0000FF'), const Color(0xFF0000FF));
    });

    test('parses white', () {
      expect(_parseHexColor('#FFFFFF'), const Color(0xFFFFFFFF));
    });

    test('parses black', () {
      expect(_parseHexColor('#000000'), const Color(0xFF000000));
    });

    test('parses lowercase hex', () {
      expect(_parseHexColor('#ff8800'), const Color(0xFFFF8800));
    });

    test('returns null for 3-digit hex', () {
      expect(_parseHexColor('#FFF'), isNull);
    });

    test('returns null for 8-digit hex', () {
      expect(_parseHexColor('#FF000000'), isNull);
    });

    test('returns null for non-hex characters', () {
      expect(_parseHexColor('#GGGGGG'), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(_parseHexColor('  #00FF00  '), const Color(0xFF00FF00));
    });

    test('parses burgundy app colour', () {
      expect(_parseHexColor('#76263D'), const Color(0xFF76263D));
    });
  });

  // =========================================================================
  // resolveTransitSegmentColor
  // =========================================================================
  group('resolveTransitSegmentColor', () {
    const defaultRed = Color(0xFF76263D);

    test('returns defaultRed for WALKING (lowercase)', () {
      expect(_resolveTransitSegmentColor(_seg(travelMode: 'walking')), defaultRed);
    });

    test('returns defaultRed for WALKING (uppercase)', () {
      expect(_resolveTransitSegmentColor(_seg(travelMode: 'WALKING')), defaultRed);
    });

    test('returns Colors.blue for BUS', () {
      expect(_resolveTransitSegmentColor(_seg(vehicleType: 'BUS')), Colors.blue);
    });

    test('returns parsed colorHex for non-bus transit', () {
      expect(
        _resolveTransitSegmentColor(_seg(vehicleType: 'SUBWAY', colorHex: '#00AA55')),
        const Color(0xFF00AA55),
      );
    });

    test('returns defaultRed when colorHex is null for SUBWAY', () {
      expect(_resolveTransitSegmentColor(_seg(vehicleType: 'SUBWAY')), defaultRed);
    });

    test('returns defaultRed when colorHex is empty string', () {
      expect(_resolveTransitSegmentColor(_seg(colorHex: '')), defaultRed);
    });

    test('BUS takes priority over colorHex', () {
      expect(
        _resolveTransitSegmentColor(_seg(vehicleType: 'BUS', colorHex: '#FF0000')),
        Colors.blue,
      );
    });
  });

  // =========================================================================
  // formatTransitSegmentTitle
  // =========================================================================
  group('formatTransitSegmentTitle', () {
    test('"Bus X" for BUS with shortName', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'BUS', shortName: '24')), 'Bus 24');
    });

    test('falls back to lineName when shortName is null', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'BUS', lineName: 'Cote')), 'Bus Cote');
    });

    test('falls back to "Route" when both names are null', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'BUS')), 'Bus Route');
    });

    test('"Metro X" for SUBWAY', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'SUBWAY', shortName: 'Orange')), 'Metro Orange');
    });

    test('"Metro X" for METRO_RAIL', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'METRO_RAIL', shortName: 'Green')), 'Metro Green');
    });

    test('"Metro X" for TRAM', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'TRAM', shortName: 'T1')), 'Metro T1');
    });

    test('"Metro X" for LIGHT_RAIL', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'LIGHT_RAIL', shortName: 'REM')), 'Metro REM');
    });

    test('"Metro X" for HEAVY_RAIL', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'HEAVY_RAIL', shortName: 'VIA')), 'Metro VIA');
    });

    test('"Metro X" for COMMUTER_TRAIN', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'COMMUTER_TRAIN', shortName: 'EXO')), 'Metro EXO');
    });

    test('"Metro X" for MONORAIL', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'MONORAIL', shortName: 'M1')), 'Metro M1');
    });

    test('"Transit X" for unknown vehicle type', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: 'FERRY', shortName: 'F1')), 'Transit F1');
    });

    test('"Transit X" for null vehicle type', () {
      expect(_formatTransitSegmentTitle(_seg(vehicleType: null, shortName: 'X')), 'Transit X');
    });

    test('shortName takes priority over lineName', () {
      expect(
        _formatTransitSegmentTitle(_seg(vehicleType: 'BUS', shortName: '24', lineName: 'Long Name')),
        'Bus 24',
      );
    });
  });

  // =========================================================================
  // formatArrivalTime
  // =========================================================================
  group('formatArrivalTime', () {
    test('returns null for null input', () {
      expect(_formatArrivalTime(null), isNull);
    });

    test('returns non-null string for 0 seconds', () {
      expect(_formatArrivalTime(0), isNotNull);
    });

    test('matches H:MM am/pm pattern for 1 hour', () {
      expect(_formatArrivalTime(3600), matches(RegExp(r'^\d{1,2}:\d{2} [ap]m$')));
    });

    test('matches H:MM am/pm pattern for 2 hours', () {
      expect(_formatArrivalTime(7200), matches(RegExp(r'^\d{1,2}:\d{2} [ap]m$')));
    });

    test('ends in "am" or "pm"', () {
      final result = _formatArrivalTime(1800)!;
      expect(result.endsWith('am') || result.endsWith('pm'), isTrue);
    });

    test('minutes are zero-padded to 2 digits', () {
      final result = _formatArrivalTime(3600)!;
      final minutePart = result.split(':')[1].split(' ')[0];
      expect(minutePart.length, 2);
    });

    test('handles large duration (24 hours)', () {
      final result = _formatArrivalTime(86400);
      expect(result, isNotNull);
      expect(result, matches(RegExp(r'^\d{1,2}:\d{2} [ap]m$')));
    });
  });

  // =========================================================================
  // isPointInPolygon
  // =========================================================================
  group('isPointInPolygon', () {
    final square = [
      const LatLng(0, 0),
      const LatLng(0, 1),
      const LatLng(1, 1),
      const LatLng(1, 0),
    ];

    test('returns true for centre of unit square', () {
      expect(_isPointInPolygon(const LatLng(0.5, 0.5), square), isTrue);
    });

    test('returns false for point outside upper-right', () {
      expect(_isPointInPolygon(const LatLng(2.0, 2.0), square), isFalse);
    });

    test('returns false for point outside lower-left', () {
      expect(_isPointInPolygon(const LatLng(-1.0, -1.0), square), isFalse);
    });

    test('returns true for point near left edge (inside)', () {
      expect(_isPointInPolygon(const LatLng(0.1, 0.5), square), isTrue);
    });

    test('triangle: point inside', () {
      final tri = [
        const LatLng(0, 0),
        const LatLng(0, 4),
        const LatLng(4, 2),
      ];
      expect(_isPointInPolygon(const LatLng(1, 2), tri), isTrue);
    });

    test('triangle: point outside', () {
      final tri = [
        const LatLng(0, 0),
        const LatLng(0, 4),
        const LatLng(4, 2),
      ];
      expect(_isPointInPolygon(const LatLng(5, 5), tri), isFalse);
    });

    test('works with a realistic SGW building footprint', () {
      final hall = [
        const LatLng(45.4968, -73.5793),
        const LatLng(45.4968, -73.5779),
        const LatLng(45.4978, -73.5779),
        const LatLng(45.4978, -73.5793),
      ];
      expect(_isPointInPolygon(const LatLng(45.4973, -73.5786), hall), isTrue);
      expect(_isPointInPolygon(const LatLng(45.500, -73.578), hall), isFalse);
    });
  });

  // =========================================================================
  // computePopupPosition
  // =========================================================================
  group('computePopupPosition', () {
    const screen = Size(390, 844);
    const topPad = 44.0;

    test('returns null when cameraMoving', () {
      expect(
        _computePopupPosition(
            screen: screen, topPad: topPad,
            anchor: const Offset(195, 422), cameraMoving: true),
        isNull,
      );
    });

    test('returns null when anchor x is negative', () {
      expect(
        _computePopupPosition(screen: screen, topPad: topPad,
            anchor: const Offset(-5, 400)),
        isNull,
      );
    });

    test('returns null when anchor x exceeds screen width', () {
      expect(
        _computePopupPosition(screen: screen, topPad: topPad,
            anchor: const Offset(400, 400)),
        isNull,
      );
    });

    test('returns null when anchor y is above topPad', () {
      expect(
        _computePopupPosition(screen: screen, topPad: topPad,
            anchor: const Offset(195, 10)),
        isNull,
      );
    });

    test('returns Offset for valid centred anchor', () {
      expect(
        _computePopupPosition(screen: screen, topPad: topPad,
            anchor: const Offset(195, 422)),
        isNotNull,
      );
    });

    test('popup left is never below margin', () {
      final pos = _computePopupPosition(screen: screen, topPad: topPad,
          anchor: const Offset(5, 422));
      expect(pos!.dx, greaterThanOrEqualTo(8.0));
    });

    test('popup left never overflows right edge', () {
      final pos = _computePopupPosition(screen: screen, topPad: topPad,
          anchor: const Offset(385, 422));
      expect(pos!.dx, lessThanOrEqualTo(screen.width - 300 - 8));
    });

    test('popup top is never above topPad + margin', () {
      final pos = _computePopupPosition(screen: screen, topPad: topPad,
          anchor: const Offset(195, 50));
      expect(pos!.dy, greaterThanOrEqualTo(topPad + 8));
    });

    test('popup never overflows bottom of screen', () {
      final pos = _computePopupPosition(screen: screen, topPad: topPad,
          anchor: const Offset(195, 840));
      expect(pos!.dy, lessThanOrEqualTo(screen.height - 260 - 8));
    });

    test('centred anchor produces expected left position', () {
      // anchor.dx=195, popupW=300 → left = 195 - 150 = 45
      final pos = _computePopupPosition(
          screen: screen, topPad: 0, anchor: const Offset(195, 422));
      expect(pos!.dx, closeTo(45.0, 1.0));
    });
  });

  // =========================================================================
  // buildTransitDetailItems
  // =========================================================================
  group('buildTransitDetailItems', () {
    test('empty list when all segments are WALKING', () {
      expect(_buildTransitDetailItems([
        _seg(travelMode: 'WALKING'),
        _seg(travelMode: 'walking'),
      ]), isEmpty);
    });

    test('skips segments with empty points', () {
      expect(_buildTransitDetailItems([_seg(vehicleType: 'BUS', points: [])]), isEmpty);
    });

    test('one item for one non-walking segment', () {
      expect(_buildTransitDetailItems([_seg(vehicleType: 'BUS', shortName: '24')]).length, 1);
    });

    test('correct count for mixed segments', () {
      expect(_buildTransitDetailItems([
        _seg(travelMode: 'WALKING'),
        _seg(vehicleType: 'BUS', shortName: '24'),
        _seg(vehicleType: 'SUBWAY', shortName: 'Orange'),
      ]).length, 2);
    });

    test('BUS: correct icon, colour, title', () {
      final item = _buildTransitDetailItems([_seg(vehicleType: 'BUS', shortName: '105')]).first;
      expect(item.icon, Icons.directions_bus);
      expect(item.color, Colors.blue);
      expect(item.title, 'Bus 105');
    });

    test('SUBWAY: correct icon and title', () {
      final item = _buildTransitDetailItems([_seg(vehicleType: 'SUBWAY', shortName: 'Green')]).first;
      expect(item.icon, Icons.directions_subway);
      expect(item.title, 'Metro Green');
    });

    test('unknown vehicle: transit icon', () {
      final item = _buildTransitDetailItems([_seg(vehicleType: 'FERRY', shortName: 'F1')]).first;
      expect(item.icon, Icons.directions_transit);
      expect(item.title, 'Transit F1');
    });

    test('multiple bus segments all get bus icon', () {
      final items = _buildTransitDetailItems([
        _seg(vehicleType: 'BUS', shortName: '24'),
        _seg(vehicleType: 'BUS', shortName: '80'),
      ]);
      expect(items.every((i) => i.icon == Icons.directions_bus), isTrue);
    });
  });

  // =========================================================================
  // OutdoorMapPage widget smoke tests
  // =========================================================================
  group('OutdoorMapPage', () {
    testWidgets('renders for SGW campus, not logged in', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: false,
          debugDisableMap: true,
          debugDisableLocation: true,
        ),
      ));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('renders for Loyola campus, logged in', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.loyola,
          isLoggedIn: true,
          debugDisableMap: true,
          debugDisableLocation: true,
        ),
      ));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('renders for Campus.none without error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.none,
          isLoggedIn: false,
          debugDisableMap: true,
          debugDisableLocation: true,
        ),
      ));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });

    testWidgets('no building popup when no building is selected', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: false,
          debugDisableMap: true,
          debugDisableLocation: true,
        ),
      ));
      await tester.pump();
      expect(find.byType(OutdoorBuildingPopup), findsNothing);
    });

    testWidgets('shows building popup when debugSelectedBuilding is set',
        (tester) async {
      final building = BuildingPolygon(
        code: 'HALL',
        name: 'Hall Building',
        points: const [
          LatLng(45.4968, -73.5793),
          LatLng(45.4968, -73.5779),
          LatLng(45.4978, -73.5779),
          LatLng(45.4978, -73.5793),
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: false,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugSelectedBuilding: building,
          debugAnchorOffset: const Offset(195, 422),
        ),
      ));
      await tester.pump();
      expect(find.byType(OutdoorBuildingPopup), findsOneWidget);
    });

    testWidgets('accepts debugLinkOverride without error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: OutdoorMapPage(
          initialCampus: Campus.sgw,
          isLoggedIn: false,
          debugDisableMap: true,
          debugDisableLocation: true,
          debugLinkOverride: 'https://concordia.ca',
        ),
      ));
      expect(find.byType(OutdoorMapPage), findsOneWidget);
    });
  });
}