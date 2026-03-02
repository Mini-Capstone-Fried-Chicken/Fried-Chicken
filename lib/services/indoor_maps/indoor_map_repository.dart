import 'dart:convert';
import 'package:flutter/services.dart';

class IndoorMapRepository {
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);

    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
