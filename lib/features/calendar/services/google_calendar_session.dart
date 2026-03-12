import '../data/models/calendar_connection_state.dart';
import '../data/models/google_calendar_event.dart';
import '../data/models/google_calendar_info.dart';

class GoogleCalendarSession {
  GoogleCalendarSession._();

  static final GoogleCalendarSession instance = GoogleCalendarSession._();

  bool isConnected = false;
  CalendarConnectionStep step = CalendarConnectionStep.connect;

  List<GoogleCalendarInfo> calendars = [];
  Set<String> selectedCalendarIds = {};
  List<GoogleCalendarEvent> events = [];

  void clear() {
    isConnected = false;
    step = CalendarConnectionStep.connect;
    calendars = [];
    selectedCalendarIds = {};
    events = [];
  }
}