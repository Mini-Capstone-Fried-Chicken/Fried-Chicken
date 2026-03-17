import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_place.dart';

class SavedPlacesController {
  SavedPlacesController._();

  static const String _storageKey = 'saved_places';
  static final ValueNotifier<List<SavedPlace>> notifier = ValueNotifier<List<SavedPlace>>(
    const <SavedPlace>[],
  );

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        notifier.value = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(SavedPlace.fromJson)
            .toList();
      } catch (_) {
        notifier.value = const <SavedPlace>[];
      }
    }
    _initialized = true;
  }

  static Future<void> _persist(List<SavedPlace> places) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(places.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, payload);
  }

  static bool isSaved(String placeId) {
    return notifier.value.any((place) => place.id == placeId);
  }

  static Future<void> savePlace(SavedPlace place) async {
    await ensureInitialized();
    final current = List<SavedPlace>.from(notifier.value);
    final index = current.indexWhere((e) => e.id == place.id);
    if (index >= 0) {
      current[index] = place;
    } else {
      current.add(place);
    }
    notifier.value = current;
    await _persist(current);
  }

  static Future<void> removePlace(String placeId) async {
    await ensureInitialized();
    final current = List<SavedPlace>.from(notifier.value)
      ..removeWhere((e) => e.id == placeId);
    notifier.value = current;
    await _persist(current);
  }

  static Future<bool> togglePlace(SavedPlace place) async {
    await ensureInitialized();
    final exists = isSaved(place.id);
    if (exists) {
      await removePlace(place.id);
      return false;
    }
    await savePlace(place);
    return true;
  }
}
