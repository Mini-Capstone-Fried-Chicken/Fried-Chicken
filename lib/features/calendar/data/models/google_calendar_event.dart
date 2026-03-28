import 'package:flutter/material.dart';

class GoogleCalendarEventCalendarUpdate {
  final String? calendarId;
  final String? calendarName;
  final Color? color;

  const GoogleCalendarEventCalendarUpdate({
    this.calendarId,
    this.calendarName,
    this.color,
  });
}

class GoogleCalendarEvent {
  final String id;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final String? location;
  final String? description;

  final String calendarId;
  final String calendarName;
  final Color color;

  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    this.start,
    this.end,
    this.location,
    this.description,
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
    String? description,
    GoogleCalendarEventCalendarUpdate? calendarInfo,
  }) {
    return GoogleCalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      description: description ?? this.description,
      calendarId: calendarInfo?.calendarId ?? calendarId,
      calendarName: calendarInfo?.calendarName ?? calendarName,
      color: calendarInfo?.color ?? color,
    );
  }
}
