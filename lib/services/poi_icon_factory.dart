import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/services/nearby_poi_service.dart';

//Builds the icon for POI with a burgundy circle and white border, and the icon in the center.
class PoiIconFactory {
  PoiIconFactory._();

  //In-memory cache: category → descriptor.
  static final Map<PoiCategory, BitmapDescriptor> _cache = {};

  //Asset paths for each category.
  static const Map<PoiCategory, String> _assetPaths = {
    PoiCategory.cafe: 'assets/images/cafe.png',
    PoiCategory.restaurant: 'assets/images/restaurant.png',
    PoiCategory.pharmacy: 'assets/images/pharmacy.png',
    PoiCategory.depanneur: 'assets/images/depanneur.png',
  };

  //Burgundy background — matches the app's primary colour
  static const Color _bgColor = Color(0xFF76263D);

  //Returns the BitmapDescriptor for category.
  static Future<BitmapDescriptor> iconFor(PoiCategory category) async {
    if (_cache.containsKey(category)) return _cache[category]!;

    final assetPath = _assetPaths[category]!;
    final descriptor = await _buildDescriptor(assetPath);
    _cache[category] = descriptor;
    return descriptor;
  }

  //Pre-warms all icons in parallel.
  static Future<void> preloadAll() async {
    await Future.wait(PoiCategory.values.map(iconFor));
  }

  static Future<BitmapDescriptor> _buildDescriptor(
    String assetPath, {
    double canvasSize = 96,
  }) async {
    // Load the PNG asset into a ui.Image
    final byteData = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: (canvasSize * 0.55).toInt(),
      targetHeight: (canvasSize * 0.55).toInt(),
    );
    final frame = await codec.getNextFrame();
    final assetImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double cx = canvasSize / 2;
    final double cy = canvasSize / 2;
    final double radius = canvasSize / 2 - 4;

    canvas.drawCircle(
      Offset(cx, cy + 3),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );

    //burgundy filled circle
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = _bgColor);

    //white border
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    //PNG asset centred in the circle
    final imgW = assetImage.width.toDouble();
    final imgH = assetImage.height.toDouble();
    final imgLeft = cx - imgW / 2;
    final imgTop = cy - imgH / 2;

    canvas.drawImage(assetImage, Offset(imgLeft, imgTop), Paint());

    //convert to BitmapDescriptor
    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(pngBytes!.buffer.asUint8List());
  }
}
