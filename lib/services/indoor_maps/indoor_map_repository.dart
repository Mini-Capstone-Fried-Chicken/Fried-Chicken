import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class IndoorMapRepository {
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    debugPrint("Trying to load asset: $assetPath");

    final raw = await rootBundle.loadString(assetPath);

    debugPrint("Loaded ${raw.length} characters");

    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
