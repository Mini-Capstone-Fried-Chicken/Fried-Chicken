import 'package:google_maps_flutter/google_maps_flutter.dart';

/// SGW shuttle stop — Hall Building entrance on De Maisonneuve Blvd W
const LatLng shuttleStopSGW = LatLng(45.497194, -73.578452);

/// Loyola shuttle stop — main entrance of the Loyola campus
const LatLng shuttleStopLoyola = LatLng(45.458052, -73.639134);


class ShuttleDeparture {
  final DateTime time;
  final String fromStop; // 'SGW' or 'Loyola'
  final String toStop;
  final Duration walkingTime;

  const ShuttleDeparture({
    required this.time,
    required this.fromStop,
    required this.toStop,
    this.walkingTime = Duration.zero,
  });

  int get minutesUntil =>
      (time.difference(DateTime.now()).inSeconds / 60).ceil();

  String get formattedTime => ConcordiaShuttleService.formatTime(time);

  String get statusLabel {
    final mins = minutesUntil;
    if (mins <= 0) return 'Departing now';
    if (mins == 1) return 'In 1 min';
    if (mins < 60) return 'In $mins min';
    return formattedTime;
  }
}

class ConcordiaShuttleService {
  static const int _weekdayStartHour = 8;
  static const int _weekdayEndHour = 22;
  static const int _weekdayIntervalMin = 30;

  static const int _weekendStartHour = 9;
  static const int _weekendEndHour = 18;
  static const int _weekendIntervalMin = 15;

  static bool isInService({DateTime? at}) {
    final t = at ?? DateTime.now();
    final weekday = t.weekday;
    final isWeekday = weekday >= DateTime.monday && weekday <= DateTime.friday;
    final start = isWeekday ? _weekdayStartHour : _weekendStartHour;
    final end = isWeekday ? _weekdayEndHour : _weekendEndHour;
    return t.hour >= start && t.hour < end;
  }

  static String nearestStop(LatLng location) {
    final dSGW = _distSq(location, shuttleStopSGW);
    final dLoyola = _distSq(location, shuttleStopLoyola);
    return dSGW <= dLoyola ? 'SGW' : 'Loyola';
  }

  static LatLng stopLocation(String stop) =>
      stop == 'SGW' ? shuttleStopSGW : shuttleStopLoyola;


  /// Appends departures for a single [day] into [departures], stopping once
  /// [count] is reached.  Only candidates at or after [earliestBoard] are added.
  static void _collectDeparturesForDay({
    required List<ShuttleDeparture> departures,
    required DateTime day,
    required DateTime earliestBoard,
    required String fromStop,
    required int count,
    required Duration walkingDuration,
  }) {
    final isWeekday =
        day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
    final intervalMin = isWeekday ? _weekdayIntervalMin : _weekendIntervalMin;
    final startHour = isWeekday ? _weekdayStartHour : _weekendStartHour;
    final endHour = isWeekday ? _weekdayEndHour : _weekendEndHour;

    var candidate = DateTime(day.year, day.month, day.day, startHour, 0);
    final endOfService = DateTime(day.year, day.month, day.day, endHour, 0);

    while (!candidate.isAfter(endOfService) && departures.length < count) {
      if (!candidate.isBefore(earliestBoard)) {
        departures.add(ShuttleDeparture(
          time: candidate,
          fromStop: fromStop,
          toStop: fromStop == 'SGW' ? 'Loyola' : 'SGW',
          walkingTime: walkingDuration,
        ));
      }
      candidate = candidate.add(Duration(minutes: intervalMin));
    }
  }

  static List<ShuttleDeparture> getNextDepartures({
    required String fromStop,
    required DateTime now,
    int count = 4,
    Duration walkingDuration = Duration.zero,
  }) {
    final departures = <ShuttleDeparture>[];
    final earliestBoard = now.add(walkingDuration);

    for (var dayOffset = 0; dayOffset <= 1 && departures.length < count; dayOffset++) {
      _collectDeparturesForDay(
        departures: departures,
        day: now.add(Duration(days: dayOffset)),
        earliestBoard: earliestBoard,
        fromStop: fromStop,
        count: count,
        walkingDuration: walkingDuration,
      );
    }

    return departures;
  }

  static List<DateTime> getFullScheduleForDay(DateTime day) {
    final isWeekday =
        day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
    final intervalMin = isWeekday ? _weekdayIntervalMin : _weekendIntervalMin;
    final startHour = isWeekday ? _weekdayStartHour : _weekendStartHour;
    final endHour = isWeekday ? _weekdayEndHour : _weekendEndHour;

    final times = <DateTime>[];
    var t = DateTime(day.year, day.month, day.day, startHour, 0);
    final end = DateTime(day.year, day.month, day.day, endHour, 0);

    while (!t.isAfter(end)) {
      times.add(t);
      t = t.add(Duration(minutes: intervalMin));
    }
    return times;
  }

  static String formatTime(DateTime dt) {
    final rawHour = dt.hour;
    final hour = rawHour % 12 == 0 ? 12 : rawHour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = rawHour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static double _distSq(LatLng a, LatLng b) {
    final dlat = a.latitude - b.latitude;
    final dlng = a.longitude - b.longitude;
    return dlat * dlat + dlng * dlng;
  }
}