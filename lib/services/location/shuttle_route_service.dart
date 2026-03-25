import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/concordia_shuttle_service.dart';
import '../../services/google_directions_service.dart';

/// Data class representing shuttle trip info
class ShuttleRouteData {
  final String nearestStop;
  final LatLng stopLatLng;
  final List<LatLng> walkToShuttlePoints;
  final List<LatLng> walkFromShuttlePoints;
  final List<LatLng> shuttleRoutePoints;
  final int? walkingToShuttleMinutes;
  final int? walkingFromShuttleMinutes;
  final String shuttleDurationLabel;
  final int? totalTripDuration;
  final List<ShuttleDeparture> buses;
  final bool isInService;
  final bool shouldUseWalking;

  ShuttleRouteData({
    required this.nearestStop,
    required this.stopLatLng,
    required this.walkToShuttlePoints,
    required this.walkFromShuttlePoints,
    required this.shuttleRoutePoints,
    required this.walkingToShuttleMinutes,
    required this.walkingFromShuttleMinutes,
    required this.shuttleDurationLabel,
    required this.totalTripDuration,
    required this.buses,
    required this.isInService,
    this.shouldUseWalking = false,
  });
}

/// Service class that calculates shuttle trip info using precomputed routes
class ShuttleRouteService {
  /// Fetch shuttle route info using precomputed walking/driving routes
  /// Returns null if walking is faster than shuttle
  static Future<ShuttleRouteData?> fetchShuttleRouteData({
    required String nearestStop,
    required LatLng stopLatLng,
    required DirectionsRouteResult? walkToShuttleRoute,
    required DirectionsRouteResult? walkFromShuttleRoute,
    required DirectionsRouteResult? shuttleDrivingRoute,
    required DirectionsRouteResult? directWalkRoute,
  }) async {
    final isInService = ConcordiaShuttleService.isInService();

    // Extract walking durations and points
    final walkingToMinutes = (walkToShuttleRoute?.durationSeconds ?? 0) ~/ 60;
    final walkToPoints = walkToShuttleRoute?.points ?? [];

    final walkingFromMinutes =
        (walkFromShuttleRoute?.durationSeconds ?? 0) ~/ 60;
    final walkFromPoints = walkFromShuttleRoute?.points ?? [];

    // Get next shuttle departures
    final buses = ConcordiaShuttleService.getNextDepartures(
      fromStop: nearestStop,
      now: DateTime.now(),
      count: 4,
      walkingDuration: Duration(minutes: walkingToMinutes),
    );

    // Calculate total trip duration
    String shuttleDurationLabel = 'No service';
    int? totalTripDuration;

    if (isInService && buses.isNotEmpty) {
      final busWaitMinutes =
          ShuttleRouteService.extractWaitMinutesFromStatusLabel(
            buses.first.statusLabel,
          );

      const shuttleRide = 18; // average shuttle ride duration
      final waitMinutes = (busWaitMinutes - walkingToMinutes).clamp(0, 999);
      totalTripDuration =
          waitMinutes + walkingToMinutes + shuttleRide + walkingFromMinutes;

      // Compare with direct walking route
      if (directWalkRoute != null) {
        final directWalkMinutes = ((directWalkRoute.durationSeconds ?? 0) / 60)
            .ceil();
        if (directWalkMinutes <= totalTripDuration) {
          return null; // walking is faster
        }
      }

      shuttleDurationLabel = totalTripDuration > 60
          ? '${totalTripDuration ~/ 60}h ${(totalTripDuration % 60).toString().padLeft(2, '0')}m'
          : '${totalTripDuration}min';
    }

    // Extract shuttle driving points
    final shuttleRoutePoints = shuttleDrivingRoute?.points ?? [];

    return ShuttleRouteData(
      nearestStop: nearestStop,
      stopLatLng: stopLatLng,
      walkToShuttlePoints: walkToPoints,
      walkFromShuttlePoints: walkFromPoints,
      shuttleRoutePoints: shuttleRoutePoints,
      walkingToShuttleMinutes: isInService ? walkingToMinutes : null,
      walkingFromShuttleMinutes: isInService ? walkingFromMinutes : null,
      shuttleDurationLabel: shuttleDurationLabel,
      totalTripDuration: isInService ? totalTripDuration : null,
      buses: buses,
      isInService: isInService,
    );
  }

  /// Parse "in X min" from shuttle status label
  static int extractWaitMinutesFromStatusLabel(String statusLabel) {
    final match = RegExp(
      r'in (\d+) min',
      caseSensitive: false,
    ).firstMatch(statusLabel);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  // Convert shuttle status label to actual time
  static String extractTimeFromStatusLabel(String statusLabel) {
    var regex = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)', caseSensitive: false);
    var match = regex.firstMatch(statusLabel);

    if (match != null) {
      final hour = match.group(1);
      final minute = match.group(2);
      final period = match.group(3);
      return '$hour:$minute ${period!.toLowerCase()}';
    }

    // Check for "in X min"
    regex = RegExp(r'in (\d+) min', caseSensitive: false);
    match = regex.firstMatch(statusLabel);

    if (match != null) {
      final waitMinutes = int.tryParse(match.group(1)!) ?? 0;
      final now = DateTime.now();

      // Ensure totalMinutes is always positive, wraps around 24 hours
      int totalMinutes =
          ((now.hour * 60 + now.minute + waitMinutes) % (24 * 60) + (24 * 60)) %
          (24 * 60);

      int hour = totalMinutes ~/ 60;
      int minute = totalMinutes % 60;

      // Convert to 12-hour format
      final period = hour >= 12 ? 'pm' : 'am';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    }
    return statusLabel;
  }
}
