import 'package:flutter/material.dart';

class GoogleCalendarEvent {
  final String id;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final String? location;

  final String calendarId;
  final String calendarName;
  final Color color;

  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.calendarId,
    required this.calendarName,
    required this.color,
  });

  GoogleCalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    String? location,
    String? calendarId,
    String? calendarName,
    Color? color,
  }) {
    return GoogleCalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      calendarId: calendarId ?? this.calendarId,
      calendarName: calendarName ?? this.calendarName,
      color: color ?? this.color,
    );
  }
}