import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/geo.dart';

class _ParsedFeature {
  final List<LatLng> points;
  final Map<String, dynamic> properties;

  _ParsedFeature(this.points, this.properties);
}

class IndoorGeoJsonRenderer {
  IndoorGeoJsonRenderer._();
  static final Map<String, BitmapDescriptor> _amenityIconCache =
      <String, BitmapDescriptor>{};

  static Future<Set<Marker>> createAmenityIcons(
    Map<String, dynamic> geojson,
  ) async {
    final featuresRaw = geojson['features'];
    if (featuresRaw is! List) return const <Marker>{};

    final markers = <Marker>{};
    var index = 0;

    for (final f in featuresRaw) {
      if (f is! Map) continue;
      final feature = f.cast<String, dynamic>();
      final geometry = feature['geometry'];
      if (geometry is! Map) continue;
      final geom = geometry.cast<String, dynamic>();
      if (geom['type'] != 'Polygon') continue;

      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      final String? amenity = props['amenity']?.toString();
      final String? highway = props['highway']?.toString();
      final String? escalators = props['escalators']?.toString();

      final bool isAmenity =
          (amenity != null && amenity.isNotEmpty) ||
          (highway == 'elevator') ||
          (highway == 'steps') ||
          (escalators == 'yes');

      if (!isAmenity) continue;

      final coords = geom['coordinates'];
      if (coords is! List || coords.isEmpty) continue;
      final outer = coords.first;
      if (outer is! List) continue;

      final points = <LatLng>[];
      for (final p in outer) {
        if (p is! List || p.length < 2) continue;
        final lng = (p[0] as num).toDouble();
        final lat = (p[1] as num).toDouble();
        points.add(LatLng(lat, lng));
      }
      if (points.length < 3) continue;

      final parsed = _ParsedFeature(points, props);
      final center = polygonCenter(parsed.points);

      final String label = (amenity != null && amenity.isNotEmpty)
          ? amenity
          : (highway != null && highway.isNotEmpty)
          ? highway
          : (escalators == 'yes')
          ? 'escalator'
          : 'amenity';

      final icon = await _amenityIconForLabel(label);

      markers.add(
        Marker(
          markerId: MarkerId('amenity-${index++}-$label'),
          position: center,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndexInt: 25,
          consumeTapEvents: false,
          infoWindow: InfoWindow(title: label),
        ),
      );
    }

    return markers;
  }

  static Future<BitmapDescriptor> _amenityIconForLabel(String label) async {
    final key = label.toLowerCase();
    final cached = _amenityIconCache[key];
    if (cached != null) return cached;

    final (IconData icon, Color bg) = switch (key) {
      'toilets' => (Icons.wc, Colors.blue),
      'elevator' => (Icons.elevator, Colors.orange),
      'steps' => (Icons.stairs, Colors.purple),
      'escalator' => (Icons.escalator, Colors.green),
      _ => (Icons.place, Colors.purple),
    };

    final built = await _createAmenityIconBitmap(icon, backgroundColor: bg);
    _amenityIconCache[key] = built;
    return built;
  }

  static Future<BitmapDescriptor> _createAmenityIconBitmap(
    IconData icon, {
    required Color backgroundColor,
    Color foregroundColor = Colors.white,
    double size = 44,
    double iconSize = 26,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final paint = Paint()..color = backgroundColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: foregroundColor,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    final offset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

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

    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

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
        return LatLng(lat, lng); // GeoJSON is [lng, lat]
      }).toList();

      if (points.length < 3) continue;

      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      final id = (props['ref'] ?? polygons.length).toString();

      // Determine fill color based on feature type
      Color fillColor;
      if (props['escalators'] == 'yes') {
        fillColor = Colors.green;
      } else if (props['highway'] == 'elevator') {
        fillColor = Colors.orange;
      } else if (props['highway'] == 'steps') {
        fillColor = Colors.purple;
      } else if (props['amenity'] == 'toilets') {
        fillColor = Colors.blue;
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
          fillColor: fillColor.withValues(alpha: 1.0),
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

      // Skip very small polygons where text won't fit
      final area = polygonArea(points);
      if (area < 1e-10) continue;

      final center = polygonCenter(points);
      final ref = props['ref'].toString();

      // Choose font size based on polygon area
      final double fontSize = area > 5e-8 ? 10 : 8;
      final icon = await _createTextBitmap(ref, fontSize: fontSize);

      markers.add(
        Marker(
          markerId: MarkerId('room-label-${index++}-$ref'),
          position: center,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndexInt: 30,
          consumeTapEvents: false,
          infoWindow: InfoWindow.noText,
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
}
