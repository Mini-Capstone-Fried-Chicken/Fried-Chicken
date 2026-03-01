import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsRouteResult {
  final List<LatLng> points;
  final String? durationText;
  final String? distanceText;
  final int? durationSeconds;
  final String? transitVehicleType;
  final String? transitLineColorHex;
  final bool transitHasBus;
  final List<DirectionsRouteSegment> transitSegments;

  const DirectionsRouteResult({
    required this.points,
    required this.durationText,
    this.distanceText,
    this.durationSeconds,
    this.transitVehicleType,
    this.transitLineColorHex,
    this.transitHasBus = false,
    this.transitSegments = const [],
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

/// Service for getting directions using Google Maps Directions API
class GoogleDirectionsService {
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_DIRECTIONS_API_KEY',
    defaultValue: '', // Use empty string if not provided for safety
  );
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  /// HTTP client for making requests (injectable for testing)
  final http.Client _client;

  /// Default singleton instance
  static final GoogleDirectionsService instance = GoogleDirectionsService();

  /// Constructor with optional HTTP client injection
  GoogleDirectionsService({http.Client? client})
    : _client = client ?? http.Client();

  /// Get route polyline points from origin to destination
  /// Returns null if route cannot be found
  Future<List<LatLng>?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking', // walking, driving, bicycling, transit
  }) async {
    final route = await getRouteDetails(
      origin: origin,
      destination: destination,
      mode: mode,
    );
    return route?.points;
  }

  /// Get route details from origin to destination.
  /// Returns decoded polyline points and leg duration text when available.
  Future<DirectionsRouteResult?> getRouteDetails({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking', // walking, driving, bicycling, transit
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/directions/json').replace(
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': mode,
          'key': _apiKey,
        },
      );

      print(
        'Fetching directions from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}',
      );

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List<dynamic>;

          if (routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;
            final overviewPolyline =
                route['overview_polyline'] as Map<String, dynamic>;
            final points = overviewPolyline['points'] as String;
            final legs = route['legs'] as List<dynamic>?;
            String? durationText;
            String? distanceText;
            int? durationSeconds;
            String? transitVehicleType;
            String? transitLineColorHex;
            bool transitHasBus = false;
            List<DirectionsRouteSegment> transitSegments = [];
            if (legs != null && legs.isNotEmpty) {
              final firstLeg = legs[0] as Map<String, dynamic>;
              final duration = firstLeg['duration'] as Map<String, dynamic>?;
              durationText = duration?['text'] as String?;
              durationSeconds = duration?['value'] as int?;
              final distance = firstLeg['distance'] as Map<String, dynamic>?;
              distanceText = distance?['text'] as String?;

              final steps = firstLeg['steps'] as List<dynamic>?;
              if (steps != null) {
                const railTypes = {
                  'SUBWAY',
                  'METRO_RAIL',
                  'HEAVY_RAIL',
                  'COMMUTER_TRAIN',
                  'RAIL',
                  'TRAM',
                  'LIGHT_RAIL',
                  'MONORAIL',
                };
                for (final rawStep in steps) {
                  final step = rawStep as Map<String, dynamic>;
                  final travelMode = step['travel_mode'] as String?;
                  if (travelMode != 'TRANSIT') continue;

                  final transitDetails =
                      step['transit_details'] as Map<String, dynamic>?;
                  final line = transitDetails?['line'] as Map<String, dynamic>?;
                  final vehicle = line?['vehicle'] as Map<String, dynamic>?;

                  final rawType = vehicle?['type'] as String?;
                  final vehicleType = rawType?.toUpperCase();

                  if (vehicleType == 'BUS') {
                    transitHasBus = true;
                  }

                  if (vehicleType != null && railTypes.contains(vehicleType)) {
                    transitVehicleType ??= vehicleType;
                    transitLineColorHex ??= line?['color'] as String?;
                  }

                  if (transitVehicleType == null) {
                    transitVehicleType = vehicleType;
                  }
                }

                if (mode == 'transit') {
                  transitSegments = _extractTransitSegments(steps);
                }
              }
            }

            // Decode the polyline
            final decodedPoints = _decodePolyline(points);
            print(
              'Successfully decoded ${decodedPoints.length} points for route',
            );

            return DirectionsRouteResult(
              points: decodedPoints,
              durationText: durationText,
              distanceText: distanceText,
              durationSeconds: durationSeconds,
              transitVehicleType: transitVehicleType,
              transitLineColorHex: transitLineColorHex,
              transitHasBus: transitHasBus,
              transitSegments: transitSegments,
            );
          } else {
            print('No routes found in response');
            return null;
          }
        } else {
          print('Directions API returned status: ${data['status']}');
          return null;
        }
      } else {
        print(
          'Directions API request failed with status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  /// Decode Google Maps encoded polyline string
  /// Based on Google's polyline encoding algorithm
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
      if (travelMode != 'TRANSIT' && travelMode != 'WALKING') {
        continue;
      }

      final polyline = step['polyline'] as Map<String, dynamic>?;
      final encoded = polyline?['points'] as String?;
      if (encoded == null || encoded.isEmpty) {
        continue;
      }

      final duration = step['duration'] as Map<String, dynamic>?;
      final distance = step['distance'] as Map<String, dynamic>?;
      final durationText = duration?['text'] as String?;
      final distanceText = distance?['text'] as String?;

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
          durationText: durationText,
          distanceText: distanceText,
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
}
