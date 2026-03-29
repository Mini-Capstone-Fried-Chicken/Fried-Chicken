import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/calendar_connection_state.dart';
import '../data/models/google_calendar_event.dart';
import '../data/models/google_calendar_info.dart';

class GoogleCalendarSession {
  GoogleCalendarSession._();

  static final GoogleCalendarSession instance = GoogleCalendarSession._();

  static const String _isConnectedKey = 'calendar_is_connected';
  static const String _stepKey = 'calendar_step';
  static const String _selectedCalendarIdsKey = 'calendar_selected_ids';

  bool isConnected = false;
  CalendarConnectionStep step = CalendarConnectionStep.connect;

  List<GoogleCalendarInfo> calendars = [];
  Set<String> selectedCalendarIds = {};
  List<GoogleCalendarEvent> events = [];

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isConnectedKey, isConnected);
    await prefs.setInt(_stepKey, step.index);
    await prefs.setStringList(
      _selectedCalendarIdsKey,
      selectedCalendarIds.toList(),
    );
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    isConnected = prefs.getBool(_isConnectedKey) ?? false;

    final stepIndex = prefs.getInt(_stepKey);
    if (stepIndex != null &&
        stepIndex >= 0 &&
        stepIndex < CalendarConnectionStep.values.length) {
      step = CalendarConnectionStep.values[stepIndex];
    } else {
      step = CalendarConnectionStep.connect;
    }

    selectedCalendarIds =
        (prefs.getStringList(_selectedCalendarIdsKey) ?? []).toSet();
  }

  Future<void> clear() async {
    isConnected = false;
    step = CalendarConnectionStep.connect;
    calendars = [];
    selectedCalendarIds = {};
    events = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isConnectedKey);
    await prefs.remove(_stepKey);
    await prefs.remove(_selectedCalendarIdsKey);
  }
}