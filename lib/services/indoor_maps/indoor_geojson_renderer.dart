import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class IndoorGeoJsonRenderer {
  IndoorGeoJsonRenderer._();

  static Set<Polygon> geoJsonToPolygons(Map<String, dynamic> geojson) {
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
        return LatLng(lat, lng);
      }).toList();

      if (points.length < 3) continue;

      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      final id = (props['ref'] ?? polygons.length).toString();

      Color fillColor;
      if (props['escalators'] == 'yes') {
        fillColor = Colors.green;
      } else if (props['highway'] == 'elevator') {
        fillColor = Colors.orange;
      } else if (props['highway'] == 'steps') {
        fillColor = Colors.purple;
      } else if (props['amenity'] == 'toilets') {
        fillColor = Colors.blue;
      } else if (props['amenity'] == 'drinking_water') {
        fillColor = Colors.cyan;
      } else if (props['indoor'] == 'corridor') {
        fillColor = const Color.fromARGB(255, 232, 122, 149);
      } else {
        fillColor = const Color(0xFF800020);
      }

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

  static Future<Set<Marker>> createRoomLabels(
    Map<String, dynamic> geojson,
  ) async {
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

      final area = polygonArea(points);
      if (area < 1e-10) continue;

      final center = polygonCenter(points);
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
          zIndex: 30,
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
    final features = (geojson['features'] as List).cast<dynamic>();
    final markers = <Marker>{};
    int index = 0;

    // Calculate icon size based on zoom level
    // Zoom 17 = 20px, Zoom 20 = 35px
    final double iconSize = (15 + (zoom - 17) * 5).clamp(16.0, 40.0);

    for (final f in features) {
      final feature = f as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

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

      IconData? iconData;
      Color iconColor;
      String markerType;

      if (props['amenity'] == 'toilets') {
        iconData = Icons.wc;
        iconColor = Colors.blue;
        markerType = 'toilet';
      } else if (props['highway'] == 'elevator') {
        iconData = Icons.elevator;
        iconColor = Colors.orange;
        markerType = 'elevator';
      } else if (props['escalators'] == 'yes') {
        iconData = Icons.escalator;
        iconColor = Colors.green;
        markerType = 'escalator';
      } else if (props['highway'] == 'steps') {
        iconData = Icons.stairs;
        iconColor = Colors.purple;
        markerType = 'stairs';
      } else if (props['amenity'] == 'drinking_water') {
        iconData = Icons.water_drop;
        iconColor = Colors.cyan;
        markerType = 'water_fountain';
      } else {
        continue;
      }

      final center = polygonCenter(points);
      final icon = await _createIconBitmap(iconData, iconColor, size: iconSize);

      markers.add(
        Marker(
          markerId: MarkerId('amenity-$markerType-${index++}'),
          position: center,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 40,
          consumeTapEvents: false,
          infoWindow: InfoWindow(title: markerType.toUpperCase()),
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
    ui.Image? img;
    ByteData? byteData;

    try {
      img = await picture.toImage(size.toInt(), size.toInt());
      byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      img?.dispose();
      picture.dispose();
    }

    final Uint8List bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
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
