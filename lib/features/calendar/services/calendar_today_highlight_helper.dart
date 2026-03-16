import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

List<TimeRegion> buildTodayHighlightRegion(CalendarView calendarView) {
  if (calendarView != CalendarView.week &&
      calendarView != CalendarView.day &&
      calendarView != CalendarView.workWeek) {
    return [];
  }

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return [
    TimeRegion(
      startTime: startOfDay,
      endTime: endOfDay,
      color: const Color(0xFF8B1E3F).withOpacity(0.28),
      enablePointerInteraction: false,
    ),
  ];
}
