import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _ParsedFeature {
  final List<LatLng> points;
  final Map<String, dynamic> properties;

  _ParsedFeature(this.points, this.properties);
}

class IndoorGeoJsonRenderer {
  IndoorGeoJsonRenderer._();

  static ({IconData icon, Color color, String type})? _amenityMetaFromProps(
    Map<String, dynamic> props,
  ) {
    final amenity = props['amenity'];
    final highway = props['highway'];
    final escalators = props['escalators'];

    if (amenity == 'toilets') {
      return (icon: Icons.wc, color: Colors.blue, type: 'toilet');
    }
    if (highway == 'elevator') {
      return (icon: Icons.elevator, color: Colors.orange, type: 'elevator');
    }
    if (escalators == 'yes') {
      return (icon: Icons.escalator, color: Colors.green, type: 'escalator');
    }
    if (highway == 'steps') {
      return (icon: Icons.stairs, color: Colors.purple, type: 'stairs');
    }
    if (amenity == 'drinking_water') {
      return (
        icon: Icons.water_drop,
        color: Colors.cyan,
        type: 'water_fountain',
      );
    }

    return null;
  }

  static Color _getAmenityColor(Map<String, dynamic> props) {
    final amenityMeta = _amenityMetaFromProps(props);
    if (amenityMeta != null) return amenityMeta.color;
    if (props['indoor'] == 'corridor') {
      return const Color.fromARGB(255, 232, 122, 149);
    }
    return const Color(0xFF800020);
  }

  static ({IconData icon, Color color, String type})? _getAmenityIcon(
    Map<String, dynamic> props,
  ) {
    return _amenityMetaFromProps(props);
  }

  static Future<BitmapDescriptor> _bitmapDescriptorFromPicture(
    ui.Picture picture,
    int width,
    int height,
  ) async {
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

  static Iterable<_ParsedFeature> _parsePolygonFeatures(
    Map<String, dynamic> geojson,
  ) sync* {
    final features = (geojson['features'] as List).cast<dynamic>();

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
        return LatLng(lat, lng);
      }).toList();

      if (points.length < 3) continue;

      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      yield _ParsedFeature(points, props);
    }
  }

  static Set<Polygon> geoJsonToPolygons(Map<String, dynamic> geojson) {
    final polygons = <Polygon>{};
    int index = 0;

    for (final parsed in _parsePolygonFeatures(geojson)) {
      final props = parsed.properties;
      final id = (props['ref'] ?? index++).toString();

      final fillColor = _getAmenityColor(props);

      polygons.add(
        Polygon(
          polygonId: PolygonId('indoor-$id'),
          points: parsed.points,
          strokeWidth: 2,
          strokeColor: Colors.black,
          fillColor: fillColor.withOpacity(1.0),
        ),
      );
    }

    return polygons;
  }

  static Future<Set<Marker>> createRoomLabels(
    Map<String, dynamic> geojson,
  ) async {
    final markers = <Marker>{};
    int index = 0;

    for (final parsed in _parsePolygonFeatures(geojson)) {
      final props = parsed.properties;
      if (props['ref'] == null) continue;

      final area = polygonArea(parsed.points);
      if (area < 1e-10) continue;

      final center = polygonCenter(parsed.points);
      final ref = props['ref'].toString();

      final double fontSize = area > 5e-8 ? 10 : 8;
      final icon = await _createTextBitmap(ref, fontSize: fontSize);

      markers.add(
        Marker(
          markerId: MarkerId('room-label-${index++}-$ref'),
          position: center,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          consumeTapEvents: false,
          infoWindow: InfoWindow.noText,
        ),
      );
    }

    return markers;
  }

  static Future<Set<Marker>> createAmenityIcons(
    Map<String, dynamic> geojson, {
    double zoom = 18.0,
  }) async {
    final markers = <Marker>{};
    int index = 0;

    // Calculate icon size based on zoom level
    // Zoom 17 = 20px, Zoom 20 = 35px
    final double iconSize = (15 + (zoom - 17) * 5).clamp(16.0, 40.0);

    for (final parsed in _parsePolygonFeatures(geojson)) {
      final props = parsed.properties;

      final amenityInfo = _getAmenityIcon(props);
      if (amenityInfo == null) continue;

      final center = polygonCenter(parsed.points);
      final icon = await _createIconBitmap(
        amenityInfo.icon,
        amenityInfo.color,
        size: iconSize,
      );

      markers.add(
        Marker(
          markerId: MarkerId('amenity-${amenityInfo.type}-${index++}'),
          position: center,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          consumeTapEvents: false,
          infoWindow: InfoWindow(title: amenityInfo.type.toUpperCase()),
        ),
      );
    }

    return markers;
  }

  static Future<BitmapDescriptor> _createTextBitmap(
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
    return _bitmapDescriptorFromPicture(picture, width, height);
  }

  static Future<BitmapDescriptor> _createIconBitmap(
    IconData iconData,
    Color color, {
    double size = 36,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, circlePaint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 1, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size * 0.6,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    final iconX = (size - textPainter.width) / 2;
    final iconY = (size - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(iconX, iconY));

    final picture = recorder.endRecording();
    final int px = size.toInt();
    return _bitmapDescriptorFromPicture(picture, px, px);
  }

  static double polygonArea(List<LatLng> pts) {
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

  static LatLng polygonCenter(List<LatLng> pts) {
    if (pts.length < 3) return pts.first;

    double lat = 0;
    double lng = 0;
    for (final p in pts) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final avg = LatLng(lat / pts.length, lng / pts.length);

    if (_isPointInPolygon(avg, pts)) return avg;

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
        if (dist > maxDist && _isPointInPolygon(mid, pts)) {
          maxDist = dist;
          best = mid;
        }
      }
    }

    return best;
  }

  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
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
}
