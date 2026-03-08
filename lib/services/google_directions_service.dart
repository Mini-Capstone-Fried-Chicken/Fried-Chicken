import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/navigation_steps.dart';

class DirectionsRouteResult {
  final List<LatLng> points;
  final String? durationText;
  final String? distanceText;
  final int? durationSeconds;
  final String? transitVehicleType;
  final String? transitLineColorHex;
  final bool transitHasBus;
  final List<DirectionsRouteSegment> transitSegments;
  final List<NavigationStep> steps;

  const DirectionsRouteResult({
    required this.points,
    required this.durationText,
    this.distanceText,
    this.durationSeconds,
    this.transitVehicleType,
    this.transitLineColorHex,
    this.transitHasBus = false,
    this.transitSegments = const [],
    this.steps = const [],
  });
}

class DirectionsRouteSegment {
  final List<LatLng> points;
  final String travelMode;
  final String? durationText;
  final String? distanceText;
  final String? transitVehicleType;
  final String? transitLineColorHex;
  final String? transitLineShortName;
  final String? transitLineName;
  final String? transitHeadsign;

  const DirectionsRouteSegment({
    required this.points,
    required this.travelMode,
    this.durationText,
    this.distanceText,
    this.transitVehicleType,
    this.transitLineColorHex,
    this.transitLineShortName,
    this.transitLineName,
    this.transitHeadsign,
  });
}

// Internal data class — holds the transit-specific fields parsed from steps
class _TransitStepInfo {
  final String? vehicleType;
  final String? lineColorHex;
  final bool hasBus;

  const _TransitStepInfo({
    this.vehicleType,
    this.lineColorHex,
    required this.hasBus,
  });
}

/// Service for getting directions using Google Maps Directions API
class GoogleDirectionsService {
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_DIRECTIONS_API_KEY',
    defaultValue: '',
  );
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  final http.Client _client;

  static final GoogleDirectionsService instance = GoogleDirectionsService();

  GoogleDirectionsService({http.Client? client})
      : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------

  Future<List<LatLng>?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking',
  }) async {
    final route = await getRouteDetails(
      origin: origin,
      destination: destination,
      mode: mode,
    );
    return route?.points;
  }

  //Helpers extracted to reduce cognitive complexity of getRouteDetails

  /// Builds and fires the Directions API request; returns the decoded JSON body or null on a non-200 response.
  Future<Map<String, dynamic>?> _fetchDirectionsJson({
    required LatLng origin,
    required LatLng destination,
    required String mode,
  }) async {
    final uri = Uri.parse('$_baseUrl/directions/json').replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': mode,
        'key': _apiKey,
      },
    );
    print(
      'Fetching directions from ${origin.latitude},${origin.longitude} '
      'to ${destination.latitude},${destination.longitude}',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      print('Directions API request failed with status: ${response.statusCode}');
      return null;
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Extracts the first route map from a decoded Directions API body, or returns null when the status is not OK or no routes are present.
  Map<String, dynamic>? _firstRouteOrNull(Map<String, dynamic> data) {
    if (data['status'] != 'OK') {
      print('Directions API returned status: ${data['status']}');
      return null;
    }
    final routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) {
      print('No routes found in response');
      return null;
    }
    return routes[0] as Map<String, dynamic>;
  }

  /// Scans a list of raw step maps and returns the combined transit metadata
  static _TransitStepInfo _extractTransitStepInfo(List<dynamic> steps) {
    const railTypes = {
      'SUBWAY', 'METRO_RAIL', 'HEAVY_RAIL', 'COMMUTER_TRAIN',
      'RAIL', 'TRAM', 'LIGHT_RAIL', 'MONORAIL',
    };

    String? vehicleType;
    String? lineColorHex;
    bool hasBus = false;

    for (final rawStep in steps) {
      final step = rawStep as Map<String, dynamic>;
      if (step['travel_mode'] != 'TRANSIT') continue;

      final transitDetails = step['transit_details'] as Map<String, dynamic>?;
      final line = transitDetails?['line'] as Map<String, dynamic>?;
      final vehicle = line?['vehicle'] as Map<String, dynamic>?;
      final type = (vehicle?['type'] as String?)?.toUpperCase();

      if (type == 'BUS') hasBus = true;

      if (type != null && railTypes.contains(type)) {
        vehicleType ??= type;
        lineColorHex ??= line?['color'] as String?;
      }

      vehicleType ??= type;
    }

    return _TransitStepInfo(
      vehicleType: vehicleType,
      lineColorHex: lineColorHex,
      hasBus: hasBus,
    );
  }

  /// Parses duration, distance, navigation steps, and transit metadata out of the first leg of a route.
  Map<String, dynamic> _parseLeg(
    Map<String, dynamic> leg,
    String mode,
  ) {
    final duration = leg['duration'] as Map<String, dynamic>?;
    final distance = leg['distance'] as Map<String, dynamic>?;
    final steps = leg['steps'] as List<dynamic>? ?? [];

    final transitInfo = _extractTransitStepInfo(steps);

    return {
      'durationText': duration?['text'] as String?,
      'durationSeconds': duration?['value'] as int?,
      'distanceText': distance?['text'] as String?,
      'transitVehicleType': transitInfo.vehicleType,
      'transitLineColorHex': transitInfo.lineColorHex,
      'transitHasBus': transitInfo.hasBus,
      'navSteps': _extractNavigationSteps(steps),
      'transitSegments':
          mode == 'transit' ? _extractTransitSegments(steps) : <DirectionsRouteSegment>[],
    };
  }


  Future<DirectionsRouteResult?> getRouteDetails({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking',
  }) async {
    try {
      final body = await _fetchDirectionsJson(
        origin: origin,
        destination: destination,
        mode: mode,
      );
      if (body == null) return null;

      final route = _firstRouteOrNull(body);
      if (route == null) return null;

      final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>;
      final decodedPoints = _decodePolyline(overviewPolyline['points'] as String);
      print('Successfully decoded ${decodedPoints.length} points for route');

      final legs = route['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) {
        return DirectionsRouteResult(points: decodedPoints, durationText: null);
      }

      final leg = _parseLeg(legs[0] as Map<String, dynamic>, mode);

      return DirectionsRouteResult(
        points: decodedPoints,
        durationText: leg['durationText'] as String?,
        distanceText: leg['distanceText'] as String?,
        durationSeconds: leg['durationSeconds'] as int?,
        transitVehicleType: leg['transitVehicleType'] as String?,
        transitLineColorHex: leg['transitLineColorHex'] as String?,
        transitHasBus: leg['transitHasBus'] as bool,
        transitSegments:
            leg['transitSegments'] as List<DirectionsRouteSegment>,
        steps: leg['navSteps'] as List<NavigationStep>,
      );
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  static List<DirectionsRouteSegment> _extractTransitSegments(
    List<dynamic> steps,
  ) {
    final segments = <DirectionsRouteSegment>[];

    for (final rawStep in steps) {
      final step = rawStep as Map<String, dynamic>;
      final travelMode = step['travel_mode'] as String?;
      if (travelMode != 'TRANSIT' && travelMode != 'WALKING') continue;

      final polyline = step['polyline'] as Map<String, dynamic>?;
      final encoded = polyline?['points'] as String?;
      if (encoded == null || encoded.isEmpty) continue;

      final duration = step['duration'] as Map<String, dynamic>?;
      final distance = step['distance'] as Map<String, dynamic>?;

      String? transitVehicleType;
      String? transitLineColorHex;
      String? transitLineShortName;
      String? transitLineName;
      String? transitHeadsign;

      if (travelMode == 'TRANSIT') {
        final transitDetails = step['transit_details'] as Map<String, dynamic>?;
        final line = transitDetails?['line'] as Map<String, dynamic>?;
        final vehicle = line?['vehicle'] as Map<String, dynamic>?;
        transitVehicleType = vehicle?['type'] as String?;
        transitLineColorHex = line?['color'] as String?;
        transitLineShortName = line?['short_name'] as String?;
        transitLineName = line?['name'] as String?;
        transitHeadsign = transitDetails?['headsign'] as String?;
      }

      segments.add(
        DirectionsRouteSegment(
          points: _decodePolyline(encoded),
          travelMode: travelMode ?? 'WALKING',
          durationText: duration?['text'] as String?,
          distanceText: distance?['text'] as String?,
          transitVehicleType: transitVehicleType,
          transitLineColorHex: transitLineColorHex,
          transitLineShortName: transitLineShortName,
          transitLineName: transitLineName,
          transitHeadsign: transitHeadsign,
        ),
      );
    }

    return segments;
  }

  static List<NavigationStep> _extractNavigationSteps(List<dynamic> steps) {
    final out = <NavigationStep>[];

    for (final rawStep in steps) {
      final step = rawStep as Map<String, dynamic>;
      final travelMode =
          (step['travel_mode'] as String?)?.toLowerCase() ?? 'walking';

      final polyline = step['polyline'] as Map<String, dynamic>?;
      final encoded = polyline?['points'] as String?;
      final stepPoints = (encoded != null && encoded.isNotEmpty)
          ? _decodePolyline(encoded)
          : <LatLng>[];
      final html = step['html_instructions'] as String? ?? '';
      final instruction = stripHtml(html);

      final distance = step['distance'] as Map<String, dynamic>?;
      final duration = step['duration'] as Map<String, dynamic>?;
      final maneuver = step['maneuver'] as String?;

      String? transitVehicleType;
      String? transitLineShortName;
      String? transitLineName;
      String? transitHeadsign;

      if (travelMode == 'transit') {
        final transitDetails = step['transit_details'] as Map<String, dynamic>?;
        final line = transitDetails?['line'] as Map<String, dynamic>?;
        final vehicle = line?['vehicle'] as Map<String, dynamic>?;
        transitVehicleType = (vehicle?['type'] as String?)?.toUpperCase();
        transitLineShortName = line?['short_name'] as String?;
        transitLineName = line?['name'] as String?;
        transitHeadsign = transitDetails?['headsign'] as String?;
      }

      if (instruction.trim().isEmpty && travelMode != 'transit') continue;

      out.add(
        NavigationStep(
          instruction: instruction.trim().isEmpty ? 'Continue' : instruction.trim(),
          travelMode: travelMode,
          points: stepPoints,
          distanceText: distance?['text'] as String?,
          durationText: duration?['text'] as String?,
          maneuver: maneuver,
          transitVehicleType: transitVehicleType,
          transitLineShortName: transitLineShortName,
          transitLineName: transitLineName,
          transitHeadsign: transitHeadsign,
        ),
      );
    }

    return out;
  }
}