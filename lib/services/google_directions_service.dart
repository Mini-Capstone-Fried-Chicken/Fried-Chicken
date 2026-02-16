import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for getting directions using Google Maps Directions API
class GoogleDirectionsService {
  static const String _apiKey = 'AIzaSyBu67d8z_Vd2eUsfASieUTgwkDHlRmk8GY';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  /// Get route polyline points from origin to destination
  /// Returns null if route cannot be found
  static Future<List<LatLng>?> getRoute({
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

      print('Fetching directions from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List<dynamic>;
          
          if (routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;
            final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>;
            final points = overviewPolyline['points'] as String;
            
            // Decode the polyline
            final decodedPoints = _decodePolyline(points);
            print('Successfully decoded ${decodedPoints.length} points for route');
            
            return decodedPoints;
          } else {
            print('No routes found in response');
            return null;
          }
        } else {
          print('Directions API returned status: ${data['status']}');
          return null;
        }
      } else {
        print('Directions API request failed with status: ${response.statusCode}');
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

      points.add(LatLng(
        lat / 1E5,
        lng / 1E5,
      ));
    }

    return points;
  }
}
