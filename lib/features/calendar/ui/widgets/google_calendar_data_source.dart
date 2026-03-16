import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../data/models/google_calendar_event.dart';

class GoogleCalendarDataSource extends CalendarDataSource {
  GoogleCalendarDataSource(List<GoogleCalendarEvent> events) {
    appointments = events;
  }

  GoogleCalendarEvent _eventAt(int index) {
    return appointments![index] as GoogleCalendarEvent;
  }

  @override
  DateTime getStartTime(int index) {
    return _eventAt(index).start ?? DateTime.now();
  }

  @override
  DateTime getEndTime(int index) {
    final event = _eventAt(index);
    return event.end ??
        event.start?.add(const Duration(hours: 1)) ??
        DateTime.now();
  }

  @override
  String getSubject(int index) {
    return _eventAt(index).title;
  }

  @override
  bool isAllDay(int index) {
    return false;
  }

  @override
  getColor(int index) {
    return _eventAt(index).color;
  }
}