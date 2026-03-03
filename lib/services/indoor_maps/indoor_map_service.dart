import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'indoor_map_repository.dart';

// ============================================================================
// Constants
// ============================================================================

/// Map of supported building codes → GeoJSON asset paths.
const Map<String, String> indoorMapAssets = {
  'HALL': 'assets/indoor_maps/geojson/Hall/h1.geojson.json',
  'MB': 'assets/indoor_maps/geojson/MB/mb1.geojson.json',
  'VE': 'assets/indoor_maps/geojson/VE/ve1.geojson.json',
  'VL': 'assets/indoor_maps/geojson/VL/vl1.geojson.json',
  'CC': 'assets/indoor_maps/geojson/CC/cc1.geojson.json',
};

/// Google Maps JSON style that hides POIs / transit when the indoor overlay is
/// active.
const String indoorMapStyle = '''
[
  {
    "featureType": "poi",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.school",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "poi.business",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "transit",
    "stylers": [{ "visibility": "off" }]
  }
]
''';

// ============================================================================
// Pure geometry helpers
// ============================================================================

/// Ray-casting algorithm to check if [point] is inside [polygon].
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
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

/// Calculates the approximate area of a polygon in square degrees
/// (Shoelace formula).
double polygonArea(List<LatLng> pts) {
  double area = 0;
  int j = pts.length - 1;
  for (int i = 0; i < pts.length; i++) {
    area +=
        (pts[j].longitude + pts[i].longitude) *
        (pts[j].latitude - pts[i].latitude);
    j = i;
  }
  return area.abs() / 2;
}

/// Returns a representative centre point for [pts].
///
/// Tries the simple average first; if that falls outside the polygon it scans
/// diagonal midpoints to find the best interior candidate.
LatLng polygonCenter(List<LatLng> pts) {
  if (pts.length < 3) return pts.first;

  // First try: simple average
  double lat = 0;
  double lng = 0;
  for (final p in pts) {
    lat += p.latitude;
    lng += p.longitude;
  }
  final avg = LatLng(lat / pts.length, lng / pts.length);

  // Check if the average point is inside the polygon
  if (isPointInPolygon(avg, pts)) return avg;

  // Fallback: try midpoint of the longest diagonal
  double maxDist = 0;
  LatLng best = avg;
  for (int i = 0; i < pts.length; i++) {
    for (int j = i + 1; j < pts.length; j++) {
      final mid = LatLng(
        (pts[i].latitude + pts[j].latitude) / 2,
        (pts[i].longitude + pts[j].longitude) / 2,
      );
      final dist =
          (pts[i].latitude - pts[j].latitude) *
              (pts[i].latitude - pts[j].latitude) +
          (pts[i].longitude - pts[j].longitude) *
              (pts[i].longitude - pts[j].longitude);
      if (dist > maxDist && isPointInPolygon(mid, pts)) {
        maxDist = dist;
        best = mid;
      }
    }
  }

  return best;
}

// ============================================================================
// GeoJSON → Google Maps widget conversion
// ============================================================================

/// Returns the GeoJSON asset path for [buildingCode], or `null` if the
/// building does not have indoor-map support.
String? indoorAssetPath(String buildingCode) {
  return indoorMapAssets[buildingCode.toUpperCase()];
}

/// Determines the fill colour for an indoor GeoJSON feature based on its
/// properties.
Color indoorFillColor(Map<String, dynamic> props) {
  if (props['escalators'] == 'yes') return Colors.green;
  if (props['highway'] == 'elevator') return Colors.orange;
  if (props['highway'] == 'steps') return Colors.pink;
  if (props['amenity'] == 'toilets') return Colors.blue;
  if (props['indoor'] == 'corridor') {
    return const Color.fromARGB(255, 232, 122, 149);
  }
  return const Color(0xFF800020); // Default room = dark red
}

/// Converts a GeoJSON [FeatureCollection] into a set of Google Maps [Polygon]s
/// suitable for rendering as an indoor overlay.
Set<Polygon> geoJsonToPolygons(Map<String, dynamic> geojson) {
  final features = (geojson['features'] as List).cast<dynamic>();
  final polygons = <Polygon>{};

  for (final f in features) {
    final feature = f as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    if (geometry['type'] != 'Polygon') continue;

    final rings = geometry['coordinates'] as List;
    if (rings.isEmpty) continue;

    final outer = rings[0] as List;

    final points = outer.map<LatLng>((p) {
      final coords = p as List;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      return LatLng(lat, lng); // GeoJSON is [lng, lat]
    }).toList();

    if (points.length < 3) continue;

    final props =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final id = (props['ref'] ?? polygons.length).toString();

    final fillColor = indoorFillColor(props);

    polygons.add(
      Polygon(
        polygonId: PolygonId('indoor-$id'),
        points: points,
        strokeWidth: 2,
        strokeColor: Colors.black,
        fillColor: fillColor.withOpacity(1.0),
        zIndex: 20,
      ),
    );
  }

  return polygons;
}

/// Creates a [BitmapDescriptor] containing [text] rendered at [fontSize].
Future<BitmapDescriptor> createTextBitmap(
  String text, {
  double fontSize = 10,
}) async {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  );
  painter.layout();

  final width = painter.width.ceil();
  final height = painter.height.ceil();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );

  painter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  ui.Image? img;
  ByteData? byteData;
  try {
    img = await picture.toImage(width, height);
    byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  } finally {
    img?.dispose();
    picture.dispose();
  }
  final Uint8List bytes = byteData!.buffer.asUint8List();

  return BitmapDescriptor.bytes(bytes);
}

/// Creates text-label [Marker]s at the centre of each room polygon found in
/// [geojson].
Future<Set<Marker>> createRoomLabels(Map<String, dynamic> geojson) async {
  final features = (geojson['features'] as List).cast<dynamic>();
  final markers = <Marker>{};
  int index = 0;

  for (final f in features) {
    final feature = f as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final props =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

    if (geometry['type'] != 'Polygon') continue;
    if (props['ref'] == null) continue;

    final rings = geometry['coordinates'] as List;
    if (rings.isEmpty) continue;
    final outer = rings[0] as List;

    final points = outer.map<LatLng>((p) {
      final coords = p as List;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();

    if (points.length < 3) continue;

    // Skip very small polygons where text won't fit
    final area = polygonArea(points);
    if (area < 1e-10) continue;

    final center = polygonCenter(points);
    final ref = props['ref'].toString();

    // Choose font size based on polygon area
    final double fontSize = area > 5e-8 ? 10 : 8;
    final icon = await createTextBitmap(ref, fontSize: fontSize);

    markers.add(
      Marker(
        markerId: MarkerId('room-label-${index++}-$ref'),
        position: center,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 30,
        consumeTapEvents: false,
        infoWindow: InfoWindow.noText,
      ),
    );
  }

  return markers;
}

// ============================================================================
// High-level helpers (combine repository + conversion)
// ============================================================================

/// Loads the indoor GeoJSON for [buildingCode] and returns the converted
/// polygons and room-label markers.
///
/// Returns `null` if the building is not supported.
Future<IndoorMapData?> loadIndoorMap(String buildingCode) async {
  final path = indoorAssetPath(buildingCode);
  if (path == null) return null;

  final repo = IndoorMapRepository();
  final geo = await repo.loadGeoJsonAsset(path);

  final polys = geoJsonToPolygons(geo);
  final labels = await createRoomLabels(geo);

  return IndoorMapData(geojson: geo, polygons: polys, roomLabels: labels);
}

/// Simple data holder returned by [loadIndoorMap].
class IndoorMapData {
  final Map<String, dynamic> geojson;
  final Set<Polygon> polygons;
  final Set<Marker> roomLabels;

  const IndoorMapData({
    required this.geojson,
    required this.polygons,
    required this.roomLabels,
  });
}
