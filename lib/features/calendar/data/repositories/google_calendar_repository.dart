import 'package:flutter/material.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../models/calendar_connection_state.dart';
import '../models/google_calendar_event.dart';
import '../models/google_calendar_info.dart';
import '../../services/google_calendar_api_service.dart';
import '../../services/google_calendar_auth_service.dart';
import '../../services/google_calendar_session.dart';

class GoogleCalendarRepository {
  GoogleCalendarRepository({
    GoogleCalendarAuthService? authService,
    GoogleCalendarApiService? apiService,
  })  : authService = authService ?? GoogleCalendarAuthService.instance,
        apiService = apiService ?? GoogleCalendarApiService();

  static final GoogleCalendarRepository instance = GoogleCalendarRepository();

  final GoogleCalendarAuthService authService;
  final GoogleCalendarApiService apiService;

  CalendarSessionState _session = const CalendarSessionState.initial();

  List<GoogleCalendarInfo> _cachedCalendars = [];
  List<GoogleCalendarEvent> _cachedEvents = [];

  static const List<Color> _calendarPalette = [
    Color(0xFF8B1E3F),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
  ];

  CalendarSessionState get session => _session;
  List<GoogleCalendarInfo> get cachedCalendars => _cachedCalendars;
  List<GoogleCalendarEvent> get cachedEvents => _cachedEvents;

  Future<bool> connect() async {
    await authService.initialize(
      serverClientId: GoogleCalendarAuthService.webServerClientId,
    );

    final connected = await authService.signIn();

    if (connected) {
      _session = _session.copyWith(
        isConnected: true,
        step: CalendarConnectionStep.selectCalendar,
      );
    }

    return connected;
  }

  Future<List<GoogleCalendarInfo>> getCalendars() async {
    if (_cachedCalendars.isNotEmpty) {
      return _cachedCalendars;
    }

    final AuthClient? client = await authService.getAuthenticatedClient();
    if (client == null) return [];

    try {
      final calendars = await apiService.fetchCalendars(client);
      _cachedCalendars = calendars;
      return calendars;
    } finally {
      client.close();
    }
  }

  Future<List<GoogleCalendarEvent>> getUpcomingEventsForCalendars(
    List<GoogleCalendarInfo> calendars,
  ) async {
    final AuthClient? client = await authService.getAuthenticatedClient();
    if (client == null) return [];

    try {
      final List<GoogleCalendarEvent> mergedEvents = [];

      for (int i = 0; i < calendars.length; i++) {
        final calendar = calendars[i];
        final color = _calendarPalette[i % _calendarPalette.length];

        final events = await apiService.fetchUpcomingEvents(
          client,
          calendarId: calendar.id,
        );

        final enriched = events
            .map(
              (event) => event.copyWith(
                calendarId: calendar.id,
                calendarName: calendar.name,
                color: color,
              ),
            )
            .toList();

        mergedEvents.addAll(enriched);
      }

      mergedEvents.sort((a, b) {
        final aStart = a.start ?? DateTime.now();
        final bStart = b.start ?? DateTime.now();
        return aStart.compareTo(bStart);
      });

      _cachedEvents = mergedEvents;

      _session = _session.copyWith(
        step: CalendarConnectionStep.schedule,
        selectedCalendarIds: calendars.map((c) => c.id).toList(),
      );

      return mergedEvents;
    } finally {
      client.close();
    }
  }

  void updateSelectedCalendars(List<String> ids) {
    _session = _session.copyWith(
      selectedCalendarIds: ids,
    );
  }

  void goToSelection() {
    _session = _session.copyWith(
      step: CalendarConnectionStep.selectCalendar,
    );
  }

  Future<void> disconnect() async {
    await authService.signOut();
    _session = const CalendarSessionState.initial();
    _cachedCalendars = [];
    _cachedEvents = [];
    GoogleCalendarSession.instance.clear();
  }
}