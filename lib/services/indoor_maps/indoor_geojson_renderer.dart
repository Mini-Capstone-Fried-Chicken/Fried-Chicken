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

class _AmenityMarkerSpec {
  final LatLng center;
  final String label;

  _AmenityMarkerSpec({required this.center, required this.label});
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

    for (final rawFeature in featuresRaw) {
      final amenity = _toAmenityMarkerSpec(rawFeature);
      if (amenity == null) continue;

      final icon = await _amenityIconForLabel(amenity.label);
      markers.add(_buildAmenityMarker(amenity, icon, index));
      index++;
    }

    return markers;
  }

  static _AmenityMarkerSpec? _toAmenityMarkerSpec(dynamic rawFeature) {
    final parsed = _parsePolygonFeature(rawFeature);
    if (parsed == null || !_isAmenityFeature(parsed.properties)) {
      return null;
    }

    return _AmenityMarkerSpec(
      center: polygonCenter(parsed.points),
      label: _amenityLabel(parsed.properties),
    );
  }

  static _ParsedFeature? _parsePolygonFeature(dynamic rawFeature) {
    if (rawFeature is! Map) return null;
    final feature = rawFeature.cast<String, dynamic>();

    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    final geom = geometry.cast<String, dynamic>();
    if (geom['type'] != 'Polygon') return null;

    final props =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final coords = geom['coordinates'];
    if (coords is! List || coords.isEmpty) return null;
    final outer = coords.first;
    if (outer is! List) return null;

    final points = <LatLng>[];
    for (final p in outer) {
      if (p is! List || p.length < 2) continue;
      final lngValue = p[0];
      final latValue = p[1];
      if (lngValue is! num || latValue is! num) continue;

      points.add(LatLng(latValue.toDouble(), lngValue.toDouble()));
    }

    if (points.length < 3) return null;
    return _ParsedFeature(points, props);
  }

  static bool _isAmenityFeature(Map<String, dynamic> properties) {
    final amenity = properties['amenity']?.toString();
    final highway = properties['highway']?.toString();
    final escalators = properties['escalators']?.toString();

    return (amenity != null && amenity.isNotEmpty) ||
        (highway == 'elevator') ||
        (highway == 'steps') ||
        (escalators == 'yes');
  }

  static String _amenityLabel(Map<String, dynamic> properties) {
    final amenity = properties['amenity']?.toString();
    if (amenity != null && amenity.isNotEmpty) return amenity;

    final highway = properties['highway']?.toString();
    if (highway != null && highway.isNotEmpty) return highway;

    final escalators = properties['escalators']?.toString();
    if (escalators == 'yes') return 'escalator';

    return 'amenity';
  }

  static Marker _buildAmenityMarker(
    _AmenityMarkerSpec amenity,
    BitmapDescriptor icon,
    int index,
  ) {
    return Marker(
      markerId: MarkerId('amenity-$index-${amenity.label}'),
      position: amenity.center,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndexInt: 25,
      consumeTapEvents: false,
      infoWindow: InfoWindow(title: amenity.label),
    );
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

    return _bitmapFromRecorder(recorder, size.toInt(), size.toInt());
  }

  static List<LatLng>? _polygonPointsFromGeometry(
    Map<String, dynamic> geometry,
  ) {
    if (geometry['type'] != 'Polygon') return null;

    final rings = geometry['coordinates'];
    if (rings is! List || rings.isEmpty) return null;

    final outer = rings.first;
    if (outer is! List) return null;

    final points = <LatLng>[];
    for (final p in outer) {
      if (p is! List || p.length < 2) continue;
      final lng = p[0];
      final lat = p[1];
      if (lng is! num || lat is! num) continue;
      points.add(LatLng(lat.toDouble(), lng.toDouble()));
    }

    if (points.length < 3) return null;
    return points;
  }

  static Future<BitmapDescriptor> _bitmapFromRecorder(
    ui.PictureRecorder recorder,
    int width,
    int height,
  ) async {
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

    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  static Set<Polygon> geoJsonToPolygons(Map<String, dynamic> geojson) {
    final features = (geojson['features'] as List).cast<dynamic>();
    final polygons = <Polygon>{};

    for (final f in features) {
      final feature = f as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final points = _polygonPointsFromGeometry(geometry);
      if (points == null) continue;

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

      if (props['ref'] == null) continue;

      final points = _polygonPointsFromGeometry(geometry);
      if (points == null) continue;

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

    return _bitmapFromRecorder(recorder, width, height);
  }
}
